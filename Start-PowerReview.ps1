#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Professional Assessment Wizard
    Enterprise-grade UI/UX for M365 and Azure assessments
    
.DESCRIPTION
    Interactive wizard interface with professional styling,
    permission validation, and step-by-step guidance
#>

[CmdletBinding()]
param(
    [switch]$SkipPrerequisites,
    [switch]$DarkMode
)

# Advanced UI Configuration
$script:Version = "4.0.0 Professional"
$script:Theme = if ($DarkMode) { "Dark" } else { "Light" }
$script:SessionId = [guid]::NewGuid().ToString()
$script:StartTime = Get-Date
$script:UserProfile = @{}
$script:ValidationResults = @{}

#region Professional UI Functions

function Show-WelcomeScreen {
    Clear-Host
    
    $width = 120
    $padding = 2
    
    # Professional ASCII Art Logo
    $logo = @"
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                                               ║
    ║     ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ ██████╗ ███████╗██╗   ██╗██╗███████╗██╗    ██╗              ║
    ║     ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔══██╗██╔════╝██║   ██║██║██╔════╝██║    ██║              ║
    ║     ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝██████╔╝█████╗  ██║   ██║██║█████╗  ██║ █╗ ██║              ║
    ║     ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗██╔══██╗██╔══╝  ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║              ║
    ║     ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║██║  ██║███████╗ ╚████╔╝ ██║███████╗╚███╔███╔╝              ║
    ║     ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝              ║
    ║                                                                                                               ║
    ║                           Enterprise Assessment Platform for Microsoft 365 & Azure                            ║
    ║                                            Version $($script:Version)                                         ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
"@
    
    Write-Host $logo -ForegroundColor Cyan
    Write-Host ""
    
    # Animated loading effect
    $loadingText = "Initializing PowerReview Assessment Wizard"
    Write-Host "    " -NoNewline
    foreach ($char in $loadingText.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor White
        Start-Sleep -Milliseconds 30
    }
    
    Write-Host ""
    Start-Sleep -Milliseconds 500
    
    # Progress dots
    Write-Host "    " -NoNewline
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host "`n"
}

function Show-MainMenu {
    Clear-Host
    
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                        POWERREVIEW MAIN MENU                                                │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    │                                                                                                             │
    │  Please select an option:                                                                                   │
    │                                                                                                             │
    │    [1] 🚀 Start New Assessment                                                                              │
    │        Begin a comprehensive M365 and Azure security assessment                                             │
    │                                                                                                             │
    │    [2] 🔧 Configuration Wizard                                                                              │
    │        Set up tenants, authentication, and assessment parameters                                            │
    │                                                                                                             │
    │    [3] 📊 Quick Assessment                                                                                  │
    │        Run a rapid security scan (30 minutes per tenant)                                                    │
    │                                                                                                             │
    │    [4] 🔍 Deep Analysis                                                                                     │
    │        Comprehensive forensic-level assessment (2-3 hours per tenant)                                       │
    │                                                                                                             │
    │    [5] 📋 Compliance Check                                                                                  │
    │        Evaluate compliance with GDPR, HIPAA, SOC2, ISO27001                                               │
    │                                                                                                             │
    │    [6] 🔑 Setup Authentication                                                                              │
    │        Configure automated authentication methods                                                           │
    │                                                                                                             │
    │    [7] ✅ Validate Environment                                                                              │
    │        Check prerequisites and permissions                                                                  │
    │                                                                                                             │
    │    [8] 📚 View Documentation                                                                                │
    │        Access user guide and best practices                                                                 │
    │                                                                                                             │
    │    [9] ⚙️  Advanced Options                                                                                 │
    │        Expert mode with custom parameters                                                                   │
    │                                                                                                             │
    │    [0] 🚪 Exit                                                                                              │
    │                                                                                                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    
"@ -ForegroundColor White
    
    Write-Host "    Session ID: $($script:SessionId)" -ForegroundColor DarkGray
    Write-Host ""
    
    $selection = Read-Host "    Enter your selection (0-9)"
    return $selection
}

