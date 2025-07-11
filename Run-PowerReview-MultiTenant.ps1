#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Multi-Tenant Execution Wrapper
    Simplified script to run assessments across multiple tenants
    
.EXAMPLE
    # Run with default config
    .\Run-PowerReview-MultiTenant.ps1
    
.EXAMPLE
    # Run with specific config and deep analysis
    .\Run-PowerReview-MultiTenant.ps1 -ConfigFile ".\production-tenants.json" -DeepAnalysis
#>

[CmdletBinding()]
param(
    [string]$ConfigFile = ".\tenant-config-template.json",
    [switch]$DeepAnalysis,
    [switch]$QuickAssessment,
    [switch]$SecurityOnly,
    [switch]$ComplianceOnly,
    [string]$SpecificTenant,
    [switch]$GenerateReport
)

# Display banner
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║           PowerReview Multi-Tenant Assessment Runner              ║
║                    Quick Start Edition                            ║
╚══════════════════════════════════════════════════════════════════╝

This script will run PowerReview assessments across all configured tenants.

"@ -ForegroundColor Cyan

# Validate config file exists
if (!(Test-Path $ConfigFile)) {
    Write-Host "ERROR: Configuration file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "`nPlease run: .\Setup-PowerReview.ps1 -CreateConfig" -ForegroundColor Yellow
    exit
}

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Yellow
$config = Get-Content $ConfigFile | ConvertFrom-Json

Write-Host "Found $($config.Tenants.Count) tenants in configuration" -ForegroundColor Green

# Set parameters based on switches
$params = @{
    TenantConfig = $ConfigFile
}

if ($DeepAnalysis) {
    $params.AnalysisDepth = "Deep"
    $params.DeepAnalysis = $true
    Write-Host "Running DEEP analysis (this will take longer)..." -ForegroundColor Yellow
}
elseif ($QuickAssessment) {
    $params.AnalysisDepth = "Basic"
    $params.Modules = @("Security", "Purview")
    Write-Host "Running QUICK assessment (Security and Purview only)..." -ForegroundColor Yellow
}

if ($SecurityOnly) {
    $params.Modules = @("Security")
    Write-Host "Running SECURITY-ONLY assessment..." -ForegroundColor Yellow
}
elseif ($ComplianceOnly) {
    $params.Modules = @("Compliance", "Purview")
    $params.ComplianceMode = $true
    Write-Host "Running COMPLIANCE-ONLY assessment..." -ForegroundColor Yellow
}

if ($SpecificTenant) {
    Write-Host "Filtering to specific tenant: $SpecificTenant" -ForegroundColor Yellow
    # Modify config to only include specific tenant
    $config.Tenants = $config.Tenants | Where-Object { $_.Name -eq $SpecificTenant -or $_.Id -eq $SpecificTenant }
    
    if ($config.Tenants.Count -eq 0) {
        Write-Host "ERROR: Tenant not found: $SpecificTenant" -ForegroundColor Red
        exit
    }
    
    # Save modified config
    $tempConfig = ".\temp-config-$(Get-Date -Format 'yyyyMMddHHmmss').json"
    $config | ConvertTo-Json -Depth 10 | Out-File $tempConfig
    $params.TenantConfig = $tempConfig
}

# Display assessment plan
Write-Host "`nAssessment Plan:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
foreach ($tenant in $config.Tenants) {
    Write-Host "  • $($tenant.Name) ($($tenant.Id))" -ForegroundColor White
}

Write-Host "`nModules to assess:" -ForegroundColor Cyan
$modules = if ($params.Modules) { $params.Modules } else { $config.Modules }
foreach ($module in $modules) {
    Write-Host "  • $module" -ForegroundColor White
}

# Confirm execution
Write-Host "`nEstimated time: " -NoNewline
$timeEstimate = switch ($params.AnalysisDepth) {
    "Basic" { "$($config.Tenants.Count * 15) minutes" }
    "Deep" { "$($config.Tenants.Count * 45) minutes" }
    default { "$($config.Tenants.Count * 30) minutes" }
}
Write-Host $timeEstimate -ForegroundColor Yellow

$confirm = Read-Host "`nProceed with assessment? (Y/N)"
if ($confirm -ne 'Y') {
    Write-Host "Assessment cancelled" -ForegroundColor Red
    exit
}

# Create output directory
$outputPath = ".\PowerReview_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$params.OutputPath = $outputPath
$params.SecureStorage = $true

Write-Host "`nStarting assessment..." -ForegroundColor Green
Write-Host "Output will be saved to: $outputPath" -ForegroundColor Yellow

# Log start time
$startTime = Get-Date

try {
    # Check if main script exists
    $mainScript = ".\PowerReview-Enhanced-Framework.ps1"
    if (!(Test-Path $mainScript)) {
        $mainScript = ".\PowerReview-Complete.ps1"
        if (!(Test-Path $mainScript)) {
            throw "PowerReview script not found. Please ensure PowerReview-Enhanced-Framework.ps1 is in the current directory."
        }
    }
    
    # Execute PowerReview
    & $mainScript @params
    
    $success = $true
}
catch {
    Write-Host "`nERROR: Assessment failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $success = $false
}
finally {
    # Cleanup temp config if created
    if ($tempConfig -and (Test-Path $tempConfig)) {
        Remove-Item $tempConfig -Force
    }
}

# Calculate duration
$duration = (Get-Date) - $startTime

# Display summary
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           Assessment Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

if ($success) {
    Write-Host "Status: " -NoNewline
    Write-Host "COMPLETED" -ForegroundColor Green
}
else {
    Write-Host "Status: " -NoNewline
    Write-Host "FAILED" -ForegroundColor Red
}

Write-Host "Duration: $([Math]::Round($duration.TotalMinutes, 1)) minutes"
Write-Host "Output Location: $outputPath"

if ($success -and $GenerateReport) {
    Write-Host "`nGenerating consolidated report..." -ForegroundColor Yellow
    
    # Open the executive report
    $execReport = Get-ChildItem -Path $outputPath -Filter "*Executive*.html" -Recurse | Select-Object -First 1
    if ($execReport) {
        Start-Process $execReport.FullName
        Write-Host "Executive report opened in browser" -ForegroundColor Green
    }
}

# Provide next steps
if ($success) {
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Review the executive report in: $outputPath" -ForegroundColor White
    Write-Host "2. Check individual tenant reports for detailed findings" -ForegroundColor White
    Write-Host "3. Use the remediation roadmap to plan fixes" -ForegroundColor White
    Write-Host "4. Schedule follow-up assessments after remediation" -ForegroundColor White
}

Write-Host "`nAssessment complete!" -ForegroundColor Green