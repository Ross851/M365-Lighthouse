# PowerReview Enhanced Framework

## Enterprise Multi-Tenant M365 & Azure Assessment Platform

PowerReview is a comprehensive assessment framework designed to evaluate Microsoft 365 and Azure environments across multiple tenants with deep analysis capabilities, secure data storage, and automated reporting.

### 🚀 Quick Start

```powershell
# 1. Setup (first time only)
.\Setup-PowerReview.ps1 -InstallModules -CreateConfig -TenantCount 4

# 2. Run assessment
.\Run-PowerReview-MultiTenant.ps1

# 3. View results
# Reports are automatically opened in your browser
```

### 📋 Features

#### Core Capabilities
- **Multi-Tenant Support**: Assess unlimited tenants in a single run
- **Deep Analysis Modes**: Basic, Standard, Deep, and Forensic analysis levels
- **Secure Storage**: Encrypted vault for sensitive findings
- **MCP Integration**: Enhanced capabilities with Model Context Protocol
- **Automated Reporting**: Executive summaries, technical details, and remediation roadmaps

#### Assessment Modules
1. **Purview**
   - DLP policy effectiveness
   - Sensitivity label usage
   - Retention policies
   - Insider risk management
   - Information barriers
   - eDiscovery readiness

2. **Security**
   - Conditional Access gaps
   - MFA coverage
   - Privileged access
   - Identity protection
   - Application permissions
   - Threat indicators

3. **SharePoint/Teams/OneDrive**
   - External sharing risks
   - Guest access audit
   - Site governance
   - Information architecture
   - Lifecycle management

4. **Power Platform**
   - Environment governance
   - DLP policy coverage
   - App and flow inventory
   - COE adoption
   - Licensing optimization

5. **Azure Landing Zone**
   - Multi-subscription analysis
   - Management group hierarchy
   - Policy compliance
   - Network architecture
   - Identity integration

6. **Compliance**
   - GDPR readiness
   - HIPAA compliance
   - SOC2 alignment
   - ISO27001 gaps
   - Custom frameworks

### 🔧 Installation

#### Prerequisites
- PowerShell 5.1 or higher
- Administrator access to target tenants
- Required licenses (E3/E5 depending on features)

#### Automated Setup
```powershell
# Install all required modules and create configuration
.\Setup-PowerReview.ps1 -InstallModules -CreateConfig -TenantCount 4
```

#### Manual Setup
```powershell
# Install required modules
Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0
Install-Module Microsoft.Graph -MinimumVersion 2.0.0
Install-Module MicrosoftTeams -MinimumVersion 4.0.0
Install-Module Microsoft.Online.SharePoint.PowerShell
Install-Module PnP.PowerShell
Install-Module Az.Accounts, Az.Resources

# Create configuration
Copy-Item tenant-config-template.json my-tenants.json
# Edit my-tenants.json with your tenant details
```

### 📖 Usage

#### Basic Assessment
```powershell
# Run standard assessment across all configured tenants
.\PowerReview-Enhanced-Framework.ps1 -TenantConfig ".\my-tenants.json"
```

#### Deep Analysis
```powershell
# Run deep analysis with forensic-level detail
.\PowerReview-Enhanced-Framework.ps1 `
    -TenantConfig ".\my-tenants.json" `
    -AnalysisDepth "Deep" `
    -DeepAnalysis `
    -SecureStorage
```

#### Security-Only Assessment
```powershell
# Focus on security modules only
.\Run-PowerReview-MultiTenant.ps1 -SecurityOnly
```

#### Compliance Assessment
```powershell
# Run compliance-focused assessment
.\Run-PowerReview-MultiTenant.ps1 -ComplianceOnly
```

#### Single Tenant
```powershell
# Assess specific tenant
.\Run-PowerReview-MultiTenant.ps1 -SpecificTenant "Contoso Corporation"
```

### 🔐 Authentication

#### Interactive (Default)
- Manual login for each tenant
- No setup required
- Best for one-time assessments

