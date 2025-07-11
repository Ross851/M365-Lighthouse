#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Setup and Configuration Helper
    
.DESCRIPTION
    Helps set up and configure PowerReview for multi-tenant assessments
    Includes module installation, configuration setup, and validation
    
.EXAMPLE
    .\Setup-PowerReview.ps1 -InstallModules -CreateConfig
#>

[CmdletBinding()]
param(
    [switch]$InstallModules,
    [switch]$CreateConfig,
    [switch]$ValidateSetup,
    [switch]$GenerateSampleConfig,
    [int]$TenantCount = 1,
    [switch]$ConfigureAuthentication,
    [switch]$TestRun
)

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║              PowerReview Setup and Configuration                  ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

#region Module Installation
if ($InstallModules) {
    Write-Host "`nInstalling required PowerShell modules..." -ForegroundColor Yellow
    
    $requiredModules = @{
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
    
    foreach ($module in $requiredModules.GetEnumerator()) {
        Write-Host "Checking $($module.Key)..." -NoNewline
        
        $installed = Get-Module -ListAvailable -Name $module.Key | 
            Where-Object { $_.Version -ge [Version]$module.Value } | 
            Select-Object -First 1
            
        if ($installed) {
            Write-Host " Installed (v$($installed.Version))" -ForegroundColor Green
        }
        else {
            Write-Host " Installing..." -ForegroundColor Yellow
            try {
                Install-Module -Name $module.Key -MinimumVersion $module.Value -Force -AllowClobber -Scope CurrentUser
                Write-Host " Successfully installed!" -ForegroundColor Green
            }
            catch {
                Write-Host " Failed: $_" -ForegroundColor Red
            }
        }
    }
}
#endregion

#region Configuration Creation
if ($CreateConfig -or $GenerateSampleConfig) {
    Write-Host "`nCreating PowerReview configuration..." -ForegroundColor Yellow
    
    $config = @{
        ConfigVersion = "1.0"
        AssessmentName = Read-Host "Enter assessment name"
        GlobalSettings = @{
            AnalysisDepth = "Deep"
            DaysToAnalyze = 90
            SecureStorage = $true
            UseMCP = $false
            GenerateEvidence = $true
            AutoRemediate = $false
            ComplianceMode = $true
        }
        Modules = @(
            "Purview",
            "PowerPlatform",
            "SharePoint",
            "Security",
            "AzureLandingZone",
            "Compliance",
            "DataGovernance"
        )
        Tenants = @()
        ReportingOptions = @{
            ConsolidatedReport = $true
            IndividualTenantReports = $true
            ComplianceReports = $true
            ExecutiveSummary = $true
            TechnicalDetails = $true
            RemediationRoadmap = $true
            OutputFormats = @("HTML", "PDF", "CSV", "JSON")
        }
    }
    
    # Add tenants
    for ($i = 1; $i -le $TenantCount; $i++) {
        Write-Host "`nConfiguring Tenant $i" -ForegroundColor Cyan
        
        $tenant = @{
            Name = Read-Host "  Tenant name"
            Id = Read-Host "  Tenant ID (domain.onmicrosoft.com)"
            AdminUser = Read-Host "  Admin user email"
            Domains = @()
            Modules = "inherit"
            CustomSettings = @{
                Region = Read-Host "  Region (US/EU/APAC/UK)"
                Industry = Read-Host "  Industry"
                UserCount = [int](Read-Host "  Approximate user count")
            }
            ComplianceRequirements = @()
            AzureSubscriptions = @()
        }
        
        # Add domains
        $domainCount = [int](Read-Host "  Number of domains")
        for ($d = 1; $d -le $domainCount; $d++) {
            $tenant.Domains += Read-Host "    Domain $d"
        }
        
        # Add compliance requirements
        Write-Host "  Select compliance requirements (comma-separated):"
        Write-Host "    Options: GDPR, HIPAA, SOC2, ISO27001, PCI-DSS, NIST"
        $compliance = Read-Host "  Requirements"
        $tenant.ComplianceRequirements = $compliance -split "," | ForEach-Object { $_.Trim() }
        
        # Add Azure subscriptions
        $azureCount = [int](Read-Host "  Number of Azure subscriptions")
        for ($a = 1; $a -le $azureCount; $a++) {
            $sub = @{
                Name = Read-Host "    Subscription $a name"
                Id = Read-Host "    Subscription $a ID"
            }
            $tenant.AzureSubscriptions += $sub
        }
        
        $config.Tenants += $tenant
    }
    
    # Save configuration
    $configPath = ".\PowerReview-Config-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding UTF8
    
    Write-Host "`nConfiguration saved to: $configPath" -ForegroundColor Green
}
#endregion

#region Authentication Configuration
if ($ConfigureAuthentication) {
    Write-Host "`nConfiguring authentication..." -ForegroundColor Yellow
    
    Write-Host @"
    
Authentication Options:
1. Interactive (manual login for each tenant)
2. Service Principal with Certificate (recommended for automation)
3. Service Principal with Secret
4. Managed Identity (for Azure Automation)

"@
    
    $authChoice = Read-Host "Select authentication method (1-4)"
    
    switch ($authChoice) {
        "2" {
            Write-Host "`nCertificate-based authentication setup:" -ForegroundColor Cyan
            Write-Host "1. Create a self-signed certificate"
            Write-Host "2. Register an app in Azure AD for each tenant"
            Write-Host "3. Upload the certificate to the app"
            Write-Host "4. Grant necessary permissions"
            Write-Host "5. Grant admin consent"
            
            $createCert = Read-Host "`nCreate certificate now? (Y/N)"
            if ($createCert -eq "Y") {
                $certName = Read-Host "Certificate name"
                $cert = New-SelfSignedCertificate `
                    -Subject "CN=$certName" `
                    -CertStoreLocation "Cert:\CurrentUser\My" `
                    -KeyExportPolicy Exportable `
                    -KeySpec Signature `
                    -KeyLength 2048 `
                    -KeyAlgorithm RSA `
                    -HashAlgorithm SHA256 `
                    -NotAfter (Get-Date).AddYears(2)
                
                $certPath = ".\$certName.cer"
                Export-Certificate -Cert $cert -FilePath $certPath
                
                Write-Host "`nCertificate created!" -ForegroundColor Green
                Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Yellow
                Write-Host "Public key exported to: $certPath" -ForegroundColor Yellow
                
                Write-Host "`nRequired API Permissions for Azure AD App:" -ForegroundColor Cyan
                Write-Host @"
                
Microsoft Graph (Application):
- Directory.Read.All
- User.Read.All
- Group.Read.All
- Policy.Read.All
- SecurityEvents.Read.All
- AuditLog.Read.All
- Reports.Read.All

Office 365 Exchange Online (Application):
- Exchange.ManageAsApp

SharePoint (Application):
- Sites.Read.All
- Sites.FullControl.All

"@
            }
        }
        "3" {
            Write-Host "`nService Principal with Secret setup:" -ForegroundColor Cyan
            Write-Host "This method is less secure than certificates but easier to set up."
            Write-Host "Follow the same app registration process but create a client secret instead."
        }
    }
}
#endregion

#region Validation
if ($ValidateSetup) {
    Write-Host "`nValidating PowerReview setup..." -ForegroundColor Yellow
    
    $validationResults = @{
        Modules = $true
        Scripts = $true
        Configuration = $true
        Permissions = $true
    }
    
    # Check modules
    Write-Host "`nChecking PowerShell modules..." -ForegroundColor Cyan
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "Microsoft.Graph",
        "MicrosoftTeams",
        "Microsoft.Online.SharePoint.PowerShell"
    )
    
    foreach ($module in $requiredModules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "  ✓ $module" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ $module" -ForegroundColor Red
            $validationResults.Modules = $false
        }
    }
    
    # Check scripts
    Write-Host "`nChecking PowerReview scripts..." -ForegroundColor Cyan
    $requiredScripts = @(
        "PowerReview-Enhanced-Framework.ps1",
        "PowerReview-Complete.ps1"
    )
    
    foreach ($script in $requiredScripts) {
        if (Test-Path ".\$script") {
            Write-Host "  ✓ $script" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ $script" -ForegroundColor Red
            $validationResults.Scripts = $false
        }
    }
    
    # Check configuration
    Write-Host "`nChecking configuration files..." -ForegroundColor Cyan
    $configFiles = Get-ChildItem -Path . -Filter "*.json" | Where-Object { $_.Name -like "*config*" }
    
    if ($configFiles) {
        Write-Host "  ✓ Found $($configFiles.Count) configuration file(s)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ No configuration files found" -ForegroundColor Red
        $validationResults.Configuration = $false
    }
    
    # Summary
    Write-Host "`nValidation Summary:" -ForegroundColor Cyan
    foreach ($result in $validationResults.GetEnumerator()) {
        $status = if ($result.Value) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($result.Value) { "Green" } else { "Red" }
        Write-Host "  $($result.Key): $status" -ForegroundColor $color
    }
    
    if ($validationResults.Values -contains $false) {
        Write-Host "`nSetup validation failed. Please run with -InstallModules to fix issues." -ForegroundColor Red
    }
    else {
        Write-Host "`nSetup validation passed! PowerReview is ready to use." -ForegroundColor Green
    }
}
#endregion

