# PowerReview Enhanced Implementation Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Feature Implementation](#feature-implementation)
7. [Deployment](#deployment)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)

## 🎯 Overview

PowerReview Enhanced is a comprehensive Microsoft 365 security assessment platform that provides:

- **Automated Security Assessments** - PowerShell scripts analyze M365 configurations
- **AI-Powered Analysis** - MCP servers provide intelligent recommendations
- **Executive Reporting** - Professional reports with Gold/Silver/Bronze recommendations
- **Real-Time Monitoring** - Threat intelligence and security hardening
- **Multi-Region Support** - Global compliance and data sovereignty
- **Parallel Execution** - Run multiple scripts simultaneously for faster assessments

### Access Model
- **Developers/Admins** - Full authentication required, access to all features
- **Clients** - No login required, can view reports and dashboards

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Astro.js)                   │
├─────────────────────────┬───────────────────────────────────┤
│     Authentication      │          Public Access            │
│   (Developers Only)     │      (Clients - No Auth)         │
├─────────────────────────┴───────────────────────────────────┤
│                    API Layer (TypeScript)                    │
├──────────────┬──────────────┬───────────────┬──────────────┤
│  PowerShell  │     MCP      │   Database    │   Storage    │
│   Scripts    │   Servers    │ (PostgreSQL)  │  (Encrypted) │
└──────────────┴──────────────┴───────────────┴──────────────┘
```

### Technology Stack
- **Frontend**: Astro.js, TypeScript, Chart.js
- **Backend**: Node.js, Express, WebSocket
- **Database**: PostgreSQL with encryption
- **Scripts**: PowerShell 7+
- **AI/MCP**: Sequential Thinking, GitHub, Filesystem MCPs
- **Deployment**: Vercel (frontend), Azure (backend)

## 📋 Prerequisites

### Required Software
```bash
# Core Requirements
- Node.js 18+ 
- PowerShell 7+
- Git
- PostgreSQL 14+
- Python 3.8+ (for MCP servers)

# Optional but Recommended
- Docker (for containerized deployment)
- Azure CLI (for cloud deployment)
- VS Code (for development)
```

### Required Accounts
- GitHub account (for version control)
- Vercel account (for frontend deployment)
- Microsoft 365 admin access (for assessments)
- Azure account (optional, for backend)

## 🚀 Installation

### 1. Clone Repository
```bash
git clone https://github.com/Ross851/M365-Lighthouse.git
cd M365-Lighthouse/powerreview-ui
```

### 2. Install Dependencies
```bash
# Install Node dependencies
npm install

# Install Python dependencies for MCP
pip install -r mcp/sequential-thinking/requirements.txt
```

### 3. Database Setup
```bash
# Run PostgreSQL setup script
npm run setup:db

# Run migrations
npm run db:migrate

# Test connection
npm run db:test
```

### 4. Environment Configuration
```bash
# Copy example environment file
cp .env.example .env.development

# Edit with your settings
nano .env.development
```

Required environment variables:
```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/powerreview_dev
DB_ENCRYPTION_KEY=your-32-character-encryption-key

# Authentication
JWT_SECRET=your-jwt-secret
AUTH_DOMAIN=your-auth-domain

# Microsoft 365
TENANT_ID=your-tenant-id
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret

# MCP Servers
GITHUB_TOKEN=your-github-token
MCP_SERVER_PORT=3002

# External APIs
VIRUSTOTAL_API_KEY=your-vt-key
ABUSEIPDB_API_KEY=your-abuse-key
```

## ⚙️ Configuration

### 1. PowerShell Scripts Configuration
Edit script parameters in each PowerReview-*.ps1 file:
```powershell
# Example: PowerReview-AzureAD.ps1
$Script:Config = @{
    MaxDaysInactive = 90
    RequireMFA = $true
    ExportPath = "./exports"
}
```

### 2. MCP Server Configuration
Configure MCP servers in `mcp.json`:
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "python",
      "args": ["./mcp/sequential-thinking/main.py"],
      "description": "Parallel script execution"
    }
  }
}
```

### 3. Security Hardening Configuration
Edit `src/config/security-config.ts`:
```typescript
export const securityConfig = {
  session: {
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    secure: true,
    httpOnly: true
  },
  rateLimit: {
    windowMs: 15 * 60 * 1000,
    max: 100
  }
};
```

## 🛠️ Feature Implementation

### 1. Running Assessments

#### Single Script Execution
```typescript
// Execute a single PowerShell script
const result = await executePowerShellScript({
  script: 'PowerReview-AzureAD.ps1',
  parameters: {
    TenantName: 'contoso',
    ExportResults: true
  }
});
```

#### Parallel Execution (Multiple Scripts)
```typescript
// Execute multiple scripts simultaneously
import { parallelExecutor } from './lib/parallel-executor';

const assessment = await parallelExecutor.runAssessment('full', {
  TenantName: 'contoso',
  SkipSharePoint: false
});

// Scripts run in priority groups:
// Priority 1: AzureAD + Exchange (parallel)
// Priority 2: SharePoint + Teams (parallel)
// Priority 3: Defender + Compliance + Intune (parallel)
```

