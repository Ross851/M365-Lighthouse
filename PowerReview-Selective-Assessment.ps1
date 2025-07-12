# PowerReview Selective Assessment Script
# Executes only selected security areas based on user input

param(
    [Parameter(Mandatory=$true)]
    [string]$SessionId,
    
    [Parameter(Mandatory=$true)]
    [string]$SelectedAreasJson,
    
    [string]$OutputPath = ".\Output\$SessionId",
    [string]$CustomerName = "Assessment"
)

# Load required modules
. .\PowerReview-ErrorHandling.ps1

# Parse selected areas
$selectedAreas = $SelectedAreasJson | ConvertFrom-Json

Write-Host "Starting selective assessment for $($selectedAreas.Count) security areas" -ForegroundColor Cyan

# Group areas by service
$serviceGroups = $selectedAreas | Group-Object -Property service

# Define assessment functions for each area
$assessmentFunctions = @{
    # Azure AD & Identity
    "azuread.user-risk" = {
        Write-Host "Assessing User Risk Analysis..." -ForegroundColor Yellow
        # Get risky users
        $riskyUsers = Get-SafeCommand { Get-MgRiskyUser -All }
        # Get sign-in risk events
        $riskDetections = Get-SafeCommand { Get-MgRiskDetection -Top 100 }
        # Get identity protection policies
        $identityPolicies = Get-SafeCommand { Get-MgIdentityConditionalAccessPolicy -All | Where-Object { $_.Conditions.SignInRiskLevels -ne $null } }
        
        return @{
            RiskyUsers = $riskyUsers
            RiskDetections = $riskDetections
            IdentityProtectionPolicies = $identityPolicies
            TotalRiskyUsers = $riskyUsers.Count
            HighRiskUsers = ($riskyUsers | Where-Object { $_.RiskLevel -eq "high" }).Count
        }
    }
    
    "azuread.pim" = {
        Write-Host "Assessing Privileged Identity Management..." -ForegroundColor Yellow
        # Get eligible role assignments
        $eligibleRoles = Get-SafeCommand { Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All }
        # Get active role assignments
        $activeRoles = Get-SafeCommand { Get-MgRoleManagementDirectoryRoleAssignment -All }
        # Get PIM policies
        $pimPolicies = Get-SafeCommand { Get-MgPolicyRoleManagementPolicy -All }
        
        return @{
            EligibleAssignments = $eligibleRoles
            ActiveAssignments = $activeRoles
            PIMPolicies = $pimPolicies
            TotalPrivilegedUsers = ($activeRoles | Select-Object -ExpandProperty PrincipalId -Unique).Count
        }
    }
    
    "azuread.mfa" = {
        Write-Host "Assessing MFA Coverage..." -ForegroundColor Yellow
        # Get users with MFA status
        $users = Get-SafeCommand { Get-MgUser -All -Property UserPrincipalName,Id,DisplayName }
        $mfaStatus = @()
        
        foreach ($user in $users) {
            $authMethods = Get-SafeCommand { Get-MgUserAuthenticationMethod -UserId $user.Id }
            $mfaStatus += @{
                User = $user.UserPrincipalName
                MFAEnabled = ($authMethods.Count -gt 1)
                Methods = $authMethods | Select-Object -ExpandProperty '@odata.type'
            }
        }
        
        return @{
            MFAStatus = $mfaStatus
            TotalUsers = $users.Count
            MFAEnabledUsers = ($mfaStatus | Where-Object { $_.MFAEnabled }).Count
            MFACoverage = [math]::Round((($mfaStatus | Where-Object { $_.MFAEnabled }).Count / $users.Count) * 100, 2)
        }
    }
    
    "azuread.conditional-access" = {
        Write-Host "Assessing Conditional Access Policies..." -ForegroundColor Yellow
        $policies = Get-SafeCommand { Get-MgIdentityConditionalAccessPolicy -All }
        $namedLocations = Get-SafeCommand { Get-MgIdentityConditionalAccessNamedLocation -All }
        
        # Analyze policy gaps
        $gaps = @()
        if (-not ($policies | Where-Object { $_.Conditions.Applications.IncludeApplications -contains "All" })) {
            $gaps += "No policy covering all applications"
        }
        if (-not ($policies | Where-Object { $_.Conditions.Users.IncludeUsers -contains "All" })) {
            $gaps += "No policy covering all users"
        }
        
        return @{
            Policies = $policies
            NamedLocations = $namedLocations
            PolicyGaps = $gaps
            TotalPolicies = $policies.Count
            EnabledPolicies = ($policies | Where-Object { $_.State -eq "enabled" }).Count
        }
    }
    
    "azuread.guest" = {
        Write-Host "Assessing Guest & External Access..." -ForegroundColor Yellow
        $guestUsers = Get-SafeCommand { Get-MgUser -All -Filter "userType eq 'Guest'" }
        $b2bPolicy = Get-SafeCommand { Get-MgPolicyAuthorizationPolicy }
        $externalIdentities = Get-SafeCommand { Get-MgPolicyCrossTenantAccessPolicy }
        
        return @{
            GuestUsers = $guestUsers
            B2BSettings = $b2bPolicy
            ExternalIdentitySettings = $externalIdentities
            TotalGuests = $guestUsers.Count
            ActiveGuests = ($guestUsers | Where-Object { $_.AccountEnabled }).Count
        }
    }
    
    # Exchange Online
    "exchange.safe-attachments" = {
        Write-Host "Assessing Safe Attachments Policies..." -ForegroundColor Yellow
        $policies = Get-SafeCommand { Get-SafeAttachmentPolicy }
        $rules = Get-SafeCommand { Get-SafeAttachmentRule }
        
        return @{
            Policies = $policies
            Rules = $rules
            TotalPolicies = $policies.Count
            EnabledPolicies = ($rules | Where-Object { $_.State -eq "Enabled" }).Count
        }
    }
    
    "exchange.safe-links" = {
        Write-Host "Assessing Safe Links Policies..." -ForegroundColor Yellow
        $policies = Get-SafeCommand { Get-SafeLinksPolicy }
        $rules = Get-SafeCommand { Get-SafeLinksRule }
        
        return @{
            Policies = $policies
            Rules = $rules
            TotalPolicies = $policies.Count
            EnabledPolicies = ($rules | Where-Object { $_.State -eq "Enabled" }).Count
        }
    }
    
    "exchange.anti-phishing" = {
        Write-Host "Assessing Anti-Phishing Policies..." -ForegroundColor Yellow
        $policies = Get-SafeCommand { Get-AntiPhishPolicy }
        $rules = Get-SafeCommand { Get-AntiPhishRule }
        
        return @{
            Policies = $policies
            Rules = $rules
            ImpersonationProtection = $policies | Where-Object { $_.EnableTargetedUserProtection -or $_.EnableTargetedDomainsProtection }
            TotalPolicies = $policies.Count
        }
    }
    
    # Add more assessment functions for other areas...
}

