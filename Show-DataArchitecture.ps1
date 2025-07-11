#Requires -Version 7.0

<#
.SYNOPSIS
    Visual representation of PowerReview data architecture
.DESCRIPTION
    Shows where data is stored and how it flows through the system
#>

param(
    [switch]$Simple,
    [switch]$Detailed,
    [switch]$CurrentConfig
)

function Show-SimpleArchitecture {
    Clear-Host
    Write-Host @"

    🖥️ YOUR COMPUTER                           ☁️ CLOUD (OPTIONAL)
    ┌─────────────────────┐                   ┌─────────────────────┐
    │                     │                   │                     │
    │  PowerReview.ps1    │                   │   Azure Cosmos DB   │
    │         ↓           │                   │   (Global Scale)    │
    │  📊 Assessment      │     ← Sync →      │   📊 All Data       │
    │         ↓           │    (Optional)     │                     │
    │  🔐 Encryption      │                   │   Azure Blob        │
    │         ↓           │                   │   📁 Large Files    │
    │  💾 Local Storage   │                   │                     │
    │                     │                   │   API Gateway       │
    │  C:\PowerReview-    │                   │   🔌 REST API       │
    │      Data\          │                   │                     │
    └─────────────────────┘                   └─────────────────────┘

    LOCAL STORAGE STRUCTURE:
    C:\PowerReview-Data\
    ├── 📁 Assessments\      ← Your assessment results (encrypted)
    ├── 🔐 SecureVault\      ← Encryption keys (protected)
    ├── 📋 Questionnaires\   ← Discovery responses
    └── 💾 Archive\          ← Old data (compressed)

"@ -ForegroundColor Cyan
}

function Show-DetailedArchitecture {
    Clear-Host
    Write-Host @"

                        🏢 POWERREVIEW DATA ARCHITECTURE
    ═══════════════════════════════════════════════════════════════════

    📥 DATA INPUT                    🔄 PROCESSING                    💾 STORAGE
    ─────────────                    ─────────────                    ─────────

    PowerShell Scripts               Encryption Layer                 LOCAL (DEFAULT)
    ├─ Start-PowerReview.ps1   →    ├─ AES-256-GCM          →       C:\PowerReview-Data\
    ├─ Questionnaire.ps1            ├─ Machine Keys                  ├─ Assessments\
    └─ Assessment.ps1               └─ HMAC Signing                  ├─ SecureVault\
                                                                     └─ Archive\
           ↓                               ↓                              ↓

    Assessment Engine                Data Processing                  CLOUD (OPTIONAL)
    ├─ Purview Module          →    ├─ JSON Transform       →       Azure Cosmos DB
    ├─ SharePoint Module            ├─ Compression                   ├─ Assessments
    ├─ Security Module              └─ Indexing                      ├─ Organizations
    └─ Azure Module                                                  └─ AuditLogs
    
           ↓                               ↓                              ↓

    Results Generation               Storage Router                   BACKUP
    ├─ Findings            →        ├─ Local First         →        Azure Blob (GRS)
    ├─ Recommendations              ├─ Cloud Sync                    ├─ Hot Tier
    └─ Reports                      └─ Cache Manager                 └─ Cool Archive


    🔐 SECURITY LAYERS               🔑 ACCESS CONTROL                📊 RETRIEVAL
    ──────────────────               ────────────────                 ───────────

    Encryption at Rest               Azure AD Auth                    PowerShell API
    ├─ Master Key (Vault)      →    ├─ MFA Required        →        Get-Assessment
    ├─ Data Keys (Unique)           ├─ RBAC Roles                   Search-Findings
    └─ File Encryption              └─ Audit Logging                Export-Report
    
    Encryption in Transit            Row-Level Security               REST API
    ├─ TLS 1.2+              →     ├─ Tenant Isolation     →       GET /assessments
    ├─ Certificate Pinning          ├─ Data Filtering               POST /search
    └─ VPN Tunnels                  └─ Time Limits                  GET /reports

"@ -ForegroundColor Cyan

    Write-Host "`n🗂️ DATA AT REST LOCATIONS:" -ForegroundColor Yellow
    Write-Host @"

    1. LOCAL FILE SYSTEM (Default)
       └─ Location: C:\PowerReview-Data\
       └─ Format: Encrypted JSON files
       └─ Key Storage: Windows DPAPI protected
       └─ Backup: Manual or scripted

    2. AZURE COSMOS DB (Enterprise)
       └─ Account: powerreview-cosmos.documents.azure.com
       └─ Database: PowerReviewDB
       └─ Containers: Assessments, Organizations, AuditLogs
       └─ Regions: East US (Primary), West Europe (Secondary)
       └─ Backup: Automatic, point-in-time restore

    3. AZURE BLOB STORAGE (Large Files)
       └─ Account: powerreviewstorage.blob.core.windows.net
       └─ Containers: assessments, reports, evidence
       └─ Tiers: Hot (Recent), Cool (Archive)
       └─ Replication: Geo-redundant (GRS)

"@ -ForegroundColor White
}

