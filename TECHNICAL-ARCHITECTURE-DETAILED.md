# 🏗️ PowerReview Technical Architecture - Data Storage & Retrieval

## Executive Summary
PowerReview uses a **hybrid storage architecture** that can operate in multiple modes:
1. **Local Mode**: Encrypted files on disk (default, no dependencies)
2. **Enterprise Mode**: Azure Cosmos DB + Blob Storage with API layer
3. **Hybrid Mode**: Local cache + Cloud sync

## 📊 Complete Data Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PowerReview Data Flow                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [PowerShell Scripts]  →  [Data Processing]  →  [Storage Layer]        │
│         ↓                        ↓                     ↓                │
│  [Assessment Engine]  →  [Encryption Layer]  →  [Multi-Store Options]  │
│                                                        ↓                │
│                                              ┌─────────────────┐       │
│                                              │  LOCAL STORAGE  │       │
│                                              │  C:\PR-Data\    │       │
│                                              │  - JSON Files   │       │
│                                              │  - Encrypted    │       │
│                                              └────────┬────────┘       │
│                                                       ↓                 │
│                                              ┌─────────────────┐       │
│                                              │  AZURE COSMOS   │       │
│                                              │  Global Scale   │       │
│                                              │  - Documents    │       │
│                                              │  - Attachments  │       │
│                                              └────────┬────────┘       │
│                                                       ↓                 │
│                                              ┌─────────────────┐       │
│                                              │  AZURE BLOB     │       │
│                                              │  Large Files    │       │
│                                              │  - Reports      │       │
│                                              │  - Evidence     │       │
│                                              └─────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

## 🗄️ Storage Options Deep Dive

### Option 1: Local File Storage (Default)

**Location**: 
```
C:\PowerReview-Data\                    (Windows)
/home/user/PowerReview-Data/            (Linux)
/Users/user/PowerReview-Data/           (macOS)
```

**Structure**:
```
PowerReview-Data/
├── Assessments/
│   └── 2024/
│       └── 01/
│           ├── Assessment_20240115_120000.json     (Encrypted)
│           ├── Assessment_20240115_120000.meta     (Metadata)
│           └── Assessment_20240115_120000.key      (Encryption key)
├── SecureVault/
│   ├── master.key                                  (Master encryption key)
│   ├── credentials.vault                           (Encrypted credentials)
│   └── tokens.vault                                (OAuth tokens)
├── Cache/
│   └── [Temporary processing files]
└── Archive/
    └── [Old assessments based on retention]
```

**Data Format** (Encrypted JSON):
```json
{
  "header": {
    "version": "1.0",
    "encrypted": true,
    "algorithm": "AES-256-GCM",
    "timestamp": "2024-01-15T12:00:00Z"
  },
  "encryptedPayload": "BASE64_ENCRYPTED_CONTENT",
  "signature": "HMAC_SHA256_SIGNATURE"
}
```

### Option 2: Azure Cosmos DB Backend

**Primary Container Structure**:

```javascript
// Database: PowerReviewDB
// Container: Assessments
// Partition Key: /tenantId

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "contoso.onmicrosoft.com",
  "type": "Assessment",
  "metadata": {
    "version": "1.0",
    "createdDate": "2024-01-15T12:00:00Z",
    "createdBy": "admin@contoso.com",
    "classification": "Confidential",
    "tags": ["Q1-2024", "Compliance", "Annual"]
  },
  "organization": {
    "name": "Contoso Ltd",
    "id": "ORG-001",
    "industry": "Financial Services",
    "size": "5000+"
  },
  "assessment": {
    "id": "ASMT-2024-001",
    "type": "Comprehensive",
    "modules": {
      "purview": {
        "status": "completed",
        "findings": 47,
        "criticalFindings": 3,
        "score": 78
      },
      "sharepoint": {
        "status": "completed",
        "findings": 23,
        "criticalFindings": 1,
        "score": 85
      }
    }
  },
  "results": {
    "summary": {
      "overallScore": 81,
      "riskLevel": "Medium",
      "complianceStatus": "Partial"
    },
    "detailedFindings": {
      "storageType": "attachment",
      "attachmentId": "ATTACH-2024-001",
      "sizeBytes": 15728640,
      "encrypted": true
    }
  },
  "questionnaire": {
    "completedDate": "2024-01-14T10:00:00Z",
    "responseCount": 127,
    "storageRef": "quest/2024/01/QUEST-001.json"
  },
  "_etag": "\"00000000-0000-0000-0000-000000000000\"",
  "_ts": 1705320000,
  "_ttl": 31536000  // 1 year retention
}
```

