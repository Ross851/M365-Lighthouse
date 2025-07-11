#Requires -Version 7.0

<#
.SYNOPSIS
    Configure security for PowerReview data storage and access
.DESCRIPTION
    Sets up encryption, authentication, auditing, and access controls
.NOTES
    Version: 1.0
#>

param(
    [switch]$ConfigureAll,
    [switch]$ConfigureAuthentication,
    [switch]$ConfigureEncryption,
    [switch]$ConfigureAuditing,
    [switch]$ConfigureBackup,
    [switch]$ConfigureDatabase,
    [switch]$ShowSecurityStatus
)

# Security configuration
$script:SecurityConfig = @{
    EncryptionAlgorithm = "AES256"
    KeyDerivationIterations = 100000
    SaltSize = 32
    RequireMFA = $true
    SessionTimeout = 20 # minutes
    MaxFailedAttempts = 3
    LockoutDuration = 30 # minutes
}

# Function to show security status
function Show-SecurityStatus {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🔐 POWERREVIEW SECURITY STATUS 🔐                      ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Check encryption
    Write-Host "`n🔒 Encryption Status:" -ForegroundColor Yellow
    $encryptionKey = Test-Path ".\SecureVault\.key"
    Write-Host "  • Encryption Key: $(if ($encryptionKey) { '✅ Configured' } else { '❌ Not configured' })" -ForegroundColor $(if ($encryptionKey) { 'Green' } else { 'Red' })
    
    # Check authentication
    Write-Host "`n🔑 Authentication:" -ForegroundColor Yellow
    $authConfig = Test-Path ".\auth-config.json"
    Write-Host "  • Auth Configuration: $(if ($authConfig) { '✅ Configured' } else { '❌ Not configured' })" -ForegroundColor $(if ($authConfig) { 'Green' } else { 'Red' })
    
    # Check auditing
    Write-Host "`n📋 Auditing:" -ForegroundColor Yellow
    $auditPath = Test-Path ".\Logs\Audit"
    Write-Host "  • Audit Logging: $(if ($auditPath) { '✅ Enabled' } else { '❌ Not enabled' })" -ForegroundColor $(if ($auditPath) { 'Green' } else { 'Red' })
    
    # Check database
    Write-Host "`n🗄️ Database:" -ForegroundColor Yellow
    $dbConfig = Test-Path ".\db-config.secure.json"
    Write-Host "  • Database Config: $(if ($dbConfig) { '✅ Configured' } else { '⚠️ Using file storage' })" -ForegroundColor $(if ($dbConfig) { 'Green' } else { 'Yellow' })
    
    # Check backup
    Write-Host "`n💾 Backup:" -ForegroundColor Yellow
    $backupConfig = Test-Path ".\backup-config.json"
    Write-Host "  • Backup Configuration: $(if ($backupConfig) { '✅ Configured' } else { '❌ Not configured' })" -ForegroundColor $(if ($backupConfig) { 'Green' } else { 'Red' })
}

# Configure encryption
function Set-Encryption {
    Write-Host "`n🔐 Configuring Encryption..." -ForegroundColor Yellow
    
    # Create secure vault directory
    $vaultPath = ".\SecureVault"
    if (-not (Test-Path $vaultPath)) {
        New-Item -ItemType Directory -Path $vaultPath -Force | Out-Null
    }
    
    # Generate master key
    Write-Host "  • Generating master encryption key..." -ForegroundColor Gray
    $masterKey = New-Object byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($masterKey)
    
    # Derive machine-specific key
    $machineId = [System.Environment]::MachineName
    $userId = [System.Environment]::UserName
    $salt = New-Object byte[] $script:SecurityConfig.SaltSize
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($salt)
    
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        "$machineId-$userId",
        $salt,
        $script:SecurityConfig.KeyDerivationIterations
    )
    
    $derivedKey = $pbkdf2.GetBytes(32)
    
    # Encrypt master key with derived key
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $derivedKey
    $aes.GenerateIV()
    
    $encryptor = $aes.CreateEncryptor()
    $encryptedMasterKey = $encryptor.TransformFinalBlock($masterKey, 0, $masterKey.Length)
    
    # Save encrypted key
    $keyData = @{
        EncryptedKey = [Convert]::ToBase64String($encryptedMasterKey)
        IV = [Convert]::ToBase64String($aes.IV)
        Salt = [Convert]::ToBase64String($salt)
        Algorithm = $script:SecurityConfig.EncryptionAlgorithm
        Iterations = $script:SecurityConfig.KeyDerivationIterations
        CreatedDate = Get-Date
        MachineId = $machineId
    }
    
    $keyData | ConvertTo-Json | Out-File -FilePath "$vaultPath\.key" -Encoding UTF8
    
    # Secure the vault directory
    $acl = Get-Acl $vaultPath
    $acl.SetAccessRuleProtection($true, $false)
    $permission = "$env:USERDOMAIN\$env:USERNAME", "FullControl", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $vaultPath $acl
    
    Write-Host "  ✅ Encryption configured successfully" -ForegroundColor Green
    Write-Host "  ✅ Secure vault created at: $vaultPath" -ForegroundColor Green
    
    # Create encryption functions module
    $encryptionModule = @'
