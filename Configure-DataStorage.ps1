#Requires -Version 7.0

<#
.SYNOPSIS
    Configure data storage locations for PowerReview
.DESCRIPTION
    Sets up and manages data storage paths for all PowerReview outputs
.NOTES
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$BasePath,
    
    [switch]$UseDefaults,
    [switch]$UseNetworkShare,
    [switch]$UseSharePoint,
    [switch]$UseAzureStorage,
    [switch]$ShowCurrent
)

# Global configuration object
$script:StorageConfig = @{
    ConfigPath = ".\storage-config.json"
    CurrentConfig = $null
}

# Function to load current configuration
function Get-StorageConfiguration {
    if (Test-Path $script:StorageConfig.ConfigPath) {
        $script:StorageConfig.CurrentConfig = Get-Content $script:StorageConfig.ConfigPath -Raw | ConvertFrom-Json
        return $script:StorageConfig.CurrentConfig
    }
    return $null
}

# Function to save configuration
function Save-StorageConfiguration {
    param($Config)
    
    $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:StorageConfig.ConfigPath -Encoding UTF8
    Write-Host "✅ Configuration saved to: $($script:StorageConfig.ConfigPath)" -ForegroundColor Green
}

# Show current configuration
function Show-CurrentConfiguration {
    $config = Get-StorageConfiguration
    
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                       📁 CURRENT STORAGE CONFIGURATION 📁                      ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    if ($config) {
        Write-Host "`nBase Output Path: $($config.StorageConfiguration.BaseOutputPath)" -ForegroundColor Yellow
        Write-Host "`nStorage Locations:" -ForegroundColor Cyan
        Write-Host "  • Questionnaires: $($config.StorageConfiguration.QuestionnaireResults.Path)" -ForegroundColor White
        Write-Host "  • Assessments: $($config.StorageConfiguration.AssessmentResults.Path)" -ForegroundColor White
        Write-Host "  • Secure Storage: $($config.StorageConfiguration.SecureStorage.Path)" -ForegroundColor White
        Write-Host "  • Client Portals: $($config.StorageConfiguration.ClientPortals.Path)" -ForegroundColor White
        Write-Host "  • Archive: $($config.StorageConfiguration.ArchivePath)" -ForegroundColor White
        
        Write-Host "`nRetention Policies:" -ForegroundColor Cyan
        Write-Host "  • Questionnaires: $($config.StorageConfiguration.QuestionnaireResults.RetentionDays) days" -ForegroundColor White
        Write-Host "  • Assessments: $($config.StorageConfiguration.AssessmentResults.RetentionDays) days" -ForegroundColor White
        Write-Host "  • Client Portals: $($config.StorageConfiguration.ClientPortals.RetentionDays) days" -ForegroundColor White
    }
    else {
        Write-Host "`n⚠️  No configuration found. Using default locations." -ForegroundColor Yellow
        Write-Host @"

Default Locations:
  • Questionnaires: .\Discovery-Results\
  • Assessments: .\PowerReview-Output\
  • EC Results: .\EC-Discovery-Results\
  • Secure Storage: .\SecureVault\
"@ -ForegroundColor Gray
    }
}

