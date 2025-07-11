#Requires -Version 7.0

<#
.SYNOPSIS
    Setup GitHub connection for PowerReview framework
.DESCRIPTION
    Initializes Git repository and connects to GitHub for the PowerReview project
.NOTES
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "PowerReview",
    
    [Parameter(Mandatory=$false)]
    [string]$BranchName = "main",
    
    [switch]$InitializeRepo = $true,
    [switch]$CreateGitIgnore = $true,
    [switch]$CreateReadme = $true
)

# Function to check if Git is installed
function Test-GitInstalled {
    try {
        $null = git --version
        return $true
    }
    catch {
        Write-Host "❌ Git is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Git from https://git-scm.com/" -ForegroundColor Yellow
        return $false
    }
}

# Function to check if we're in a Git repository
function Test-GitRepository {
    try {
        $null = git rev-parse --git-dir 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Main setup process
Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        🔗 POWERREVIEW GITHUB SETUP 🔗                         ║
║                                                                               ║
║                    Connect your PowerReview project to GitHub                  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check Git installation
if (-not (Test-GitInstalled)) {
    exit 1
}

# Get GitHub username if not provided
if (-not $GitHubUsername) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

# Initialize Git repository if needed
if ($InitializeRepo -and -not (Test-GitRepository)) {
    Write-Host "`n📁 Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

# Create .gitignore file
if ($CreateGitIgnore) {
    Write-Host "`n📝 Creating .gitignore file..." -ForegroundColor Yellow
    
    $gitignoreContent = @"
# PowerReview Ignore File

# Output directories
Discovery-Results/
PowerReview-Results/
EC-Discovery-Results/
PowerReview-Output/
Assessment-Results/

# Sensitive files
*.key
*.pfx
*.cer
secrets.json
config.secure.json

# User-specific files
local.settings.json
personal-config.json

# Temporary files
*.tmp
*.temp
*.log
~$*

# Encrypted vault files
*.vault
*.encrypted

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# PowerShell specific
*.ps1xml
Export-*/

# Credentials and tokens
*-credentials.json
*-token.txt
client_secret*

# Backup files
*.bak
*.backup
*_backup/

# Test results
TestResults/
*.trx
"@
    
    $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Host "✅ .gitignore created" -ForegroundColor Green
}

# Create README if needed
if ($CreateReadme) {
    Write-Host "`n📄 Creating README.md..." -ForegroundColor Yellow
    
    $readmeContent = @"
# 🚀 PowerReview - Microsoft 365 & Azure Assessment Framework

A comprehensive assessment tool for Microsoft 365 and Azure environments, focusing on security, compliance, and best practices.

## 📋 Overview

PowerReview is an enterprise-grade assessment framework that evaluates:
- **Microsoft Purview** - Data governance, compliance, and information protection
- **Power Platform** - Apps, flows, and governance
- **SharePoint/Teams/OneDrive** - Collaboration security and configuration
- **Azure Landing Zone** - Multi-tenant Azure infrastructure
- **Security & Compliance** - Comprehensive security posture

## 🎯 Key Features

- **Discovery Questionnaire System** - Interactive wizard for gathering requirements
- **Multi-Tenant Support** - Assess multiple tenants in a single run
- **Deep Analysis Modes** - Basic, Standard, Deep, and Forensic analysis levels
- **Professional UI/UX** - Wizard-style interface with progress tracking
- **Secure Client Portal** - Executive-friendly reports with evidence
- **Compliance Mapping** - GDPR, HIPAA, ISO 27001, NIST frameworks
- **Best Practice Recommendations** - Actionable insights with justification

## 🚦 Getting Started

### Prerequisites
- PowerShell 7.0 or higher
- Microsoft 365 Global Admin or equivalent permissions
- Azure AD Application with appropriate permissions

### Quick Start
```powershell
# Run the main wizard
.\Start-PowerReview.ps1

# Run with discovery questionnaire
.\PowerReview-Questionnaire-Integration.ps1
Start-PowerReviewWithDiscovery

# Run Electoral Commission template
.\Electoral-Commission-Questionnaire.ps1
Start-ElectoralCommissionQuestionnaire
```

## 📁 Project Structure

```
PowerReview/
├── Core Assessment Scripts
│   ├── PowerReview-Complete.ps1           # Main assessment engine
│   ├── PowerReview-Enhanced-Framework.ps1 # Advanced framework with deep analysis
│   └── Start-PowerReview.ps1             # Professional wizard interface
│
├── Discovery & Questionnaires
│   ├── PowerReview-Discovery-Questionnaire.ps1    # Base questionnaire framework
│   ├── Electoral-Commission-Questionnaire.ps1     # Comprehensive EC template
│   └── PowerReview-Questionnaire-Integration.ps1  # Integration module
│
├── UI & Reporting
│   ├── PowerReview-UI-Components.ps1      # Reusable UI components
│   ├── PowerReview-Dashboard.ps1          # Executive dashboard
│   └── PowerReview-Client-Portal.ps1      # Secure client portal generator
│
├── Configuration
│   ├── Multi-Tenant-Config-Template.json  # Multi-tenant configuration
│   └── DEPLOYMENT-GUIDE.md               # Deployment best practices
│
└── Setup & Utilities
    └── Setup-GitHubConnection.ps1        # GitHub setup script
```

## 🔧 Configuration

### Multi-Tenant Setup
Edit `Multi-Tenant-Config-Template.json`:
```json
{
  "Tenants": [
    {
      "Name": "Contoso Production",
      "TenantId": "your-tenant-id",
      "Environment": "Production"
    }
  ]
}
```

### Authentication Methods
- Certificate-based (recommended)
- Client Secret
- Interactive (for testing)

## 🛡️ Security Features

- **Encrypted Storage** - Machine-specific encryption for sensitive data
- **Secure Authentication** - Certificate-based auth with PIM support
- **Audit Logging** - Complete audit trail of all operations
- **Token-based Portal Access** - Time-limited secure URLs
- **Data Classification** - Automatic sensitivity labeling

## 📊 Reports & Outputs

1. **Technical Assessment Report** - Detailed findings with evidence
2. **Executive Summary** - High-level dashboard with KPIs
3. **Compliance Report** - Mapping to regulatory frameworks
4. **Client Portal** - Interactive HTML portal with:
   - Finding details with evidence
   - Best practice justifications
   - Remediation roadmaps
   - Risk scoring

## 🚀 Advanced Usage

### Custom Questionnaires
```powershell
# Add custom questions
Add-DiscoveryQuestion -Category "Security" -Question @{
    ID = "SEC-001"
    Question = "Describe your incident response process"
    Type = "Text"
    Required = $true
    Hint = "Include escalation procedures"
}
```

### Deep Analysis Mode
```powershell
# Run with forensic analysis
.\PowerReview-Enhanced-Framework.ps1
Invoke-PowerReviewAssessment -AnalysisLevel "Forensic"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: See `/docs` folder
- **Issues**: Report issues on GitHub
- **Contact**: powerreview-support@example.com

## 🏆 Acknowledgments

- Based on Microsoft best practices
- Electoral Commission discovery framework
- Community feedback and contributions

---

**Created by**: PowerReview Team  
**Version**: 1.0  
**Last Updated**: $(Get-Date -Format "MMMM dd, yyyy")
"@
    
    $readmeContent | Out-File -FilePath "README.md" -Encoding UTF8
    Write-Host "✅ README.md created" -ForegroundColor Green
}

# Add all files to staging
Write-Host "`n📦 Adding files to Git..." -ForegroundColor Yellow
git add .

# Show status
Write-Host "`n📊 Git Status:" -ForegroundColor Cyan
git status --short

# Create initial commit
$commitMessage = "Initial commit: PowerReview Assessment Framework

- Core assessment scripts for M365 and Azure
- Discovery questionnaire system with EC template
- Professional UI/UX with wizard interface
- Secure client portal generator
- Multi-tenant support
- Compliance frameworks integration"

Write-Host "`n💾 Creating initial commit..." -ForegroundColor Yellow
git commit -m $commitMessage

# Set up remote repository
Write-Host "`n🌐 Setting up GitHub remote..." -ForegroundColor Yellow
Write-Host "Repository will be: https://github.com/$GitHubUsername/$RepositoryName" -ForegroundColor Cyan

$createNew = Read-Host "`nHave you created this repository on GitHub? (Y/N)"

if ($createNew -eq 'N') {
    Write-Host @"

Please create a new repository on GitHub:
1. Go to https://github.com/new
2. Repository name: $RepositoryName
3. Make it Private or Public as needed
4. Do NOT initialize with README, .gitignore, or license
5. Click 'Create repository'

Press Enter when done...
"@ -ForegroundColor Yellow
    Read-Host
}

# Add remote origin
$remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
Write-Host "`n🔗 Adding remote origin..." -ForegroundColor Yellow
git remote add origin $remoteUrl

# Rename branch if needed
if ($BranchName -ne "master") {
    Write-Host "`n🌿 Renaming branch to $BranchName..." -ForegroundColor Yellow
    git branch -M $BranchName
}

# Push to GitHub
Write-Host "`n🚀 Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "You may be prompted for your GitHub credentials." -ForegroundColor Cyan

try {
    git push -u origin $BranchName
    Write-Host "`n✅ Successfully pushed to GitHub!" -ForegroundColor Green
}
catch {
    Write-Host "`n⚠️ Push failed. You may need to:" -ForegroundColor Yellow
    Write-Host "1. Set up GitHub Personal Access Token (PAT)" -ForegroundColor White
    Write-Host "2. Configure Git credentials" -ForegroundColor White
    Write-Host "3. Check repository permissions" -ForegroundColor White
    
    Write-Host "`nTo set up PAT:" -ForegroundColor Cyan
    Write-Host "1. Go to https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "2. Generate new token with 'repo' scope" -ForegroundColor White
    Write-Host "3. Use token as password when prompted" -ForegroundColor White
}

# Create useful Git aliases
Write-Host "`n⚙️ Setting up useful Git aliases..." -ForegroundColor Yellow
git config alias.st "status --short"
git config alias.cm "commit -m"
git config alias.co "checkout"
git config alias.br "branch"
git config alias.last "log -1 HEAD"
git config alias.visual "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Create development branch
$createDev = Read-Host "`nCreate development branch? (Y/N)"
if ($createDev -eq 'Y') {
    git checkout -b development
    git push -u origin development
    git checkout $BranchName
    Write-Host "✅ Development branch created" -ForegroundColor Green
}

# Show summary
Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                           ✅ GITHUB SETUP COMPLETE! ✅                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Your PowerReview project is now connected to GitHub!

📦 Repository: https://github.com/$GitHubUsername/$RepositoryName
🌿 Branch: $BranchName
📁 Files: $(git ls-files | Measure-Object | Select-Object -ExpandProperty Count) files tracked

Useful Git Commands:
  git st          - Short status
  git cm "msg"    - Quick commit
  git visual      - Pretty log view
  git push        - Push changes
  git pull        - Pull changes

Next Steps:
1. Share repository with team members
2. Set up branch protection rules
3. Configure GitHub Actions for CI/CD
4. Add additional documentation

"@ -ForegroundColor Green

# Create GitHub Actions workflow
$createActions = Read-Host "`nSet up GitHub Actions workflow? (Y/N)"
if ($createActions -eq 'Y') {
    New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null
    
    $workflowContent = @"
name: PowerReview CI

on:
  push:
    branches: [ main, development ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        Install-Module -Name PSScriptAnalyzer -Force
        Invoke-ScriptAnalyzer -Path . -Recurse -OutputFormat GitHub
    
    - name: Test PowerShell Scripts
      shell: pwsh
      run: |
        `$scripts = Get-ChildItem -Path . -Filter *.ps1 -Recurse
        foreach (`$script in `$scripts) {
          Write-Host "Testing `$(`$script.Name)..."
          powershell -File `$script.FullName -WhatIf
        }
"@
    
    $workflowContent | Out-File -FilePath ".github\workflows\ci.yml" -Encoding UTF8
    git add .github/workflows/ci.yml
    git commit -m "Add GitHub Actions workflow"
    git push
    
    Write-Host "✅ GitHub Actions workflow created" -ForegroundColor Green
}