# Execute selected assessments
$results = @{}
$totalAreas = $selectedAreas.Count
$currentArea = 0

foreach ($area in $selectedAreas) {
    $currentArea++
    $areaKey = "$($area.service).$($area.area)"
    Write-Progress -Activity "Security Assessment" -Status "Assessing $($area.name)" -PercentComplete (($currentArea / $totalAreas) * 100)
    
    if ($assessmentFunctions.ContainsKey($areaKey)) {
        try {
            $results[$areaKey] = & $assessmentFunctions[$areaKey]
            Send-StreamUpdate -Type "progress" -Data @{
                current = $currentArea
                total = $totalAreas
                area = $area.name
                status = "completed"
            }
        }
        catch {
            Write-Warning "Failed to assess $($area.name): $_"
            $results[$areaKey] = @{
                Error = $_.Exception.Message
                Status = "Failed"
            }
            Send-StreamUpdate -Type "progress" -Data @{
                current = $currentArea
                total = $totalAreas
                area = $area.name
                status = "failed"
                error = $_.Exception.Message
            }
        }
    }
    else {
        Write-Warning "No assessment function defined for $areaKey"
    }
}

# Save results
$outputFile = Join-Path $OutputPath "selective-assessment-results.json"
$results | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8

# Generate summary
$summary = @{
    SessionId = $SessionId
    CustomerName = $CustomerName
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    AreasAssessed = $selectedAreas.Count
    AreasCompleted = ($results.Keys | Where-Object { $results[$_].Status -ne "Failed" }).Count
    AreasFailed = ($results.Keys | Where-Object { $results[$_].Status -eq "Failed" }).Count
    Results = $results
}

$summaryFile = Join-Path $OutputPath "assessment-summary.json"
$summary | ConvertTo-Json -Depth 10 | Out-File $summaryFile -Encoding UTF8

Write-Host "`nSelective assessment completed!" -ForegroundColor Green
Write-Host "Results saved to: $outputFile" -ForegroundColor Cyan

# Helper function to send updates
function Send-StreamUpdate {
    param(
        [string]$Type,
        [hashtable]$Data
    )
    
    $streamData = @{
        type = $Type
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        sessionId = $SessionId
    } + $Data
    
    Write-Host "STREAM:$($streamData | ConvertTo-Json -Compress)"
}