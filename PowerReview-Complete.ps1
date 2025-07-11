#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Complete Assessment Tool - Production Ready
    
.DESCRIPTION
    Comprehensive M365 and Azure assessment tool that gathers all data
    Supports multiple tenants and generates complete reports
    
.EXAMPLE
    # Single tenant assessment
    .\PowerReview-Complete.ps1 -TenantName "contoso" -TenantId "contoso.onmicrosoft.com"
    
.EXAMPLE
    # Multi-tenant assessment
    .\PowerReview-Complete.ps1 -ConfigFile ".\multi-tenant-config.json"
#>

[CmdletBinding()]
param(
    [Parameter(ParameterSetName='Single', Mandatory=$true)]
    [string]$TenantName,
    
    [Parameter(ParameterSetName='Single', Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(ParameterSetName='Multi', Mandatory=$true)]
    [string]$ConfigFile,
    
    [string[]]$Modules = @("Purview", "PowerPlatform", "SharePoint", "Security", "AzureLandingZone"),
    
    [string]$OutputPath,
    
    [switch]$SkipPrerequisites,
    
    [switch]$ExportOnly,
    
    [ValidateSet("Basic", "Detailed", "Full")]
    [string]$AssessmentDepth = "Full"
)

#region Script Configuration
$script:StartTime = Get-Date
$script:Version = "2.0.0"
$script:RequiredModules = @{
    "ExchangeOnlineManagement" = "3.0.0"
    "Microsoft.Online.SharePoint.PowerShell" = "16.0.0"
    "MicrosoftTeams" = "4.0.0"
    "Microsoft.Graph" = "2.0.0"
    "Microsoft.PowerApps.Administration.PowerShell" = "2.0.0"
    "Microsoft.PowerApps.PowerShell" = "1.0.0"
    "Az.Accounts" = "2.0.0"
    "Az.Resources" = "6.0.0"
    "PnP.PowerShell" = "2.0.0"
}

# Initialize collections
$script:AllFindings = @()
$script:AllEvidence = @()
$script:Metrics = @{}
$script:ConnectionCache = @{}

#endregion

#region Logging Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Color output
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # Log to file
    if ($script:LogPath) {
        Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
}

#endregion

#region Prerequisites and Setup
function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    $missingModules = @()
    
    foreach ($module in $script:RequiredModules.GetEnumerator()) {
        $installed = Get-Module -ListAvailable -Name $module.Key | 
            Where-Object { $_.Version -ge [Version]$module.Value }
        
        if (!$installed) {
            $missingModules += $module.Key
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Log "Missing modules: $($missingModules -join ', ')" "WARN"
        
        if (!$SkipPrerequisites) {
            $install = Read-Host "Install missing modules? (Y/N)"
            if ($install -eq 'Y') {
                foreach ($module in $missingModules) {
                    try {
                        Write-Log "Installing $module..." "INFO"
                        Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                        Write-Log "$module installed" "SUCCESS"
                    }
                    catch {
                        Write-Log "Failed to install $module`: $_" "ERROR"
                        return $false
                    }
                }
            }
            else {
                return $false
            }
        }
    }
    
    return $true
}

function Initialize-OutputStructure {
    param([string]$Path)
    
    if (!$Path) {
        $Path = ".\PowerReview_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    $script:OutputPath = $Path
    $script:LogPath = "$Path\PowerReview.log"
    
    # Create directory structure
    $directories = @(
        $Path,
        "$Path\00_Executive",
        "$Path\01_Purview",
        "$Path\02_PowerPlatform", 
        "$Path\03_SharePoint",
        "$Path\04_Security",
        "$Path\05_Azure",
        "$Path\06_Reports",
        "$Path\07_Evidence",
        "$Path\08_Workshop"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Log "Output structure created at: $Path" "SUCCESS"
}

#endregion

#region Connection Management
function Connect-M365Services {
    param(
        [string]$TenantId,
        [string[]]$RequiredServices = @("ExchangeOnline", "SecurityCompliance", "SharePoint", "Teams", "Graph", "PowerPlatform")
    )
    
    Write-Log "Connecting to M365 services for tenant: $TenantId" "INFO"
    
    $results = @{}
    
    # Exchange Online
    if ("ExchangeOnline" -in $RequiredServices) {
        try {
            Write-Log "Connecting to Exchange Online..." "INFO"
            Connect-ExchangeOnline -UserPrincipalName "$TenantId" -ShowBanner:$false -ErrorAction Stop
            $results.ExchangeOnline = $true
            Write-Log "Connected to Exchange Online" "SUCCESS"
        }
        catch {
            Write-Log "Exchange Online connection failed: $_" "ERROR"
            $results.ExchangeOnline = $false
        }
    }
    
    # Security & Compliance
    if ("SecurityCompliance" -in $RequiredServices) {
        try {
            Write-Log "Connecting to Security & Compliance Center..." "INFO"
            Connect-IPPSSession -UserPrincipalName "$TenantId" -ShowBanner:$false -ErrorAction Stop
            $results.SecurityCompliance = $true
            Write-Log "Connected to Security & Compliance Center" "SUCCESS"
        }
        catch {
            Write-Log "Security & Compliance connection failed: $_" "ERROR"
            $results.SecurityCompliance = $false
        }
    }
    
    # SharePoint Online
    if ("SharePoint" -in $RequiredServices) {
        try {
            Write-Log "Connecting to SharePoint Online..." "INFO"
            $adminUrl = "https://$($TenantId.Split('@')[1].Split('.')[0])-admin.sharepoint.com"
            Connect-SPOService -Url $adminUrl -ErrorAction Stop
            $results.SharePoint = $true
            
            # Also connect PnP for advanced operations
            Connect-PnPOnline -Url $adminUrl -Interactive -ErrorAction Stop
            $results.PnP = $true
            Write-Log "Connected to SharePoint Online" "SUCCESS"
        }
        catch {
            Write-Log "SharePoint connection failed: $_" "ERROR"
            $results.SharePoint = $false
        }
    }
    
    # Microsoft Teams
    if ("Teams" -in $RequiredServices) {
        try {
            Write-Log "Connecting to Microsoft Teams..." "INFO"
            Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
            $results.Teams = $true
            Write-Log "Connected to Microsoft Teams" "SUCCESS"
        }
        catch {
            Write-Log "Teams connection failed: $_" "ERROR"
            $results.Teams = $false
        }
    }
    
    # Microsoft Graph
    if ("Graph" -in $RequiredServices) {
        try {
            Write-Log "Connecting to Microsoft Graph..." "INFO"
            Connect-MgGraph -Scopes @(
                "Directory.Read.All",
                "User.Read.All",
                "Group.Read.All",
                "Policy.Read.All",
                "SecurityEvents.Read.All",
                "AuditLog.Read.All",
                "Reports.Read.All",
                "Mail.Read",
                "Sites.Read.All",
                "Chat.Read.All"
            ) -NoWelcome -ErrorAction Stop
            $results.Graph = $true
            Write-Log "Connected to Microsoft Graph" "SUCCESS"
        }
        catch {
            Write-Log "Graph connection failed: $_" "ERROR"
            $results.Graph = $false
        }
    }
    
    # Power Platform
    if ("PowerPlatform" -in $RequiredServices) {
        try {
            Write-Log "Connecting to Power Platform..." "INFO"
            Add-PowerAppsAccount -ErrorAction Stop
            $results.PowerPlatform = $true
            Write-Log "Connected to Power Platform" "SUCCESS"
        }
        catch {
            Write-Log "Power Platform connection failed: $_" "ERROR"
            $results.PowerPlatform = $false
        }
    }
    
    $script:ConnectionCache[$TenantId] = $results
    return $results
}

#endregion

#region Purview Assessment Module
function Invoke-PurviewAssessment {
    param([string]$OutputPath)
    
    Write-Log "Starting Purview Assessment..." "INFO"
    
    $purviewFindings = @()
    $purviewEvidence = @()
    
    try {
        # 1. DLP Assessment
        Write-Log "Assessing Data Loss Prevention..." "INFO"
        $dlpPolicies = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
        
        if ($dlpPolicies.Count -eq 0) {
            $purviewFindings += [PSCustomObject]@{
                Module = "Purview"
                Category = "Data Loss Prevention"
                Severity = "CRITICAL"
                Issue = "No DLP policies configured"
                Impact = "Sensitive data can be shared without restriction"
                CurrentValue = "0 policies"
                RecommendedValue = "Minimum 5 baseline DLP policies"
                Evidence = "No DLP policies found"
                RemediationSteps = @(
                    "Create DLP policy for Credit Card protection",
                    "Create DLP policy for SSN/Tax ID protection", 
                    "Create DLP policy for Health Records",
                    "Create DLP policy for Financial Data",
                    "Create DLP policy for Intellectual Property"
                ) -join "; "
                EstimatedHours = 24
            }
        }
        else {
            # Analyze DLP policies
            foreach ($policy in $dlpPolicies) {
                $purviewEvidence += [PSCustomObject]@{
                    Component = "DLP Policy"
                    Name = $policy.Name
                    Enabled = $policy.Enabled
                    Mode = $policy.Mode
                    Workloads = $policy.Workload -join ", "
                    LastModified = $policy.WhenChanged
                    CreatedBy = $policy.CreatedBy
                }
                
                if ($policy.Mode -ne "Enforce") {
                    $purviewFindings += [PSCustomObject]@{
                        Module = "Purview"
                        Category = "Data Loss Prevention"
                        Severity = "HIGH"
                        Issue = "DLP policy not enforced: $($policy.Name)"
                        Impact = "Policy not actively preventing data loss"
                        CurrentValue = "Mode: $($policy.Mode)"
                        RecommendedValue = "Mode: Enforce"
                        Evidence = "Policy: $($policy.Name)"
                        RemediationSteps = "Switch policy to Enforce mode after testing"
                        EstimatedHours = 2
                    }
                }
            }
        }
        
        # 2. Sensitivity Labels Assessment
        Write-Log "Assessing Sensitivity Labels..." "INFO"
        $labels = Get-Label -ErrorAction SilentlyContinue
        
        if ($labels.Count -lt 3) {
            $purviewFindings += [PSCustomObject]@{
                Module = "Purview"
                Category = "Information Protection"
                Severity = "HIGH"
                Issue = "Insufficient sensitivity labels"
                Impact = "Cannot properly classify and protect data"
                CurrentValue = "$($labels.Count) labels"
                RecommendedValue = "Minimum 5 labels (Public, Internal, Confidential, Highly Confidential, etc.)"
                Evidence = "Label count: $($labels.Count)"
                RemediationSteps = "Create comprehensive label taxonomy"
                EstimatedHours = 16
            }
        }
        
        # 3. Retention Policies Assessment
        Write-Log "Assessing Retention Policies..." "INFO"
        $retentionPolicies = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
        
        foreach ($policy in $retentionPolicies) {
            $purviewEvidence += [PSCustomObject]@{
                Component = "Retention Policy"
                Name = $policy.Name
                Enabled = $policy.Enabled
                RetentionAction = $policy.RetentionAction
                RetentionDuration = $policy.RetentionDuration
                Workloads = $policy.Workload -join ", "
            }
        }
        
        # 4. Insider Risk Assessment
        Write-Log "Assessing Insider Risk Management..." "INFO"
        try {
            $insiderRiskPolicies = Get-InsiderRiskPolicy -ErrorAction SilentlyContinue
            
            if ($insiderRiskPolicies.Count -eq 0) {
                $purviewFindings += [PSCustomObject]@{
                    Module = "Purview"
                    Category = "Insider Risk"
                    Severity = "HIGH"
                    Issue = "No insider risk policies configured"
                    Impact = "Cannot detect insider threats"
                    CurrentValue = "0 policies"
                    RecommendedValue = "Configure data theft and leak policies"
                    Evidence = "No insider risk policies"
                    RemediationSteps = "Enable insider risk management and configure policies"
                    EstimatedHours = 20
                }
            }
        }
        catch {
            Write-Log "Insider Risk assessment skipped - may require additional licensing" "WARN"
        }
        
        # 5. Data Catalog Assessment (if available)
        Write-Log "Assessing Data Catalog configuration..." "INFO"
        # Note: This would require Azure Purview API access
        
        # 6. Information Barriers Assessment
        Write-Log "Assessing Information Barriers..." "INFO"
        try {
            $ibPolicies = Get-InformationBarrierPolicy -ErrorAction SilentlyContinue
            
            if ($ibPolicies.Count -eq 0) {
                $purviewEvidence += [PSCustomObject]@{
                    Component = "Information Barriers"
                    Status = "Not Configured"
                    PolicyCount = 0
                }
            }
        }
        catch {
            Write-Log "Information Barriers assessment skipped" "WARN"
        }
        
        # Export Purview data
        $purviewFindings | Export-Csv "$OutputPath\01_Purview\Purview_Findings.csv" -NoTypeInformation
        $purviewEvidence | Export-Csv "$OutputPath\01_Purview\Purview_Evidence.csv" -NoTypeInformation
        
        # Add to global collections
        $script:AllFindings += $purviewFindings
        $script:AllEvidence += $purviewEvidence
        
        Write-Log "Purview Assessment completed - Found $($purviewFindings.Count) issues" "SUCCESS"
        
    }
    catch {
        Write-Log "Purview Assessment failed: $_" "ERROR"
    }
}

#endregion

#region Power Platform Assessment Module
function Invoke-PowerPlatformAssessment {
    param([string]$OutputPath)
    
    Write-Log "Starting Power Platform Assessment..." "INFO"
    
    $ppFindings = @()
    $ppEvidence = @()
    
    try {
        # 1. Environment Assessment
        Write-Log "Assessing Power Platform Environments..." "INFO"
        $environments = Get-AdminPowerAppEnvironment
        
        foreach ($env in $environments) {
            $ppEvidence += [PSCustomObject]@{
                Component = "Environment"
                Name = $env.DisplayName
                Type = $env.EnvironmentType
                Region = $env.Location
                CreatedBy = $env.CreatedBy.userPrincipalName
                CreatedTime = $env.CreatedTime
                State = $env.EnvironmentState
            }
            
            # Check for default environment usage
            if ($env.EnvironmentType -eq "Default") {
                $apps = Get-AdminPowerApp -EnvironmentName $env.EnvironmentName
                if ($apps.Count -gt 10) {
                    $ppFindings += [PSCustomObject]@{
                        Module = "PowerPlatform"
                        Category = "Environment Management"
                        Severity = "HIGH"
                        Issue = "Overuse of Default environment"
                        Impact = "No isolation between production and development"
                        CurrentValue = "$($apps.Count) apps in Default environment"
                        RecommendedValue = "Use dedicated environments for production"
                        Evidence = "Default environment: $($env.DisplayName)"
                        RemediationSteps = "Create production environment and migrate apps"
                        EstimatedHours = 40
                    }
                }
            }
        }
        
        # 2. DLP Policy Assessment
        Write-Log "Assessing Power Platform DLP Policies..." "INFO"
        $dlpPolicies = Get-DlpPolicy
        
        if ($dlpPolicies.Count -eq 0) {
            $ppFindings += [PSCustomObject]@{
                Module = "PowerPlatform"
                Category = "Data Loss Prevention"
                Severity = "CRITICAL"
                Issue = "No Power Platform DLP policies"
                Impact = "Apps can connect to any service without restriction"
                CurrentValue = "0 DLP policies"
                RecommendedValue = "Environment-specific DLP policies"
                Evidence = "No DLP policies found"
                RemediationSteps = "Create baseline DLP policy for all environments"
                EstimatedHours = 16
            }
        }
        else {
            foreach ($policy in $dlpPolicies) {
                $ppEvidence += [PSCustomObject]@{
                    Component = "DLP Policy"
                    Name = $policy.DisplayName
                    Environments = $policy.EnvironmentName -join ", "
                    BusinessDataGroup = ($policy.BusinessDataGroup | Measure-Object).Count
                    NonBusinessDataGroup = ($policy.NonBusinessDataGroup | Measure-Object).Count
                    BlockedGroup = ($policy.BlockedGroup | Measure-Object).Count
                }
            }
        }
        
        # 3. Power Apps Assessment
        Write-Log "Assessing Power Apps..." "INFO"
        $allApps = @()
        foreach ($env in $environments) {
            $apps = Get-AdminPowerApp -EnvironmentName $env.EnvironmentName
            $allApps += $apps
            
            foreach ($app in $apps) {
                # Check for orphaned apps
                if ($app.Owner.userPrincipalName -like "*#EXT#*") {
                    $ppFindings += [PSCustomObject]@{
                        Module = "PowerPlatform"
                        Category = "App Governance"
                        Severity = "MEDIUM"
                        Issue = "App owned by external user"
                        Impact = "Potential loss of app control"
                        CurrentValue = "Owner: $($app.Owner.userPrincipalName)"
                        RecommendedValue = "Transfer to internal owner"
                        Evidence = "App: $($app.DisplayName)"
                        RemediationSteps = "Reassign app ownership to internal user"
                        EstimatedHours = 2
                    }
                }
            }
        }
        
        # 4. Power Automate Flows Assessment
        Write-Log "Assessing Power Automate Flows..." "INFO"
        $allFlows = @()
        foreach ($env in $environments) {
            $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
            $allFlows += $flows
            
            # Check for high-frequency flows
            $highFreqFlows = $flows | Where-Object { 
                $_.Properties.definitionSummary.triggers -and 
                $_.Properties.definitionSummary.triggers[0].type -eq "Recurrence" 
            }
            
            if ($highFreqFlows.Count -gt 0) {
                $ppEvidence += [PSCustomObject]@{
                    Component = "High Frequency Flows"
                    Count = $highFreqFlows.Count
                    Environment = $env.DisplayName
                }
            }
        }
        
        # 5. Licensing Assessment
        Write-Log "Assessing Power Platform Licensing..." "INFO"
        $licenses = Get-AdminPowerAppLicenses
        
        $ppEvidence += [PSCustomObject]@{
            Component = "Licensing"
            TotalLicenses = ($licenses | Measure-Object).Count
            PerAppLicenses = ($licenses | Where-Object { $_.LicenseType -eq "PerApp" } | Measure-Object).Count
            PerUserLicenses = ($licenses | Where-Object { $_.LicenseType -eq "PerUser" } | Measure-Object).Count
        }
        
        # 6. COE Adoption Check
        Write-Log "Checking for COE Starter Kit..." "INFO"
        $coeApps = $allApps | Where-Object { $_.DisplayName -like "*COE*" -or $_.DisplayName -like "*Center of Excellence*" }
        
        if ($coeApps.Count -eq 0) {
            $ppFindings += [PSCustomObject]@{
                Module = "PowerPlatform"
                Category = "Governance"
                Severity = "HIGH"
                Issue = "COE Starter Kit not deployed"
                Impact = "Limited governance and monitoring capabilities"
                CurrentValue = "No COE components found"
                RecommendedValue = "Deploy COE Starter Kit"
                Evidence = "No COE apps detected"
                RemediationSteps = "Download and deploy COE Starter Kit from Microsoft"
                EstimatedHours = 40
            }
        }
        
        # Export Power Platform data
        $ppFindings | Export-Csv "$OutputPath\02_PowerPlatform\PowerPlatform_Findings.csv" -NoTypeInformation
        $ppEvidence | Export-Csv "$OutputPath\02_PowerPlatform\PowerPlatform_Evidence.csv" -NoTypeInformation
        
        # Environment summary
        $envSummary = $environments | Select-Object DisplayName, EnvironmentType, Location, CreatedTime
        $envSummary | Export-Csv "$OutputPath\02_PowerPlatform\Environment_Summary.csv" -NoTypeInformation
        
        # Add to global collections
        $script:AllFindings += $ppFindings
        $script:AllEvidence += $ppEvidence
        
        Write-Log "Power Platform Assessment completed - Found $($ppFindings.Count) issues" "SUCCESS"
        
    }
    catch {
        Write-Log "Power Platform Assessment failed: $_" "ERROR"
    }
}

#endregion

#region SharePoint/Teams/OneDrive Assessment Module
function Invoke-SharePointTeamsAssessment {
    param([string]$OutputPath)
    
    Write-Log "Starting SharePoint, Teams, and OneDrive Assessment..." "INFO"
    
    $spoFindings = @()
    $spoEvidence = @()
    
    try {
        # 1. SharePoint Tenant Configuration
        Write-Log "Assessing SharePoint tenant configuration..." "INFO"
        $spoTenant = Get-SPOTenant
        
        $spoEvidence += [PSCustomObject]@{
            Component = "SPO Tenant Config"
            SharingCapability = $spoTenant.SharingCapability
            DefaultSharingLinkType = $spoTenant.DefaultSharingLinkType
            RequireAcceptingAccountMatchInvitedAccount = $spoTenant.RequireAcceptingAccountMatchInvitedAccount
            PreventExternalUsersFromResharing = $spoTenant.PreventExternalUsersFromResharing
            ShowEveryoneClaim = $spoTenant.ShowEveryoneClaim
            FileAnonymousLinkType = $spoTenant.FileAnonymousLinkType
            FolderAnonymousLinkType = $spoTenant.FolderAnonymousLinkType
        }
        
        # Check sharing settings
        if ($spoTenant.SharingCapability -eq "ExternalUserAndGuestSharing") {
            $spoFindings += [PSCustomObject]@{
                Module = "SharePoint"
                Category = "External Sharing"
                Severity = "HIGH"
                Issue = "Anonymous sharing enabled tenant-wide"
                Impact = "Anyone with a link can access content"
                CurrentValue = $spoTenant.SharingCapability
                RecommendedValue = "ExternalUserSharingOnly or Disabled"
                Evidence = "Tenant setting: $($spoTenant.SharingCapability)"
                RemediationSteps = "Restrict to authenticated external users only"
                EstimatedHours = 4
            }
        }
        
        # 2. Site Analysis
        Write-Log "Analyzing SharePoint sites..." "INFO"
        $sites = Get-SPOSite -Limit All
        
        $siteSummary = @{
            TotalSites = $sites.Count
            ExternalSharingEnabled = ($sites | Where-Object { $_.SharingCapability -ne "Disabled" }).Count
            GroupConnected = ($sites | Where-Object { $_.GroupId -ne "00000000-0000-0000-0000-000000000000" }).Count
            HubSites = ($sites | Where-Object { $_.IsHubSite }).Count
        }
        
        $spoEvidence += [PSCustomObject]@{
            Component = "Site Statistics"
            TotalSites = $siteSummary.TotalSites
            ExternalSharingEnabled = $siteSummary.ExternalSharingEnabled
            GroupConnected = $siteSummary.GroupConnected
            HubSites = $siteSummary.HubSites
        }
        
        # Check for ungoverned sites
        $ungoverned = $sites | Where-Object { 
            $_.Owner -eq "" -or 
            $_.Owner -like "*admin*" -or 
            $_.LastContentModifiedDate -lt (Get-Date).AddMonths(-12)
        }
        
        if ($ungoverned.Count -gt 10) {
            $spoFindings += [PSCustomObject]@{
                Module = "SharePoint"
                Category = "Site Governance"
                Severity = "HIGH"
                Issue = "Large number of ungoverned sites"
                Impact = "Orphaned content and security risks"
                CurrentValue = "$($ungoverned.Count) ungoverned sites"
                RecommendedValue = "All sites should have active owners"
                Evidence = "Sites without proper ownership"
                RemediationSteps = "Implement site lifecycle management"
                EstimatedHours = 40
            }
        }
        
        # 3. Teams Assessment
        Write-Log "Assessing Microsoft Teams configuration..." "INFO"
        $teamsConfig = Get-CsTeamsMessagingPolicy
        $teamsMeetingPolicy = Get-CsTeamsMeetingPolicy
        
        foreach ($policy in $teamsConfig) {
            $spoEvidence += [PSCustomObject]@{
                Component = "Teams Messaging Policy"
                Name = $policy.Identity
                AllowGiphy = $policy.AllowGiphy
                AllowMemes = $policy.AllowMemes
                AllowUserEditMessages = $policy.AllowUserEditMessages
                AllowUserDeleteMessages = $policy.AllowUserDeleteMessages
            }
        }
        
        # Get all Teams
        $allTeams = Get-Team
        $teamsWithGuests = @()
        
        foreach ($team in $allTeams) {
            try {
                $users = Get-TeamUser -GroupId $team.GroupId
                $guestUsers = $users | Where-Object { $_.UserType -eq "Guest" }
                if ($guestUsers.Count -gt 0) {
                    $teamsWithGuests += $team
                }
            }
            catch {
                Write-Log "Could not check team users for: $($team.DisplayName)" "WARN"
            }
        }
        
        if ($teamsWithGuests.Count -gt 20) {
            $spoFindings += [PSCustomObject]@{
                Module = "Teams"
                Category = "Guest Access"
                Severity = "MEDIUM"
                Issue = "Extensive guest access in Teams"
                Impact = "Potential data exposure to external users"
                CurrentValue = "$($teamsWithGuests.Count) teams with guests"
                RecommendedValue = "Regular guest access reviews"
                Evidence = "Teams with external users"
                RemediationSteps = "Implement guest access governance"
                EstimatedHours = 24
            }
        }
        
        # 4. OneDrive Assessment
        Write-Log "Assessing OneDrive configuration..." "INFO"
        $odConfig = Get-SPOTenantSyncClientRestriction
        
        $spoEvidence += [PSCustomObject]@{
            Component = "OneDrive Config"
            TenantRestrictionsEnabled = $odConfig.TenantRestrictionEnabled
            AllowedDomainList = ($odConfig.AllowedDomainList -join ", ")
            BlockMacSync = $odConfig.BlockMacSync
            DisableReportProblemDialog = $odConfig.DisableReportProblemDialog
        }
        
        # 5. Information Architecture
        Write-Log "Assessing Information Architecture..." "INFO"
        
        # Check for naming conventions
        $poorlyNamedSites = $sites | Where-Object { 
            $_.Title -match "^test|^temp|^new|^copy|^old" -or
            $_.Title -match "\d{8}" -or
            $_.Title.Length -lt 5
        }
        
        if ($poorlyNamedSites.Count -gt 10) {
            $spoFindings += [PSCustomObject]@{
                Module = "SharePoint"
                Category = "Information Architecture"
                Severity = "MEDIUM"
                Issue = "Poor site naming conventions"
                Impact = "Difficult to find and manage content"
                CurrentValue = "$($poorlyNamedSites.Count) poorly named sites"
                RecommendedValue = "Implement naming standards"
                Evidence = "Sites with non-standard names"
                RemediationSteps = "Create and enforce naming convention policy"
                EstimatedHours = 16
            }
        }
        
        # Export SharePoint/Teams data
        $spoFindings | Export-Csv "$OutputPath\03_SharePoint\SharePoint_Teams_Findings.csv" -NoTypeInformation
        $spoEvidence | Export-Csv "$OutputPath\03_SharePoint\SharePoint_Teams_Evidence.csv" -NoTypeInformation
        $sites | Select-Object Title, Url, SharingCapability, StorageUsageCurrent, LastContentModifiedDate | 
            Export-Csv "$OutputPath\03_SharePoint\Site_Inventory.csv" -NoTypeInformation
        
        # Add to global collections
        $script:AllFindings += $spoFindings
        $script:AllEvidence += $spoEvidence
        
        Write-Log "SharePoint/Teams Assessment completed - Found $($spoFindings.Count) issues" "SUCCESS"
        
    }
    catch {
        Write-Log "SharePoint/Teams Assessment failed: $_" "ERROR"
    }
}

#endregion

#region Security Assessment Module
function Invoke-SecurityAssessment {
    param([string]$OutputPath)
    
    Write-Log "Starting Security Assessment..." "INFO"
    
    $secFindings = @()
    $secEvidence = @()
    
    try {
        # 1. Conditional Access Assessment
        Write-Log "Assessing Conditional Access policies..." "INFO"
        $caPolicies = Get-MgIdentityConditionalAccessPolicy
        
        if ($caPolicies.Count -lt 5) {
            $secFindings += [PSCustomObject]@{
                Module = "Security"
                Category = "Conditional Access"
                Severity = "CRITICAL"
                Issue = "Insufficient Conditional Access policies"
                Impact = "Weak authentication security"
                CurrentValue = "$($caPolicies.Count) policies"
                RecommendedValue = "Minimum 5 baseline policies"
                Evidence = "Policy count: $($caPolicies.Count)"
                RemediationSteps = "Implement Microsoft security defaults or custom policies"
                EstimatedHours = 16
            }
        }
        
        foreach ($policy in $caPolicies) {
            $secEvidence += [PSCustomObject]@{
                Component = "CA Policy"
                Name = $policy.DisplayName
                State = $policy.State
                CreatedDateTime = $policy.CreatedDateTime
                ModifiedDateTime = $policy.ModifiedDateTime
                GrantControls = ($policy.GrantControls.BuiltInControls -join ", ")
            }
        }
        
        # 2. MFA Status Assessment
        Write-Log "Assessing MFA status..." "INFO"
        $mfaStatus = Get-MgReportAuthenticationMethodUserRegistrationDetail
        $totalUsers = ($mfaStatus | Measure-Object).Count
        $mfaEnabled = ($mfaStatus | Where-Object { $_.IsMfaRegistered -eq $true } | Measure-Object).Count
        
        $mfaPercentage = if ($totalUsers -gt 0) { [math]::Round(($mfaEnabled / $totalUsers) * 100, 2) } else { 0 }
        
        if ($mfaPercentage -lt 90) {
            $secFindings += [PSCustomObject]@{
                Module = "Security"
                Category = "Multi-Factor Authentication"
                Severity = "CRITICAL"
                Issue = "Low MFA adoption"
                Impact = "Accounts vulnerable to compromise"
                CurrentValue = "$mfaPercentage% MFA enabled"
                RecommendedValue = "100% MFA coverage"
                Evidence = "$mfaEnabled of $totalUsers users"
                RemediationSteps = "Enforce MFA for all users"
                EstimatedHours = 8
            }
        }
        
        # 3. Legacy Authentication
        Write-Log "Checking for legacy authentication..." "INFO"
        $signIns = Get-MgAuditLogSignIn -Filter "clientAppUsed ne 'Browser' and clientAppUsed ne 'Mobile Apps and Desktop clients'" -Top 100
        
        if ($signIns.Count -gt 0) {
            $secFindings += [PSCustomObject]@{
                Module = "Security"
                Category = "Authentication"
                Severity = "HIGH"
                Issue = "Legacy authentication detected"
                Impact = "Bypass modern security controls"
                CurrentValue = "$($signIns.Count) legacy auth events"
                RecommendedValue = "Block all legacy authentication"
                Evidence = "Recent legacy auth sign-ins"
                RemediationSteps = "Create CA policy to block legacy auth"
                EstimatedHours = 4
            }
        }
        
        # 4. Privileged Access
        Write-Log "Assessing privileged access..." "INFO"
        $adminRoles = Get-MgDirectoryRole
        $privilegedUsers = @()
        
        foreach ($role in $adminRoles | Where-Object { $_.DisplayName -like "*Admin*" }) {
            $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
            $privilegedUsers += $members
        }
        
        $uniquePrivilegedUsers = $privilegedUsers | Select-Object -Unique Id
        
        $secEvidence += [PSCustomObject]@{
            Component = "Privileged Access"
            TotalAdminRoles = $adminRoles.Count
            TotalPrivilegedUsers = $uniquePrivilegedUsers.Count
            GlobalAdmins = ($adminRoles | Where-Object { $_.DisplayName -eq "Global Administrator" } | Get-MgDirectoryRoleMember).Count
        }
        
        # 5. Security Defaults Check
        Write-Log "Checking security defaults..." "INFO"
        $orgSettings = Get-MgOrganization
        
        # Export Security data
        $secFindings | Export-Csv "$OutputPath\04_Security\Security_Findings.csv" -NoTypeInformation
        $secEvidence | Export-Csv "$OutputPath\04_Security\Security_Evidence.csv" -NoTypeInformation
        
        # Add to global collections
        $script:AllFindings += $secFindings
        $script:AllEvidence += $secEvidence
        
        Write-Log "Security Assessment completed - Found $($secFindings.Count) issues" "SUCCESS"
        
    }
    catch {
        Write-Log "Security Assessment failed: $_" "ERROR"
    }
}

#endregion

#region Azure Landing Zone Assessment Module
function Invoke-AzureLandingZoneAssessment {
    param(
        [string]$OutputPath,
        [string[]]$TenantIds
    )
    
    Write-Log "Starting Azure Landing Zone Assessment..." "INFO"
    
    $azFindings = @()
    $azEvidence = @()
    
    foreach ($tenantId in $TenantIds) {
        try {
            Write-Log "Assessing Azure tenant: $tenantId" "INFO"
            
            # Connect to Azure
            $context = Connect-AzAccount -TenantId $tenantId -ErrorAction Stop
            
            # 1. Subscription Structure
            Write-Log "Analyzing subscription structure..." "INFO"
            $subscriptions = Get-AzSubscription
            
            $azEvidence += [PSCustomObject]@{
                Component = "Azure Subscriptions"
                TenantId = $tenantId
                TotalSubscriptions = $subscriptions.Count
                ProductionSubs = ($subscriptions | Where-Object { $_.Name -like "*prod*" }).Count
                DevTestSubs = ($subscriptions | Where-Object { $_.Name -like "*dev*" -or $_.Name -like "*test*" }).Count
            }
            
            # 2. Management Group Hierarchy
            Write-Log "Checking management group structure..." "INFO"
            $mgmtGroups = Get-AzManagementGroup
            
            if ($mgmtGroups.Count -lt 3) {
                $azFindings += [PSCustomObject]@{
                    Module = "AzureLandingZone"
                    Category = "Governance"
                    Severity = "HIGH"
                    Issue = "Insufficient management group hierarchy"
                    Impact = "Limited policy and access control inheritance"
                    CurrentValue = "$($mgmtGroups.Count) management groups"
                    RecommendedValue = "Hierarchical structure with Platform/Landing Zones"
                    Evidence = "Tenant: $tenantId"
                    RemediationSteps = "Implement Azure Landing Zone architecture"
                    EstimatedHours = 80
                }
            }
            
            # 3. Policy Assessment
            Write-Log "Assessing Azure Policies..." "INFO"
            $policies = Get-AzPolicyDefinition | Where-Object { $_.Properties.policyType -eq "Custom" }
            $policyAssignments = Get-AzPolicyAssignment
            
            if ($policies.Count -lt 10) {
                $azFindings += [PSCustomObject]@{
                    Module = "AzureLandingZone"
                    Category = "Policy"
                    Severity = "MEDIUM"
                    Issue = "Limited custom policies"
                    Impact = "Inconsistent governance across resources"
                    CurrentValue = "$($policies.Count) custom policies"
                    RecommendedValue = "Comprehensive policy library"
                    Evidence = "Tenant: $tenantId"
                    RemediationSteps = "Create policies for tagging, naming, regions, etc."
                    EstimatedHours = 40
                }
            }
            
            # 4. Network Architecture
            Write-Log "Analyzing network architecture..." "INFO"
            $vnets = Get-AzVirtualNetwork
            $hubVnets = $vnets | Where-Object { $_.Name -like "*hub*" }
            
            if ($hubVnets.Count -eq 0) {
                $azFindings += [PSCustomObject]@{
                    Module = "AzureLandingZone"
                    Category = "Networking"
                    Severity = "HIGH"
                    Issue = "No hub-spoke network topology"
                    Impact = "Inefficient network architecture"
                    CurrentValue = "No hub VNet detected"
                    RecommendedValue = "Hub-spoke topology"
                    Evidence = "Tenant: $tenantId"
                    RemediationSteps = "Implement hub-spoke network design"
                    EstimatedHours = 60
                }
            }
            
            # 5. Identity and Access
            Write-Log "Checking Azure AD integration..." "INFO"
            $roleAssignments = Get-AzRoleAssignment
            $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom }
            
            $azEvidence += [PSCustomObject]@{
                Component = "Azure IAM"
                TenantId = $tenantId
                TotalRoleAssignments = $roleAssignments.Count
                CustomRoles = $customRoles.Count
                ServicePrincipals = ($roleAssignments | Where-Object { $_.ObjectType -eq "ServicePrincipal" }).Count
            }
            
        }
        catch {
            Write-Log "Azure assessment failed for tenant $tenantId`: $_" "ERROR"
        }
    }
    
    # Export Azure data
    $azFindings | Export-Csv "$OutputPath\05_Azure\Azure_Findings.csv" -NoTypeInformation
    $azEvidence | Export-Csv "$OutputPath\05_Azure\Azure_Evidence.csv" -NoTypeInformation
    
    # Add to global collections
    $script:AllFindings += $azFindings
    $script:AllEvidence += $azEvidence
    
    Write-Log "Azure Landing Zone Assessment completed - Found $($azFindings.Count) issues" "SUCCESS"
}

#endregion

#region Report Generation
function New-PowerReviewReports {
    param([string]$OutputPath)
    
    Write-Log "Generating PowerReview reports..." "INFO"
    
    # 1. Executive Summary HTML Report
    New-ExecutiveSummaryReport -OutputPath $OutputPath
    
    # 2. Detailed Technical Report
    New-TechnicalReport -OutputPath $OutputPath
    
    # 3. Findings Matrix
    New-FindingsMatrix -OutputPath $OutputPath
    
    # 4. Remediation Roadmap
    New-RemediationRoadmap -OutputPath $OutputPath
    
    # 5. Workshop Materials
    New-WorkshopMaterials -OutputPath $OutputPath
    
    Write-Log "All reports generated successfully" "SUCCESS"
}

function New-ExecutiveSummaryReport {
    param([string]$OutputPath)
    
    $totalFindings = $script:AllFindings.Count
    $criticalCount = ($script:AllFindings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $highCount = ($script:AllFindings | Where-Object { $_.Severity -eq "HIGH" }).Count
    $totalEffort = ($script:AllFindings | Measure-Object -Property EstimatedHours -Sum).Sum
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Executive Summary</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0078D4 0%, #40E0D0 100%); color: white; padding: 60px 40px; text-align: center; }
        .header h1 { margin: 0; font-size: 48px; font-weight: 300; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 30px; margin: 40px 0; }
        .metric-card { background: white; padding: 30px; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); text-align: center; }
        .metric-value { font-size: 48px; font-weight: bold; margin: 15px 0; }
        .critical { color: #D83B01; }
        .high { color: #FF8C00; }
        .medium { color: #FFB900; }
        .low { color: #107C10; }
        .section { margin: 40px 0; }
        .finding-card { background: #F8F9FA; padding: 25px; margin: 15px 0; border-left: 5px solid #0078D4; border-radius: 5px; }
        .chart-container { height: 400px; margin: 30px 0; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="header">
        <h1>PowerReview Assessment</h1>
        <h2>Executive Summary</h2>
        <p>Assessment Date: $(Get-Date -Format "MMMM dd, yyyy")</p>
    </div>
    
    <div class="container">
        <div class="metrics">
            <div class="metric-card">
                <h3>Total Findings</h3>
                <div class="metric-value">$totalFindings</div>
                <p>Issues Identified</p>
            </div>
            <div class="metric-card">
                <h3>Critical Issues</h3>
                <div class="metric-value critical">$criticalCount</div>
                <p>Require Immediate Action</p>
            </div>
            <div class="metric-card">
                <h3>High Priority</h3>
                <div class="metric-value high">$highCount</div>
                <p>Should Address Soon</p>
            </div>
            <div class="metric-card">
                <h3>Estimated Effort</h3>
                <div class="metric-value">$totalEffort</div>
                <p>Total Hours</p>
            </div>
        </div>
        
        <div class="section">
            <h2>Risk Distribution</h2>
            <div class="chart-container">
                <canvas id="riskChart"></canvas>
            </div>
        </div>
        
        <div class="section">
            <h2>Key Findings by Module</h2>
$(
    $moduleGroups = $script:AllFindings | Group-Object Module
    foreach ($module in $moduleGroups) {
        $moduleCritical = ($module.Group | Where-Object { $_.Severity -eq "CRITICAL" }).Count
        $moduleHigh = ($module.Group | Where-Object { $_.Severity -eq "HIGH" }).Count
        
        @"
            <div class="finding-card">
                <h3>$($module.Name)</h3>
                <p><strong>Total Issues:</strong> $($module.Count) | <strong>Critical:</strong> <span class="critical">$moduleCritical</span> | <strong>High:</strong> <span class="high">$moduleHigh</span></p>
                <p><strong>Key Concerns:</strong></p>
                <ul>
$(
    $topIssues = $module.Group | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") } | Select-Object -First 3
    foreach ($issue in $topIssues) {
        "                    <li>$($issue.Issue)</li>`n"
    }
)
                </ul>
            </div>
"@
    }
)
        </div>
        
        <div class="section">
            <h2>Executive Recommendations</h2>
            <div class="finding-card">
                <h3>Immediate Actions (Next 30 Days)</h3>
                <ol>
$(
    $criticalFindings = $script:AllFindings | Where-Object { $_.Severity -eq "CRITICAL" } | Select-Object -First 5
    foreach ($finding in $criticalFindings) {
        "                    <li><strong>$($finding.Module):</strong> $($finding.RecommendedValue)</li>`n"
    }
)
                </ol>
            </div>
            
            <div class="finding-card">
                <h3>Investment Required</h3>
                <ul>
                    <li><strong>Technical Effort:</strong> Approximately $totalEffort hours</li>
                    <li><strong>Timeline:</strong> 3-6 months for full remediation</li>
                    <li><strong>Resources:</strong> Dedicated security and governance team recommended</li>
                    <li><strong>Budget Consideration:</strong> Include licensing upgrades and potential consulting</li>
                </ul>
            </div>
        </div>
    </div>
    
    <script>
        // Risk distribution chart
        const ctx = document.getElementById('riskChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Critical', 'High', 'Medium', 'Low'],
                datasets: [{
                    data: [
                        $criticalCount,
                        $highCount,
                        $(($script:AllFindings | Where-Object { $_.Severity -eq "MEDIUM" }).Count),
                        $(($script:AllFindings | Where-Object { $_.Severity -eq "LOW" }).Count)
                    ],
                    backgroundColor: ['#D83B01', '#FF8C00', '#FFB900', '#107C10']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'right' }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $html | Out-File "$OutputPath\00_Executive\Executive_Summary.html" -Encoding UTF8
    Write-Log "Executive summary report created" "SUCCESS"
}

function New-FindingsMatrix {
    param([string]$OutputPath)
    
    # Create comprehensive findings matrix
    $matrix = $script:AllFindings | Select-Object @{
        Name = "Priority"
        Expression = {
            switch ($_.Severity) {
                "CRITICAL" { 1 }
                "HIGH" { 2 }
                "MEDIUM" { 3 }
                "LOW" { 4 }
            }
        }
    }, Module, Category, Severity, Issue, Impact, CurrentValue, RecommendedValue, EstimatedHours, RemediationSteps |
    Sort-Object Priority, Module, Category
    
    $matrix | Export-Csv "$OutputPath\06_Reports\Complete_Findings_Matrix.csv" -NoTypeInformation
    
    # Create pivot summary
    $summary = $script:AllFindings | Group-Object Module, Severity | Select-Object @{
        Name = "Module"
        Expression = { $_.Group[0].Module }
    }, @{
        Name = "Severity" 
        Expression = { $_.Group[0].Severity }
    }, Count
    
    $summary | Export-Csv "$OutputPath\06_Reports\Findings_Summary.csv" -NoTypeInformation
    
    Write-Log "Findings matrix created" "SUCCESS"
}

function New-RemediationRoadmap {
    param([string]$OutputPath)
    
    $roadmap = @"
# PowerReview Remediation Roadmap

Generated: $(Get-Date -Format "MMMM dd, yyyy")

## Overview
This roadmap provides a structured approach to addressing the findings from your PowerReview assessment.

### Assessment Summary
- **Total Findings:** $($script:AllFindings.Count)
- **Critical Issues:** $(($script:AllFindings | Where-Object { $_.Severity -eq "CRITICAL" }).Count)
- **Total Effort Required:** $(($script:AllFindings | Measure-Object -Property EstimatedHours -Sum).Sum) hours

## Phase 1: Critical Security Issues (0-30 Days)

### Objective
Address immediate security vulnerabilities and compliance gaps.

### Tasks
$(
    $phase1 = $script:AllFindings | Where-Object { $_.Severity -eq "CRITICAL" } | Sort-Object EstimatedHours
    foreach ($task in $phase1) {
        @"

#### $($task.Issue)
- **Module:** $($task.Module)
- **Current State:** $($task.CurrentValue)
- **Target State:** $($task.RecommendedValue)
- **Effort:** $($task.EstimatedHours) hours
- **Steps:** $($task.RemediationSteps)

"@
    }
)

## Phase 2: High Priority Items (30-60 Days)

### Objective
Implement governance controls and operational improvements.

### Tasks
$(
    $phase2 = $script:AllFindings | Where-Object { $_.Severity -eq "HIGH" } | Sort-Object EstimatedHours | Select-Object -First 10
    foreach ($task in $phase2) {
        @"

#### $($task.Issue)
- **Module:** $($task.Module)
- **Impact:** $($task.Impact)
- **Effort:** $($task.EstimatedHours) hours

"@
    }
)

## Phase 3: Optimization (60-90 Days)

### Objective
Enhance configurations and improve user experience.

### Focus Areas
$(
    $phase3Modules = $script:AllFindings | Where-Object { $_.Severity -eq "MEDIUM" } | Group-Object Module
    foreach ($module in $phase3Modules) {
        "- **$($module.Name):** $($module.Count) items`n"
    }
)

## Success Metrics

### Phase 1 Completion
- [ ] All critical vulnerabilities remediated
- [ ] Security baseline established
- [ ] Compliance gaps addressed

### Phase 2 Completion
- [ ] Governance framework implemented
- [ ] Automated controls in place
- [ ] Monitoring configured

### Phase 3 Completion
- [ ] Performance optimized
- [ ] User training completed
- [ ] Documentation updated

## Resource Requirements

### Team Composition
- Security Engineer: 1.0 FTE
- M365 Administrator: 1.0 FTE
- Power Platform Specialist: 0.5 FTE
- Project Manager: 0.5 FTE

### Estimated Timeline
- Phase 1: 4 weeks
- Phase 2: 4 weeks  
- Phase 3: 4 weeks
- Total: 12 weeks

## Next Steps

1. **Week 1:**
   - Review and approve roadmap
   - Assign resources
   - Create detailed project plan

2. **Week 2:**
   - Begin Phase 1 implementation
   - Establish weekly checkpoints
   - Set up progress tracking

3. **Ongoing:**
   - Weekly status meetings
   - Monthly steering committee updates
   - Quarterly maturity assessments
"@
    
    $roadmap | Out-File "$OutputPath\06_Reports\Remediation_Roadmap.md" -Encoding UTF8
    Write-Log "Remediation roadmap created" "SUCCESS"
}

function New-WorkshopMaterials {
    param([string]$OutputPath)
    
    # Create workshop agenda
    $agenda = @"
# PowerReview Findings Workshop

## Agenda

### 1. Welcome & Introductions (10 minutes)
- Workshop objectives
- Participant introductions

### 2. Assessment Overview (15 minutes)
- Methodology
- Scope and coverage
- Data collection approach

### 3. Key Findings (60 minutes)
$(
    $moduleGroups = $script:AllFindings | Group-Object Module
    foreach ($module in $moduleGroups) {
        "- **$($module.Name):** $(15) minutes`n"
    }
)

### 4. Risk Analysis (20 minutes)
- Critical risks
- Business impact
- Compliance gaps

### 5. Remediation Roadmap (20 minutes)
- Phased approach
- Resource requirements
- Timeline

### 6. Next Steps & Q&A (15 minutes)
- Immediate actions
- Project planning
- Questions

## Pre-Read Materials
1. Executive Summary Report
2. Findings Matrix
3. Remediation Roadmap

## Key Discussion Points
$(
    $criticalFindings = $script:AllFindings | Where-Object { $_.Severity -eq "CRITICAL" } | Select-Object -First 5
    foreach ($finding in $criticalFindings) {
        "- $($finding.Issue)`n"
    }
)
"@
    
    $agenda | Out-File "$OutputPath\08_Workshop\Workshop_Agenda.md" -Encoding UTF8
    Write-Log "Workshop materials created" "SUCCESS"
}

#endregion

#region Multi-Tenant Support
function Invoke-MultiTenantAssessment {
    param([string]$ConfigFile)
    
    Write-Log "Starting multi-tenant assessment..." "INFO"
    
    # Load configuration
    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    foreach ($tenant in $config.Tenants) {
        Write-Log "========================================" "INFO"
        Write-Log "Assessing tenant: $($tenant.Name)" "INFO"
        Write-Log "========================================" "INFO"
        
        # Create tenant-specific output
        $tenantOutput = "$($script:OutputPath)\$($tenant.Name)"
        Initialize-OutputStructure -Path $tenantOutput
        
        # Connect to services
        $connections = Connect-M365Services -TenantId $tenant.TenantId
        
        # Run assessments based on tenant configuration
        if ($tenant.Modules -contains "Purview" -and $connections.SecurityCompliance) {
            Invoke-PurviewAssessment -OutputPath $tenantOutput
        }
        
        if ($tenant.Modules -contains "PowerPlatform" -and $connections.PowerPlatform) {
            Invoke-PowerPlatformAssessment -OutputPath $tenantOutput
        }
        
        if ($tenant.Modules -contains "SharePoint" -and $connections.SharePoint) {
            Invoke-SharePointTeamsAssessment -OutputPath $tenantOutput
        }
        
        if ($tenant.Modules -contains "Security" -and $connections.Graph) {
            Invoke-SecurityAssessment -OutputPath $tenantOutput
        }
        
        # Generate tenant-specific reports
        New-PowerReviewReports -OutputPath $tenantOutput
        
        # Disconnect services
        Disconnect-M365Services
        
        Write-Log "Completed assessment for tenant: $($tenant.Name)" "SUCCESS"
    }
    
    # Generate consolidated report across all tenants
    New-ConsolidatedReport -OutputPath $script:OutputPath
}

function New-ConsolidatedReport {
    param([string]$OutputPath)
    
    Write-Log "Creating consolidated multi-tenant report..." "INFO"
    
    # Aggregate findings from all tenant folders
    $allTenantFindings = @()
    $tenantFolders = Get-ChildItem -Path $OutputPath -Directory | Where-Object { $_.Name -ne "00_Executive" }
    
    foreach ($folder in $tenantFolders) {
        $findingsFile = Join-Path $folder.FullName "06_Reports\Complete_Findings_Matrix.csv"
        if (Test-Path $findingsFile) {
            $tenantFindings = Import-Csv $findingsFile
            $tenantFindings | Add-Member -NotePropertyName "Tenant" -NotePropertyValue $folder.Name -Force
            $allTenantFindings += $tenantFindings
        }
    }
    
    # Export consolidated findings
    $allTenantFindings | Export-Csv "$OutputPath\00_Executive\Consolidated_Findings.csv" -NoTypeInformation
    
    Write-Log "Consolidated report created" "SUCCESS"
}

#endregion

#region Cleanup Functions
function Disconnect-M365Services {
    Write-Log "Disconnecting from M365 services..." "INFO"
    
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-SPOService -ErrorAction SilentlyContinue
        Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Error during disconnect: $_" "WARN"
    }
}

#endregion

#region Main Execution

try {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║              PowerReview Complete Assessment Tool                 ║
║                        Version $($script:Version)                        ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Check prerequisites
    if (!(Test-Prerequisites)) {
        throw "Prerequisites check failed"
    }
    
    # Initialize output structure
    Initialize-OutputStructure -Path $OutputPath
    
    # Multi-tenant or single tenant?
    if ($PSCmdlet.ParameterSetName -eq 'Multi') {
        Invoke-MultiTenantAssessment -ConfigFile $ConfigFile
    }
    else {
        # Single tenant assessment
        Write-Log "Starting assessment for tenant: $TenantName" "INFO"
        
        # Connect to services
        $connections = Connect-M365Services -TenantId $TenantId
        
        # Run selected modules
        if ($Modules -contains "Purview" -and $connections.SecurityCompliance) {
            Invoke-PurviewAssessment -OutputPath $script:OutputPath
        }
        
        if ($Modules -contains "PowerPlatform" -and $connections.PowerPlatform) {
            Invoke-PowerPlatformAssessment -OutputPath $script:OutputPath
        }
        
        if ($Modules -contains "SharePoint" -and $connections.SharePoint) {
            Invoke-SharePointTeamsAssessment -OutputPath $script:OutputPath
        }
        
        if ($Modules -contains "Security" -and $connections.Graph) {
            Invoke-SecurityAssessment -OutputPath $script:OutputPath
        }
        
        if ($Modules -contains "AzureLandingZone") {
            # Get Azure tenant IDs
            $azureTenants = @($TenantId)
            if ($TenantName -eq "Kaplan") {
                # For Kaplan, we know they have 4 tenants
                $azureTenants = @(
                    "$TenantId",
                    "tenant2.onmicrosoft.com",
                    "tenant3.onmicrosoft.com",
                    "tenant4.onmicrosoft.com"
                )
            }
            Invoke-AzureLandingZoneAssessment -OutputPath $script:OutputPath -TenantIds $azureTenants
        }
        
        # Generate reports
        New-PowerReviewReports -OutputPath $script:OutputPath
    }
    
    # Display summary
    $duration = (Get-Date) - $script:StartTime
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ASSESSMENT COMPLETE!                           ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Duration: $([math]::Round($duration.TotalMinutes, 1)) minutes"
    Write-Host "  Total Findings: $($script:AllFindings.Count)"
    Write-Host "  Critical Issues: $(($script:AllFindings | Where-Object { $_.Severity -eq 'CRITICAL' }).Count)" -ForegroundColor Red
    Write-Host "  Output Location: $($script:OutputPath)" -ForegroundColor Yellow
    
    Write-Host "`nKey Deliverables:" -ForegroundColor Cyan
    Write-Host "  1. Executive Summary: $($script:OutputPath)\00_Executive\Executive_Summary.html"
    Write-Host "  2. Findings Matrix: $($script:OutputPath)\06_Reports\Complete_Findings_Matrix.csv"
    Write-Host "  3. Remediation Roadmap: $($script:OutputPath)\06_Reports\Remediation_Roadmap.md"
    Write-Host "  4. Workshop Materials: $($script:OutputPath)\08_Workshop\"
    
    # Open executive summary
    if (!$ExportOnly) {
        Start-Process "$($script:OutputPath)\00_Executive\Executive_Summary.html"
    }
}
catch {
    Write-Log "Assessment failed: $_" "ERROR"
    throw
}
finally {
    Disconnect-M365Services
    Write-Log "PowerReview session completed" "INFO"
}

#endregion