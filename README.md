# 🚀 PowerReview - Microsoft 365 & Azure Security Assessment Framework

<div align="center">
  <img src="https://img.shields.io/badge/version-2.0.0-blue.svg" alt="Version 2.0.0">
  <img src="https://img.shields.io/badge/platform-M365-orange.svg" alt="M365 Platform">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/powershell-7.0+-purple.svg" alt="PowerShell 7.0+">
  <img src="https://img.shields.io/badge/ui-Astro-ff5e00.svg" alt="Astro UI">
</div>

A comprehensive, enterprise-grade assessment tool for Microsoft 365 and Azure environments, focusing on security, compliance, and governance best practices.

## 🆕 PowerReview v2.0 - Now with Ultra-Professional Web UI!

### ✨ What's New in v2.0
- **🌐 Stunning Web Interface**: Beautiful Astro-based UI with real-time monitoring
- **🔐 Secure Authentication**: Professional login system with pre-flight checks
- **📊 Live Assessment Tracking**: Watch your security scans execute in real-time
- **📈 Interactive Dashboard**: Comprehensive results with scores and recommendations
- **🛡️ Enhanced Error Handling**: Robust error recovery and logging throughout
- **🎯 Wizard Interface**: Step-by-step guidance through the assessment process

## 🎯 What is PowerReview?

PowerReview is a professional security assessment framework that evaluates:

- **Microsoft Purview** - Data governance, compliance, and information protection
- **Power Platform** - Apps, flows, and governance controls
- **SharePoint/Teams/OneDrive** - Collaboration security and configuration
- **Azure Landing Zone** - Multi-tenant Azure infrastructure assessment
- **Security & Compliance** - Complete security posture evaluation

## 🌟 Key Features

### 🔍 Comprehensive Assessment
- **Multi-tenant support** with parallel execution
- **Deep analysis modes** (Basic, Standard, Deep, Forensic)
- **Automated evidence collection** with screenshots and logs
- **Best practice mapping** to industry frameworks (NIST, CIS, ISO27001)

### 🎨 Professional User Experience
- **NEW: Web-based UI** with real-time execution monitoring
- **Wizard-style interface** with progress tracking
- **Interactive discovery questionnaires** based on industry templates
- **Executive dashboards** with risk scoring and recommendations
- **Secure client portals** with time-limited access

### 🔐 Enterprise Security
- **AES-256 encryption** for all sensitive data
- **Role-based access control** with Azure AD integration
- **Comprehensive audit logging** for compliance
- **Zero-trust architecture** with certificate-based authentication

### 📊 Advanced Reporting
- **Multiple output formats** (HTML, PDF, PowerBI, CSV)
- **Evidence-backed findings** with justification
- **Priority-based roadmaps** with effort estimates
- **Client feedback integration** with satisfaction tracking

## 🚀 Quick Start

### Option 1: Web UI (Recommended for v2.0)
```bash
# 1. Clone repository
git clone https://github.com/Ross851/M365-Lighthouse.git
cd M365-Lighthouse/powerreview-ui

# 2. Install dependencies
npm install

# 3. Start the web interface
npm run dev

# 4. Open browser to http://localhost:4321/login
```

### Option 2: PowerShell Direct
```powershell
# 1. Clone repository
git clone https://github.com/Ross851/M365-Lighthouse.git
cd M365-Lighthouse

# 2. Run enhanced PowerShell wizard
.\Start-PowerReview-Enhanced.ps1
```

### Prerequisites
- Windows 10/11 or Windows Server 2019+
- PowerShell 7.0+
- Node.js 18+ (for web UI)
- Microsoft 365 Global Reader (minimum) or Global Admin (full features)
- Azure Reader role (for Azure assessments)

## 🌐 Deploy to Production

### Deploy Web UI to Vercel
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/Ross851/M365-Lighthouse/tree/main/powerreview-ui)

### Deploy to Azure Static Web Apps
See [deployment guide](./DEPLOYMENT_GUIDE.md) for detailed instructions.

## 📋 Assessment Modules

