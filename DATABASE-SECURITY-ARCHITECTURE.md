# 🔐 PowerReview Database & Security Architecture

## Overview
PowerReview uses a hybrid storage approach with multiple layers of security. This document explains our database strategy, security measures, and access control.

## 🗄️ Database Architecture

### Current Storage Model (File-Based + Optional Database)

```
┌─────────────────────────────────────────────────────────────┐
│                    PowerReview Data Flow                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Assessment Engine] → [Encrypted Files] → [Optional DB]    │
│         ↓                    ↓                    ↓         │
│   JSON Results        Local Storage         SQL/Cosmos      │
│                    + Azure Blob Storage                     │
└─────────────────────────────────────────────────────────────┘
```

### 1. **Primary Storage: Encrypted JSON Files**
- **Format**: JSON files with AES-256 encryption
- **Location**: Configurable (local/network/cloud)
- **Why**: Portability, no database dependencies, easy backup

### 2. **Optional Database Integration**
PowerReview can integrate with these databases:

#### **Option A: Azure SQL Database** (Recommended for Enterprise)
```sql
-- PowerReview Database Schema
CREATE SCHEMA PowerReview;

-- Organizations Table
CREATE TABLE PowerReview.Organizations (
    OrganizationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(255) NOT NULL,
    TenantId NVARCHAR(255),
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    EncryptionKey VARBINARY(256)
);

-- Assessments Table
CREATE TABLE PowerReview.Assessments (
    AssessmentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrganizationId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES PowerReview.Organizations(OrganizationId),
    AssessmentType NVARCHAR(50),
    StartTime DATETIME2,
    EndTime DATETIME2,
    Status NVARCHAR(50),
    ResultsJson NVARCHAR(MAX), -- Encrypted JSON
    CreatedBy NVARCHAR(255),
    Classification NVARCHAR(50) DEFAULT 'Confidential'
);

-- Findings Table
CREATE TABLE PowerReview.Findings (
    FindingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    AssessmentId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES PowerReview.Assessments(AssessmentId),
    Module NVARCHAR(100),
    Severity NVARCHAR(20),
    Title NVARCHAR(500),
    Description NVARCHAR(MAX),
    Evidence NVARCHAR(MAX), -- Encrypted
    Recommendation NVARCHAR(MAX),
    ComplianceMapping NVARCHAR(MAX)
);

-- Audit Log Table
CREATE TABLE PowerReview.AuditLog (
    LogId BIGINT IDENTITY(1,1) PRIMARY KEY,
    Timestamp DATETIME2 DEFAULT GETUTCDATE(),
    UserId NVARCHAR(255),
    Action NVARCHAR(100),
    ObjectType NVARCHAR(100),
    ObjectId NVARCHAR(255),
    Details NVARCHAR(MAX),
    IPAddress NVARCHAR(50),
    UserAgent NVARCHAR(500)
);

-- Row Level Security
CREATE FUNCTION PowerReview.SecurityPredicate(@OrganizationId UNIQUEIDENTIFIER)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS Result
WHERE 
    -- User can only see their organization's data
    @OrganizationId = CAST(SESSION_CONTEXT(N'OrganizationId') AS UNIQUEIDENTIFIER)
    OR IS_ROLEMEMBER('PowerReviewAdmin') = 1;

-- Apply RLS
CREATE SECURITY POLICY PowerReview.AssessmentSecurityPolicy
ADD FILTER PREDICATE PowerReview.SecurityPredicate(OrganizationId)
ON PowerReview.Assessments
WITH (STATE = ON);
```

#### **Option B: Azure Cosmos DB** (For Global Scale)
```json
// Container: Assessments
{
    "id": "assessment-guid",
    "partitionKey": "org-tenant-id",
    "type": "Assessment",
    "organization": {
        "id": "org-id",
        "name": "Contoso Ltd",
        "tenantId": "tenant-guid"
    },
    "metadata": {
        "startTime": "2024-01-15T10:00:00Z",
        "endTime": "2024-01-15T12:00:00Z",
        "modules": ["Purview", "SharePoint", "Security"],
        "classification": "Confidential"
    },
    "results": {
        "encrypted": true,
        "data": "BASE64_ENCRYPTED_CONTENT"
    },
    "findings": [],
    "_etag": "\"0x8DC1234567890\"",
    "_ts": 1705315200
}
```

#### **Option C: PostgreSQL** (Open Source)
```sql
-- PowerReview PostgreSQL Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE organizations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    encryption_key BYTEA
);

CREATE TABLE assessments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id),
    assessment_type VARCHAR(50),
    results_encrypted JSONB,
    created_by VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_isolation ON assessments
    FOR ALL
    USING (organization_id = current_setting('app.current_org_id')::UUID);
```