### 2. Report Generation

#### Generate Executive Report
```typescript
const report = await generateReport({
  type: 'executive',
  organization: 'contoso',
  data: assessmentResults,
  format: 'pdf'
});
```

#### Available Report Types
- **Executive Summary** - High-level overview with recommendations
- **Technical Analysis** - Detailed findings with remediation scripts
- **Compliance Report** - Framework compliance status (GDPR, ISO, etc.)
- **Security Assessment** - Comprehensive security posture analysis
- **Vulnerability Report** - Detailed vulnerability findings

### 3. Threat Intelligence Integration

```typescript
// Fetch threat intelligence
const threats = await fetchThreatIntelligence({
  sources: ['virustotal', 'abuseipdb', 'alienvault'],
  domain: 'contoso.com'
});

// Apply to assessment
const enrichedResults = await enrichWithThreatData(
  assessmentResults,
  threats
);
```

### 4. Real-Time Monitoring

```typescript
// WebSocket connection for live updates
const ws = new WebSocket('ws://localhost:3001/monitoring');

ws.on('message', (data) => {
  const event = JSON.parse(data);
  if (event.type === 'threat_detected') {
    handleThreatAlert(event);
  }
});
```

## 🚀 Deployment

### Frontend Deployment (Vercel)

1. **Connect GitHub Repository**
```bash
vercel link
vercel env pull
```

2. **Configure Build Settings**
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "installCommand": "npm install"
}
```

3. **Deploy**
```bash
vercel --prod
```

### Backend Deployment (Azure)

1. **Create Resources**
```bash
# Create resource group
az group create --name powerreview-rg --location eastus

# Create App Service
az appservice plan create --name powerreview-plan --resource-group powerreview-rg --sku B2

# Create Web App
az webapp create --name powerreview-api --plan powerreview-plan --resource-group powerreview-rg
```

2. **Deploy Code**
```bash
# Build and deploy
npm run build:api
az webapp deployment source config-zip --src api.zip --name powerreview-api
```

### Database Deployment

1. **Azure Database for PostgreSQL**
```bash
az postgres server create \
  --name powerreview-db \
  --resource-group powerreview-rg \
  --sku GP_Gen5_2 \
  --admin-user dbadmin \
  --admin-password <password>
```

2. **Configure SSL and Firewall**
```bash
# Enable SSL
az postgres server update --name powerreview-db --ssl-enforcement Enabled

# Add firewall rule
az postgres server firewall-rule create \
  --server powerreview-db \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

## 🔒 Security

### Authentication Flow

```mermaid
graph LR
    A[User] -->|Login| B[Auth API]
    B -->|Validate| C[Azure AD]
    C -->|Token| B
    B -->|JWT| D[Frontend]
    D -->|Bearer Token| E[API Calls]
```

### Security Best Practices

1. **Environment Variables**
   - Never commit .env files
   - Use Azure Key Vault for production
   - Rotate secrets regularly

2. **Database Security**
   - Enable SSL/TLS
   - Use connection pooling
   - Implement row-level security

3. **API Security**
   - Rate limiting enabled
   - CORS configured
   - Input validation on all endpoints

4. **Script Security**
   - Run with least privilege
   - Validate all parameters
   - Sanitize output data

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Errors
```bash
# Clear cache and rebuild
rm -rf node_modules dist
npm install
npm run build
```

#### 2. Database Connection Issues
```bash
# Test connection
psql -U powerreview_user -d powerreview_dev -c "SELECT 1"

# Check logs
tail -f /var/log/postgresql/postgresql-*.log
```

#### 3. PowerShell Script Errors
```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Test script manually
pwsh -NoProfile -File PowerReview-AzureAD.ps1 -TenantName "test"
```

#### 4. MCP Server Issues
```bash
# Test MCP server
python mcp/sequential-thinking/main.py

# Check logs
tail -f logs/mcp-server.log
```

### Debug Mode

Enable debug mode in development:
```typescript
// src/config/debug.ts
export const DEBUG = {
  logLevel: 'verbose',
  showStackTraces: true,
  mockData: true,
  bypassAuth: true // Only in development!
};
```

## 📚 Additional Resources

- [API Documentation](./API-DOCUMENTATION.md)
- [Security Architecture](./SECURITY-ARCHITECTURE.md)
- [Database Guide](./DATABASE-GUIDE.md)
- [UI Components Guide](./UI-COMPONENTS-GUIDE.md)
- [Deployment Guide](./PRODUCTION-DEPLOYMENT-GUIDE.md)

## 🤝 Support

- **GitHub Issues**: https://github.com/Ross851/M365-Lighthouse/issues
- **Documentation**: https://docs.powerreview.com
- **Email**: support@powerreview.com

---

Last Updated: January 2025 | Version 2.1.0