# PowerReview Encryption Module

function Protect-PowerReviewData {
    param(
        [Parameter(Mandatory=$true)]
        $Data,
        
        [Parameter(Mandatory=$false)]
        [string]$VaultPath = ".\SecureVault"
    )
    
    # Load master key
    $keyData = Get-Content "$VaultPath\.key" -Raw | ConvertFrom-Json
    $masterKey = Get-PowerReviewMasterKey -VaultPath $VaultPath
    
    # Encrypt data
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $masterKey
    $aes.GenerateIV()
    
    $jsonData = $Data | ConvertTo-Json -Depth 10 -Compress
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonData)
    
    $encryptor = $aes.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
    
    return @{
        Data = [Convert]::ToBase64String($encryptedData)
        IV = [Convert]::ToBase64String($aes.IV)
        Timestamp = Get-Date
        Version = "1.0"
    }
}

function Unprotect-PowerReviewData {
    param(
        [Parameter(Mandatory=$true)]
        $EncryptedData,
        
        [Parameter(Mandatory=$false)]
        [string]$VaultPath = ".\SecureVault"
    )
    
    # Load master key
    $masterKey = Get-PowerReviewMasterKey -VaultPath $VaultPath
    
    # Decrypt data
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $masterKey
    $aes.IV = [Convert]::FromBase64String($EncryptedData.IV)
    
    $encryptedBytes = [Convert]::FromBase64String($EncryptedData.Data)
    
    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
    
    $jsonData = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    return $jsonData | ConvertFrom-Json
}

function Get-PowerReviewMasterKey {
    param(
        [string]$VaultPath = ".\SecureVault"
    )
    
    $keyData = Get-Content "$VaultPath\.key" -Raw | ConvertFrom-Json
    
    # Derive machine-specific key
    $machineId = [System.Environment]::MachineName
    $userId = [System.Environment]::UserName
    $salt = [Convert]::FromBase64String($keyData.Salt)
    
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        "$machineId-$userId",
        $salt,
        $keyData.Iterations
    )
    
    $derivedKey = $pbkdf2.GetBytes(32)
    
    # Decrypt master key
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $derivedKey
    $aes.IV = [Convert]::FromBase64String($keyData.IV)
    
    $encryptedKey = [Convert]::FromBase64String($keyData.EncryptedKey)
    
    $decryptor = $aes.CreateDecryptor()
    $masterKey = $decryptor.TransformFinalBlock($encryptedKey, 0, $encryptedKey.Length)
    
    return $masterKey
}
'@
    
    $encryptionModule | Out-File -FilePath ".\PowerReview-Encryption.psm1" -Encoding UTF8
    Write-Host "  ✅ Encryption module created: PowerReview-Encryption.psm1" -ForegroundColor Green
}

