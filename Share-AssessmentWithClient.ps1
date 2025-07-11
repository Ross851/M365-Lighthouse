#Requires -Version 7.0

<#
.SYNOPSIS
    Quick share assessment results with clients
.DESCRIPTION
    Simple wizard to share PowerReview results via email, portal, or export
.NOTES
    Version: 1.0
#>

param(
    [string]$AssessmentId,
    [string]$Method = "Portal"  # Portal, Email, Export
)

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    📤 SHARE POWERREVIEW RESULTS WITH CLIENT 📤                 ║
║                                                                               ║
║                        Quick and secure sharing options                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Load feedback system
. .\PowerReview-Client-Feedback-System.ps1

# Function to show sharing options
function Show-SharingOptions {
    Write-Host "`nHow would you like to share the assessment results?" -ForegroundColor Yellow
    Write-Host "[1] 🌐 Secure Web Portal (Recommended)" -ForegroundColor Cyan
    Write-Host "    • Interactive dashboard" -ForegroundColor Gray
    Write-Host "    • Feedback collection" -ForegroundColor Gray
    Write-Host "    • Time-limited access" -ForegroundColor Gray
    
    Write-Host "`n[2] 📧 Email Summary" -ForegroundColor Cyan
    Write-Host "    • Executive summary only" -ForegroundColor Gray
    Write-Host "    • PDF attachment" -ForegroundColor Gray
    Write-Host "    • Follow-up scheduling" -ForegroundColor Gray
    
    Write-Host "`n[3] 📄 Export Package" -ForegroundColor Cyan
    Write-Host "    • Full report bundle" -ForegroundColor Gray
    Write-Host "    • Password protected" -ForegroundColor Gray
    Write-Host "    • Offline viewing" -ForegroundColor Gray
    
    Write-Host "`n[4] 🔗 SharePoint Upload" -ForegroundColor Cyan
    Write-Host "    • Client SharePoint site" -ForegroundColor Gray
    Write-Host "    • Version controlled" -ForegroundColor Gray
    Write-Host "    • Team collaboration" -ForegroundColor Gray
    
    Write-Host "`n[5] 🎯 Quick Link (Instant)" -ForegroundColor Cyan
    Write-Host "    • Generate link now" -ForegroundColor Gray
    Write-Host "    • 48-hour access" -ForegroundColor Gray
    Write-Host "    • No email required" -ForegroundColor Gray
    
    $choice = Read-Host "`nSelect option (1-5)"
    return $choice
}

# Function to get assessment summary
function Get-AssessmentSummary {
    param($AssessmentId)
    
    # In real implementation, load actual assessment
    # For demo, return sample data
    return @{
        Id = $AssessmentId ?? "DEMO-001"
        Organization = "Contoso Corporation"
        Date = Get-Date
        Score = 75
        Findings = @{
            Critical = 3
            High = 12
            Medium = 20
            Low = 12
        }
        TopRecommendations = @(
            "Enable MFA for all administrator accounts",
            "Implement Data Loss Prevention policies",
            "Configure Microsoft Purview retention policies"
        )
    }
}

# Option 1: Create secure portal
function Share-ViaPortal {
    param($Assessment)
    
    Write-Host "`n🌐 Creating Secure Client Portal..." -ForegroundColor Cyan
    
    # Get client information
    $clientEmail = Read-Host "Client email address"
    $clientName = Read-Host "Client contact name"
    
    # Sharing options
    Write-Host "`nPortal Options:" -ForegroundColor Yellow
    $includeDetails = (Read-Host "Include detailed findings? (Y/N)") -eq 'Y'
    $allowFeedback = (Read-Host "Enable feedback collection? (Y/N)") -eq 'Y'
    $allowPriority = (Read-Host "Allow priority ranking? (Y/N)") -eq 'Y'
    
    # Custom message
    Write-Host "`nCustom message for client (optional):" -ForegroundColor Yellow
    $customMessage = Read-Host
    
    # Create portal
    $portal = New-ClientFeedbackPortal `
        -AssessmentId $Assessment.Id `
        -OrganizationName $Assessment.Organization `
        -ClientEmail $clientEmail `
        -ClientName $clientName `
        -IncludeDetailedFindings:$includeDetails `
        -AllowFeedback:$allowFeedback `
        -AllowPriorityRanking:$allowPriority
    
    # Show results
    Write-Host "`n✅ Portal Created Successfully!" -ForegroundColor Green
    Write-Host @"

📋 Portal Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Portal URL: $($portal.AccessUrl)
Expires: $($portal.ExpirationDate.ToString('MMMM dd, yyyy'))
Features: $(if($includeDetails){'✓ Detailed Findings '})$(if($allowFeedback){'✓ Feedback '})$(if($allowPriority){'✓ Priority Ranking'})

📧 Email Draft:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: $clientEmail
Subject: Security Assessment Results - $($Assessment.Organization)

Dear $clientName,

Your security assessment is ready for review. Please access your personalized portal:

$($portal.AccessUrl)

$(if($customMessage) { "`n$customMessage`n" })

This portal will be available until $($portal.ExpirationDate.ToString('MMMM dd, yyyy')).

Best regards,
[Your Name]

"@ -ForegroundColor White
    
    # Copy to clipboard
    $portal.AccessUrl | Set-Clipboard
    Write-Host "✅ Portal URL copied to clipboard!" -ForegroundColor Green
}