# Configure default local storage
function Set-DefaultStorage {
    param(
        [string]$BasePath = "C:\PowerReview-Data"
    )
    
    Write-Host "`n📁 Configuring default local storage..." -ForegroundColor Yellow
    
    $config = @{
        StorageConfiguration = @{
            BaseOutputPath = $BasePath
            QuestionnaireResults = @{
                Path = Join-Path $BasePath "Questionnaires"
                RetentionDays = 90
            }
            AssessmentResults = @{
                Path = Join-Path $BasePath "Assessments"
                RetentionDays = 365
            }
            SecureStorage = @{
                Path = Join-Path $BasePath "Secure"
                EncryptionRequired = $true
            }
            ClientPortals = @{
                Path = Join-Path $BasePath "Portals"
                RetentionDays = 30
            }
            ArchivePath = Join-Path $BasePath "Archive"
            Logs = @{
                Path = Join-Path $BasePath "Logs"
                RetentionDays = 180
            }
        }
    }
    
    # Create directories
    foreach ($pathProperty in $config.StorageConfiguration.PSObject.Properties) {
        if ($pathProperty.Value -is [string]) {
            $path = $pathProperty.Value
        }
        elseif ($pathProperty.Value.Path) {
            $path = $pathProperty.Value.Path
        }
        else {
            continue
        }
        
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "  ✓ Created: $path" -ForegroundColor Green
        }
        else {
            Write-Host "  • Exists: $path" -ForegroundColor Gray
        }
    }
    
    # Set security on Secure folder
    $securePath = $config.StorageConfiguration.SecureStorage.Path
    Write-Host "`n🔐 Securing sensitive data folder..." -ForegroundColor Yellow
    $acl = Get-Acl $securePath
    $acl.SetAccessRuleProtection($true, $false)
    $permission = "$env:USERDOMAIN\$env:USERNAME", "FullControl", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $securePath $acl
    Write-Host "  ✓ Secured: $securePath" -ForegroundColor Green
    
    Save-StorageConfiguration -Config $config
    return $config
}

# Configure network share storage
function Set-NetworkShareStorage {
    Write-Host "`n🌐 Configuring network share storage..." -ForegroundColor Yellow
    
    $shareBase = Read-Host "Enter network share base path (e.g., \\FileServer\PowerReview)"
    
    # Test connection
    Write-Host "Testing network path..." -ForegroundColor Gray
    if (-not (Test-Path $shareBase)) {
        Write-Host "⚠️  Cannot access $shareBase. Creating configuration anyway." -ForegroundColor Yellow
    }
    
    $config = @{
        StorageConfiguration = @{
            BaseOutputPath = $shareBase
            QuestionnaireResults = @{
                Path = Join-Path $shareBase "Questionnaires"
                RetentionDays = 90
            }
            AssessmentResults = @{
                Path = Join-Path $shareBase "Assessments"
                RetentionDays = 365
            }
            SecureStorage = @{
                Path = Join-Path $shareBase "Secure"
                EncryptionRequired = $true
                AccessControl = @{
                    AllowedGroups = @("Domain\PowerReview-Admins", "Domain\PowerReview-Users")
                }
            }
            ClientPortals = @{
                Path = Join-Path $shareBase "Portals"
                RetentionDays = 30
                WebAccessUrl = "https://portal.contoso.com/powerreview"
            }
            ArchivePath = Join-Path $shareBase "Archive"
            Logs = @{
                Path = Join-Path $shareBase "Logs"
                RetentionDays = 180
            }
        }
    }
    
    Save-StorageConfiguration -Config $config
    return $config
}

# Configure SharePoint storage
function Set-SharePointStorage {
    Write-Host "`n📊 Configuring SharePoint storage..." -ForegroundColor Yellow
    
    $siteUrl = Read-Host "Enter SharePoint site URL (e.g., https://contoso.sharepoint.com/sites/PowerReview)"
    $docLib = Read-Host "Enter document library name (default: Documents)"
    
    if ([string]::IsNullOrWhiteSpace($docLib)) {
        $docLib = "Documents"
    }
    
    $config = @{
        StorageConfiguration = @{
            StorageType = "SharePoint"
            BaseOutputPath = $siteUrl
            DocumentLibrary = $docLib
            QuestionnaireResults = @{
                Folder = "Questionnaires"
                RetentionDays = 90
                ContentType = "PowerReview Questionnaire"
            }
            AssessmentResults = @{
                Folder = "Assessments"
                RetentionDays = 365
                ContentType = "PowerReview Assessment"
            }
            SecureStorage = @{
                Folder = "Secure"
                EncryptionRequired = $true
                Permissions = "Restricted"
            }
            ClientPortals = @{
                Folder = "Portals"
                RetentionDays = 30
                EnableVersioning = $true
            }
            ArchiveFolder = "Archive"
            SharePointSettings = @{
                UseManagedMetadata = $true
                EnableSearch = $true
                RequireCheckOut = $false
            }
        }
    }
    
    Save-StorageConfiguration -Config $config
    
    Write-Host @"

📝 SharePoint Setup Required:
1. Create document library: $docLib
2. Create folders: Questionnaires, Assessments, Secure, Portals, Archive
3. Set permissions on Secure folder
4. Enable versioning
5. Configure retention policies

"@ -ForegroundColor Yellow
    
    return $config
}

