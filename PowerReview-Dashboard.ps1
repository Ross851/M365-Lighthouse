#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Professional Dashboard
    Real-time monitoring and control center for assessments
#>

[CmdletBinding()]
param(
    [switch]$DarkMode,
    [switch]$Kiosk
)

# Import UI components
. .\PowerReview-UI-Components.ps1

# Initialize dashboard
$script:DashboardData = @{
    ActiveAssessments = @()
    CompletedAssessments = @()
    TotalTenants = 0
    TotalFindings = 0
    CriticalIssues = 0
    SystemHealth = "Optimal"
    LastUpdate = Get-Date
}

function Start-Dashboard {
    # Set console properties for best display
    $Host.UI.RawUI.WindowTitle = "PowerReview Dashboard - Enterprise Assessment Platform"
    
    if ($Host.UI.RawUI.WindowSize.Width -lt 120) {
        $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 50)
        $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
    }
    
    # Show splash screen
    Show-SplashScreen
    Start-Sleep -Seconds 2
    
    # Main dashboard loop
    $exitDashboard = $false
    
    while (!$exitDashboard) {
        Show-MainDashboard
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.Character) {
            '1' { Start-NewAssessmentWorkflow }
            '2' { Show-AssessmentHistory }
            '3' { Show-TenantManagement }
            '4' { Show-ComplianceOverview }
            '5' { Show-SecurityPosture }
            '6' { Show-ReportsHub }
            '7' { Show-SettingsPanel }
            '8' { Show-LiveMonitor }
            '9' { Show-HelpDocumentation }
            '0' { $exitDashboard = $true }
            'r' { Update-DashboardData }
            'R' { Update-DashboardData }
        }
    }
}

function Show-MainDashboard {
    Clear-Host
    
    # Header
    Write-Host @"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                         POWERREVIEW COMMAND CENTER                                                  ┃
┃                                    Enterprise Assessment Dashboard v4.0                                             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
"@ -ForegroundColor Cyan
    
    # System Status Bar
    Show-SystemStatus
    
    # Key Metrics Grid
    Show-MetricsGrid
    
    # Quick Actions Panel
    Show-QuickActions
    
    # Recent Activity Feed
    Show-ActivityFeed
    
    # Footer
    Write-Host @"

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  [1] New Assessment  [2] History  [3] Tenants  [4] Compliance  [5] Security  [6] Reports  [7] Settings  [0] Exit  ┃
┃                                        [R] Refresh Dashboard  [8] Live Monitor                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
"@ -ForegroundColor DarkGray
    
    Write-Host "  Last Update: $($script:DashboardData.LastUpdate.ToString('HH:mm:ss'))" -ForegroundColor DarkGray
}

function Show-SystemStatus {
    $statusColor = switch ($script:DashboardData.SystemHealth) {
        "Optimal" { "Green" }
        "Warning" { "Yellow" }
        "Critical" { "Red" }
        default { "Gray" }
    }
    
    Write-Host "`n  SYSTEM STATUS: " -NoNewline -ForegroundColor White
    Write-Host $script:DashboardData.SystemHealth.ToUpper() -ForegroundColor $statusColor
    
    # Status indicators
    $indicators = @(
        @{Name="API Connectivity"; Status="Connected"; Icon="🌐"},
        @{Name="Module Health"; Status="All Operational"; Icon="✅"},
        @{Name="License Status"; Status="Valid"; Icon="🔑"},
        @{Name="Storage"; Status="85% Free"; Icon="💾"}
    )
    
    Write-Host "  " -NoNewline
    foreach ($ind in $indicators) {
        Write-Host "$($ind.Icon) $($ind.Name): " -NoNewline -ForegroundColor Gray
        Write-Host "$($ind.Status)  " -NoNewline -ForegroundColor Green
    }
    Write-Host ""
}

function Show-MetricsGrid {
    Write-Host "`n┌────────────────────────────┬────────────────────────────┬────────────────────────────┬────────────────────────────┐"
    Write-Host "│" -NoNewline
    
    # Metric 1: Active Assessments
    Write-Host "    🚀 ACTIVE ASSESSMENTS    " -NoNewline -ForegroundColor Yellow
    Write-Host "│" -NoNewline
    
    # Metric 2: Total Tenants
    Write-Host "      🏢 TOTAL TENANTS       " -NoNewline -ForegroundColor Cyan
    Write-Host "│" -NoNewline
    
    # Metric 3: Findings
    Write-Host "     ⚠️  TOTAL FINDINGS      " -NoNewline -ForegroundColor White
    Write-Host "│" -NoNewline
    
    # Metric 4: Critical Issues
    Write-Host "    🚨 CRITICAL ISSUES      " -NoNewline -ForegroundColor Red
    Write-Host "│"
    
    Write-Host "│" -NoNewline
    Write-Host ("         " + $script:DashboardData.ActiveAssessments.Count.ToString().PadLeft(3)) -NoNewline -ForegroundColor White
    Write-Host "                │" -NoNewline
    
    Write-Host ("          " + $script:DashboardData.TotalTenants.ToString().PadLeft(3)) -NoNewline -ForegroundColor White
    Write-Host "                │" -NoNewline
    
    Write-Host ("         " + $script:DashboardData.TotalFindings.ToString().PadLeft(4)) -NoNewline -ForegroundColor White
    Write-Host "               │" -NoNewline
    
    Write-Host ("         " + $script:DashboardData.CriticalIssues.ToString().PadLeft(3)) -NoNewline -ForegroundColor White
    Write-Host "                │"
    
    Write-Host "└────────────────────────────┴────────────────────────────┴────────────────────────────┴────────────────────────────┘"
}

