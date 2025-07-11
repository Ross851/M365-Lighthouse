#Requires -Version 7.0

<#
.SYNOPSIS
    Post-deployment GitHub repository setup
.DESCRIPTION
    Helps configure your GitHub repository after initial push
#>

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    🚀 GITHUB REPOSITORY CONFIGURATION 🚀                      ║
║                                                                               ║
║                    Configure your M365-Lighthouse repository                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n📋 POST-PUSH CONFIGURATION CHECKLIST:" -ForegroundColor Yellow

Write-Host @"

1. ADD REPOSITORY TOPICS
   Go to: https://github.com/Ross851/M365-Lighthouse
   Click Settings (gear icon) → Add topics:
   - microsoft-365
   - azure
   - security-assessment
   - powershell
   - compliance
   - purview
   - sharepoint
   - teams

2. UPDATE REPOSITORY DESCRIPTION
   "Enterprise Microsoft 365 & Azure Security Assessment Framework - PowerReview"

3. CONFIGURE SECURITY SETTINGS
   Settings → Security & analysis:
   - Enable Dependabot alerts
   - Enable Dependabot security updates
   - Enable secret scanning
   - Enable code scanning

4. SET UP BRANCH PROTECTION
   Settings → Branches → Add rule:
   - Branch name pattern: main
   - ✅ Require pull request reviews
   - ✅ Dismiss stale pull request approvals
   - ✅ Require branches to be up to date

5. CREATE YOUR FIRST RELEASE
   Go to: https://github.com/Ross851/M365-Lighthouse/releases/new
   - Tag: v1.0.0
   - Target: main
   - Title: PowerReview v1.0.0 - Initial Release
   - Description: See template below

6. ENABLE GITHUB FEATURES
   Settings → General:
   - ✅ Issues
   - ✅ Discussions
   - ✅ Projects
   - ✅ Wiki

"@ -ForegroundColor White

Write-Host "`n📝 RELEASE DESCRIPTION TEMPLATE:" -ForegroundColor Yellow
Write-Host @"

# 🚀 PowerReview v1.0.0 - Initial Release

## 🎯 Overview
Enterprise-grade Microsoft 365 and Azure security assessment framework designed for multi-tenant environments.

## ✨ Key Features
- **Multi-tenant Assessment** - Assess up to 10 tenants in parallel
- **Comprehensive Coverage** - Purview, Power Platform, SharePoint/Teams/OneDrive, Azure
- **Professional UI** - Wizard-style interface with progress tracking
- **Secure Client Portals** - Time-limited access with evidence-based findings
- **Discovery Questionnaires** - Based on Electoral Commission standards
- **Role-Based Access** - 7 pre-defined roles with granular permissions
- **Enterprise Security** - AES-256 encryption, audit logging, compliance ready

## 📋 Modules Included
- Core assessment engine (PowerReview-Complete.ps1)
- Enhanced framework with deep analysis
- Interactive wizard interface
- Client portal generation
- Discovery questionnaire system
- Role-based access control
- Security configuration tools
- Multi-tenant execution framework

## 🚀 Getting Started
\`\`\`powershell
# Quick start
./QUICK-START-WORKSHOP.ps1

# Or manual setup
./Start-PowerReview.ps1
\`\`\`

## 📚 Documentation
- [Deployment Guide](./DEPLOYMENT-GUIDE.md)
- [Developer Guide](./DEVELOPER-IMPLEMENTATION-GUIDE.md)
- [Where to Run](./WHERE-TO-RUN-POWERREVIEW.md)

## 🔒 Security
- All sensitive data encrypted with AES-256
- Certificate-based authentication supported
- Comprehensive audit logging
- No hard-coded credentials or tenant information

## 🙏 Acknowledgments
Thanks to the Microsoft Security team and PowerShell community for guidance and best practices.

"@ -ForegroundColor Gray

# Create GitHub Actions workflow
$workflowPath = ".github/workflows"
if (!(Test-Path $workflowPath)) {
    New-Item -ItemType Directory -Path $workflowPath -Force | Out-Null
}

$ciYaml = @'
name: PowerReview CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  analyze:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
        $results = Invoke-ScriptAnalyzer -Path . -Recurse -ExcludeRule PSAvoidUsingWriteHost
        if ($results) {
          $results | Format-Table -AutoSize
          throw "PSScriptAnalyzer found issues"
        }
    
    - name: Check PowerShell version compatibility
      shell: pwsh
      run: |
        $files = Get-ChildItem -Path . -Filter *.ps1 -Recurse
        foreach ($file in $files) {
          $content = Get-Content $file.FullName -Raw
          if ($content -notmatch '#Requires -Version 7') {
            Write-Warning "$($file.Name) missing PowerShell 7 requirement"
          }
        }
'@

$ciYaml | Out-File -FilePath "$workflowPath/ci.yml" -Encoding UTF8

Write-Host "`n✅ Created GitHub Actions workflow at .github/workflows/ci.yml" -ForegroundColor Green
Write-Host "   Don't forget to commit and push this file!" -ForegroundColor Yellow

Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Complete GitHub authentication (see GITHUB-AUTH-INSTRUCTIONS.md)" -ForegroundColor White
Write-Host "2. Push your code: git push -u origin main" -ForegroundColor White
Write-Host "3. Follow the checklist above to configure your repository" -ForegroundColor White
Write-Host "4. Create your first release" -ForegroundColor White
Write-Host "5. Share with your team!" -ForegroundColor White

Write-Host "`n📎 Quick Links:" -ForegroundColor Yellow
Write-Host "Repository: https://github.com/Ross851/M365-Lighthouse" -ForegroundColor Cyan
Write-Host "Settings: https://github.com/Ross851/M365-Lighthouse/settings" -ForegroundColor Cyan
Write-Host "New Release: https://github.com/Ross851/M365-Lighthouse/releases/new" -ForegroundColor Cyan

$openBrowser = Read-Host "`nOpen repository in browser? (Y/N)"
if ($openBrowser -eq 'Y') {
    Start-Process "https://github.com/Ross851/M365-Lighthouse"
}