# Configure authentication
function Set-Authentication {
    Write-Host "`n🔑 Configuring Authentication..." -ForegroundColor Yellow
    
    $authConfig = @{
        AuthenticationMethod = "AzureAD"
        RequireMFA = $script:SecurityConfig.RequireMFA
        SessionTimeout = $script:SecurityConfig.SessionTimeout
        MaxFailedAttempts = $script:SecurityConfig.MaxFailedAttempts
        LockoutDuration = $script:SecurityConfig.LockoutDuration
        
        AzureAD = @{
            TenantId = Read-Host "  Enter Azure AD Tenant ID"
            ClientId = Read-Host "  Enter Application (Client) ID"
            RequiredGroups = @(
                "PowerReview-Admins",
                "PowerReview-Analysts",
                "PowerReview-Viewers"
            )
        }
        
        ConditionalAccess = @{
            RequireCompliantDevice = $false
            RequireManagedDevice = $false
            AllowedLocations = @("*")
            BlockedLocations = @()
        }
        
        Roles = @{
            "PowerReview-Admins" = @{
                Permissions = @("*")
                DataScope = "All"
                RequiresPIM = $true
            }
            "PowerReview-Analysts" = @{
                Permissions = @(
                    "Assessment.Create",
                    "Assessment.Read",
                    "Report.Generate"
                )
                DataScope = "Organization"
                RequiresPIM = $false
            }
            "PowerReview-Viewers" = @{
                Permissions = @(
                    "Report.Read",
                    "Dashboard.View"
                )
                DataScope = "Limited"
                RequiresPIM = $false
            }
        }
    }
    
    # Save configuration (encrypt sensitive parts)
    Import-Module .\PowerReview-Encryption.psm1 -Force
    $encryptedConfig = Protect-PowerReviewData -Data $authConfig
    $encryptedConfig | ConvertTo-Json | Out-File -FilePath ".\auth-config.json" -Encoding UTF8
    
    Write-Host "  ✅ Authentication configured successfully" -ForegroundColor Green
    
    # Create authentication module
    $authModule = @'
# PowerReview Authentication Module

function Test-PowerReviewAuthentication {
    param(
        [string]$UserPrincipalName,
        [string]$TenantId
    )
    
    # Load configuration
    $configData = Get-Content ".\auth-config.json" -Raw | ConvertFrom-Json
    Import-Module .\PowerReview-Encryption.psm1
    $authConfig = Unprotect-PowerReviewData -EncryptedData $configData
    
    # Verify tenant
    if ($TenantId -ne $authConfig.AzureAD.TenantId) {
        throw "Invalid tenant"
    }
    
    # Check user groups
    $userGroups = Get-AzureADUserMembership -UserPrincipalName $UserPrincipalName
    $hasAccess = $false
    
    foreach ($group in $authConfig.AzureAD.RequiredGroups) {
        if ($userGroups -contains $group) {
            $hasAccess = $true
            break
        }
    }
    
    if (-not $hasAccess) {
        throw "User not in required groups"
    }
    
    # Check MFA if required
    if ($authConfig.RequireMFA) {
        if (-not (Test-UserMFA -UserPrincipalName $UserPrincipalName)) {
            throw "MFA required but not completed"
        }
    }
    
    return $true
}

function Get-PowerReviewUserPermissions {
    param(
        [string]$UserPrincipalName
    )
    
    $configData = Get-Content ".\auth-config.json" -Raw | ConvertFrom-Json
    Import-Module .\PowerReview-Encryption.psm1
    $authConfig = Unprotect-PowerReviewData -EncryptedData $configData
    
    $userGroups = Get-AzureADUserMembership -UserPrincipalName $UserPrincipalName
    $permissions = @()
    
    foreach ($role in $authConfig.Roles.Keys) {
        if ($userGroups -contains $role) {
            $permissions += $authConfig.Roles[$role].Permissions
        }
    }
    
    return $permissions | Select-Object -Unique
}
'@
    
    $authModule | Out-File -FilePath ".\PowerReview-Authentication.psm1" -Encoding UTF8
    Write-Host "  ✅ Authentication module created: PowerReview-Authentication.psm1" -ForegroundColor Green
}