# Configure Azure Storage
function Set-AzureStorage {
    Write-Host "`n☁️ Configuring Azure Storage..." -ForegroundColor Yellow
    
    $storageAccount = Read-Host "Enter storage account name"
    $container = Read-Host "Enter container name (default: powerreview)"
    
    if ([string]::IsNullOrWhiteSpace($container)) {
        $container = "powerreview"
    }
    
    $config = @{
        StorageConfiguration = @{
            StorageType = "AzureBlob"
            StorageAccount = $storageAccount
            Container = $container
            BaseOutputPath = "https://$storageAccount.blob.core.windows.net/$container"
            QuestionnaireResults = @{
                Path = "questionnaires"
                RetentionDays = 90
                AccessTier = "Hot"
            }
            AssessmentResults = @{
                Path = "assessments"
                RetentionDays = 365
                AccessTier = "Hot"
            }
            SecureStorage = @{
                Path = "secure"
                EncryptionRequired = $true
                UseManagedIdentity = $true
                KeyVaultName = "PowerReviewKV"
            }
            ClientPortals = @{
                Path = "portals"
                RetentionDays = 30
                EnableCDN = $true
                CustomDomain = "portals.powerreview.com"
            }
            ArchivePath = "archive"
            ArchiveSettings = @{
                AccessTier = "Cool"
                MoveToArchiveAfterDays = 90
            }
            AzureSettings = @{
                UsePrivateEndpoint = $true
                EnableSoftDelete = $true
                RetentionDays = 7
                ReplicationMode = "GRS"
            }
        }
    }
    
    Save-StorageConfiguration -Config $config
    
    Write-Host @"

☁️ Azure Setup Required:
1. Create storage account: $storageAccount
2. Create container: $container
3. Configure access policies
4. Set up lifecycle management rules
5. Enable blob versioning and soft delete

PowerShell Setup:
Install-Module -Name Az.Storage
Connect-AzAccount
New-AzStorageContainer -Name "$container" -Context `$ctx

"@ -ForegroundColor Yellow
    
    return $config
}

# Environment variable setup
function Set-EnvironmentVariables {
    param($Config)
    
    Write-Host "`n🔧 Setting environment variables..." -ForegroundColor Yellow
    
    [Environment]::SetEnvironmentVariable("POWERREVIEW_DATA", $Config.StorageConfiguration.BaseOutputPath, "User")
    [Environment]::SetEnvironmentVariable("POWERREVIEW_SECURE", $Config.StorageConfiguration.SecureStorage.Path, "User")
    
    Write-Host "✅ Environment variables set:" -ForegroundColor Green
    Write-Host "  • POWERREVIEW_DATA = $($Config.StorageConfiguration.BaseOutputPath)" -ForegroundColor White
    Write-Host "  • POWERREVIEW_SECURE = $($Config.StorageConfiguration.SecureStorage.Path)" -ForegroundColor White
}

# Create data management scripts
function New-DataManagementScripts {
    param($Config)
    
    Write-Host "`n📝 Creating data management scripts..." -ForegroundColor Yellow
    
    # Cleanup script
    $cleanupScript = @"
# PowerReview Data Cleanup Script
# Run monthly to apply retention policies

`$config = Get-Content ".\storage-config.json" -Raw | ConvertFrom-Json
`$baseDate = Get-Date

# Clean questionnaires
`$questPath = `$config.StorageConfiguration.QuestionnaireResults.Path
`$questRetention = `$config.StorageConfiguration.QuestionnaireResults.RetentionDays

Get-ChildItem -Path `$questPath -File | Where-Object {
    `$_.LastWriteTime -lt `$baseDate.AddDays(-`$questRetention)
} | ForEach-Object {
    Write-Host "Archiving: `$(`$_.Name)"
    Move-Item -Path `$_.FullName -Destination "`$(`$config.StorageConfiguration.ArchivePath)\`$(`$_.Name)"
}