function Show-CurrentConfiguration {
    Write-Host "`n📍 CURRENT CONFIGURATION STATUS" -ForegroundColor Yellow
    Write-Host "════════════════════════════════" -ForegroundColor Yellow
    
    # Check storage config
    if (Test-Path ".\storage-config.json") {
        $config = Get-Content ".\storage-config.json" -Raw | ConvertFrom-Json
        Write-Host "`n✅ Storage Configuration Found:" -ForegroundColor Green
        Write-Host "   Base Path: $($config.StorageConfiguration.BaseOutputPath)" -ForegroundColor White
        
        if ($config.StorageConfiguration.StorageType) {
            Write-Host "   Type: $($config.StorageConfiguration.StorageType)" -ForegroundColor White
        } else {
            Write-Host "   Type: Local File System" -ForegroundColor White
        }
    } else {
        Write-Host "`n⚠️  No storage configuration found" -ForegroundColor Yellow
        Write-Host "   Using default locations:" -ForegroundColor Gray
        Write-Host "   • Assessments: .\PowerReview-Output\" -ForegroundColor Gray
        Write-Host "   • Questionnaires: .\Discovery-Results\" -ForegroundColor Gray
    }
    
    # Check security config
    if (Test-Path ".\SecureVault\.key") {
        Write-Host "`n✅ Encryption Configured:" -ForegroundColor Green
        Write-Host "   Algorithm: AES-256-GCM" -ForegroundColor White
        Write-Host "   Key Location: .\SecureVault\ (Protected)" -ForegroundColor White
    } else {
        Write-Host "`n⚠️  Encryption not configured" -ForegroundColor Yellow
        Write-Host "   Run: .\Setup-PowerReviewSecurity.ps1 -ConfigureEncryption" -ForegroundColor Gray
    }
    
    # Check database config
    if (Test-Path ".\db-config.secure.json") {
        Write-Host "`n✅ Database Configured:" -ForegroundColor Green
        Write-Host "   Type: [Encrypted - Run with -Detailed to view]" -ForegroundColor White
    } else {
        Write-Host "`n📁 Using File-Based Storage Only" -ForegroundColor Cyan
    }
    
    # Show data statistics
    Write-Host "`n📊 DATA STATISTICS:" -ForegroundColor Yellow
    
    $assessmentCount = (Get-ChildItem -Path "*Assessment-Results*.json" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    $questionnaireCount = (Get-ChildItem -Path "*Discovery-Results*.json" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    
    Write-Host "   Assessments Stored: $assessmentCount" -ForegroundColor White
    Write-Host "   Questionnaires Stored: $questionnaireCount" -ForegroundColor White
    
    # Calculate total size
    $totalSize = 0
    Get-ChildItem -Path "." -Include "*.json", "*.html" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $totalSize += $_.Length
    }
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Host "   Total Data Size: $totalSizeMB MB" -ForegroundColor White
}

function Show-DataFlow {
    Write-Host "`n🔄 DATA FLOW EXAMPLE:" -ForegroundColor Yellow
    Write-Host @"

    1. USER RUNS ASSESSMENT
       ↓
    2. QUESTIONNAIRE RESPONSES → Saved to: .\Discovery-Results\Discovery-Results-[timestamp].json
       ↓
    3. ASSESSMENT EXECUTES → Processing in memory
       ↓
    4. RESULTS GENERATED → Encrypted with AES-256
       ↓
    5. STORED LOCALLY → C:\PowerReview-Data\Assessments\2024\01\Assessment_[timestamp].json
       ↓
    6. (OPTIONAL) SYNC TO CLOUD → Azure Cosmos DB: /dbs/PowerReviewDB/colls/Assessments
       ↓
    7. REPORTS GENERATED → .\PowerReview-Output\Executive-Summary-[timestamp].html
       ↓
    8. CLIENT PORTAL → .\PowerReview-Output\Client-Portal-[timestamp].html (Token protected)

"@ -ForegroundColor Cyan
}

# Main execution
Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    🏗️  POWERREVIEW DATA ARCHITECTURE VIEWER 🏗️                ║
║                                                                               ║
║                      Understanding where your data lives                       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if ($Simple -or (!$Simple -and !$Detailed -and !$CurrentConfig)) {
    Show-SimpleArchitecture
}

if ($Detailed) {
    Show-DetailedArchitecture
}

if ($CurrentConfig) {
    Show-CurrentConfiguration
}

Write-Host "`n💡 QUICK ANSWERS:" -ForegroundColor Yellow
Write-Host @"

Q: Where is my data stored?
A: By default, locally at C:\PowerReview-Data\ (encrypted)

Q: Is it safe?
A: Yes - AES-256 encryption, machine-specific keys, access controlled

Q: Can I use cloud storage?
A: Yes - Azure Cosmos DB and Blob Storage are supported

Q: How do I retrieve old assessments?
A: Use Get-PowerReviewAssessment -AssessmentId 'ID' or check the Archive folder

Q: What about backups?
A: Configure with .\Setup-PowerReviewSecurity.ps1 -ConfigureBackup

"@ -ForegroundColor White

Write-Host "`n📚 For more information:" -ForegroundColor Gray
Write-Host "   • Simple view: .\Show-DataArchitecture.ps1 -Simple" -ForegroundColor Gray
Write-Host "   • Detailed view: .\Show-DataArchitecture.ps1 -Detailed" -ForegroundColor Gray
Write-Host "   • Current setup: .\Show-DataArchitecture.ps1 -CurrentConfig" -ForegroundColor Gray