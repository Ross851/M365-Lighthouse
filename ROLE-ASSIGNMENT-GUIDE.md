# 🔐 PowerReview Role Assignment Guide

## Quick Start: Assign Roles in 2 Minutes

### Step 1: Run Role Setup
```powershell
.\Initialize-RoleBasedAccess.ps1
# Choose option 1 for Quick Setup
```

### Step 2: View Available Roles
```powershell
. .\PowerReview-Role-Management.ps1
Get-PowerReviewRoles
```

### Step 3: Create Users with Roles
```powershell
# Create an analyst
New-PowerReviewUser -UserPrincipalName "sarah@contoso.com" `
    -DisplayName "Sarah Smith" `
    -Role "PowerReview-Analyst" `
    -Organizations @("Contoso", "Fabrikam")

# Create a developer/contractor
New-PowerReviewUser -UserPrincipalName "contractor@external.com" `
    -DisplayName "John Contractor" `
    -Role "PowerReview-Developer" `
    -AssignedClients @("Contoso", "Northwind")
```

## 📊 Role Matrix

| Role | Who Is This For? | What Can They Do? | Data Access |
|------|-----------------|-------------------|-------------|
| **PowerReview-Admin** | IT Administrators | Everything - full control | All organizations |
| **PowerReview-Analyst** | Security team members | Run assessments, create reports | Assigned organizations only |
| **PowerReview-Developer** | Contractors/Consultants | Run assessments for clients | Assigned clients only |
| **PowerReview-Viewer** | Managers, stakeholders | View reports only | Assigned organizations |
| **PowerReview-Executive** | C-suite executives | View executive dashboards | Their organization |
| **PowerReview-Auditor** | Compliance auditors | Read all data, export audit logs | All organizations |
| **PowerReview-ClientPortal** | External clients | View their portal only | Own data only |

## 🎯 Common Scenarios

### Scenario 1: Onboard a New Security Analyst
```powershell
# Sarah joins the security team, needs access to Contoso and Fabrikam
New-PowerReviewUser -UserPrincipalName "sarah@company.com" `
    -DisplayName "Sarah Johnson" `
    -Role "PowerReview-Analyst" `
    -Organizations @("Contoso", "Fabrikam")
```

### Scenario 2: External Contractor for Specific Clients
```powershell
# John is a contractor working with 3 specific clients
New-PowerReviewUser -UserPrincipalName "john@contractor.com" `
    -DisplayName "John Smith (Contractor)" `
    -Role "PowerReview-Developer" `
    -AssignedClients @("ClientA", "ClientB", "ClientC") `
    -ExpirationDate (Get-Date).AddMonths(6)  # 6-month contract
```

### Scenario 3: Temporary Auditor Access
```powershell
# External auditor needs 30-day access
New-PowerReviewUser -UserPrincipalName "auditor@auditfirm.com" `
    -DisplayName "External Auditor" `
    -Role "PowerReview-Auditor" `
    -Organizations @("All") `
    -ExpirationDate (Get-Date).AddDays(30)
```

### Scenario 4: Executive Dashboard Access
```powershell
# CEO needs dashboard access
New-PowerReviewUser -UserPrincipalName "ceo@company.com" `
    -DisplayName "Jane CEO" `
    -Role "PowerReview-Executive" `
    -Organizations @("Contoso")
```

## 🔄 Managing Roles

### Change User Role (Promotion/Demotion)
```powershell
# Promote analyst to admin
Set-PowerReviewUserRole -UserPrincipalName "sarah@company.com" `
    -NewRole "PowerReview-Admin" `
    -Justification "Promoted to security team lead"
```

### Add Organizations to User
```powershell
# Give user access to additional organizations
Add-PowerReviewUserOrganization -UserPrincipalName "sarah@company.com" `
    -Organizations @("Tailwind", "AdventureWorks")
```

### Bulk Import Users
```powershell
# 1. Create CSV file with users
# 2. Import all at once
Import-PowerReviewUsers -CsvPath ".\NewUsers.csv"
```

CSV Format:
```csv
UserPrincipalName,DisplayName,Role,Organizations,AssignedClients
user1@company.com,User One,PowerReview-Analyst,"Contoso;Fabrikam",
user2@company.com,User Two,PowerReview-Developer,,"Client1;Client2"
```

## 🔍 Checking Permissions

### Test if User Can Perform Action
```powershell
# Can Sarah create assessments for Contoso?
Test-PowerReviewPermission -UserPrincipalName "sarah@company.com" `
    -Permission "Assessment.Create" `
    -Organization "Contoso"

# Can John view reports for ClientA?
Test-PowerReviewPermission -UserPrincipalName "john@contractor.com" `
    -Permission "Report.Read" `
    -Organization "ClientA"
```

### View All Users and Their Roles
```powershell
Get-PowerReviewUserSummary
```

### Export Role Assignments
```powershell
Export-PowerReviewRoleAssignments -OutputPath ".\RoleAudit.csv"
```

## 🏢 Integration with Azure AD

### Option 1: Manual Sync
```powershell
# Run this to sync with Azure AD groups
.\Initialize-RoleBasedAccess.ps1
# Choose option 2 (Azure AD Integration)
```

### Option 2: Group Mapping
Map Azure AD groups to PowerReview roles:
- `SG-PowerReview-Admins` → PowerReview-Admin
- `SG-PowerReview-Analysts` → PowerReview-Analyst
- `SG-PowerReview-Viewers` → PowerReview-Viewer

## 🛡️ Security Best Practices

### 1. Principle of Least Privilege
```powershell
# Give minimum required access
# ❌ Bad: Everyone gets Admin
# ✅ Good: Specific roles for specific needs
```

### 2. Time-Limited Access
```powershell
# Set expiration for temporary users
-ExpirationDate (Get-Date).AddDays(90)
```

### 3. Regular Access Reviews
```powershell
# Monthly review of all users
Get-PowerReviewUserSummary | Export-Csv ".\MonthlyReview.csv"
```

### 4. Audit Trail
```powershell
# All role changes are logged
Get-ChildItem ".\Logs\Audit\role-audit-*.json"
```

## 🎭 Workshop Mode

For workshops, sample users are automatically created:
- `admin@workshop.local` - Full admin
- `analyst1@workshop.local` - Analyst for Contoso
- `analyst2@workshop.local` - Analyst for Fabrikam
- `developer@workshop.local` - Developer for multiple clients
- `viewer@workshop.local` - Read-only viewer
- `executive@workshop.local` - Executive dashboard
- `auditor@workshop.local` - Temporary auditor

### Quick Login for Workshop
```powershell
# Load auth module
Import-Module .\PowerReview-Local-Auth.psm1

# Login as admin
Connect-PowerReviewLocal -UserPrincipalName "admin@workshop.local" `
    -Password (ConvertTo-SecureString "Workshop123!" -AsPlainText -Force)
```

## ❓ Troubleshooting

### "User not found"
```powershell
# Check if user exists
Get-PowerReviewUsers | ConvertTo-Json
```

### "Permission denied"
```powershell
# Check user's role and permissions
$users = Get-PowerReviewUsers
$users["user@domain.com"].Role
$users["user@domain.com"].Organizations
```

### Reset Everything
```powershell
Remove-Item ".\PowerReview-Users.json" -Force
.\Initialize-RoleBasedAccess.ps1
```

## 📞 Need Help?

1. View all available commands:
   ```powershell
   Get-Command -Module PowerReview-Role-Management
   ```

2. Get detailed help:
   ```powershell
   Get-Help New-PowerReviewUser -Full
   ```

3. Check role definitions:
   ```powershell
   Get-PowerReviewRoles
   ```