#### Certificate-Based (Recommended)
```powershell
# Configure certificate authentication
.\Setup-PowerReview.ps1 -ConfigureAuthentication

# Required permissions:
- Directory.Read.All
- User.Read.All
- Policy.Read.All
- SecurityEvents.Read.All
- Exchange.ManageAsApp
- Sites.Read.All
```

### 📊 Output Structure

```
PowerReview_Results_20240711_143022/
├── Executive_Report_Enhanced.html      # Consolidated executive summary
├── Contoso_Corporation/               # Per-tenant results
│   ├── Purview/
│   │   ├── Purview_Deep_Findings.csv
│   │   ├── Purview_Deep_Evidence.csv
│   │   └── Purview_Label_Usage.csv
│   ├── Security/
│   │   ├── Security_Deep_Findings.csv
│   │   └── Security_Risky_Apps.csv
│   ├── Compliance/
│   │   └── Compliance_Gaps.csv
│   └── Tenant_Detailed_Report.md
└── Vault/                             # Encrypted sensitive data
    └── *.vault
```

### 🎯 Analysis Depth Levels

| Level | Days Analyzed | Sample Size | Features |
|-------|--------------|-------------|----------|
| Basic | 30 | 100 | Quick overview |
| Standard | 90 | 1,000 | Comprehensive assessment |
| Deep | 180 | 5,000 | Pattern analysis, trend detection |
| Forensic | 365 | All data | Full evidence collection |

### 🔍 Key Findings Categories

#### Severity Levels
- **CRITICAL**: Immediate action required (security vulnerabilities)
- **HIGH**: Should be addressed within 30 days
- **MEDIUM**: Important but not urgent (60-90 days)
- **LOW**: Best practices and optimizations

#### Common Findings
1. No DLP policies configured
2. Insufficient MFA coverage
3. Excessive permanent admin assignments
4. Anonymous sharing enabled
5. No insider risk policies
6. Missing sensitivity labels
7. Ungoverned Power Platform usage

### 📈 Reporting

#### Executive Summary
- High-level overview
- Risk distribution charts
- Tenant comparison scores
- Strategic recommendations
- Investment summary

#### Technical Details
- Detailed findings by module
- Evidence collection
- Configuration snapshots
- Remediation steps
- Effort estimates

#### Compliance Reports
- Framework alignment scores
- Gap analysis
- Regulatory mapping
- Remediation priorities

### 🛠️ Troubleshooting

#### Common Issues

1. **Module not found**
   ```powershell
   .\Setup-PowerReview.ps1 -InstallModules
   ```

2. **Access denied**
   - Ensure you have Global Reader or equivalent
   - Check if conditional access is blocking

3. **Timeout errors**
   - Use Basic analysis depth for large tenants
   - Run modules individually

4. **Memory issues**
   - Close other applications
   - Use 64-bit PowerShell
   - Reduce sample size

### 🔄 Best Practices

1. **Pre-Assessment**
   - Notify tenant admins
   - Schedule during low-usage hours
   - Test with one tenant first

2. **During Assessment**
   - Monitor progress in logs
   - Don't interrupt the process
   - Keep credentials ready

3. **Post-Assessment**
   - Review findings immediately
   - Prioritize critical issues
   - Plan remediation sprints
   - Schedule follow-up assessment

### 📅 Recommended Assessment Schedule

- **Initial**: Comprehensive deep analysis
- **Quarterly**: Standard assessment
- **Monthly**: Security-only quick check
- **After major changes**: Targeted assessment

### 🤝 Contributing

To add new checks or modules:

1. Follow the module interface pattern
2. Include severity ratings
3. Provide remediation steps
4. Estimate effort hours
5. Test with multiple tenants

### 📝 License

This tool is provided as-is for assessment purposes. Ensure you have appropriate permissions before running assessments.

### 🆘 Support

For issues or questions:
1. Check the logs in the output directory
2. Validate setup with `.\Setup-PowerReview.ps1 -ValidateSetup`
3. Run test assessment with `.\Setup-PowerReview.ps1 -TestRun`
4. Review this README for common solutions

---

**PowerReview Enhanced Framework v3.0.0**  
*Enterprise-ready multi-tenant assessment platform*