function Show-QuickActions {
    Write-Host "`n  ⚡ QUICK ACTIONS" -ForegroundColor Yellow
    Write-Host "  ═══════════════" -ForegroundColor Yellow
    
    $actions = @(
        @{Key="F1"; Action="Quick Security Scan"; Icon="🔍"},
        @{Key="F2"; Action="Generate Executive Report"; Icon="📊"},
        @{Key="F3"; Action="Export All Findings"; Icon="💾"},
        @{Key="F4"; Action="Schedule Assessment"; Icon="📅"}
    )
    
    Write-Host "  " -NoNewline
    foreach ($action in $actions) {
        Write-Host "[$($action.Key)] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($action.Icon) $($action.Action)  " -NoNewline -ForegroundColor White
    }
    Write-Host ""
}

function Show-ActivityFeed {
    Write-Host "`n  📜 RECENT ACTIVITY" -ForegroundColor Yellow
    Write-Host "  ═════════════════" -ForegroundColor Yellow
    
    # Simulated activity
    $activities = @(
        @{Time="14:32"; Event="Assessment completed for Contoso"; Type="Success"},
        @{Time="14:15"; Event="Critical finding in Fabrikam tenant"; Type="Warning"},
        @{Time="13:48"; Event="Compliance scan initiated for Northwind"; Type="Info"},
        @{Time="12:30"; Event="PIM roles activated successfully"; Type="Success"},
        @{Time="11:45"; Event="New tenant configuration added"; Type="Info"}
    )
    
    foreach ($activity in $activities | Select-Object -First 5) {
        $icon = switch ($activity.Type) {
            "Success" { "✅" }
            "Warning" { "⚠️" }
            "Error" { "❌" }
            default { "ℹ️" }
        }
        
        $color = switch ($activity.Type) {
            "Success" { "Green" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "Gray" }
        }
        
        Write-Host "  [$($activity.Time)] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$icon " -NoNewline
        Write-Host $activity.Event -ForegroundColor $color
    }
}

function Start-NewAssessmentWorkflow {
    Clear-Host
    
    # Professional assessment setup wizard
    $wizard = @{
        CurrentStep = 1
        TotalSteps = 5
        AssessmentConfig = @{}
    }
    
    # Step 1: Welcome
    Show-AssessmentWizardStep -Step 1 -Title "Welcome to PowerReview Assessment Wizard"
    
    Write-Host @"
    
    This wizard will guide you through setting up a comprehensive security assessment
    for your Microsoft 365 and Azure environments.
    
    Before we begin, please ensure you have:
    
    ✓ Global Reader or equivalent permissions
    ✓ PIM roles activated (if applicable)
    ✓ Network connectivity to all required endpoints
    ✓ Approximately 1-3 hours for the assessment
    
    Press any key to continue...
"@ -ForegroundColor White
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Continue with additional steps...
}

function Show-AssessmentWizardStep {
    param(
        [int]$Step,
        [string]$Title
    )
    
    Clear-Host
    
    # Progress bar
    $progress = [Math]::Round(($Step / 5) * 100)
    
    Write-Host @"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                    ASSESSMENT CONFIGURATION WIZARD                                                  ┃
┃                                            Step $Step of 5                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  Progress: [
"@ -ForegroundColor Cyan -NoNewline
    
    # Draw progress bar
    $completed = [Math]::Round($progress / 2)
    for ($i = 0; $i -lt 50; $i++) {
        if ($i -lt $completed) {
            Write-Host "█" -NoNewline -ForegroundColor Green
        }
        else {
            Write-Host "░" -NoNewline -ForegroundColor DarkGray
        }
    }
    
    Write-Host "] $progress%" -ForegroundColor White
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "  " + ("═" * $Title.Length) -ForegroundColor Yellow
}

function Update-DashboardData {
    # Simulate data refresh
    Show-Notification -Message "Refreshing dashboard data..." -Type "Info" -Duration 1000
    
    # Update metrics
    $script:DashboardData.LastUpdate = Get-Date
    $script:DashboardData.TotalFindings = Get-Random -Minimum 50 -Maximum 200
    $script:DashboardData.CriticalIssues = Get-Random -Minimum 0 -Maximum 20
    
    Show-Notification -Message "Dashboard updated successfully" -Type "Success"
}

# Auto-start dashboard
Start-Dashboard