function Show-PermissionRequirements {
    Clear-Host
    
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    PERMISSION REQUIREMENTS                                                  │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    Write-Host "`n    📋 REQUIRED PERMISSIONS" -ForegroundColor Yellow
    Write-Host "    ═══════════════════════" -ForegroundColor Yellow
    
    $permissions = @(
        @{Icon="👤"; Role="Global Reader"; Desc="Minimum requirement for read-only assessment"},
        @{Icon="🛡️"; Role="Security Reader"; Desc="Required for security-related assessments"},
        @{Icon="📊"; Role="Compliance Administrator"; Desc="Needed for compliance and Purview modules"},
        @{Icon="🌐"; Role="SharePoint Administrator"; Desc="Required for SharePoint/Teams assessments"},
        @{Icon="⚡"; Role="Power Platform Administrator"; Desc="Needed for Power Apps/Automate analysis"},
        @{Icon="☁️"; Role="Azure Subscription Reader"; Desc="Required for Azure Landing Zone assessment"}
    )
    
    foreach ($perm in $permissions) {
        Write-Host "`n    $($perm.Icon) " -NoNewline -ForegroundColor White
        Write-Host $perm.Role -ForegroundColor Green
        Write-Host "       $($perm.Desc)" -ForegroundColor Gray
    }
    
    Write-Host "`n`n    ⚡ PRIVILEGED IDENTITY MANAGEMENT (PIM)" -ForegroundColor Yellow
    Write-Host "    ══════════════════════════════════════" -ForegroundColor Yellow
    
    Write-Host @"
    
    If your organization uses PIM, ensure you have:
    
    ✓ Eligible assignments for the required roles
    ✓ Ability to activate roles for 4-8 hours
    ✓ Justification prepared for activation
    ✓ MFA configured for role activation
    
"@ -ForegroundColor White
    
    Write-Host "    🔗 REQUIRED URLS AND ENDPOINTS" -ForegroundColor Yellow
    Write-Host "    ══════════════════════════════" -ForegroundColor Yellow
    
    $urls = @(
        @{Service="Exchange Online"; URL="outlook.office365.com"},
        @{Service="SharePoint Admin"; URL="[tenant]-admin.sharepoint.com"},
        @{Service="Security & Compliance"; URL="compliance.microsoft.com"},
        @{Service="Azure Portal"; URL="portal.azure.com"},
        @{Service="Power Platform Admin"; URL="admin.powerplatform.microsoft.com"},
        @{Service="Microsoft Graph"; URL="graph.microsoft.com"}
    )
    
    Write-Host ""
    foreach ($url in $urls) {
        Write-Host ("    {0,-25} {1}" -f $url.Service, $url.URL) -ForegroundColor White
    }
    
    Write-Host "`n`n    Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ConfigurationWizard {
    Clear-Host
    
    # Step 1: Welcome
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    CONFIGURATION WIZARD                                                     │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    │                                                                                                             │
    │  Welcome to the PowerReview Configuration Wizard!                                                           │
    │                                                                                                             │
    │  This wizard will guide you through:                                                                        │
    │    • Setting up tenant configurations                                                                       │
    │    • Configuring authentication methods                                                                     │
    │    • Selecting assessment modules                                                                           │
    │    • Defining compliance requirements                                                                       │
    │                                                                                                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    Write-Host "`n    Press any key to begin..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Initialize configuration
    $config = @{
        AssessmentName = ""
        Tenants = @()
        Modules = @()
        ComplianceFrameworks = @()
        AnalysisDepth = "Standard"
    }
    
    # Step 2: Assessment Name
    Clear-Host
    Show-WizardHeader -Step 1 -Total 6 -Title "Assessment Configuration"
    
    Write-Host "`n    📝 ASSESSMENT DETAILS" -ForegroundColor Yellow
    Write-Host "    ════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    $config.AssessmentName = Read-HostWithDefault -Prompt "    Assessment Name" -Default "Enterprise M365 Security Assessment"
    $config.Description = Read-HostWithDefault -Prompt "    Description" -Default "Comprehensive security and compliance assessment"
    
    # Step 3: Tenant Configuration
    Clear-Host
    Show-WizardHeader -Step 2 -Total 6 -Title "Tenant Configuration"
    
    Write-Host "`n    🏢 TENANT SETUP" -ForegroundColor Yellow
    Write-Host "    ═══════════════" -ForegroundColor Yellow
    Write-Host ""
    
    $addMore = $true
    $tenantCount = 0
    
    while ($addMore) {
        $tenantCount++
        Write-Host "`n    ── Tenant $tenantCount ──" -ForegroundColor Cyan
        
        $tenant = @{}
        $tenant.Name = Read-Host "    Organization Name"
        $tenant.TenantId = Read-Host "    Tenant ID (domain.onmicrosoft.com)"
        $tenant.AdminEmail = Read-Host "    Admin Email"
        
        # Primary domain
        $tenant.PrimaryDomain = Read-Host "    Primary Domain (e.g., company.com)"
        
        # Region selection
        Write-Host "`n    Select Region:" -ForegroundColor White
        Write-Host "      [1] North America" -ForegroundColor Gray
        Write-Host "      [2] Europe" -ForegroundColor Gray
        Write-Host "      [3] Asia Pacific" -ForegroundColor Gray
        Write-Host "      [4] United Kingdom" -ForegroundColor Gray
        Write-Host "      [5] Other" -ForegroundColor Gray
        
        $regionChoice = Read-Host "    Selection"
        $tenant.Region = switch ($regionChoice) {
            "1" { "North America" }
            "2" { "Europe" }
            "3" { "Asia Pacific" }
            "4" { "United Kingdom" }
            "5" { Read-Host "    Specify Region" }
            default { "Global" }
        }
        
        $config.Tenants += $tenant
        
        Write-Host ""
        $continue = Read-Host "    Add another tenant? (Y/N)"
        $addMore = $continue -eq 'Y'
    }
    
    # Step 4: Module Selection
    Clear-Host
    Show-WizardHeader -Step 3 -Total 6 -Title "Module Selection"
    
    Write-Host "`n    📦 SELECT ASSESSMENT MODULES" -ForegroundColor Yellow
    Write-Host "    ═══════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Select the modules you want to include:" -ForegroundColor White
    Write-Host ""
    
    $modules = @(
        @{Name="Microsoft Purview"; Key="Purview"; Desc="DLP, Information Protection, Compliance"},
        @{Name="Security & Identity"; Key="Security"; Desc="Conditional Access, MFA, Identity Protection"},
        @{Name="SharePoint & Teams"; Key="SharePoint"; Desc="Collaboration, External Sharing, Governance"},
        @{Name="Power Platform"; Key="PowerPlatform"; Desc="Power Apps, Power Automate, Connectors"},
        @{Name="Azure Landing Zone"; Key="Azure"; Desc="Subscriptions, Policies, Architecture"},
        @{Name="Compliance Frameworks"; Key="Compliance"; Desc="GDPR, HIPAA, SOC2, ISO27001"}
    )
    
    $selectedModules = @()
    
    foreach ($module in $modules) {
        Write-Host "    [$($modules.IndexOf($module) + 1)] " -NoNewline -ForegroundColor White
        Write-Host $module.Name -ForegroundColor Green
        Write-Host "        $($module.Desc)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "    [A] Select All Modules" -ForegroundColor Cyan
    Write-Host ""
    
    $moduleSelection = Read-Host "    Enter selections (comma-separated, e.g., 1,2,3 or A)"
    
    if ($moduleSelection -eq 'A') {
        $selectedModules = $modules | ForEach-Object { $_.Key }
    }
    else {
        $selections = $moduleSelection -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        $selectedModules = $selections | ForEach-Object { $modules[$_].Key }
    }
    
    $config.Modules = $selectedModules
    
    # Step 5: Analysis Depth
    Clear-Host
    Show-WizardHeader -Step 4 -Total 6 -Title "Analysis Configuration"
    
    Write-Host "`n    🔍 ANALYSIS DEPTH" -ForegroundColor Yellow
    Write-Host "    ════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "    Select the depth of analysis:" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] 🚀 Quick Scan (30 minutes/tenant)" -ForegroundColor White
    Write-Host "        • Last 30 days of data" -ForegroundColor Gray
    Write-Host "        • High-level findings only" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [2] 📊 Standard Analysis (1 hour/tenant)" -ForegroundColor White
    Write-Host "        • Last 90 days of data" -ForegroundColor Gray
    Write-Host "        • Comprehensive findings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [3] 🔬 Deep Analysis (2-3 hours/tenant)" -ForegroundColor White
    Write-Host "        • Last 180 days of data" -ForegroundColor Gray
    Write-Host "        • Pattern analysis included" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [4] 🕵️ Forensic Analysis (4+ hours/tenant)" -ForegroundColor White
    Write-Host "        • Full year of data" -ForegroundColor Gray
    Write-Host "        • Complete evidence collection" -ForegroundColor Gray
    Write-Host ""
    
    $depthChoice = Read-Host "    Selection"
    $config.AnalysisDepth = switch ($depthChoice) {
        "1" { "Quick" }
        "2" { "Standard" }
        "3" { "Deep" }
        "4" { "Forensic" }
        default { "Standard" }
    }
    
    # Step 6: Summary
    Clear-Host
    Show-WizardHeader -Step 5 -Total 6 -Title "Configuration Summary"
    
    Write-Host "`n    📋 CONFIGURATION SUMMARY" -ForegroundColor Yellow
    Write-Host "    ═══════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "    Assessment: " -NoNewline -ForegroundColor White
    Write-Host $config.AssessmentName -ForegroundColor Green
    
    Write-Host "    Tenants: " -NoNewline -ForegroundColor White
    Write-Host "$($config.Tenants.Count) configured" -ForegroundColor Green
    
    foreach ($tenant in $config.Tenants) {
        Write-Host "      • $($tenant.Name) ($($tenant.Region))" -ForegroundColor Gray
    }
    
    Write-Host "    Modules: " -NoNewline -ForegroundColor White
    Write-Host ($config.Modules -join ", ") -ForegroundColor Green
    
    Write-Host "    Analysis Depth: " -NoNewline -ForegroundColor White
    Write-Host $config.AnalysisDepth -ForegroundColor Green
    
    Write-Host ""
    $confirm = Read-Host "    Save this configuration? (Y/N)"
    
    if ($confirm -eq 'Y') {
        $configPath = ".\PowerReview_Config_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $config | ConvertTo-Json -Depth 10 | Out-File $configPath
        
        Write-Host "`n    ✅ Configuration saved to: " -NoNewline -ForegroundColor Green
        Write-Host $configPath -ForegroundColor Yellow
        
        $script:UserProfile.ConfigPath = $configPath
    }
    
    Write-Host "`n    Press any key to return to main menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-WizardHeader {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Title
    )
    
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │  $Title $((' ' * (90 - $Title.Length)))Step $Step of $Total  │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    # Progress bar
    $progressWidth = 80
    $progress = [math]::Round(($Step / $Total) * $progressWidth)
    
    Write-Host "    Progress: [" -NoNewline -ForegroundColor White
    Write-Host ("█" * $progress) -NoNewline -ForegroundColor Green
    Write-Host ("░" * ($progressWidth - $progress)) -NoNewline -ForegroundColor DarkGray
    Write-Host "] $([math]::Round(($Step / $Total) * 100))%" -ForegroundColor White
}

