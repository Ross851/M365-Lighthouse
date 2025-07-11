#Requires -Version 7.0

<#
.SYNOPSIS
    Quick start script for PowerReview workshops - 5 minute setup
.DESCRIPTION
    Sets up everything needed for a workshop in under 5 minutes with no dependencies
.NOTES
    Version: 1.0
    Perfect for: Workshops, POCs, Demos, Training
#>

param(
    [switch]$SkipPreCheck,
    [switch]$Minimal,
    [switch]$Reset
)

# Display banner
function Show-Banner {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    🚀 POWERREVIEW WORKSHOP QUICK START 🚀                     ║
║                                                                               ║
║                         5-Minute Setup for Developers                          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

This script will set up PowerReview for workshop/development use.
No Azure account or internet connection required!

"@ -ForegroundColor Cyan
}

# Pre-flight checks
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    $checks = @(
        @{
            Name = "PowerShell Version"
            Test = { $PSVersionTable.PSVersion.Major -ge 7 }
            Message = "PowerShell 7+ required. Download from: https://aka.ms/powershell"
        },
        @{
            Name = "Administrator Rights"
            Test = { ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
            Message = "Please run as Administrator"
        },
        @{
            Name = "Disk Space"
            Test = { (Get-PSDrive C).Free -gt 1GB }
            Message = "At least 1GB free space required"
        }
    )
    
    $passed = $true
    foreach ($check in $checks) {
        Write-Host -NoNewline "  • $($check.Name): "
        if (& $check.Test) {
            Write-Host "✅ PASS" -ForegroundColor Green
        } else {
            Write-Host "❌ FAIL - $($check.Message)" -ForegroundColor Red
            $passed = $false
        }
    }
    
    return $passed
}