**Cosmos DB Configuration**:
```json
{
  "account": "powerreview-cosmos",
  "database": "PowerReviewDB",
  "containers": [
    {
      "name": "Assessments",
      "partitionKey": "/tenantId",
      "defaultTTL": 31536000,
      "indexingPolicy": {
        "automatic": true,
        "includedPaths": [
          {"path": "/*"}
        ],
        "excludedPaths": [
          {"path": "/results/detailedFindings/*"}
        ]
      }
    },
    {
      "name": "Organizations",
      "partitionKey": "/id",
      "uniqueKeys": [
        {"paths": ["/tenantId"]}
      ]
    },
    {
      "name": "AuditLogs",
      "partitionKey": "/date",
      "defaultTTL": 7776000  // 90 days
    }
  ],
  "consistency": "Session",
  "regions": [
    {"name": "East US", "failoverPriority": 0},
    {"name": "West Europe", "failoverPriority": 1}
  ]
}
```

### Option 3: Hybrid Storage Architecture

**Best of Both Worlds**:
```
┌──────────────────────────────────────────────────────────────┐
│                    Hybrid Architecture                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Local Cache                     Cloud Storage               │
│  ┌─────────────┐               ┌──────────────┐            │
│  │ Recent Data │  ←─ Sync ─→   │ Cosmos DB    │            │
│  │ (30 days)   │               │ (All Data)   │            │
│  └─────────────┘               └──────────────┘            │
│                                                              │
│  ┌─────────────┐               ┌──────────────┐            │
│  │ Large Files │  ←─ Sync ─→   │ Blob Storage │            │
│  │ (On Demand) │               │ (All Files)  │            │
│  └─────────────┘               └──────────────┘            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 🔐 Data at Rest - Security Details

### Encryption Implementation

```powershell
# How data is encrypted before storage
function Encrypt-AssessmentData {
    param($AssessmentData)
    
    # 1. Generate unique encryption key for this assessment
    $dataKey = [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32)
    
    # 2. Encrypt the data key with master key
    $masterKey = Get-MasterKey  # Retrieved from secure vault
    $encryptedDataKey = Protect-DataKey -DataKey $dataKey -MasterKey $masterKey
    
    # 3. Encrypt assessment data
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $dataKey
    $aes.GenerateIV()
    
    $jsonData = $AssessmentData | ConvertTo-Json -Depth 100 -Compress
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonData)
    
    $encryptor = $aes.CreateEncryptor()
    $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
    
    # 4. Create storage object
    return @{
        Version = "1.0"
        Algorithm = "AES-256-GCM"
        EncryptedData = [Convert]::ToBase64String($encryptedBytes)
        EncryptedKey = [Convert]::ToBase64String($encryptedDataKey)
        IV = [Convert]::ToBase64String($aes.IV)
        Signature = Get-HMAC -Data $encryptedBytes -Key $masterKey
        Timestamp = [DateTime]::UtcNow
    }
}
```

### Where Encryption Keys Are Stored

1. **Master Key**: 
   - Location: `C:\PowerReview-Data\SecureVault\master.key`
   - Protected by: Windows DPAPI (or OS equivalent)
   - Backed up to: Azure Key Vault (optional)

2. **Data Keys**:
   - Unique per assessment
   - Stored with encrypted data
   - Never stored in plain text

3. **Key Hierarchy**:
```
Azure Key Vault (Optional)
    └─> Master Key (Hardware-protected)
         └─> Data Encryption Keys
              └─> Individual Assessment Data
```

## 🔄 Data Retrieval API

### REST API Structure (When Using Cloud Storage)

```yaml
BaseURL: https://api.powerreview.yourdomain.com/v1

Endpoints:
  # List assessments
  GET /assessments
    Query Parameters:
      - organizationId: string
      - startDate: datetime
      - endDate: datetime
      - moduleType: string
    Response: AssessmentList[]

  # Get specific assessment
  GET /assessments/{id}
    Headers:
      - Authorization: Bearer {token}
    Response: AssessmentDetail

  # Get assessment report
  GET /assessments/{id}/report
    Query Parameters:
      - format: json|html|pdf
    Response: Report

  # Search assessments
  POST /assessments/search
    Body:
      {
        "query": "compliance",
        "filters": {
          "severity": ["critical", "high"],
          "dateRange": {...}
        }
      }
    Response: SearchResults