function Read-HostWithDefault {
    param(
        [string]$Prompt,
        [string]$Default
    )
    
    Write-Host "$Prompt " -NoNewline -ForegroundColor White
    Write-Host "[$Default]: " -NoNewline -ForegroundColor DarkGray
    
    $input = Read-Host
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

function Show-ValidationWizard {
    Clear-Host
    
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    ENVIRONMENT VALIDATION                                                   │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    Write-Host "`n    🔍 Running comprehensive environment validation..." -ForegroundColor Yellow
    Write-Host ""
    
    # PowerShell Version
    Show-ValidationItem -Name "PowerShell Version" -Status "Checking"
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Show-ValidationItem -Name "PowerShell Version" -Status "Pass" -Value "v$($psVersion.ToString())"
        $script:ValidationResults.PowerShell = $true
    }
    else {
        Show-ValidationItem -Name "PowerShell Version" -Status "Fail" -Value "v$($psVersion.ToString()) (5.1+ required)"
        $script:ValidationResults.PowerShell = $false
    }
    
    # Required Modules
    Write-Host "`n    📦 REQUIRED MODULES" -ForegroundColor Yellow
    Write-Host "    ═════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    $requiredModules = @{
        "ExchangeOnlineManagement" = "3.0.0"
        "Microsoft.Graph" = "2.0.0"
        "MicrosoftTeams" = "4.0.0"
        "Microsoft.Online.SharePoint.PowerShell" = "16.0.0"
        "PnP.PowerShell" = "2.0.0"
        "Az.Accounts" = "2.0.0"
    }
    
    $moduleStatus = @{}
    
    foreach ($module in $requiredModules.GetEnumerator()) {
        Show-ValidationItem -Name $module.Key -Status "Checking"
        
        $installed = Get-Module -ListAvailable -Name $module.Key | 
            Where-Object { $_.Version -ge [Version]$module.Value } | 
            Select-Object -First 1
        
        if ($installed) {
            Show-ValidationItem -Name $module.Key -Status "Pass" -Value "v$($installed.Version)"
            $moduleStatus[$module.Key] = $true
        }
        else {
            Show-ValidationItem -Name $module.Key -Status "Fail" -Value "Not installed (v$($module.Value)+ required)"
            $moduleStatus[$module.Key] = $false
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    $script:ValidationResults.Modules = !($moduleStatus.Values -contains $false)
    
    # Network Connectivity
    Write-Host "`n    🌐 NETWORK CONNECTIVITY" -ForegroundColor Yellow
    Write-Host "    ═════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    $endpoints = @(
        @{Name="Microsoft Graph"; Url="https://graph.microsoft.com"; Required=$true},
        @{Name="Exchange Online"; Url="https://outlook.office365.com"; Required=$true},
        @{Name="SharePoint Online"; Url="https://microsoft.sharepoint.com"; Required=$true},
        @{Name="Azure Management"; Url="https://management.azure.com"; Required=$false}
    )
    
    $connectivityStatus = @{}
    
    foreach ($endpoint in $endpoints) {
        Show-ValidationItem -Name $endpoint.Name -Status "Testing"
        
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method Head -TimeoutSec 5 -ErrorAction Stop
            Show-ValidationItem -Name $endpoint.Name -Status "Pass" -Value "Reachable"
            $connectivityStatus[$endpoint.Name] = $true
        }
        catch {
            if ($endpoint.Required) {
                Show-ValidationItem -Name $endpoint.Name -Status "Fail" -Value "Unreachable"
            }
            else {
                Show-ValidationItem -Name $endpoint.Name -Status "Warn" -Value "Unreachable (optional)"
            }
            $connectivityStatus[$endpoint.Name] = $false
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    $script:ValidationResults.Network = !($endpoints | Where-Object { $_.Required -and !$connectivityStatus[$_.Name] })
    
    # Summary
    Write-Host "`n    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
    Write-Host ""
    
    $overallPass = !($script:ValidationResults.Values -contains $false)
    
    if ($overallPass) {
        Write-Host "    ✅ VALIDATION PASSED" -ForegroundColor Green
        Write-Host "       Your environment is ready for PowerReview assessments!" -ForegroundColor White
    }
    else {
        Write-Host "    ❌ VALIDATION FAILED" -ForegroundColor Red
        Write-Host "       Please address the issues above before proceeding." -ForegroundColor White
        
        Write-Host "`n    Would you like to automatically fix issues? (Y/N): " -NoNewline -ForegroundColor Yellow
        $fix = Read-Host
        
        if ($fix -eq 'Y') {
            Start-AutoFix
        }
    }
    
    Write-Host "`n    Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ValidationItem {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Value = ""
    )
    
    $statusSymbol = switch ($Status) {
        "Checking" { "⏳" }
        "Testing" { "🔄" }
        "Pass" { "✅" }
        "Fail" { "❌" }
        "Warn" { "⚠️" }
        default { "•" }
    }
    
    $statusColor = switch ($Status) {
        "Pass" { "Green" }
        "Fail" { "Red" }
        "Warn" { "Yellow" }
        default { "Gray" }
    }
    
    # Clear the line and rewrite
    Write-Host "`r    $statusSymbol " -NoNewline -ForegroundColor $statusColor
    Write-Host ("{0,-40}" -f $Name) -NoNewline -ForegroundColor White
    
    if ($Value) {
        Write-Host $Value -ForegroundColor $statusColor
    }
    else {
        Write-Host ""
    }
}