| Module | Purpose | Key Features |
|--------|---------|--------------|
| **Purview** | Data governance & compliance | DLP policies, sensitivity labels, retention rules |
| **SharePoint** | Collaboration security | Site permissions, sharing policies, external access |
| **Teams** | Communication security | Meeting policies, app governance, data loss prevention |
| **OneDrive** | Personal data protection | Sharing controls, sync restrictions, compliance |
| **Power Platform** | Low-code governance | App policies, connector controls, data loss prevention |
| **Azure** | Infrastructure security | Landing zone assessment, policy compliance |
| **Security** | Overall posture | MFA, conditional access, identity protection |

## 🏢 Enterprise Features

### Multi-Tenant Assessment
```powershell
# Configure multi-tenant assessment
.\Run-PowerReview-MultiTenant.ps1 -ConfigPath ".\tenant-config-template.json"
```

### Role-Based Access Control
```powershell
# Create users with specific roles
New-PowerReviewUser -UserPrincipalName "analyst@company.com" `
    -Role "PowerReview-Analyst" -Organizations @("Contoso", "Fabrikam")
```

### Client Communication
```powershell
# Share results with clients
.\Share-AssessmentWithClient.ps1
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Web UI Guide](./README-UI.md) | Complete guide for the new web interface |
| [Deployment Guide](./DEPLOYMENT-GUIDE.md) | Complete deployment instructions |
| [Developer Guide](./DEVELOPER-IMPLEMENTATION-GUIDE.md) | For developers and contractors |
| [Role Assignment Guide](./ROLE-ASSIGNMENT-GUIDE.md) | User management and permissions |
| [Data Architecture](./TECHNICAL-ARCHITECTURE-DETAILED.md) | Technical implementation details |
| [Storage Guide](./DATA-STORAGE-GUIDE.md) | Data storage and security |
| [Where to Run](./WHERE-TO-RUN-POWERREVIEW.md) | Deployment options guide |

## 🛠️ Key Scripts

### Core Assessment
- `Start-PowerReview-Enhanced.ps1` - Enhanced wizard interface (v2.0)
- `PowerReview-Complete.ps1` - Core assessment engine
- `PowerReview-Enhanced-Framework.ps1` - Advanced features
- `PowerReview-Wizard.ps1` - Interactive wizard component (v2.0)

### Error Handling & Fixes (New in v2.0)
- `PowerReview-ErrorHandling.ps1` - Comprehensive error handling
- `Fix-PowerPlatformIssue.ps1` - Power Platform compatibility fixes

### Discovery & Questionnaires
- `PowerReview-Discovery-Questionnaire.ps1` - Interactive questionnaire system
- `Electoral-Commission-Questionnaire.ps1` - Industry-standard template

### Security & Access
- `Setup-PowerReviewSecurity.ps1` - Security configuration
- `Initialize-RoleBasedAccess.ps1` - User and role management

### Client Communication
- `PowerReview-Client-Portal.ps1` - Secure portal generation
- `Share-AssessmentWithClient.ps1` - Result sharing wizard

## 🔐 Security & Compliance

- **Encryption**: AES-256 for all sensitive data
- **Authentication**: Azure AD, local auth, certificate-based
- **Compliance**: GDPR, HIPAA, SOC2, ISO27001 ready
- **Audit**: Complete audit trail for all operations

## 📈 Version History

### v2.0.0 (2025-07-11)
- Added professional web interface with Astro
- Implemented secure authentication flow
- Created pre-flight checklist system
- Built real-time execution monitoring
- Added comprehensive results dashboard
- Fixed Power Platform cmdlet issues
- Enhanced error handling throughout

### v1.0.0 (2025-07-10)
- Initial release
- Basic PowerShell assessment framework
- Core security checks

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Microsoft Security Team for best practices guidance
- PowerShell Community for module development
- Electoral Commission for comprehensive questionnaire templates
- Enterprise customers for real-world testing and feedback
- Astro Framework Team for the amazing web framework

---

<div align="center">
  <strong>PowerReview v2.0</strong> - Professional M365 Security Assessments<br>
  <strong>Ready to secure your Microsoft 365 environment?</strong><br>
  <a href="./powerreview-ui">🌐 Try the Web UI</a> | <a href="./Start-PowerReview-Enhanced.ps1">🖥️ Use PowerShell</a>
</div>