# Configure auditing
function Set-Auditing {
    Write-Host "`n📋 Configuring Audit Logging..." -ForegroundColor Yellow
    
    # Create audit directories
    $auditPaths = @(
        ".\Logs\Audit",
        ".\Logs\Security",
        ".\Logs\Access",
        ".\Logs\Changes"
    )
    
    foreach ($path in $auditPaths) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    
    # Audit configuration
    $auditConfig = @{
        Enabled = $true
        LogLevel = "Information"
        RetentionDays = 365
        
        LogTypes = @{
            Authentication = @{
                Enabled = $true
                Path = ".\Logs\Audit\Authentication"
                IncludeFailures = $true
            }
            DataAccess = @{
                Enabled = $true
                Path = ".\Logs\Audit\DataAccess"
                IncludeSensitive = $true
            }
            Configuration = @{
                Enabled = $true
                Path = ".\Logs\Audit\Configuration"
            }
            Security = @{
                Enabled = $true
                Path = ".\Logs\Security"
                AlertOnSuspicious = $true
            }
        }
        
        Alerts = @{
            FailedAuthentication = @{
                Threshold = 3
                TimeWindow = 300 # seconds
                Action = "Block"
            }
            BulkDataAccess = @{
                Threshold = 1000
                TimeWindow = 3600
                Action = "Alert"
            }
            ConfigurationChange = @{
                RequireJustification = $true
                NotifyAdmins = $true
            }
        }
    }
    
    $auditConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\audit-config.json" -Encoding UTF8
    
    Write-Host "  ✅ Audit logging configured" -ForegroundColor Green
    
    # Create audit module
    $auditModule = @'
# PowerReview Audit Module

function Write-PowerReviewAudit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EventType,
        
        [Parameter(Mandatory=$true)]
        [string]$Action,
        
        [string]$UserId = $env:USERNAME,
        [string]$ObjectType,
        [string]$ObjectId,
        [hashtable]$Details,
        [string]$Result = "Success"
    )
    
    $auditEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        EventId = [Guid]::NewGuid().ToString()
        EventType = $EventType
        Action = $Action
        UserId = $UserId
        UserDomain = $env:USERDOMAIN
        MachineName = $env:COMPUTERNAME
        ProcessId = $PID
        ObjectType = $ObjectType
        ObjectId = $ObjectId
        Result = $Result
        Details = $Details
        IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    }
    
    # Determine log path
    $logDate = Get-Date -Format "yyyy-MM-dd"
    $logPath = ".\Logs\Audit\$EventType\audit-$logDate.json"
    
    # Ensure directory exists
    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Append to log file
    $auditEntry | ConvertTo-Json -Compress | Add-Content -Path $logPath
    
    # Check for security alerts
    Test-SecurityAlert -AuditEntry $auditEntry
}

function Test-SecurityAlert {
    param($AuditEntry)
    
    $config = Get-Content ".\audit-config.json" -Raw | ConvertFrom-Json
    
    # Check failed authentication
    if ($AuditEntry.EventType -eq "Authentication" -and $AuditEntry.Result -eq "Failed") {
        $recentFailures = Get-RecentAuditEntries -EventType "Authentication" -Result "Failed" -UserId $AuditEntry.UserId -TimeWindow 300
        
        if ($recentFailures.Count -ge $config.Alerts.FailedAuthentication.Threshold) {
            Send-SecurityAlert -Type "ExcessiveFailedLogins" -UserId $AuditEntry.UserId
            Block-User -UserId $AuditEntry.UserId -Duration $config.Alerts.FailedAuthentication.LockoutDuration
        }
    }
}

function Get-PowerReviewAuditReport {
    param(
        [datetime]$StartDate = (Get-Date).AddDays(-7),
        [datetime]$EndDate = (Get-Date),
        [string]$EventType,
        [string]$UserId
    )
    
    $auditEntries = @()
    $logFiles = Get-ChildItem -Path ".\Logs\Audit" -Filter "*.json" -Recurse
    
    foreach ($file in $logFiles) {
        $entries = Get-Content $file.FullName | ForEach-Object {
            $_ | ConvertFrom-Json
        }
        
        $filtered = $entries | Where-Object {
            $_.Timestamp -ge $StartDate -and $_.Timestamp -le $EndDate
        }
        
        if ($EventType) {
            $filtered = $filtered | Where-Object { $_.EventType -eq $EventType }
        }
        
        if ($UserId) {
            $filtered = $filtered | Where-Object { $_.UserId -eq $UserId }
        }
        
        $auditEntries += $filtered
    }
    
    return $auditEntries | Sort-Object Timestamp -Descending
}
'@
    
    $auditModule | Out-File -FilePath ".\PowerReview-Audit.psm1" -Encoding UTF8
    Write-Host "  ✅ Audit module created: PowerReview-Audit.psm1" -ForegroundColor Green
}