Write-Host "✅ Cleanup complete"
"@
    
    $cleanupScript | Out-File -FilePath ".\Cleanup-PowerReviewData.ps1" -Encoding UTF8
    
    # Backup script
    $backupScript = @"
# PowerReview Backup Script
# Run daily/weekly as needed

`$config = Get-Content ".\storage-config.json" -Raw | ConvertFrom-Json
`$backupDate = Get-Date -Format "yyyy-MM-dd"
`$backupBase = "D:\Backups\PowerReview\`$backupDate"

# Create backup directory
New-Item -ItemType Directory -Path `$backupBase -Force

# Backup each component
@(
    `$config.StorageConfiguration.QuestionnaireResults.Path,
    `$config.StorageConfiguration.AssessmentResults.Path,
    `$config.StorageConfiguration.SecureStorage.Path
) | ForEach-Object {
    `$source = `$_
    `$destName = Split-Path `$source -Leaf
    `$destination = Join-Path `$backupBase `$destName
    
    Write-Host "Backing up: `$source"
    Copy-Item -Path `$source -Destination `$destination -Recurse -Force
}

Write-Host "✅ Backup complete: `$backupBase"
"@
    
    $backupScript | Out-File -FilePath ".\Backup-PowerReviewData.ps1" -Encoding UTF8
    
    Write-Host "✅ Created management scripts:" -ForegroundColor Green
    Write-Host "  • Cleanup-PowerReviewData.ps1" -ForegroundColor White
    Write-Host "  • Backup-PowerReviewData.ps1" -ForegroundColor White
}

# Main execution
Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                      💾 POWERREVIEW DATA STORAGE SETUP 💾                     ║
║                                                                               ║
║                    Configure where assessment data is stored                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if ($ShowCurrent) {
    Show-CurrentConfiguration
    return
}

if (-not $BasePath -and -not $UseDefaults -and -not $UseNetworkShare -and -not $UseSharePoint -and -not $UseAzureStorage) {
    Write-Host "`nSelect storage type:" -ForegroundColor Yellow
    Write-Host "[1] Local Storage (Default)" -ForegroundColor Cyan
    Write-Host "[2] Network Share" -ForegroundColor Cyan
    Write-Host "[3] SharePoint Document Library" -ForegroundColor Cyan
    Write-Host "[4] Azure Blob Storage" -ForegroundColor Cyan
    Write-Host "[5] Show Current Configuration" -ForegroundColor Gray
    
    $choice = Read-Host "`nYour choice (1-5)"
    
    switch ($choice) {
        "1" { $UseDefaults = $true }
        "2" { $UseNetworkShare = $true }
        "3" { $UseSharePoint = $true }
        "4" { $UseAzureStorage = $true }
        "5" { Show-CurrentConfiguration; return }
    }
}

# Configure based on selection
$newConfig = $null

if ($UseDefaults -or $BasePath) {
    $newConfig = Set-DefaultStorage -BasePath $(if ($BasePath) { $BasePath } else { "C:\PowerReview-Data" })
}
elseif ($UseNetworkShare) {
    $newConfig = Set-NetworkShareStorage
}
elseif ($UseSharePoint) {
    $newConfig = Set-SharePointStorage
}
elseif ($UseAzureStorage) {
    $newConfig = Set-AzureStorage
}

if ($newConfig) {
    # Set environment variables
    Set-EnvironmentVariables -Config $newConfig
    
    # Create management scripts
    New-DataManagementScripts -Config $newConfig
    
    # Show summary
    Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                         ✅ STORAGE SETUP COMPLETE! ✅                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Your PowerReview data storage has been configured.

Configuration saved to: .\storage-config.json

Next steps:
1. Review the configuration
2. Test write access to all paths
3. Set up backup schedule
4. Configure retention policies

To view current configuration:
  .\Configure-DataStorage.ps1 -ShowCurrent

"@ -ForegroundColor Green
}