```

### PowerShell Retrieval Functions

```powershell
# Retrieve from local storage
function Get-PowerReviewAssessment {
    param(
        [string]$AssessmentId,
        [string]$OrganizationId,
        [datetime]$Date
    )
    
    # Check local cache first
    $localPath = "C:\PowerReview-Data\Assessments\$($Date.Year)\$($Date.ToString('MM'))"
    $assessmentFile = Get-ChildItem -Path $localPath -Filter "*$AssessmentId*.json" -ErrorAction SilentlyContinue
    
    if ($assessmentFile) {
        # Load and decrypt
        $encryptedData = Get-Content $assessmentFile.FullName -Raw | ConvertFrom-Json
        return Decrypt-AssessmentData -EncryptedData $encryptedData
    }
    
    # If not found locally, check cloud
    if (Test-CloudConnection) {
        return Get-AssessmentFromCloud -AssessmentId $AssessmentId
    }
    
    throw "Assessment not found"
}

# Retrieve from Cosmos DB
function Get-AssessmentFromCloud {
    param($AssessmentId)
    
    $cosmosConfig = Get-CosmosConfiguration
    $uri = "$($cosmosConfig.Endpoint)/dbs/PowerReviewDB/colls/Assessments/docs/$AssessmentId"
    
    $headers = Get-CosmosHeaders -Verb "GET" -ResourceLink "dbs/PowerReviewDB/colls/Assessments/docs/$AssessmentId"
    
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    
    # Decrypt if necessary
    if ($response.results.encrypted) {
        $response.results = Decrypt-CloudData -Data $response.results
    }
    
    return $response
}
```

## 📍 Data Residency & Compliance

### Geographic Storage Locations

```json
{
  "DataResidency": {
    "PrimaryRegion": "East US",
    "SecondaryRegion": "West Europe",
    "ComplianceMode": {
      "GDPR": {
        "EUDataInEU": true,
        "DataSubjectRights": "Automated"
      },
      "SOC2": {
        "Compliant": true,
        "AuditFrequency": "Annual"
      }
    }
  }
}
```

### Backup Locations

1. **Primary**: Azure Blob Storage (GRS)
   - Location: Same region as primary data
   - Replication: Geo-redundant
   - Retention: 1 year

2. **Secondary**: Azure Backup Vault
   - Location: Paired region
   - Encryption: Additional layer
   - Retention: 5 years

3. **Archive**: Azure Cool Storage
   - Location: Cheapest region
   - Access: Rare
   - Retention: 7 years

## 🚀 Quick Retrieval Examples

### Example 1: Get Latest Assessment
```powershell
# From local storage
$latest = Get-PowerReviewAssessment -OrganizationId "ORG-001" -Latest

# From Cosmos DB
$latest = Get-CloudAssessment -Query "SELECT TOP 1 * FROM c WHERE c.organizationId = 'ORG-001' ORDER BY c._ts DESC"
```

### Example 2: Search Findings
```powershell
# Search for critical findings
$critical = Search-PowerReviewFindings -Severity "Critical" -Module "Purview" -DateRange (Get-Date).AddDays(-30)
```

### Example 3: Bulk Export
```powershell
# Export all assessments for an organization
Export-PowerReviewData -OrganizationId "ORG-001" -Format "JSON" -OutputPath "C:\Exports"
```

## 🏢 Enterprise Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Global Enterprise Setup                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Region: Americas          Region: Europe                   │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ Cosmos DB    │ ←────→  │ Cosmos DB    │                │
│  │ (Primary)    │  Sync   │ (Secondary)  │                │
│  └──────┬───────┘         └──────────────┘                │
│         │                                                   │
│         ↓                                                   │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ Blob Storage │         │ Blob Storage │                │
│  │ (Hot Tier)   │         │ (Archive)    │                │
│  └──────────────┘         └──────────────┘                │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ API Gateway  │         │ CDN          │                │
│  │ (REST API)   │         │ (Reports)    │                │
│  └──────────────┘         └──────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Key Takeaways

1. **Default Storage**: Local encrypted JSON files at `C:\PowerReview-Data`
2. **Enterprise Option**: Azure Cosmos DB with global replication
3. **Encryption**: AES-256 always, keys in secure vault
4. **Retrieval**: Local functions or REST API
5. **Backup**: Automated to multiple locations
6. **Compliance**: GDPR, SOC2, HIPAA ready
7. **Scale**: From single laptop to global enterprise