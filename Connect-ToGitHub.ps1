# Simple GitHub Connection Script

Write-Host "🔗 Connecting PowerReview to GitHub" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Check if git is installed
try {
    git --version | Out-Null
    Write-Host "✅ Git is installed" -ForegroundColor Green
}
catch {
    Write-Host "❌ Git is not installed. Please install from: https://git-scm.com/" -ForegroundColor Red
    exit
}

# Initialize repository if not already
if (!(Test-Path ".git")) {
    Write-Host "`nInitializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Repository initialized" -ForegroundColor Green
}

# Get GitHub username
$username = Read-Host "`nEnter your GitHub username"
$repoName = Read-Host "Enter repository name (default: PowerReview)"
if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "PowerReview"
}

Write-Host "`n📝 Creating .gitignore..." -ForegroundColor Yellow
@"
# Output directories
*-Results/
*-Output/

# Sensitive files
*.key
*.pfx
secrets.json
*-credentials.json

# Temporary files
*.tmp
*.log

# OS files
.DS_Store
Thumbs.db
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# Add all files
Write-Host "`n📦 Adding files to Git..." -ForegroundColor Yellow
git add .

# Create commit
Write-Host "💾 Creating initial commit..." -ForegroundColor Yellow
git commit -m "Initial commit: PowerReview Assessment Framework with Discovery Questionnaires"

# Add remote
Write-Host "`n🌐 Adding GitHub remote..." -ForegroundColor Yellow
$remoteUrl = "https://github.com/$username/$repoName.git"
git remote add origin $remoteUrl

# Rename branch to main
git branch -M main

Write-Host @"

✅ Local setup complete!

Next steps:
1. Create a new repository on GitHub:
   - Go to: https://github.com/new
   - Name: $repoName
   - Keep it empty (no README, .gitignore, or license)
   
2. After creating the repository, run:
   git push -u origin main

If you get authentication errors, you'll need a Personal Access Token:
   - Go to: https://github.com/settings/tokens
   - Generate new token with 'repo' scope
   - Use the token as your password

"@ -ForegroundColor Green

$ready = Read-Host "`nHave you created the GitHub repository? (Y/N)"
if ($ready -eq 'Y') {
    Write-Host "`n🚀 Pushing to GitHub..." -ForegroundColor Yellow
    git push -u origin main
}