## 🔐 Security Layers

### 1. **Encryption at Rest**

```powershell
# Machine-specific encryption key generation
function New-PowerReviewEncryptionKey {
    $machineKey = [System.Text.Encoding]::UTF8.GetBytes($env:COMPUTERNAME)
    $userKey = [System.Text.Encoding]::UTF8.GetBytes($env:USERNAME)
    $salt = [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32)
    
    $pbkdf2 = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        $machineKey + $userKey, 
        $salt, 
        10000
    )
    
    return @{
        Key = $pbkdf2.GetBytes(32)
        IV = $pbkdf2.GetBytes(16)
        Salt = $salt
    }
}

# Encrypt sensitive data
function Protect-PowerReviewData {
    param($Data, $Key)
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key.Key
    $aes.IV = $Key.IV
    
    $encryptor = $aes.CreateEncryptor()
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data | ConvertTo-Json -Compress)
    $encrypted = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
    
    return [Convert]::ToBase64String($encrypted)
}
```

### 2. **Encryption in Transit**
- All API calls use TLS 1.2+
- Certificate pinning for critical operations
- Encrypted tunnels for database connections

### 3. **Access Control Matrix**

| Role | Permissions | Database Access | File Access | Portal Access |
|------|------------|-----------------|-------------|---------------|
| **PowerReview Admin** | Full access | Read/Write all orgs | All files | All portals |
| **Organization Admin** | Org-specific full | Read/Write own org | Own org files | Own portals |
| **Security Analyst** | Read + create assessments | Read own org | Assessment files | Read portals |
| **Compliance Officer** | Read + reports | Read compliance data | Compliance reports | Compliance portals |
| **Executive Viewer** | Read summaries only | No direct access | Executive reports | Executive portal |
| **External Auditor** | Time-limited read | Read-only subset | Audit exports | Audit portal |

### 4. **Authentication & Authorization**

```powershell
# Multi-factor authentication enforcement
function Test-PowerReviewAccess {
    param(
        [string]$UserId,
        [string]$Resource,
        [string]$Action
    )
    
    # Check authentication
    if (-not (Test-UserAuthenticated $UserId)) {
        throw "User not authenticated"
    }
    
    # Check MFA
    if (-not (Test-UserMFACompleted $UserId)) {
        throw "MFA required for this action"
    }
    
    # Check authorization
    $userRole = Get-UserRole $UserId
    $permission = Get-RolePermission $userRole $Resource $Action
    
    if (-not $permission) {
        throw "Access denied: $Action on $Resource"
    }
    
    # Log access
    Write-AuditLog -UserId $UserId -Action $Action -Resource $Resource
    
    return $true
}
```

## 🔑 Access Management

### 1. **Azure AD Integration**
```powershell
# Configure Azure AD authentication
$config = @{
    TenantId = "your-tenant-id"
    ClientId = "powerreview-app-id"
    RequiredGroups = @(
        "PowerReview-Admins",
        "PowerReview-Analysts",
        "PowerReview-Viewers"
    )
    ConditionalAccess = @{
        RequireMFA = $true
        RequireCompliantDevice = $true
        AllowedLocations = @("Corporate Network", "VPN")
    }
}
```

### 2. **Role-Based Access Control (RBAC)**
```json
{
    "Roles": {
        "PowerReviewAdmin": {
            "Permissions": ["*"],
            "DataScope": "All",
            "RequiresMFA": true,
            "RequiresPIM": true
        },
        "SecurityAnalyst": {
            "Permissions": [
                "Assessment.Create",
                "Assessment.Read",
                "Report.Generate",
                "Finding.Create"
            ],
            "DataScope": "Organization",
            "RequiresMFA": true
        },
        "ComplianceOfficer": {
            "Permissions": [
                "Assessment.Read",
                "Compliance.Read",
                "Report.Export"
            ],
            "DataScope": "Compliance",
            "RequiresMFA": true
        }
    }
}
```