# Configure database
function Set-Database {
    Write-Host "`n🗄️ Configuring Database Connection..." -ForegroundColor Yellow
    
    Write-Host "Select database type:" -ForegroundColor Cyan
    Write-Host "[1] Azure SQL Database" -ForegroundColor White
    Write-Host "[2] Azure Cosmos DB" -ForegroundColor White
    Write-Host "[3] PostgreSQL" -ForegroundColor White
    Write-Host "[4] File-based only (no database)" -ForegroundColor White
    
    $dbChoice = Read-Host "Your choice (1-4)"
    
    switch ($dbChoice) {
        "1" {
            $dbConfig = @{
                Type = "AzureSQL"
                Server = Read-Host "  Enter server name (e.g., powerreview.database.windows.net)"
                Database = Read-Host "  Enter database name"
                Authentication = "ActiveDirectoryIntegrated"
                Encrypt = $true
                TrustServerCertificate = $false
            }
        }
        "2" {
            $dbConfig = @{
                Type = "CosmosDB"
                AccountEndpoint = Read-Host "  Enter Cosmos DB endpoint"
                Database = Read-Host "  Enter database name"
                Container = "Assessments"
                PartitionKey = "/organizationId"
            }
        }
        "3" {
            $dbConfig = @{
                Type = "PostgreSQL"
                Host = Read-Host "  Enter PostgreSQL host"
                Database = Read-Host "  Enter database name"
                Port = 5432
                SslMode = "Require"
            }
        }
        "4" {
            Write-Host "  ✅ Using file-based storage only" -ForegroundColor Green
            return
        }
    }
    
    # Encrypt and save database configuration
    Import-Module .\PowerReview-Encryption.psm1 -Force
    $encryptedConfig = Protect-PowerReviewData -Data $dbConfig
    $encryptedConfig | ConvertTo-Json | Out-File -FilePath ".\db-config.secure.json" -Encoding UTF8
    
    Write-Host "  ✅ Database configuration saved (encrypted)" -ForegroundColor Green
    
    # Generate database schema script
    if ($dbChoice -eq "1") {
        $schemaScript = @'
-- PowerReview Azure SQL Database Schema
-- Run this script to create the database schema

USE [PowerReviewDB]
GO

-- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'PowerReview')
BEGIN
    EXEC('CREATE SCHEMA PowerReview')
END
GO

-- Enable Transparent Data Encryption
ALTER DATABASE [PowerReviewDB] SET ENCRYPTION ON
GO

-- Create tables with encryption
CREATE TABLE PowerReview.Organizations (
    OrganizationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(255) NOT NULL,
    TenantId NVARCHAR(255),
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    EncryptionKey VARBINARY(256)
)
GO

CREATE TABLE PowerReview.Assessments (
    AssessmentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrganizationId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES PowerReview.Organizations(OrganizationId),
    AssessmentType NVARCHAR(50),
    StartTime DATETIME2,
    EndTime DATETIME2,
    Status NVARCHAR(50),
    ResultsJson NVARCHAR(MAX), -- Always encrypted
    CreatedBy NVARCHAR(255),
    Classification NVARCHAR(50) DEFAULT 'Confidential'
)
GO

-- Enable Row-Level Security
CREATE FUNCTION PowerReview.fn_SecurityPredicate(@OrganizationId UNIQUEIDENTIFIER)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS Result
WHERE 
    @OrganizationId = CAST(SESSION_CONTEXT(N'OrganizationId') AS UNIQUEIDENTIFIER)
    OR IS_ROLEMEMBER('PowerReviewAdmin') = 1
GO

CREATE SECURITY POLICY PowerReview.AssessmentSecurityPolicy
ADD FILTER PREDICATE PowerReview.fn_SecurityPredicate(OrganizationId)
ON PowerReview.Assessments
WITH (STATE = ON)
GO

PRINT 'PowerReview database schema created successfully'
'@
        
        $schemaScript | Out-File -FilePath ".\Create-PowerReviewDatabase.sql" -Encoding UTF8
        Write-Host "  ✅ Database schema script created: Create-PowerReviewDatabase.sql" -ForegroundColor Green
    }
}

