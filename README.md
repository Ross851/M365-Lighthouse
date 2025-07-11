# 🚀 PowerReview - Microsoft 365 & Azure Security Assessment Framework

A comprehensive, enterprise-grade assessment tool for Microsoft 365 and Azure environments, focusing on security, compliance, and governance best practices.

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

### Prerequisites
- Windows 10/11 or Windows Server 2019+
- PowerShell 7.0+
- Microsoft 365 Global Reader (minimum) or Global Admin (full features)
- Azure Reader role (for Azure assessments)

### 5-Minute Setup
```powershell
# 1. Clone repository
git clone https://github.com/yourorg/PowerReview.git
cd PowerReview

# 2. Run quick setup
.\QUICK-START-WORKSHOP.ps1

# 3. Start assessment
.\Start-PowerReview.ps1
```

### Professional Setup
```powershell
# 1. Configure storage and security
.\Configure-DataStorage.ps1 -UseDefaults
.\Setup-PowerReviewSecurity.ps1 -ConfigureAll

# 2. Setup role-based access
.\Initialize-RoleBasedAccess.ps1

# 3. Run comprehensive assessment
.\Start-PowerReview.ps1 -DeepAnalysis
```

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
| [Deployment Guide](./DEPLOYMENT-GUIDE.md) | Complete deployment instructions |
| [Developer Guide](./DEVELOPER-IMPLEMENTATION-GUIDE.md) | For developers and contractors |
| [Role Assignment Guide](./ROLE-ASSIGNMENT-GUIDE.md) | User management and permissions |
| [Data Architecture](./TECHNICAL-ARCHITECTURE-DETAILED.md) | Technical implementation details |
| [Storage Guide](./DATA-STORAGE-GUIDE.md) | Data storage and security |
| [Where to Run](./WHERE-TO-RUN-POWERREVIEW.md) | Deployment options guide |

## 🛠️ Key Scripts

### Core Assessment
- `Start-PowerReview.ps1` - Main wizard interface
- `PowerReview-Complete.ps1` - Core assessment engine
- `PowerReview-Enhanced-Framework.ps1` - Advanced features

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

---

**Ready to secure your Microsoft 365 environment? [Get started now!](./QUICK-START-WORKSHOP.ps1)**