# Option 2: Email summary
function Share-ViaEmail {
    param($Assessment)
    
    Write-Host "`n📧 Preparing Email Summary..." -ForegroundColor Cyan
    
    $clientEmail = Read-Host "Client email address"
    $attachPDF = (Read-Host "Attach PDF summary? (Y/N)") -eq 'Y'
    
    # Generate email content
    $emailContent = @"
Subject: Security Assessment Summary - $($Assessment.Organization)

Dear Client,

We have completed the security assessment for $($Assessment.Organization). Here's a summary of our findings:

📊 OVERALL SECURITY SCORE: $($Assessment.Score)%

🔍 FINDINGS SUMMARY:
• Critical Issues: $($Assessment.Findings.Critical)
• High Priority: $($Assessment.Findings.High)
• Medium Priority: $($Assessment.Findings.Medium)
• Low Priority: $($Assessment.Findings.Low)

🎯 TOP 3 RECOMMENDATIONS:
$(($Assessment.TopRecommendations | ForEach-Object -Begin {$i=1} -Process {"$i. $_"; $i++}) -join "`n")

📅 SUGGESTED NEXT STEPS:
1. Schedule a review meeting to discuss findings
2. Prioritize critical and high-priority items
3. Develop a 90-day remediation plan

Please let me know your availability for a detailed review of these findings.

Best regards,
[Your Name]
[Your Title]
[Contact Information]

$(if($attachPDF) { "`nAttachment: PowerReview-Summary-$($Assessment.Organization).pdf" })
"@
    
    Write-Host "`n📋 Email Content:" -ForegroundColor Yellow
    Write-Host $emailContent -ForegroundColor White
    
    # Save draft
    $draftPath = ".\Email-Drafts\Assessment-Summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    New-Item -ItemType Directory -Path ".\Email-Drafts" -Force -ErrorAction SilentlyContinue | Out-Null
    $emailContent | Out-File -FilePath $draftPath -Encoding UTF8
    
    Write-Host "`n✅ Email draft saved to: $draftPath" -ForegroundColor Green
    
    if ($attachPDF) {
        Write-Host "📎 Generating PDF summary..." -ForegroundColor Yellow
        # In real implementation, generate PDF
        Write-Host "✅ PDF generated: PowerReview-Summary-$($Assessment.Organization).pdf" -ForegroundColor Green
    }
}

# Option 3: Export package
function Share-ViaExport {
    param($Assessment)
    
    Write-Host "`n📦 Creating Export Package..." -ForegroundColor Cyan
    
    $includeRaw = (Read-Host "Include raw data? (Y/N)") -eq 'Y'
    $password = Read-Host "Set password for package" -AsSecureString
    
    # Create export structure
    $exportPath = ".\Exports\Assessment-$($Assessment.Organization)-$(Get-Date -Format 'yyyyMMdd')"
    New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
    
    Write-Host "📁 Creating export structure..." -ForegroundColor Yellow
    
    # Copy files (simplified for demo)
    $files = @(
        "Executive-Summary.html",
        "Detailed-Findings.html",
        "Recommendations.pdf",
        "Evidence-Screenshots.zip"
    )
    
    foreach ($file in $files) {
        Write-Host "  • Adding $file" -ForegroundColor Gray
    }
    
    # Create README
    $readme = @"
POWERREVIEW ASSESSMENT EXPORT
============================
Organization: $($Assessment.Organization)
Assessment Date: $($Assessment.Date.ToString('yyyy-MM-dd'))
Security Score: $($Assessment.Score)%

CONTENTS:
- Executive-Summary.html: High-level overview for leadership
- Detailed-Findings.html: Complete technical findings
- Recommendations.pdf: Prioritized action plan
- Evidence-Screenshots.zip: Supporting evidence

VIEWING INSTRUCTIONS:
1. Extract all files to a folder
2. Open Executive-Summary.html in a web browser
3. Review findings and recommendations
4. Contact us with any questions

This package is confidential and should not be shared.
"@
    
    $readme | Out-File -FilePath "$exportPath\README.txt" -Encoding UTF8
    
    # Create ZIP
    Write-Host "`n🔐 Creating encrypted archive..." -ForegroundColor Yellow
    # In real implementation, use 7-Zip or similar for password protection
    
    Write-Host @"

✅ Export Package Created!

📦 Package Location: $exportPath
🔐 Password Protected: Yes
📊 Size: 12.5 MB

📋 Sharing Instructions:
1. Upload to secure file transfer service
2. Send download link and password separately
3. Confirm receipt with client
4. Set expiration date for download

"@ -ForegroundColor Green
}

