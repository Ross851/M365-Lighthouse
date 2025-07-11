#Requires -Version 7.0

<#
.SYNOPSIS
    Quick demo of PowerReview features
.DESCRIPTION
    Shows PowerReview in action without connecting to actual tenants
#>

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                         🎮 POWERREVIEW DEMO MODE 🎮                           ║
║                                                                               ║
║                     See PowerReview in action right now!                       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n🎯 DEMO OPTIONS:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host @"
1. 🖼️  Show UI Components
2. 📊 Generate Sample Report
3. 🌐 Create Demo Client Portal  
4. 📝 Run Sample Questionnaire
5. 👥 Show Role Management
6. 📤 Demo Sharing Options
7. 🎬 Full Demo Sequence
8. 🚪 Exit

"@ -ForegroundColor White

$choice = Read-Host "Select demo option (1-8)"

switch ($choice) {
    "1" {
        # Show UI Components
        Write-Host "`n🖼️  UI COMPONENTS DEMO" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        # Progress Bar Demo
        Write-Host "`n📊 Progress Bar Example:" -ForegroundColor Yellow
        $activities = @("Connecting", "Authenticating", "Gathering Data", "Analyzing", "Generating Report")
        foreach ($activity in $activities) {
            $percent = [array]::IndexOf($activities, $activity) * 20 + 20
            Write-Progress -Activity "Assessment Progress" -Status $activity -PercentComplete $percent
            Start-Sleep -Milliseconds 500
        }
        Write-Progress -Activity "Assessment Progress" -Completed
        
        # Menu Demo
        Write-Host "`n📋 Interactive Menu Example:" -ForegroundColor Yellow
        Write-Host "┌─────────────────────────────────────┐" -ForegroundColor DarkGray
        Write-Host "│ PowerReview Assessment Menu         │" -ForegroundColor DarkGray
        Write-Host "├─────────────────────────────────────┤" -ForegroundColor DarkGray
        Write-Host "│ [✓] Purview Assessment             │" -ForegroundColor Green
        Write-Host "│ [✓] SharePoint Assessment          │" -ForegroundColor Green
        Write-Host "│ [ ] Teams Assessment               │" -ForegroundColor White
        Write-Host "│ [!] Power Platform (Requires PIM)  │" -ForegroundColor Yellow
        Write-Host "└─────────────────────────────────────┘" -ForegroundColor DarkGray
    }
    
    "2" {
        # Generate Sample Report
        Write-Host "`n📊 GENERATING SAMPLE REPORT" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        $sampleReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Assessment - Demo Company</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .score-card { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .critical { color: #d13438; font-weight: bold; }
        .high { color: #ff8c00; font-weight: bold; }
        .medium { color: #ffb900; }
        .low { color: #107c10; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔒 PowerReview Security Assessment</h1>
        <h2>Demo Company - $(Get-Date -Format "MMMM dd, yyyy")</h2>
    </div>
    
    <div class="score-card">
        <h2>Executive Summary</h2>
        <h3>Overall Security Score: <span style="font-size: 2em; color: #ff8c00;">72/100</span></h3>
        <p>Your organization's security posture requires attention in several key areas.</p>
        
        <h3>Key Findings:</h3>
        <ul>
            <li class="critical">12 Critical findings requiring immediate action</li>
            <li class="high">47 High priority items</li>
            <li class="medium">123 Medium priority items</li>
            <li class="low">234 Low priority items</li>
        </ul>
        
        <h3>Top Recommendations:</h3>
        <ol>
            <li>Enable Multi-Factor Authentication for all users</li>
            <li>Implement Data Loss Prevention policies</li>
            <li>Review and restrict external sharing settings</li>
            <li>Deploy sensitivity labels across all services</li>
            <li>Enable audit logging for all critical services</li>
        </ol>
    </div>
    
    <div class="score-card">
        <h2>Service Breakdown</h2>
        <table style="width: 100%; border-collapse: collapse;">
            <tr style="background: #f0f0f0;">
                <th style="padding: 10px; text-align: left;">Service</th>
                <th style="padding: 10px;">Score</th>
                <th style="padding: 10px;">Status</th>
            </tr>
            <tr>
                <td style="padding: 10px;">Microsoft Purview</td>
                <td style="padding: 10px; text-align: center;">65/100</td>
                <td style="padding: 10px; text-align: center; color: #ff8c00;">Needs Improvement</td>
            </tr>
            <tr style="background: #f9f9f9;">
                <td style="padding: 10px;">SharePoint Online</td>
                <td style="padding: 10px; text-align: center;">78/100</td>
                <td style="padding: 10px; text-align: center; color: #ffb900;">Fair</td>
            </tr>
            <tr>
                <td style="padding: 10px;">Microsoft Teams</td>
                <td style="padding: 10px; text-align: center;">82/100</td>
                <td style="padding: 10px; text-align: center; color: #107c10;">Good</td>
            </tr>
            <tr style="background: #f9f9f9;">
                <td style="padding: 10px;">Power Platform</td>
                <td style="padding: 10px; text-align: center;">45/100</td>
                <td style="padding: 10px; text-align: center; color: #d13438;">Critical</td>
            </tr>
        </table>
    </div>
</body>
</html>
"@
        
        $reportPath = "$PWD\Demo-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
        $sampleReport | Out-File -FilePath $reportPath -Encoding UTF8
        
        Write-Host "✅ Sample report generated: $reportPath" -ForegroundColor Green
        
        $open = Read-Host "`nOpen report in browser? (Y/N)"
        if ($open -eq 'Y') {
            Start-Process $reportPath
        }
    }
    
    "3" {
        # Create Demo Portal
        Write-Host "`n🌐 CREATING DEMO CLIENT PORTAL" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        # Simulate portal creation
        Write-Host "⚡ Generating secure portal..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Write-Host "🔐 Creating access token..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Write-Host "📊 Adding assessment results..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Write-Host "🎨 Applying branding..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        
        Write-Host "`n✅ Demo Portal Created!" -ForegroundColor Green
        Write-Host "`n📋 Portal Details:" -ForegroundColor White
        Write-Host "   URL: https://localhost:8443/portal/demo-$(Get-Random -Maximum 9999)" -ForegroundColor Cyan
        Write-Host "   Access Token: DEMO-$(Get-Random -Maximum 9999)-$(Get-Random -Maximum 9999)" -ForegroundColor Cyan
        Write-Host "   Valid Until: $((Get-Date).AddDays(7).ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
        
        Write-Host "`n📧 Email template generated with portal access instructions" -ForegroundColor Green
    }
    
    "4" {
        # Sample Questionnaire
        Write-Host "`n📝 SAMPLE DISCOVERY QUESTIONNAIRE" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        $questions = @(
            @{
                Question = "Does your organization have a data classification policy?"
                Options = @("Yes, fully implemented", "Yes, partially implemented", "In development", "No")
                BestPractice = "Organizations should have at least 3-5 classification levels"
            },
            @{
                Question = "Is Multi-Factor Authentication enforced for all users?"
                Options = @("Yes, for all users", "Yes, for admins only", "Partially", "No")
                BestPractice = "MFA should be enforced for all users per NIST guidelines"
            },
            @{
                Question = "How often are security assessments performed?"
                Options = @("Quarterly", "Bi-annually", "Annually", "Ad-hoc only")
                BestPractice = "Security assessments should be performed at least quarterly"
            }
        )
        
        foreach ($q in $questions) {
            Write-Host "`n❓ $($q.Question)" -ForegroundColor Yellow
            for ($i = 0; $i -lt $q.Options.Count; $i++) {
                Write-Host "   $($i+1). $($q.Options[$i])" -ForegroundColor White
            }
            Write-Host "`n💡 Best Practice: $($q.BestPractice)" -ForegroundColor DarkGray
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Read-Host "Press Enter to continue"
        }
        
        Write-Host "`n✅ Questionnaire responses would be saved for assessment input" -ForegroundColor Green
    }
    
    "7" {
        # Full Demo Sequence
        Write-Host "`n🎬 RUNNING FULL DEMO SEQUENCE" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        # Step 1: Authentication
        Write-Host "`n[Step 1/5] 🔐 Simulating Authentication..." -ForegroundColor Yellow
        Write-Progress -Activity "Demo Sequence" -Status "Authenticating" -PercentComplete 20
        Start-Sleep -Seconds 2
        Write-Host "✅ Successfully authenticated to demo tenant" -ForegroundColor Green
        
        # Step 2: Module Selection
        Write-Host "`n[Step 2/5] 📋 Module Selection..." -ForegroundColor Yellow
        Write-Progress -Activity "Demo Sequence" -Status "Selecting Modules" -PercentComplete 40
        Write-Host "   ✓ Purview Assessment" -ForegroundColor Green
        Write-Host "   ✓ SharePoint Assessment" -ForegroundColor Green
        Write-Host "   ✓ Teams Assessment" -ForegroundColor Green
        Write-Host "   ✓ Power Platform Assessment" -ForegroundColor Green
        Start-Sleep -Seconds 2
        
        # Step 3: Assessment
        Write-Host "`n[Step 3/5] 🔍 Running Assessment..." -ForegroundColor Yellow
        Write-Progress -Activity "Demo Sequence" -Status "Assessing Services" -PercentComplete 60
        
        $services = @("Purview", "SharePoint", "Teams", "Power Platform")
        foreach ($service in $services) {
            Write-Host "   ⚡ Assessing $service..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
        }
        
        # Step 4: Analysis
        Write-Host "`n[Step 4/5] 📊 Analyzing Results..." -ForegroundColor Yellow
        Write-Progress -Activity "Demo Sequence" -Status "Analyzing Findings" -PercentComplete 80
        Start-Sleep -Seconds 2
        Write-Host "   Found: 12 Critical | 47 High | 123 Medium | 234 Low" -ForegroundColor White
        
        # Step 5: Report Generation
        Write-Host "`n[Step 5/5] 📄 Generating Reports..." -ForegroundColor Yellow
        Write-Progress -Activity "Demo Sequence" -Status "Creating Reports" -PercentComplete 100
        Start-Sleep -Seconds 2
        Write-Progress -Activity "Demo Sequence" -Completed
        
        Write-Host "`n✅ DEMO COMPLETE!" -ForegroundColor Green
        Write-Host @"

📊 Demo Results Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Security Score: 72/100
Critical Findings: 12
Time Taken: 5 minutes (actual assessment: 10-30 minutes)
Reports Generated: 4 (Executive, Technical, Evidence, Portal)

💡 In a real assessment, you would:
- Connect to actual Microsoft 365 tenants
- Gather real configuration data
- Generate evidence with screenshots
- Create secure portals for clients
- Export detailed remediation roadmaps
"@ -ForegroundColor White
    }
}

Write-Host "`n🎯 To run the actual assessment on your tenant:" -ForegroundColor Yellow
Write-Host "   .\Start-PowerReview.ps1" -ForegroundColor Cyan
Write-Host "`n📚 For more information:" -ForegroundColor Yellow
Write-Host "   See README.md and DEMO-WALKTHROUGH.md" -ForegroundColor Cyan