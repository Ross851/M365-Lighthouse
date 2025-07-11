# 📁 PowerReview Data Storage Guide

## Overview
This guide explains where PowerReview stores different types of data and how to configure storage locations.

## 🗂️ Default Storage Locations

### 1. **Discovery Questionnaire Results**
```
.\Discovery-Results\
├── Discovery-Results-[timestamp].json      # Raw questionnaire responses
├── Discovery-Report-[timestamp].html       # Human-readable report
├── Discovery-Responses-[timestamp].csv     # CSV for analysis
└── Assessment-Input-[timestamp].json       # Input for PowerReview
```

### 2. **Electoral Commission Questionnaires**
```
.\EC-Discovery-Results\
├── Discovery-Results-[timestamp].json
├── Discovery-Report-[timestamp].html
├── EC-Recommendations-[timestamp].json
└── PowerReview-Config-[timestamp].json
```

### 3. **PowerReview Assessment Results**
```
.\PowerReview-Output\
├── Assessment-Results-[timestamp].json     # Complete assessment data
├── Executive-Summary-[timestamp].html      # C-suite dashboard
├── Technical-Report-[timestamp].html       # Detailed findings
├── Compliance-Report-[timestamp].html      # Compliance mapping
└── Client-Portal-[timestamp].html          # Secure portal
```

### 4. **Multi-Tenant Results**
```
.\PowerReview-Output\
└── Multi-Tenant-Assessment-[timestamp]\
    ├── Tenant-Contoso\
    │   ├── Purview-Results.json
    │   ├── SharePoint-Results.json
    │   └── Security-Results.json
    ├── Tenant-Fabrikam\
    │   └── [Same structure]
    └── Consolidated-Report.html
```

### 5. **Secure/Encrypted Data**
```
.\SecureVault\
├── credentials.vault              # Encrypted credentials
├── tokens.vault                  # OAuth tokens
└── sensitive-findings.vault      # Encrypted sensitive data
```

## 🔧 Configuration Options

### Configure Storage Locations

Create a `storage-config.json` file:

```json
{
  "StorageConfiguration": {
    "BaseOutputPath": "C:\\PowerReview-Data",
    "QuestionnaireResults": {
      "Path": "C:\\PowerReview-Data\\Questionnaires",
      "RetentionDays": 90
    },
    "AssessmentResults": {
      "Path": "C:\\PowerReview-Data\\Assessments",
      "RetentionDays": 365
    },
    "SecureStorage": {
      "Path": "C:\\PowerReview-Data\\Secure",
      "EncryptionRequired": true
    },
    "ClientPortals": {
      "Path": "C:\\PowerReview-Data\\Portals",
      "RetentionDays": 30
    },
    "ArchivePath": "\\\\FileServer\\PowerReview-Archive"
  }
}
```

### Environment-Specific Storage

```powershell
# Development
$env:POWERREVIEW_DATA = "C:\Dev\PowerReview-Data"

# Production
$env:POWERREVIEW_DATA = "\\NetworkShare\PowerReview\Production"

# Cloud Storage
$env:POWERREVIEW_DATA = "https://storageaccount.blob.core.windows.net/powerreview"
```

## 💾 Storage Options by Deployment Type

### 1. **Local Storage** (Default)
- **Pros**: Fast, simple, no dependencies
- **Cons**: Not shared, manual backup needed
- **Best for**: Single-user, development, POC

### 2. **Network Share**
```powershell
# Configure network storage
$config = @{
    OutputPath = "\\FileServer\PowerReview\Results"
    ArchivePath = "\\FileServer\PowerReview\Archive"
}
```
- **Pros**: Team access, centralized
- **Cons**: Requires permissions, network dependency
- **Best for**: Team environments, on-premises

### 3. **SharePoint Document Library**
```powershell
# Configure SharePoint storage
$config = @{
    SharePointUrl = "https://contoso.sharepoint.com/sites/PowerReview"
    DocumentLibrary = "Assessment Results"
}
```
- **Pros**: Version control, permissions, search
- **Cons**: Size limits, requires sync
- **Best for**: Collaboration, compliance tracking

### 4. **Azure Storage**
```powershell
# Configure Azure Blob Storage
$config = @{
    StorageAccount = "powerreviewstorage"
    Container = "assessments"
    UseManagedIdentity = $true
}
```
- **Pros**: Scalable, secure, backup included
- **Cons**: Requires Azure subscription
- **Best for**: Enterprise, multi-region

