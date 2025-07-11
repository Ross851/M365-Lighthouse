# PowerReview Vercel Deployment Script
Write-Host "🚀 Deploying PowerReview Dashboard to Vercel..." -ForegroundColor Cyan

# Check if npm is installed
if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ npm is not installed. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Navigate to web directory
Set-Location $PSScriptRoot

# Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install

# Install Vercel CLI
Write-Host "`n🔧 Installing Vercel CLI..." -ForegroundColor Yellow
npm install -g vercel

# Deploy
Write-Host "`n🚀 Deploying to Vercel..." -ForegroundColor Cyan
Write-Host "Follow the prompts:" -ForegroundColor Yellow
Write-Host "1. Set up and deploy: Yes" -ForegroundColor Gray
Write-Host "2. Scope: Select your account" -ForegroundColor Gray
Write-Host "3. Link to existing project: No" -ForegroundColor Gray
Write-Host "4. Project name: powerreview-m365 (or your choice)" -ForegroundColor Gray
Write-Host "5. Directory: ./ (current)" -ForegroundColor Gray
Write-Host "6. Override settings: No" -ForegroundColor Gray

vercel

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "Your dashboard is now live on Vercel!" -ForegroundColor Green