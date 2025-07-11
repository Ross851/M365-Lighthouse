#Requires -Version 7.0

<#
.SYNOPSIS
    Deploy PowerReview to GitHub
.DESCRIPTION
    Helper script to deploy PowerReview to GitHub repository
.NOTES
    Version: 1.0
#>

param(
    [string]$GitHubUsername,
    [string]$RepositoryName = "PowerReview",
    [switch]$Public = $false
)

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        🚀 DEPLOY POWERREVIEW TO GITHUB 🚀                     ║
║                                                                               ║
║                          Push your code to GitHub repository                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if we're in a git repository
if (!(Test-Path .git)) {
    Write-Host "❌ Not in a Git repository! Run this from the PowerReview directory." -ForegroundColor Red
    exit 1
}

# Get GitHub username if not provided
if (!$GitHubUsername) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

# Check current status
Write-Host "`n📊 Checking repository status..." -ForegroundColor Yellow
git status --short

# Check if we have a remote
$remotes = git remote
if ($remotes -contains "origin") {
    Write-Host "`n⚠️  Remote 'origin' already exists!" -ForegroundColor Yellow
    $existingUrl = git remote get-url origin
    Write-Host "   Current URL: $existingUrl" -ForegroundColor Gray
    
    $update = Read-Host "`nUpdate remote URL? (Y/N)"
    if ($update -eq 'Y') {
        $newUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
        git remote set-url origin $newUrl
        Write-Host "✅ Remote URL updated to: $newUrl" -ForegroundColor Green
    }
} else {
    # Add remote
    $remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
    Write-Host "`n🔗 Adding remote repository..." -ForegroundColor Yellow
    Write-Host "   URL: $remoteUrl" -ForegroundColor Gray
    git remote add origin $remoteUrl
}

# Instructions for creating repository
Write-Host @"

📋 BEFORE PUSHING - Create Repository on GitHub:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to: https://github.com/new
2. Repository name: $RepositoryName
3. Description: Enterprise Microsoft 365 & Azure Security Assessment Framework
4. Visibility: $(if($Public){"Public"}else{"Private"})
5. DO NOT initialize with README, .gitignore, or license
6. Click 'Create repository'

"@ -ForegroundColor Yellow

$created = Read-Host "Have you created the repository on GitHub? (Y/N)"

if ($created -ne 'Y') {
    Write-Host "`n⏸️  Deployment paused. Create the repository first, then run this script again." -ForegroundColor Yellow
    exit 0
}

# Push to GitHub
Write-Host "`n🚀 Pushing to GitHub..." -ForegroundColor Cyan

try {
    # Push main branch
    git push -u origin main
    
    Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                          ✅ DEPLOYMENT SUCCESSFUL! ✅                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🎉 PowerReview has been deployed to GitHub!

📍 Repository URL: https://github.com/$GitHubUsername/$RepositoryName

📋 Next Steps:
1. Go to your repository: https://github.com/$GitHubUsername/$RepositoryName
2. Add topics: powershell, microsoft-365, azure, security-assessment
3. Configure branch protection for 'main'
4. Enable security features (Settings → Security)
5. Create first release (v1.0.0)

🔒 Security Reminders:
- Never commit secrets or credentials
- Keep client data out of the repository
- Review commits before pushing

📚 Optional Enhancements:
- Add GitHub Actions for CI/CD
- Enable Issues and Discussions
- Create a project board for roadmap
- Set up GitHub Pages for documentation

🌟 Make it discoverable:
- Star your own repository
- Add a good description
- Create comprehensive Wiki pages
- Share with the community

"@ -ForegroundColor Green

    # Open repository in browser
    $openBrowser = Read-Host "`nOpen repository in browser? (Y/N)"
    if ($openBrowser -eq 'Y') {
        Start-Process "https://github.com/$GitHubUsername/$RepositoryName"
    }

} catch {
    Write-Host "`n❌ Push failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    Write-Host @"

🔧 Troubleshooting:
1. Ensure you've created the repository on GitHub
2. Check your GitHub credentials:
   - Use Personal Access Token (PAT) as password
   - Go to: https://github.com/settings/tokens
   - Create token with 'repo' scope
3. Try pushing manually:
   git push -u origin main

"@ -ForegroundColor Yellow
}

# Create a quick reference card
$quickRef = @"
# PowerReview GitHub Quick Reference

## Repository URLs
- HTTPS: https://github.com/$GitHubUsername/$RepositoryName.git
- Web: https://github.com/$GitHubUsername/$RepositoryName

## Common Commands
- Update code: git pull
- Check status: git status
- Add changes: git add .
- Commit: git commit -m "Description"
- Push: git push

## Creating a Release
1. Go to: https://github.com/$GitHubUsername/$RepositoryName/releases/new
2. Tag: v1.0.0
3. Title: PowerReview v1.0.0 - Initial Release
4. Describe features and changes
5. Attach any binaries if needed
6. Publish release

## Accepting Contributions
1. Fork workflow is standard
2. Require pull requests for changes
3. Use issues for bug tracking
4. Enable discussions for Q&A
"@

$quickRef | Out-File -FilePath "GITHUB-QUICK-REFERENCE.md" -Encoding UTF8
Write-Host "`n📄 Created GITHUB-QUICK-REFERENCE.md for your reference" -ForegroundColor Cyan