### 5. **Database Storage**
```powershell
# Configure SQL Database
$config = @{
    SqlServer = "sql.contoso.com"
    Database = "PowerReview"
    UseIntegratedAuth = $true
}
```
- **Pros**: Queryable, relationships, reporting
- **Cons**: Requires SQL infrastructure
- **Best for**: Large scale, analytics

## 🔐 Security Considerations

### Encryption at Rest
```powershell
# Enable encryption for sensitive data
Enable-PowerReviewEncryption -Path "C:\PowerReview-Data" -Algorithm AES256
```

### Access Control
```powershell
# Set folder permissions
$acl = Get-Acl "C:\PowerReview-Data"
$permission = "Domain\PowerReviewAdmins","FullControl","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\PowerReview-Data" $acl
```

### Data Classification
All stored data is classified as:
- **Public**: Executive summaries (anonymized)
- **Internal**: Assessment reports
- **Confidential**: Detailed findings
- **Highly Confidential**: Credentials, tokens

## 📊 Data Retention Policies

### Default Retention Periods
| Data Type | Retention | Archive After | Delete After |
|-----------|-----------|---------------|--------------|
| Questionnaires | 90 days | 6 months | 1 year |
| Assessments | 1 year | 2 years | 5 years |
| Client Portals | 30 days | N/A | 30 days |
| Audit Logs | 2 years | 5 years | 7 years |
| Encrypted Data | As needed | N/A | Manual |

### Implement Retention
```powershell
# Run monthly cleanup
.\Invoke-PowerReviewCleanup.ps1 -ApplyRetentionPolicies
```

## 🔄 Backup Strategies

### Local Backup Script
```powershell
# Create backup script
$backupScript = @'
$source = "C:\PowerReview-Data"
$destination = "D:\Backups\PowerReview\$(Get-Date -Format 'yyyy-MM-dd')"
Copy-Item -Path $source -Destination $destination -Recurse
'@
```

### Azure Backup
```powershell
# Configure Azure Backup
Enable-AzRecoveryServicesBackupProtection `
    -ResourceGroupName "PowerReview-RG" `
    -Name "PowerReviewData" `
    -Policy "DailyBackup"
```

## 🌍 Multi-Geography Considerations

For global deployments:
```json
{
  "Regions": {
    "NorthAmerica": {
      "Primary": "\\\\US-FileServer\\PowerReview",
      "Backup": "https://useast.blob.core.windows.net/powerreview"
    },
    "Europe": {
      "Primary": "\\\\EU-FileServer\\PowerReview",
      "Backup": "https://westeurope.blob.core.windows.net/powerreview"
    },
    "AsiaPacific": {
      "Primary": "\\\\APAC-FileServer\\PowerReview",
      "Backup": "https://southeastasia.blob.core.windows.net/powerreview"
    }
  }
}
```

## 🚨 Important Notes

1. **Never store in Git**: Results, reports, and client data should NEVER be committed to Git
2. **Sensitive Data**: Always encrypt credentials and tokens
3. **Client Portals**: Should have time-limited access
4. **Compliance**: Ensure storage meets regulatory requirements (GDPR, HIPAA, etc.)

## 📝 Quick Configuration

Run this to set up standard storage:
```powershell
# Create PowerReview data structure
$basePath = "C:\PowerReview-Data"
$folders = @(
    "$basePath\Questionnaires",
    "$basePath\Assessments",
    "$basePath\Portals",
    "$basePath\Secure",
    "$basePath\Archive",
    "$basePath\Logs"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force
}

# Set permissions (adjust for your environment)
icacls $basePath /grant "Administrators:(OI)(CI)F"
icacls "$basePath\Secure" /grant "Administrators:(OI)(CI)F" /remove "Users"
```

## 🔍 Finding Your Data

To locate existing results:
```powershell
# Find all assessment results
Get-ChildItem -Path C:\ -Include "*Assessment-Results*.json" -Recurse -ErrorAction SilentlyContinue

# Find questionnaire results
Get-ChildItem -Path C:\ -Include "*Discovery-Results*.json" -Recurse -ErrorAction SilentlyContinue

# Find client portals
Get-ChildItem -Path C:\ -Include "*Client-Portal*.html" -Recurse -ErrorAction SilentlyContinue
```