### 3. **Database Connection Security**
```powershell
# Secure database connection
function Connect-PowerReviewDatabase {
    param(
        [string]$DatabaseType = "AzureSQL"
    )
    
    switch ($DatabaseType) {
        "AzureSQL" {
            $connection = @{
                Server = "powerreview.database.windows.net"
                Database = "PowerReviewDB"
                Authentication = "ActiveDirectoryIntegrated"
                Encrypt = $true
                TrustServerCertificate = $false
                ConnectionTimeout = 30
                ApplicationName = "PowerReview"
            }
        }
        "CosmosDB" {
            $connection = @{
                AccountEndpoint = "https://powerreview.documents.azure.com:443/"
                AuthKeyOrResourceToken = Get-SecretFromKeyVault -Name "CosmosKey"
                Database = "PowerReview"
                PreferredRegions = @("East US", "West Europe")
            }
        }
        "PostgreSQL" {
            $connection = @{
                Host = "powerreview-pg.postgres.database.azure.com"
                Database = "powerreview"
                Username = "powerreview@powerreview-pg"
                SslMode = "Require"
                TrustServerCertificate = $false
            }
        }
    }
    
    return $connection
}
```

## 🛡️ Data Protection Features

### 1. **Audit Trail**
Every action is logged with:
- Who (User ID, Role, IP)
- What (Action, Object, Changes)
- When (Timestamp, Duration)
- Where (Location, Device)
- Why (Justification for sensitive actions)

### 2. **Data Loss Prevention**
```powershell
# Prevent unauthorized data export
function Export-AssessmentData {
    param($AssessmentId, $Format, $UserId)
    
    # Check export permissions
    if (-not (Test-ExportPermission $UserId)) {
        throw "Export permission denied"
    }
    
    # Add watermark
    $exportData = Get-AssessmentData $AssessmentId
    $exportData.Metadata.ExportedBy = $UserId
    $exportData.Metadata.ExportTime = Get-Date
    $exportData.Metadata.Watermark = New-Guid
    
    # Log export
    Write-ExportAuditLog -AssessmentId $AssessmentId -UserId $UserId -Format $Format
    
    # Apply DLP policy
    if (Test-DLPViolation $exportData) {
        Send-SecurityAlert -Type "DLP" -UserId $UserId
        throw "Export blocked by DLP policy"
    }
    
    return $exportData
}
```

### 3. **Backup & Recovery**
```powershell
# Automated backup with encryption
$backupConfig = @{
    Schedule = "0 2 * * *"  # 2 AM daily
    Retention = @{
        Daily = 7
        Weekly = 4
        Monthly = 12
        Yearly = 5
    }
    Encryption = @{
        Algorithm = "AES-256"
        KeyVault = "PowerReviewBackupKeys"
    }
    Destinations = @(
        "Primary: Azure Blob Storage (GRS)",
        "Secondary: On-premises encrypted NAS"
    )
}
```

## 🚨 Security Monitoring

### Real-time Alerts
```json
{
    "SecurityAlerts": {
        "UnauthorizedAccess": {
            "Threshold": 3,
            "TimeWindow": "5 minutes",
            "Action": "Block user, alert admin"
        },
        "BulkDataExport": {
            "Threshold": "100 records",
            "Action": "Require additional approval"
        },
        "PrivilegeEscalation": {
            "Detection": "Role change without PIM",
            "Action": "Immediate investigation"
        },
        "AnomalousLocation": {
            "Detection": "Access from new country",
            "Action": "MFA challenge + alert"
        }
    }
}
```

## 📋 Security Checklist

### Initial Setup
- [ ] Configure Azure AD authentication
- [ ] Set up database with encryption
- [ ] Enable audit logging
- [ ] Configure backup strategy
- [ ] Set up Key Vault for secrets
- [ ] Enable Azure Security Center
- [ ] Configure DLP policies
- [ ] Set up monitoring alerts

### Ongoing Security
- [ ] Monthly access reviews
- [ ] Quarterly security assessments
- [ ] Annual penetration testing
- [ ] Regular backup restore tests
- [ ] Security training for users
- [ ] Incident response drills

## 🔧 Quick Security Setup

Run this script to configure basic security:

```powershell
# PowerReview Security Setup
.\Setup-PowerReviewSecurity.ps1 -ConfigureAll

# Individual components
.\Setup-PowerReviewSecurity.ps1 -ConfigureAuthentication
.\Setup-PowerReviewSecurity.ps1 -ConfigureEncryption
.\Setup-PowerReviewSecurity.ps1 -ConfigureAuditing
.\Setup-PowerReviewSecurity.ps1 -ConfigureBackup
```

## 🆘 Security Incident Response

1. **Detection**: Automated alerts + monitoring
2. **Containment**: Automatic user/IP blocking
3. **Investigation**: Full audit trail analysis
4. **Recovery**: Restore from encrypted backups
5. **Lessons Learned**: Update security policies

## 📞 Security Contacts

- **Security Team**: security@powerreview.com
- **Incident Response**: +1-800-SECURE (24/7)
- **Compliance Officer**: compliance@powerreview.com