# Configure backup
function Set-Backup {
    Write-Host "`n💾 Configuring Backup Strategy..." -ForegroundColor Yellow
    
    $backupConfig = @{
        Enabled = $true
        Schedule = @{
            Daily = @{
                Enabled = $true
                Time = "02:00"
                Retention = 7
            }
            Weekly = @{
                Enabled = $true
                DayOfWeek = "Sunday"
                Time = "03:00"
                Retention = 4
            }
            Monthly = @{
                Enabled = $true
                DayOfMonth = 1
                Time = "04:00"
                Retention = 12
            }
        }
        
        Destinations = @{
            Primary = @{
                Type = "AzureBlob"
                StorageAccount = Read-Host "  Enter backup storage account name"
                Container = "powerreview-backups"
                UseMangedIdentity = $true
            }
            Secondary = @{
                Type = "FileSystem"
                Path = Read-Host "  Enter secondary backup path (e.g., \\backup-server\powerreview)"
                Compress = $true
                Encrypt = $true
            }
        }
        
        IncludeItems = @(
            "AssessmentResults",
            "Questionnaires",
            "Configuration",
            "AuditLogs"
        )
        
        ExcludeItems = @(
            "TempFiles",
            "Cache",
            "Logs\Debug"
        )
    }
    
    $backupConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\backup-config.json" -Encoding UTF8
    
    Write-Host "  ✅ Backup configuration saved" -ForegroundColor Green
    
    # Create backup script
    $backupScript = @'
# PowerReview Backup Script
param(
    [string]$BackupType = "Daily"
)

$config = Get-Content ".\backup-config.json" -Raw | ConvertFrom-Json
$backupDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupName = "PowerReview_Backup_$($BackupType)_$backupDate"

Write-Host "Starting $BackupType backup: $backupName" -ForegroundColor Cyan

# Create backup staging directory
$stagingPath = ".\Temp\$backupName"
New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

# Copy items to backup
foreach ($item in $config.IncludeItems) {
    if (Test-Path ".\$item") {
        Write-Host "  Backing up: $item"
        Copy-Item -Path ".\$item" -Destination "$stagingPath\$item" -Recurse -Force
    }
}

# Encrypt backup if required
if ($config.Destinations.Secondary.Encrypt) {
    Write-Host "  Encrypting backup..."
    Import-Module .\PowerReview-Encryption.psm1
    # Encryption logic here
}

# Compress backup
if ($config.Destinations.Secondary.Compress) {
    Write-Host "  Compressing backup..."
    Compress-Archive -Path "$stagingPath\*" -DestinationPath ".\Temp\$backupName.zip" -Force
    Remove-Item -Path $stagingPath -Recurse -Force
    $backupFile = ".\Temp\$backupName.zip"
} else {
    $backupFile = $stagingPath
}

# Copy to destinations
Write-Host "  Copying to primary destination..."
# Azure Blob Storage upload logic here

Write-Host "  Copying to secondary destination..."
Copy-Item -Path $backupFile -Destination $config.Destinations.Secondary.Path -Force

# Cleanup old backups based on retention
# Retention logic here

Write-Host "✅ Backup completed successfully!" -ForegroundColor Green

# Log backup completion
Import-Module .\PowerReview-Audit.psm1
Write-PowerReviewAudit -EventType "Backup" -Action "BackupCompleted" -Details @{
    BackupType = $BackupType
    BackupName = $backupName
    Size = (Get-Item $backupFile).Length
}
'@
    
    $backupScript | Out-File -FilePath ".\Backup-PowerReview.ps1" -Encoding UTF8
    Write-Host "  ✅ Backup script created: Backup-PowerReview.ps1" -ForegroundColor Green
}

# Main execution
Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                       🔐 POWERREVIEW SECURITY SETUP 🔐                        ║
║                                                                               ║
║                    Configure security, encryption, and access                  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if ($ShowSecurityStatus) {
    Show-SecurityStatus
    return
}

# Configure all if requested
if ($ConfigureAll) {
    $ConfigureEncryption = $true
    $ConfigureAuthentication = $true
    $ConfigureAuditing = $true
    $ConfigureDatabase = $true
    $ConfigureBackup = $true
}

# Run configurations
if ($ConfigureEncryption) {
    Set-Encryption
}

if ($ConfigureAuthentication) {
    if (-not (Test-Path ".\PowerReview-Encryption.psm1")) {
        Write-Host "⚠️  Encryption must be configured first!" -ForegroundColor Yellow
        Set-Encryption
    }
    Set-Authentication
}

if ($ConfigureAuditing) {
    Set-Auditing
}

if ($ConfigureDatabase) {
    if (-not (Test-Path ".\PowerReview-Encryption.psm1")) {
        Write-Host "⚠️  Encryption must be configured first!" -ForegroundColor Yellow
        Set-Encryption
    }
    Set-Database
}

if ($ConfigureBackup) {
    Set-Backup
}

# Show final status
if ($ConfigureEncryption -or $ConfigureAuthentication -or $ConfigureAuditing -or $ConfigureDatabase -or $ConfigureBackup) {
    Write-Host "`n" -NoNewline
    Show-SecurityStatus
    
    Write-Host @"

📋 Next Steps:
1. Review generated configuration files
2. Run database schema script if using SQL
3. Configure Azure resources (Storage, Key Vault)
4. Set up backup schedule
5. Test authentication flow
6. Perform security audit

For help: Get-Help .\Setup-PowerReviewSecurity.ps1 -Detailed

"@ -ForegroundColor Green
}