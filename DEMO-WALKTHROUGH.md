# 🎮 PowerReview Demo Walkthrough

## Starting PowerReview

When you run `.\Start-PowerReview.ps1` on your Windows machine, you'll see:

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║  ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ ██████╗ ███████╗██╗   ██╗██╗███████╗██╗    ██╗║
║  ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔══██╗██╔════╝██║   ██║██║██╔════╝██║    ██║║
║  ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝██████╔╝█████╗  ██║   ██║██║█████╗  ██║ █╗ ██║║
║  ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗██╔══██╗██╔══╝  ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║║
║  ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║██║  ██║███████╗ ╚████╔╝ ██║███████╗╚███╔███╔╝║
║  ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝ ║
║                                                                               ║
║          🚀 Microsoft 365 & Azure Security Assessment Framework 🚀            ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🔍 Checking Prerequisites...
✅ PowerShell 7.4 detected
✅ Running as Administrator
✅ Execution policy: RemoteSigned

📋 Assessment Options:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 🚀 Quick Assessment (Single Tenant)
2. 🏢 Multi-Tenant Assessment
3. 📊 Deep Analysis Mode
4. 🔧 Configure Settings
5. 📝 Run Discovery Questionnaire
6. 👥 Manage Users & Roles
7. 📤 Share Previous Results
8. ❓ Help
9. 🚪 Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select an option (1-9):
```

## Demo Flow - Quick Assessment

### 1. Select Option 1 - Quick Assessment

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 QUICK ASSESSMENT MODE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Required Permissions:
• Global Reader (minimum)
• Security Reader
• Compliance Administrator (for Purview)
• Power Platform Administrator (for Power Platform)

🔐 PIM Requirements:
• Activate required roles before proceeding
• Session duration: ~2-4 hours

🌐 Required URLs to access:
• https://compliance.microsoft.com
• https://security.microsoft.com
• https://admin.microsoft.com
• https://portal.azure.com

Ready to continue? (Y/N): Y
```

### 2. Authentication

```
🔐 Authentication Method:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Interactive (Browser)
2. Certificate-based
3. Service Principal
4. Existing Connection

Select authentication method (1-4): 1

🌐 Launching browser for authentication...
   Organization: Contoso
   
[Browser opens for Microsoft login]

✅ Successfully authenticated to Contoso tenant!
```

### 3. Module Selection

```
📊 Select Modules to Assess:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[X] 1. Microsoft Purview
[X] 2. Power Platform
[X] 3. SharePoint & OneDrive
[X] 4. Microsoft Teams
[X] 5. Exchange Online
[X] 6. Azure Landing Zone
[X] 7. Security & Compliance Center
[ ] 8. Select All
[ ] 9. Continue with selected

Toggle selection (1-7) or Continue (9): 9
```

### 4. Assessment Running

```
🚀 Starting Assessment...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[■■■□□□□□□□] 30% - Assessing Microsoft Purview...
   ✓ DLP Policies: 12 found
   ✓ Sensitivity Labels: 8 configured
   ✓ Retention Policies: 15 active
   ⚡ Analyzing policy effectiveness...

[■■■■■□□□□□] 50% - Assessing Power Platform...
   ✓ Power Apps: 45 apps discovered
   ✓ Power Automate: 128 flows active
   ✓ Connectors: 23 premium, 67 standard
   ⚡ Checking governance policies...

[■■■■■■■□□□] 70% - Assessing SharePoint...
   ✓ Site Collections: 234 found
   ✓ External Sharing: Analyzing...
   ✓ Sensitivity Labels: Checking usage...
   
[■■■■■■■■■■] 100% - Assessment Complete!

⏱️ Total Time: 12 minutes 34 seconds
📊 Findings: 47 High | 123 Medium | 89 Low | 234 Info
```

### 5. Report Generation

```
📄 Generating Reports...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Executive Summary Generated
✅ Technical Report Generated  
✅ Evidence Package Created
✅ Client Portal Created

📁 Results saved to: C:\PowerReview-Data\Contoso-2024-01-11\

🌐 Client Portal URL: https://localhost:8443/portal/a7f3d2e1
   Access Token: CTX-2024-7B3F
   Valid for: 7 days
```

## Demo Flow - Discovery Questionnaire

### Run Option 5 - Discovery Questionnaire

```
📝 DISCOVERY QUESTIONNAIRE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available Questionnaires:
1. 📋 General Discovery (15 questions)
2. 🏛️ Electoral Commission Template (50+ questions)
3. 🏥 Healthcare Compliance (HIPAA)
4. 💰 Financial Services (SOX)
5. 🔐 Zero Trust Readiness

Select questionnaire (1-5): 2

🏛️ Electoral Commission Questionnaire
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Section 1: Data Classification & Labeling
Question 1/52:

Do you currently have a data classification scheme in place?

📝 Your Answer: Yes

💡 Best Practice: Organizations should have at least 3-5 
classification levels (Public, Internal, Confidential, 
Highly Confidential)

✨ Follow-up: What classification levels do you use?
📝 Your Answer: Public, Internal, Confidential, Secret

[Progress: ■■□□□□□□□□] 10%
```

## Demo Flow - Client Portal

### The generated client portal shows:

```html
PowerReview Assessment Results - Contoso
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Executive Dashboard
┌─────────────────────────────────────────────────────────┐
│ Overall Security Score: 72/100                          │
│                                                         │
│ Critical Findings: 12                                   │
│ High Risk Items: 47                                     │
│ Medium Risk Items: 123                                  │
│                                                         │
│ [View Details] [Download Report] [Schedule Discussion]  │
└─────────────────────────────────────────────────────────┘

Key Findings with Evidence:

🔴 Critical: Unrestricted External Sharing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finding: 45 SharePoint sites allow anonymous access
Evidence: [Screenshot attached]
Impact: High risk of data leakage
Recommendation: Implement conditional access policies

Best Practice Reference:
"Organizations should restrict anonymous access and 
implement conditional access policies based on user, 
device, and location." - NIST SP 800-171 Rev 2

[View Full Evidence] [Export Finding]
```

## Running on Your Machine

To see it working on your Windows machine:

```powershell
# 1. Open PowerShell 7 as Administrator
# 2. Navigate to the directory
cd C:\SharePointScripts\Lighthouse

# 3. Run the wizard
.\Start-PowerReview.ps1

# Or run specific components:

# Run discovery questionnaire only
.\PowerReview-Discovery-Questionnaire.ps1

# Share previous results
.\Share-AssessmentWithClient.ps1

# Quick 5-minute demo
.\QUICK-START-WORKSHOP.ps1
```

## What You'll See:

1. **Professional ASCII art header**
2. **Interactive menu system**
3. **Real-time progress bars**
4. **Color-coded output** (errors in red, success in green)
5. **Detailed findings with evidence**
6. **Generated HTML reports**
7. **Secure client portal**

## Try These Commands:

```powershell
# Test the UI without running full assessment
.\Start-PowerReview.ps1 -TestMode

# See the client portal generator
.\PowerReview-Client-Portal.ps1 -Demo

# Run role management
.\Initialize-RoleBasedAccess.ps1
```