# Reset function for clean slate
function Reset-Workshop {
    Write-Host "`n🧹 Resetting PowerReview..." -ForegroundColor Yellow
    
    $paths = @(
        ".\PowerReview-Data",
        ".\Discovery-Results",
        ".\EC-Discovery-Results",
        ".\PowerReview-Output",
        ".\SecureVault",
        ".\Logs",
        ".\storage-config.json",
        ".\auth-config.json",
        ".\db-config.secure.json",
        ".\audit-config.json",
        ".\backup-config.json"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  • Removed: $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "✅ Reset complete!" -ForegroundColor Green
}

# Main setup function
function Start-WorkshopSetup {
    param([bool]$Minimal)
    
    # Step 1: Configure local storage
    Write-Host "`n📁 Step 1: Configuring local storage..." -ForegroundColor Yellow
    try {
        .\Configure-DataStorage.ps1 -UseDefaults -ErrorAction Stop
        Write-Host "✅ Storage configured!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Storage configuration failed: $_" -ForegroundColor Red
        return $false
    }
    
    # Step 2: Setup encryption
    Write-Host "`n🔐 Step 2: Setting up encryption..." -ForegroundColor Yellow
    try {
        .\Setup-PowerReviewSecurity.ps1 -ConfigureEncryption -ErrorAction Stop
        Write-Host "✅ Encryption enabled!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Encryption setup failed: $_" -ForegroundColor Red
        return $false
    }
    
    if (-not $Minimal) {
        # Step 3: Setup audit logging
        Write-Host "`n📋 Step 3: Configuring audit logging..." -ForegroundColor Yellow
        try {
            .\Setup-PowerReviewSecurity.ps1 -ConfigureAuditing -ErrorAction Stop
            Write-Host "✅ Audit logging enabled!" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Audit setup failed (non-critical): $_" -ForegroundColor Yellow
        }
    }
    
    # Step 4: Create sample data
    Write-Host "`n📊 Step 4: Creating sample data..." -ForegroundColor Yellow
    Create-SampleData
    Write-Host "✅ Sample data created!" -ForegroundColor Green
    
    return $true
}

# Create sample data for workshop
function Create-SampleData {
    $sampleOrg = @{
        Name = "Contoso Workshop Ltd"
        TenantId = "workshop.onmicrosoft.com"
        Users = 100
        Industry = "Technology"
    }
    
    $sampleConfig = @{
        Organization = $sampleOrg.Name
        TenantId = $sampleOrg.TenantId
        Modules = @{
            Purview = @{ Enabled = $true; Priority = "High" }
            SharePoint = @{ Enabled = $true; Priority = "Medium" }
            Security = @{ Enabled = $true; Priority = "High" }
        }
    }
    
    # Save sample configuration
    $sampleConfig | ConvertTo-Json -Depth 10 | Out-File -Path ".\workshop-config.json" -Encoding UTF8
    
    # Create sample questionnaire responses
    $sampleResponses = @{
        Organization = $sampleOrg.Name
        StartTime = Get-Date
        Responses = @{
            "GO-001" = "Technology"
            "GO-002" = "51-250"
            "DC-001" = @("Personal Identifiable Information (PII)", "Financial Data")
            "DC-002" = "No"
            "CR-001" = @("GDPR", "ISO 27001")
        }
    }
    
    $outputPath = ".\Discovery-Results"
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $sampleResponses | ConvertTo-Json -Depth 10 | Out-File -Path "$outputPath\Sample-Discovery-$timestamp.json" -Encoding UTF8
}

# Verification function
function Test-WorkshopSetup {
    Write-Host "`n🔍 Verifying setup..." -ForegroundColor Yellow
    
    $tests = @(
        @{
            Name = "Storage Configuration"
            Path = ".\storage-config.json"
        },
        @{
            Name = "Encryption Keys"
            Path = ".\SecureVault\.key"
        },
        @{
            Name = "Encryption Module"
            Path = ".\PowerReview-Encryption.psm1"
        },
        @{
            Name = "Data Directories"
            Path = "C:\PowerReview-Data"
        }
    )
    
    $allPassed = $true
    foreach ($test in $tests) {
        Write-Host -NoNewline "  • $($test.Name): "
        if (Test-Path $test.Path) {
            Write-Host "✅ Found" -ForegroundColor Green
        } else {
            Write-Host "❌ Missing" -ForegroundColor Red
            $allPassed = $false
        }
    }
    
    return $allPassed
}

# Workshop helper functions
function Show-WorkshopCommands {
    Write-Host @"

📚 WORKSHOP QUICK REFERENCE
═══════════════════════════════════════════════════════════════

1️⃣ Run Assessment with Wizard:
   .\Start-PowerReview.ps1

2️⃣ Run Discovery Questionnaire:
   . .\PowerReview-Discovery-Questionnaire.ps1
   Start-DiscoveryQuestionnaire

3️⃣ Run Electoral Commission Template:
   . .\Electoral-Commission-Questionnaire.ps1
   Start-ElectoralCommissionQuestionnaire

4️⃣ View Data Architecture:
   .\Show-DataArchitecture.ps1 -Simple

5️⃣ Check Security Status:
   .\Setup-PowerReviewSecurity.ps1 -ShowSecurityStatus

6️⃣ Find Your Data:
   Get-ChildItem C:\PowerReview-Data -Recurse

7️⃣ View Latest Assessment:
   `$latest = Get-Content (Get-ChildItem *Assessment*.json | Sort LastWriteTime -Desc | Select -First 1)
   `$latest | ConvertFrom-Json | ConvertTo-Json -Depth 3

📁 Key Locations:
   • Assessments: C:\PowerReview-Data\Assessments\
   • Questions: .\Discovery-Results\
   • Reports: .\PowerReview-Output\

🆘 Need Help?
   Get-Help .\Start-PowerReview.ps1 -Full
   Get-Help .\Configure-DataStorage.ps1 -Examples

"@ -ForegroundColor Cyan
}

# Main execution
Show-Banner

# Handle reset
if ($Reset) {
    $confirm = Read-Host "⚠️  This will delete all PowerReview data. Continue? (Y/N)"
    if ($confirm -eq 'Y') {
        Reset-Workshop
    }
    return
}

# Run pre-checks
if (-not $SkipPreCheck) {
    if (-not (Test-Prerequisites)) {
        Write-Host "`n❌ Prerequisites not met. Please fix the issues above." -ForegroundColor Red
        return
    }
}

# Check if already configured
if ((Test-Path ".\storage-config.json") -and (Test-Path ".\SecureVault\.key")) {
    Write-Host "`n✅ PowerReview is already configured!" -ForegroundColor Green
    Write-Host "   Run with -Reset to start fresh." -ForegroundColor Gray
    Show-WorkshopCommands
    return
}

# Start setup
Write-Host "`nStarting workshop setup..." -ForegroundColor Green
$setupResult = Start-WorkshopSetup -Minimal:$Minimal

if ($setupResult) {
    # Verify setup
    if (Test-WorkshopSetup) {
        Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                          ✅ SETUP COMPLETE! ✅                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🎉 PowerReview is ready for your workshop!

Setup Summary:
• Storage: C:\PowerReview-Data\ (Local encrypted)
• Encryption: AES-256 enabled
• Sample Data: Created
• Time Taken: ~$(((Get-Date) - $startTime).TotalSeconds) seconds

"@ -ForegroundColor Green
        
        Show-WorkshopCommands
        
        Write-Host "`n🚀 Ready to start? Try this command:" -ForegroundColor Yellow
        Write-Host "   .\Start-PowerReview.ps1" -ForegroundColor Cyan
    }
    else {
        Write-Host "`n⚠️  Setup completed with warnings. Some components may be missing." -ForegroundColor Yellow
    }
}
else {
    Write-Host "`n❌ Setup failed. Please check the errors above." -ForegroundColor Red
    Write-Host "   You can try manual setup with individual commands." -ForegroundColor Gray
}

# Create quick test script
$testScript = @'
# Quick test to verify everything works
Write-Host "Testing PowerReview setup..." -ForegroundColor Cyan

# Test encryption
Import-Module .\PowerReview-Encryption.psm1
$testData = @{Message = "Hello Workshop!"}
$encrypted = Protect-PowerReviewData -Data $testData
$decrypted = Unprotect-PowerReviewData -EncryptedData $encrypted

if ($decrypted.Message -eq "Hello Workshop!") {
    Write-Host "✅ Encryption working!" -ForegroundColor Green
} else {
    Write-Host "❌ Encryption test failed" -ForegroundColor Red
}

Write-Host "`nSetup verification complete!" -ForegroundColor Green
'@

$testScript | Out-File -Path ".\Test-Workshop.ps1" -Encoding UTF8
Write-Host "`n💡 TIP: Run .\Test-Workshop.ps1 to verify encryption is working" -ForegroundColor Cyan