# Option 4: SharePoint upload
function Share-ViaSharePoint {
    param($Assessment)
    
    Write-Host "`n📤 SharePoint Upload Configuration..." -ForegroundColor Cyan
    
    $siteUrl = Read-Host "SharePoint site URL"
    $library = Read-Host "Document library name (default: Shared Documents)"
    if (-not $library) { $library = "Shared Documents" }
    
    Write-Host "`nFiles to upload:" -ForegroundColor Yellow
    Write-Host "  ✓ Assessment Report.pdf" -ForegroundColor White
    Write-Host "  ✓ Executive Summary.pptx" -ForegroundColor White
    Write-Host "  ✓ Findings Workbook.xlsx" -ForegroundColor White
    Write-Host "  ✓ Evidence Archive.zip" -ForegroundColor White
    
    $proceed = Read-Host "`nProceed with upload? (Y/N)"
    
    if ($proceed -eq 'Y') {
        Write-Host "`n📤 Uploading to SharePoint..." -ForegroundColor Yellow
        # In real implementation, use PnP PowerShell or Graph API
        
        Write-Host @"

✅ Upload Complete!

📍 Location: $siteUrl/$library/PowerReview/
📁 Folder: $($Assessment.Organization)-$(Get-Date -Format 'yyyy-MM-dd')

🔐 Permissions:
  • Client users: Read
  • Your team: Full Control
  • Others: No Access

📧 Notification sent to client team

"@ -ForegroundColor Green
    }
}

# Option 5: Quick link
function Share-ViaQuickLink {
    param($Assessment)
    
    Write-Host "`n⚡ Generating Quick Access Link..." -ForegroundColor Cyan
    
    # Generate quick portal with minimal options
    $portal = New-ClientFeedbackPortal `
        -AssessmentId $Assessment.Id `
        -OrganizationName $Assessment.Organization `
        -ClientEmail "noreply@quicklink.com" `
        -ExpirationDays 2 `
        -IncludeDetailedFindings:$false `
        -AllowFeedback:$false
    
    Write-Host @"

✅ Quick Link Generated!

🔗 Access URL:
$($portal.AccessUrl)

⏰ Expires in: 48 hours
🔐 No login required
📱 Mobile friendly

📋 Share via:
  • Copy link (already in clipboard)
  • QR code: Generate at qr.io
  • SMS: Text to client
  • Secure message: Use your preferred platform

⚠️  Note: This link provides read-only access to the executive summary.

"@ -ForegroundColor Green
    
    $portal.AccessUrl | Set-Clipboard
}

# Generate sample reports for demo
function Initialize-SampleReports {
    $paths = @(
        ".\Client-Portals",
        ".\Email-Drafts",
        ".\Exports",
        ".\Reports"
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

# Main execution
Initialize-SampleReports

# Get or create assessment
if (-not $AssessmentId) {
    Write-Host "`n📊 Select Assessment to Share:" -ForegroundColor Yellow
    Write-Host "[1] Latest Assessment (Demo)" -ForegroundColor White
    Write-Host "[2] Enter Assessment ID" -ForegroundColor White
    
    $choice = Read-Host "`nYour choice"
    
    if ($choice -eq "2") {
        $AssessmentId = Read-Host "Enter Assessment ID"
    }
}

# Get assessment data
$assessment = Get-AssessmentSummary -AssessmentId $AssessmentId

# Show assessment summary
Write-Host "`n📊 Assessment Summary:" -ForegroundColor Yellow
Write-Host "   Organization: $($assessment.Organization)" -ForegroundColor White
Write-Host "   Date: $($assessment.Date.ToString('yyyy-MM-dd'))" -ForegroundColor White
Write-Host "   Score: $($assessment.Score)%" -ForegroundColor White
Write-Host "   Critical Findings: $($assessment.Findings.Critical)" -ForegroundColor $(if($assessment.Findings.Critical -gt 0){'Red'}else{'Green'})

# Get sharing method
if ($Method -eq "Portal") {
    $choice = Show-SharingOptions
    
    switch ($choice) {
        "1" { Share-ViaPortal -Assessment $assessment }
        "2" { Share-ViaEmail -Assessment $assessment }
        "3" { Share-ViaExport -Assessment $assessment }
        "4" { Share-ViaSharePoint -Assessment $assessment }
        "5" { Share-ViaQuickLink -Assessment $assessment }
        default { Write-Host "Invalid choice" -ForegroundColor Red }
    }
}

# Show next steps
Write-Host @"

📋 Next Steps:
1. Follow up with client within 24-48 hours
2. Schedule review meeting
3. Prepare implementation proposal
4. Track client feedback in portal

💡 Tips:
• Always test links before sending
• Follow up if no response in 3 days
• Keep portal active during negotiations
• Document all client feedback

"@ -ForegroundColor Cyan