function Start-AutoFix {
    Clear-Host
    
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                        AUTO-FIX WIZARD                                                      │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    Write-Host "`n    🔧 Attempting to fix validation issues..." -ForegroundColor Yellow
    Write-Host ""
    
    # Fix missing modules
    if (!$script:ValidationResults.Modules) {
        Write-Host "    📦 Installing missing modules..." -ForegroundColor White
        Write-Host ""
        
        foreach ($module in $requiredModules.GetEnumerator()) {
            $installed = Get-Module -ListAvailable -Name $module.Key
            
            if (!$installed) {
                Write-Host "    Installing $($module.Key)..." -NoNewline -ForegroundColor White
                
                try {
                    Install-Module -Name $module.Key -MinimumVersion $module.Value -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                    Write-Host " ✅" -ForegroundColor Green
                }
                catch {
                    Write-Host " ❌" -ForegroundColor Red
                    Write-Host "      Error: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "`n    Auto-fix complete. Please run validation again." -ForegroundColor Yellow
    Write-Host "    Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-AssessmentWizard {
    param([string]$Mode = "Standard")
    
    Clear-Host
    
    # Check for existing configuration
    $configFiles = Get-ChildItem -Path . -Filter "PowerReview_Config_*.json" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if ($configFiles.Count -eq 0) {
        Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    NO CONFIGURATION FOUND                                                   │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    │                                                                                                             │
    │  No configuration files found. Please run the Configuration Wizard first.                                   │
    │                                                                                                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Yellow
        
        Write-Host "`n    Press any key to return to main menu..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Select configuration
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    SELECT CONFIGURATION                                                     │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    Write-Host "`n    📁 Available Configurations:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $configFiles.Count; $i++) {
        $config = Get-Content $configFiles[$i].FullName | ConvertFrom-Json
        Write-Host "    [$($i+1)] " -NoNewline -ForegroundColor White
        Write-Host $configFiles[$i].Name -ForegroundColor Green
        Write-Host "        Assessment: $($config.AssessmentName)" -ForegroundColor Gray
        Write-Host "        Tenants: $($config.Tenants.Count)" -ForegroundColor Gray
        Write-Host "        Created: $($configFiles[$i].LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        Write-Host ""
    }
    
    $selection = Read-Host "    Select configuration (1-$($configFiles.Count))"
    $selectedConfig = $configFiles[[int]$selection - 1]
    
    if (!$selectedConfig) {
        Write-Host "    Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Pre-flight checklist
    Clear-Host
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    PRE-FLIGHT CHECKLIST                                                     │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    $config = Get-Content $selectedConfig.FullName | ConvertFrom-Json
    
    Write-Host "`n    📋 Assessment: " -NoNewline -ForegroundColor White
    Write-Host $config.AssessmentName -ForegroundColor Green
    
    Write-Host "`n    🏢 Tenants to Assess:" -ForegroundColor White
    foreach ($tenant in $config.Tenants) {
        Write-Host "      • $($tenant.Name) ($($tenant.TenantId))" -ForegroundColor Gray
    }
    
    Write-Host "`n    📦 Modules:" -ForegroundColor White
    Write-Host "      $($config.Modules -join ', ')" -ForegroundColor Gray
    
    Write-Host "`n    🔍 Analysis Depth: " -NoNewline -ForegroundColor White
    Write-Host $config.AnalysisDepth -ForegroundColor Green
    
    # Time estimate
    $timePerTenant = switch ($config.AnalysisDepth) {
        "Quick" { 30 }
        "Standard" { 60 }
        "Deep" { 150 }
        "Forensic" { 240 }
        default { 60 }
    }
    
    $totalTime = $timePerTenant * $config.Tenants.Count
    
    Write-Host "`n    ⏱️  Estimated Time: " -NoNewline -ForegroundColor White
    Write-Host "$totalTime minutes" -ForegroundColor Yellow
    
    Write-Host "`n    ⚡ PIM Activation Required:" -ForegroundColor White
    Write-Host "      Please ensure you have activated required roles for all tenants" -ForegroundColor Yellow
    
    Write-Host "`n    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
    
    Write-Host "`n    Ready to start assessment? (Y/N): " -NoNewline -ForegroundColor Green
    $confirm = Read-Host
    
    if ($confirm -ne 'Y') {
        return
    }
    
    # Start assessment
    Clear-Host
    Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                    ASSESSMENT IN PROGRESS                                                   │
    │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Cyan
    
    $outputPath = ".\PowerReview_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    Write-Host "`n    🚀 Starting PowerReview Assessment..." -ForegroundColor Yellow
    Write-Host "    Output: $outputPath" -ForegroundColor Gray
    Write-Host ""
    
    # Execute assessment
    $params = @{
        TenantConfig = $selectedConfig.FullName
        OutputPath = $outputPath
        AnalysisDepth = $config.AnalysisDepth
    }
    
    if ($Mode -eq "Quick") {
        $params.AnalysisDepth = "Basic"
    }
    elseif ($Mode -eq "Deep") {
        $params.DeepAnalysis = $true
    }
    elseif ($Mode -eq "Compliance") {
        $params.ComplianceMode = $true
        $params.Modules = @("Compliance", "Purview")
    }
    
    try {
        # Check for main script
        $mainScript = ".\PowerReview-Enhanced-Framework.ps1"
        if (!(Test-Path $mainScript)) {
            $mainScript = ".\PowerReview-Complete.ps1"
        }
        
        & $mainScript @params
        
        Write-Host "`n    ✅ Assessment completed successfully!" -ForegroundColor Green
        Write-Host "    Results saved to: $outputPath" -ForegroundColor White
        
        # Open report
        $report = Get-ChildItem -Path $outputPath -Filter "*Executive*.html" -Recurse | Select-Object -First 1
        if ($report) {
            Start-Process $report.FullName
        }
    }
    catch {
        Write-Host "`n    ❌ Assessment failed: $_" -ForegroundColor Red
    }
    
    Write-Host "`n    Press any key to return to main menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#endregion

#region Main Execution

# Show welcome screen
Show-WelcomeScreen

# Main loop
$exitRequested = $false

while (!$exitRequested) {
    $selection = Show-MainMenu
    
    switch ($selection) {
        "1" {
            # Start New Assessment
            Show-PermissionRequirements
            Start-AssessmentWizard -Mode "Standard"
        }
        "2" {
            # Configuration Wizard
            Show-ConfigurationWizard
        }
        "3" {
            # Quick Assessment
            Start-AssessmentWizard -Mode "Quick"
        }
        "4" {
            # Deep Analysis
            Start-AssessmentWizard -Mode "Deep"
        }
        "5" {
            # Compliance Check
            Start-AssessmentWizard -Mode "Compliance"
        }
        "6" {
            # Setup Authentication
            Clear-Host
            & .\Setup-PowerReview.ps1 -ConfigureAuthentication
            Write-Host "`n    Press any key to continue..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "7" {
            # Validate Environment
            Show-ValidationWizard
        }
        "8" {
            # View Documentation
            Clear-Host
            if (Test-Path ".\README-PowerReview.md") {
                Start-Process ".\README-PowerReview.md"
            }
            else {
                Write-Host "    Documentation not found." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        "9" {
            # Advanced Options
            Clear-Host
            Write-Host "    Launching PowerReview with advanced options..." -ForegroundColor Yellow
            Write-Host "    Use command line parameters for full control." -ForegroundColor Gray
            Write-Host "`n    Example:" -ForegroundColor White
            Write-Host '    .\PowerReview-Enhanced-Framework.ps1 -TenantConfig "config.json" -DeepAnalysis -SecureStorage' -ForegroundColor Gray
            Write-Host "`n    Press any key to continue..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "0" {
            # Exit
            $exitRequested = $true
        }
        default {
            Write-Host "    Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

# Exit screen
Clear-Host
Write-Host @"
    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                                             │
    │                              Thank you for using PowerReview!                                               │
    │                                                                                                             │
    │                         Enterprise Assessment Platform for M365 & Azure                                     │
    │                                                                                                             │
    │     Session Duration: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 1)) minutes           │
    │                                                                                                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

"@ -ForegroundColor Cyan

#endregion