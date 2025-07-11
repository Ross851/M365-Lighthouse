# Enhanced PowerReview Launcher
# Professional M365 Security Assessment Tool

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [switch]$SkipPrerequisites,
    [switch]$AutoConnect,
    [string]$ConfigFile
)

# Set script root
$global:PowerReviewRoot = $PSScriptRoot

# Import required modules
. "$PSScriptRoot\PowerReview-ErrorHandling.ps1"
. "$PSScriptRoot\Fix-PowerPlatformIssue.ps1"
. "$PSScriptRoot\PowerReview-Wizard.ps1"

function Show-StartupBanner {
    $banner = @"
    
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              PowerReview M365 Security Suite              ║
    ║           Professional Assessment Framework v2.0           ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    
"@
    
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "    Initializing security assessment framework..." -ForegroundColor Yellow
    Write-Host ""
}

function Initialize-PowerReview {
    Show-StartupBanner
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Host "WARNING: Not running as Administrator. Some features may be limited." -ForegroundColor Yellow
        Write-Host "Restart PowerShell as Administrator for full functionality.`n" -ForegroundColor Yellow
        
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue -ne 'Y') {
            exit
        }
    }
    
    # Initialize logging
    $logPath = "$PSScriptRoot\Logs"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    
    $global:PowerReviewLogFile = "$logPath\PowerReview_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Write-Log -Level "INFO" -Message "PowerReview initialized. Log file: $global:PowerReviewLogFile"
    
    # Check for updates (optional)
    if (Test-Path "$PSScriptRoot\.git") {
        Write-Host "Checking for updates..." -ForegroundColor Cyan
        $gitStatus = Invoke-SafeCommand -Command {
            git fetch --quiet
            git status -uno
        } -ErrorMessage "Failed to check for updates" -ContinueOnError
        
        if ($gitStatus.Success -and $gitStatus.Result -match "Your branch is behind") {
            Write-Host "Updates available! Run 'git pull' to update." -ForegroundColor Yellow
        }
    }
    
    # Load configuration if provided
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        Write-Host "Loading configuration from: $ConfigFile" -ForegroundColor Green
        $global:PowerReviewConfig = Get-Content $ConfigFile | ConvertFrom-Json
    }
    
    # Main menu
    $menuOptions = @(
        "Start Security Assessment Wizard",
        "Quick Security Check",
        "Generate Report from Previous Assessment",
        "Configure Settings",
        "View Documentation",
        "Exit"
    )
    
    while ($true) {
        Write-Host "`nMain Menu" -ForegroundColor Cyan
        Write-Host "=========" -ForegroundColor Cyan
        
        $selection = Show-Menu -Title "" -Options $menuOptions -Prompt "Select an option"
        
        switch ($selection) {
            0 { 
                # Start wizard
                Start-WizardAssessment
            }
            1 { 
                # Quick check
                Write-Host "`nStarting quick security check..." -ForegroundColor Green
                # Add quick check logic here
            }
            2 { 
                # Generate report
                Write-Host "`nAvailable assessments:" -ForegroundColor Green
                Get-ChildItem -Path "C:\SharePointScripts" -Filter "M365Review_*" -Directory | 
                    Select-Object Name, CreationTime | 
                    Format-Table -AutoSize
            }
            3 { 
                # Configure settings
                Write-Host "`nConfiguration options coming soon..." -ForegroundColor Yellow
            }
            4 { 
                # View documentation
                if (Test-Path "$PSScriptRoot\DEPLOYMENT_GUIDE.md") {
                    Start-Process "$PSScriptRoot\DEPLOYMENT_GUIDE.md"
                }
            }
            5 { 
                # Exit
                Write-Host "`nThank you for using PowerReview!" -ForegroundColor Green
                exit
            }
        }
        
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Clear-Host
        Show-StartupBanner
    }
}

# Error handler
trap {
    Write-Log -Level "ERROR" -Message "Fatal error: $_"
    Write-Host "`nFATAL ERROR: $_" -ForegroundColor Red
    Write-Host "Check log file for details: $global:PowerReviewLogFile" -ForegroundColor Yellow
    exit 1
}

# Start the application
Initialize-PowerReview