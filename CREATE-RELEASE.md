# 🏷️ Create GitHub Release v2.0.0

## Steps to Create Release:

1. **Go to Releases Page**:
   https://github.com/Ross851/M365-Lighthouse/releases/new

2. **Fill in Release Details**:
   - **Tag**: `v2.0.0`
   - **Target**: `main`
   - **Release Title**: `PowerReview v2.0.0 - Web Dashboard Release`

3. **Release Description** (copy this):

```markdown
# 🚀 PowerReview v2.0.0 - Web Dashboard Release

## 🎉 Major Update: Web-Based Dashboard

We're excited to announce PowerReview v2.0.0, featuring a brand new web-based dashboard deployed on Vercel!

### 🌐 Live Demo
Visit our dashboard: [PowerReview Dashboard](https://m365-lighthouse-ni9k.vercel.app)

### ✨ What's New in v2.0.0

#### Web Dashboard Features:
- 🔐 **Authentication System** - Secure login with demo credentials
- 📊 **Interactive Dashboard** - Real-time metrics and visualizations
- 🔍 **Assessment Execution** - Run assessments with live progress tracking
- 📝 **Discovery Questionnaire** - Interactive Q&A with best practices
- 📤 **Export Functionality** - Generate PDF, Excel, and PowerBI reports
- 🎯 **Single-Page Demo** - Full functionality at `/demo` route
- 📱 **Responsive Design** - Works on all devices

#### Technical Improvements:
- Next.js 13.5.6 for modern web experience
- Static export for Vercel deployment
- Client-side routing for better performance
- Version tracking system implemented

### 🚀 Getting Started

1. **Try the Live Demo**:
   - Visit: https://m365-lighthouse-ni9k.vercel.app/demo
   - Login: `admin` / `PowerReview2024`

2. **Run Locally**:
   ```bash
   git clone https://github.com/Ross851/M365-Lighthouse.git
   cd M365-Lighthouse
   ./Start-PowerReview.ps1
   ```

3. **Deploy Your Own**:
   ```bash
   cd web
   npm install
   vercel
   ```

### 📋 Full Changelog
See [CHANGELOG.md](https://github.com/Ross851/M365-Lighthouse/blob/main/CHANGELOG.md) for detailed changes.

### 🙏 Thank You
Thanks to everyone who contributed to making PowerReview better!

---
*PowerReview - Enterprise Microsoft 365 & Azure Security Assessment Framework*
```

4. **Attach Assets** (optional):
   - You can attach ZIP of the PowerShell scripts
   - Or deployment guide PDFs

5. **Click "Publish release"**

## 🏷️ Version Tags

- Current: `v2.0.0` - Web Dashboard
- Previous: `v1.5.0` - Enhanced Features
- Initial: `v1.0.0` - Core Framework

## 📊 Semantic Versioning

We follow semantic versioning:
- **Major** (X.0.0): Breaking changes or major features
- **Minor** (0.X.0): New features, backwards compatible
- **Patch** (0.0.X): Bug fixes and minor improvements