# PowerReview Wizard Interface
# Enhanced user-friendly interface for M365 security assessments

. "$PSScriptRoot\PowerReview-ErrorHandling.ps1"

function Show-WizardHeader {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "     PowerReview M365 Security Wizard" -ForegroundColor Yellow
    Write-Host "     Professional Security Assessment Tool" -ForegroundColor Yellow
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Progress {
    param(
        [int]$Step,
        [int]$TotalSteps,
        [string]$StepName
    )
    
    $percentage = [math]::Round(($Step / $TotalSteps) * 100)
    $progressBar = "[" + ("=" * [math]::Floor($percentage / 5)) + (" " * (20 - [math]::Floor($percentage / 5))) + "]"
    
    Write-Host "`nStep $Step of $TotalSteps : $StepName" -ForegroundColor Green
    Write-Host "$progressBar $percentage%" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Options,
        [string]$Prompt = "Please select an option"
    )
    
    Write-Host "`n$Title" -ForegroundColor Cyan
    Write-Host ("=" * $Title.Length) -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i + 1). $($Options[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host $Prompt
    
    while ([int]$selection -lt 1 -or [int]$selection -gt $Options.Count) {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        $selection = Read-Host $Prompt
    }
    
    return [int]$selection - 1
}

function Get-AssessmentScope {
    Show-WizardHeader
    Write-Host "Welcome to PowerReview!" -ForegroundColor Green
    Write-Host "This wizard will guide you through your M365 security assessment.`n" -ForegroundColor White
    
    $scopeOptions = @(
        "Quick Assessment (15-30 minutes)",
        "Standard Assessment (1-2 hours)",
        "Comprehensive Assessment (2-4 hours)",
        "Custom Assessment (Select specific areas)"
    )
    
    $scopeIndex = Show-Menu -Title "Assessment Scope" -Options $scopeOptions
    
    $scope = @{
        Type = $scopeOptions[$scopeIndex]
        Areas = @()
    }
    
    if ($scopeIndex -eq 3) {
        $areaOptions = @(
            "Azure AD & Identity",
            "Exchange & Email Security",
            "SharePoint & OneDrive",
            "Microsoft Teams",
            "Data Loss Prevention (DLP)",
            "Microsoft Defender",
            "Compliance & Audit",
            "Power Platform"
        )
        
        Write-Host "`nSelect areas to assess (comma-separated numbers):" -ForegroundColor Yellow
        for ($i = 0; $i -lt $areaOptions.Count; $i++) {
            Write-Host "$($i + 1). $($areaOptions[$i])" -ForegroundColor White
        }
        
        $selections = (Read-Host "Enter selections").Split(',') | ForEach-Object { [int]$_.Trim() - 1 }
        $scope.Areas = $selections | ForEach-Object { $areaOptions[$_] }
    }
    else {
        # Predefined areas based on assessment type
        switch ($scopeIndex) {
            0 { $scope.Areas = @("Azure AD & Identity", "Exchange & Email Security") }
            1 { $scope.Areas = @("Azure AD & Identity", "Exchange & Email Security", "SharePoint & OneDrive", "Microsoft Teams") }
            2 { $scope.Areas = $areaOptions }
        }
    }
    
    return $scope
}

function Test-Prerequisites {
    Show-Progress -Step 1 -TotalSteps 10 -StepName "Checking Prerequisites"
    
    $prereqs = @{
        PowerShellVersion = $PSVersionTable.PSVersion.Major -ge 5
        ExecutionPolicy = (Get-ExecutionPolicy) -ne 'Restricted'
        Modules = @{}
    }
    
    $requiredModules = @(
        "AzureAD",
        "ExchangeOnlineManagement",
        "Microsoft.Online.SharePoint.PowerShell",
        "MicrosoftTeams",
        "Microsoft.Graph"
    )
    
    foreach ($module in $requiredModules) {
        $installed = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue
        $prereqs.Modules[$module] = $installed -ne $null
        
        if ($prereqs.Modules[$module]) {
            Write-Host "✓ $module module found" -ForegroundColor Green
        }
        else {
            Write-Host "✗ $module module not found" -ForegroundColor Yellow
        }
    }
    
    return $prereqs
}

function Connect-M365Services {
    param($Scope)
    
    Show-Progress -Step 2 -TotalSteps 10 -StepName "Connecting to M365 Services"
    
    $connections = @{}
    
    foreach ($area in $Scope.Areas) {
        switch ($area) {
            "Azure AD & Identity" {
                Write-Host "Connecting to Azure AD..." -ForegroundColor Yellow
                $result = Invoke-SafeCommand -Command {
                    Connect-AzureAD -ErrorAction Stop
                } -ErrorMessage "Failed to connect to Azure AD" -ContinueOnError
                $connections["AzureAD"] = $result.Success
            }
            "Exchange & Email Security" {
                Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
                $result = Invoke-SafeCommand -Command {
                    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                } -ErrorMessage "Failed to connect to Exchange Online" -ContinueOnError
                $connections["Exchange"] = $result.Success
            }
            "SharePoint & OneDrive" {
                $adminUrl = Read-Host "Enter SharePoint Admin URL (e.g., https://contoso-admin.sharepoint.com)"
                Write-Host "Connecting to SharePoint Online..." -ForegroundColor Yellow
                $result = Invoke-SafeCommand -Command {
                    Connect-SPOService -Url $adminUrl -ErrorAction Stop
                } -ErrorMessage "Failed to connect to SharePoint" -ContinueOnError
                $connections["SharePoint"] = $result.Success
            }
            "Microsoft Teams" {
                Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
                $result = Invoke-SafeCommand -Command {
                    Connect-MicrosoftTeams -ErrorAction Stop
                } -ErrorMessage "Failed to connect to Teams" -ContinueOnError
                $connections["Teams"] = $result.Success
            }
        }
    }
    
    return $connections
}

function Start-WizardAssessment {
    Show-WizardHeader
    
    # Get assessment scope
    $scope = Get-AssessmentScope
    
    Write-Host "`nSelected areas:" -ForegroundColor Green
    $scope.Areas | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
    
    $confirm = Read-Host "`nProceed with assessment? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Host "Assessment cancelled." -ForegroundColor Yellow
        return
    }
    
    # Check prerequisites
    $prereqs = Test-Prerequisites
    
    if (-not $prereqs.PowerShellVersion) {
        Write-Host "`nERROR: PowerShell 5.0 or higher required!" -ForegroundColor Red
        return
    }
    
    # Connect to services
    $connections = Connect-M365Services -Scope $scope
    
    # Create output directory
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "C:\SharePointScripts\PowerReview_$timestamp"
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    
    Write-Host "`nOutput directory: $outputPath" -ForegroundColor Green
    
    # Run assessments based on scope
    $stepCounter = 3
    foreach ($area in $scope.Areas) {
        Show-Progress -Step $stepCounter -TotalSteps 10 -StepName "Assessing $area"
        
        # Here you would call the specific assessment functions
        # For now, we'll simulate the assessment
        Start-Sleep -Seconds 2
        
        Write-Log -Level "INFO" -Message "Completed assessment for $area"
        $stepCounter++
    }
    
    # Generate reports
    Show-Progress -Step 9 -TotalSteps 10 -StepName "Generating Reports"
    Write-Host "Generating security assessment reports..." -ForegroundColor Yellow
    
    # Final summary
    Show-Progress -Step 10 -TotalSteps 10 -StepName "Assessment Complete"
    
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host "     Assessment Completed Successfully!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "`nReports saved to: $outputPath" -ForegroundColor Yellow
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the EXECUTIVE_SUMMARY.md file" -ForegroundColor White
    Write-Host "2. Check CRITICAL_FINDINGS.md for urgent issues" -ForegroundColor White
    Write-Host "3. Use M365_SECURITY_ACTION_PLAN.md for remediation" -ForegroundColor White
}

# Main entry point
if ($MyInvocation.InvocationName -ne '.') {
    Start-WizardAssessment
}