#region Test Run
if ($TestRun) {
    Write-Host "`nRunning PowerReview test..." -ForegroundColor Yellow
    
    # Check for config file
    $configFile = Get-ChildItem -Path . -Filter "*.json" | 
        Where-Object { $_.Name -like "*config*" } | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if (!$configFile) {
        Write-Host "No configuration file found. Create one with -CreateConfig" -ForegroundColor Red
        return
    }
    
    Write-Host "Using configuration: $($configFile.Name)" -ForegroundColor Cyan
    
    # Run basic test
    try {
        Write-Host "Testing with Basic analysis depth..." -ForegroundColor Yellow
        
        & .\PowerReview-Enhanced-Framework.ps1 `
            -TenantConfig $configFile.FullName `
            -AnalysisDepth "Basic" `
            -Modules @("Security") `
            -OutputPath ".\Test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        Write-Host "`nTest completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "`nTest failed: $_" -ForegroundColor Red
    }
}
#endregion

#region Usage Examples
if (!$PSBoundParameters.Count) {
    Write-Host @"

Usage Examples:

1. First-time setup (install modules and create config):
   .\Setup-PowerReview.ps1 -InstallModules -CreateConfig -TenantCount 4

2. Configure authentication:
   .\Setup-PowerReview.ps1 -ConfigureAuthentication

3. Validate setup:
   .\Setup-PowerReview.ps1 -ValidateSetup

4. Run a test assessment:
   .\Setup-PowerReview.ps1 -TestRun

5. Generate sample configuration:
   .\Setup-PowerReview.ps1 -GenerateSampleConfig -TenantCount 4

For full assessment, run:
   .\PowerReview-Enhanced-Framework.ps1 -TenantConfig ".\your-config.json"

"@ -ForegroundColor Cyan
}
#endregion