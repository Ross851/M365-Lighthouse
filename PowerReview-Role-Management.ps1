#Requires -Version 7.0

<#
.SYNOPSIS
    PowerReview Role-Based Access Control (RBAC) Management
.DESCRIPTION
    Manages user roles, permissions, and access control for PowerReview
.NOTES
    Version: 1.0
#>

# Role definitions
$script:RoleDefinitions = @{
    "PowerReview-Admin" = @{
        DisplayName = "PowerReview Administrator"
        Description = "Full access to all PowerReview features and data"
        Permissions = @(
            "Assessment.*",
            "Questionnaire.*",
            "Report.*",
            "User.*",
            "Config.*",
            "Audit.*",
            "Security.*",
            "Data.*"
        )
        DataScope = "All"
        RequiresMFA = $true
        RequiresPIM = $true
        MaxSessionHours = 8
    }
    
    "PowerReview-Analyst" = @{
        DisplayName = "Security Analyst"
        Description = "Can run assessments and view reports for assigned organizations"
        Permissions = @(
            "Assessment.Create",
            "Assessment.Read",
            "Assessment.Update",
            "Questionnaire.Create",
            "Questionnaire.Read",
            "Report.Read",
            "Report.Generate",
            "Audit.Read"
        )
        DataScope = "Organization"
        RequiresMFA = $true
        RequiresPIM = $false
        MaxSessionHours = 12
    }
    
    "PowerReview-Viewer" = @{
        DisplayName = "Report Viewer"
        Description = "Read-only access to reports and dashboards"
        Permissions = @(
            "Report.Read",
            "Dashboard.View",
            "Assessment.ReadSummary"
        )
        DataScope = "Organization"
        RequiresMFA = $true
        RequiresPIM = $false
        MaxSessionHours = 24
    }
    
    "PowerReview-Auditor" = @{
        DisplayName = "Compliance Auditor"
        Description = "Read access to assessments and audit logs for compliance"
        Permissions = @(
            "Assessment.Read",
            "Report.Read",
            "Audit.Read",
            "Audit.Export",
            "Compliance.Read"
        )
        DataScope = "All"
        RequiresMFA = $true
        RequiresPIM = $false
        MaxSessionHours = 8
        TimeBasedAccess = $true
    }
    
    "PowerReview-Developer" = @{
        DisplayName = "Developer/Contractor"
        Description = "Can run assessments and questionnaires for assigned clients"
        Permissions = @(
            "Assessment.Create",
            "Assessment.Read",
            "Questionnaire.*",
            "Report.Generate",
            "Report.Read"
        )
        DataScope = "AssignedClients"
        RequiresMFA = $true
        RequiresPIM = $false
        MaxSessionHours = 12
    }
    
    "PowerReview-Executive" = @{
        DisplayName = "Executive Viewer"
        Description = "Access to executive dashboards and summary reports"
        Permissions = @(
            "Dashboard.Executive",
            "Report.ReadSummary",
            "Assessment.ReadSummary"
        )
        DataScope = "Organization"
        RequiresMFA = $true
        RequiresPIM = $false
        MaxSessionHours = 24
    }
    
    "PowerReview-ClientPortal" = @{
        DisplayName = "Client Portal User"
        Description = "External client access to their portal and reports"
        Permissions = @(
            "Portal.View",
            "Report.ReadOwn",
            "Assessment.ReadOwnSummary"
        )
        DataScope = "Own"
        RequiresMFA = $false
        RequiresPIM = $false
        MaxSessionHours = 2
        ExternalUser = $true
    }
}

# Permission definitions
$script:PermissionDefinitions = @{
    "Assessment.Create" = "Create new assessments"
    "Assessment.Read" = "View assessment details"
    "Assessment.ReadSummary" = "View assessment summaries only"
    "Assessment.Update" = "Update existing assessments"
    "Assessment.Delete" = "Delete assessments"
    "Questionnaire.Create" = "Create questionnaires"
    "Questionnaire.Read" = "View questionnaire responses"
    "Questionnaire.Update" = "Update questionnaires"
    "Report.Generate" = "Generate new reports"
    "Report.Read" = "View reports"
    "Report.ReadSummary" = "View report summaries"
    "Report.Export" = "Export reports"
    "User.Create" = "Create users"
    "User.Read" = "View user information"
    "User.Update" = "Update user roles"
    "User.Delete" = "Delete users"
    "Config.Read" = "View configuration"
    "Config.Update" = "Update configuration"
    "Audit.Read" = "View audit logs"
    "Audit.Export" = "Export audit logs"
    "Security.Manage" = "Manage security settings"
    "Data.Export" = "Export raw data"
    "Data.Import" = "Import data"
    "Portal.View" = "View client portal"
    "Dashboard.View" = "View dashboards"
    "Dashboard.Executive" = "View executive dashboard"
}

# Function to create a new user
function New-PowerReviewUser {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerReview-Admin", "PowerReview-Analyst", "PowerReview-Viewer", 
                     "PowerReview-Auditor", "PowerReview-Developer", "PowerReview-Executive", 
                     "PowerReview-ClientPortal")]
        [string]$Role,
        
        [string[]]$Organizations = @(),
        
        [string[]]$AssignedClients = @(),
        
        [switch]$Enabled = $true,
        
        [datetime]$ExpirationDate,
        
        [hashtable]$AdditionalProperties = @{}
    )
    
    Write-Host "Creating PowerReview user..." -ForegroundColor Yellow
    
    # Load existing users
    $users = Get-PowerReviewUsers
    
    # Check if user already exists
    if ($users.ContainsKey($UserPrincipalName)) {
        Write-Host "❌ User already exists: $UserPrincipalName" -ForegroundColor Red
        return
    }
    
    # Create user object
    $user = @{
        UserPrincipalName = $UserPrincipalName
        DisplayName = $DisplayName
        Role = $Role
        RoleDefinition = $script:RoleDefinitions[$Role]
        Organizations = $Organizations
        AssignedClients = $AssignedClients
        Enabled = $Enabled
        CreatedDate = Get-Date
        CreatedBy = $env:USERNAME
        LastModified = Get-Date
        ModifiedBy = $env:USERNAME
        Properties = $AdditionalProperties
    }
    
    # Add expiration if specified
    if ($ExpirationDate) {
        $user.ExpirationDate = $ExpirationDate
    }
    
    # Add to users database
    $users[$UserPrincipalName] = $user
    
    # Save users
    Save-PowerReviewUsers -Users $users
    
    # Log the action
    Write-AuditLog -Action "User.Create" -ObjectType "User" -ObjectId $UserPrincipalName -Details @{
        Role = $Role
        Organizations = $Organizations
    }
    
    Write-Host "✅ User created successfully!" -ForegroundColor Green
    Write-Host "   User: $DisplayName ($UserPrincipalName)" -ForegroundColor White
    Write-Host "   Role: $($script:RoleDefinitions[$Role].DisplayName)" -ForegroundColor White
    
    return $user
}

# Function to update user role
function Set-PowerReviewUserRole {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerReview-Admin", "PowerReview-Analyst", "PowerReview-Viewer", 
                     "PowerReview-Auditor", "PowerReview-Developer", "PowerReview-Executive", 
                     "PowerReview-ClientPortal")]
        [string]$NewRole,
        
        [string]$Justification
    )
    
    Write-Host "Updating user role..." -ForegroundColor Yellow
    
    # Load users
    $users = Get-PowerReviewUsers
    
    if (-not $users.ContainsKey($UserPrincipalName)) {
        Write-Host "❌ User not found: $UserPrincipalName" -ForegroundColor Red
        return
    }
    
    $user = $users[$UserPrincipalName]
    $oldRole = $user.Role
    
    # Update role
    $user.Role = $NewRole
    $user.RoleDefinition = $script:RoleDefinitions[$NewRole]
    $user.LastModified = Get-Date
    $user.ModifiedBy = $env:USERNAME
    
    # Save changes
    Save-PowerReviewUsers -Users $users
    
    # Log the change
    Write-AuditLog -Action "User.UpdateRole" -ObjectType "User" -ObjectId $UserPrincipalName -Details @{
        OldRole = $oldRole
        NewRole = $NewRole
        Justification = $Justification
    }
    
    Write-Host "✅ Role updated successfully!" -ForegroundColor Green
    Write-Host "   User: $($user.DisplayName)" -ForegroundColor White
    Write-Host "   Old Role: $($script:RoleDefinitions[$oldRole].DisplayName)" -ForegroundColor White
    Write-Host "   New Role: $($script:RoleDefinitions[$NewRole].DisplayName)" -ForegroundColor White
}

# Function to assign organizations to user
function Add-PowerReviewUserOrganization {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Organizations
    )
    
    $users = Get-PowerReviewUsers
    
    if (-not $users.ContainsKey($UserPrincipalName)) {
        Write-Host "❌ User not found: $UserPrincipalName" -ForegroundColor Red
        return
    }
    
    $user = $users[$UserPrincipalName]
    
    # Add organizations
    foreach ($org in $Organizations) {
        if ($user.Organizations -notcontains $org) {
            $user.Organizations += $org
        }
    }
    
    $user.LastModified = Get-Date
    $user.ModifiedBy = $env:USERNAME
    
    Save-PowerReviewUsers -Users $users
    
    Write-Host "✅ Organizations assigned successfully!" -ForegroundColor Green
    Write-Host "   User: $($user.DisplayName)" -ForegroundColor White
    Write-Host "   Organizations: $($user.Organizations -join ', ')" -ForegroundColor White
}

# Function to check user permissions
function Test-PowerReviewPermission {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$true)]
        [string]$Permission,
        
        [string]$Organization,
        
        [string]$ResourceId
    )
    
    # Load user
    $users = Get-PowerReviewUsers
    
    if (-not $users.ContainsKey($UserPrincipalName)) {
        return $false
    }
    
    $user = $users[$UserPrincipalName]
    
    # Check if user is enabled
    if (-not $user.Enabled) {
        return $false
    }
    
    # Check expiration
    if ($user.ExpirationDate -and $user.ExpirationDate -lt (Get-Date)) {
        return $false
    }
    
    # Get user permissions
    $rolePermissions = $user.RoleDefinition.Permissions
    
    # Check exact permission
    if ($rolePermissions -contains $Permission) {
        # Check data scope
        return Test-DataScope -User $user -Organization $Organization -ResourceId $ResourceId
    }
    
    # Check wildcard permissions
    foreach ($perm in $rolePermissions) {
        if ($perm -like "*.*" -and $Permission -like "$($perm.Split('.')[0]).*") {
            return Test-DataScope -User $user -Organization $Organization -ResourceId $ResourceId
        }
    }
    
    return $false
}

# Function to test data scope
function Test-DataScope {
    param(
        $User,
        $Organization,
        $ResourceId
    )
    
    switch ($User.RoleDefinition.DataScope) {
        "All" { return $true }
        "Organization" { return $User.Organizations -contains $Organization }
        "AssignedClients" { return $User.AssignedClients -contains $Organization }
        "Own" { return $ResourceId -eq $User.UserPrincipalName }
        default { return $false }
    }
}

# Function to get all users
function Get-PowerReviewUsers {
    $userFile = ".\PowerReview-Users.json"
    
    if (Test-Path $userFile) {
        $encryptedData = Get-Content $userFile -Raw | ConvertFrom-Json
        
        # Check if we have encryption module
        if (Test-Path ".\PowerReview-Encryption.psm1") {
            Import-Module .\PowerReview-Encryption.psm1 -Force
            $users = Unprotect-PowerReviewData -EncryptedData $encryptedData
            return $users
        } else {
            # Return unencrypted for workshops
            return $encryptedData
        }
    }
    
    return @{}
}

# Function to save users
function Save-PowerReviewUsers {
    param($Users)
    
    $userFile = ".\PowerReview-Users.json"
    
    # Check if we have encryption
    if (Test-Path ".\PowerReview-Encryption.psm1") {
        Import-Module .\PowerReview-Encryption.psm1 -Force
        $encrypted = Protect-PowerReviewData -Data $Users
        $encrypted | ConvertTo-Json -Depth 10 | Out-File -FilePath $userFile -Encoding UTF8
    } else {
        # Save unencrypted for workshops
        $Users | ConvertTo-Json -Depth 10 | Out-File -FilePath $userFile -Encoding UTF8
    }
}

# Function to show all roles
function Get-PowerReviewRoles {
    Write-Host "`n📋 POWERREVIEW ROLE DEFINITIONS" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    foreach ($role in $script:RoleDefinitions.Keys | Sort-Object) {
        $def = $script:RoleDefinitions[$role]
        
        Write-Host "`n🔐 $($def.DisplayName) ($role)" -ForegroundColor Yellow
        Write-Host "   $($def.Description)" -ForegroundColor Gray
        Write-Host "   Data Scope: $($def.DataScope)" -ForegroundColor White
        Write-Host "   MFA Required: $($def.RequiresMFA)" -ForegroundColor White
        Write-Host "   PIM Required: $($def.RequiresPIM)" -ForegroundColor White
        Write-Host "   Max Session: $($def.MaxSessionHours) hours" -ForegroundColor White
        
        Write-Host "   Permissions:" -ForegroundColor Cyan
        foreach ($perm in $def.Permissions | Sort-Object) {
            if ($script:PermissionDefinitions.ContainsKey($perm)) {
                Write-Host "     • $perm - $($script:PermissionDefinitions[$perm])" -ForegroundColor White
            } else {
                Write-Host "     • $perm" -ForegroundColor White
            }
        }
    }
}

# Function to show user summary
function Get-PowerReviewUserSummary {
    $users = Get-PowerReviewUsers
    
    Write-Host "`n👥 POWERREVIEW USER SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    Write-Host "`nTotal Users: $($users.Count)" -ForegroundColor Yellow
    
    # Group by role
    $roleGroups = $users.Values | Group-Object -Property Role
    
    Write-Host "`nUsers by Role:" -ForegroundColor Yellow
    foreach ($group in $roleGroups | Sort-Object Name) {
        Write-Host "  • $($script:RoleDefinitions[$group.Name].DisplayName): $($group.Count)" -ForegroundColor White
    }
    
    Write-Host "`nUser List:" -ForegroundColor Yellow
    foreach ($user in $users.Values | Sort-Object DisplayName) {
        $status = if ($user.Enabled) { "✅" } else { "❌" }
        $expiry = if ($user.ExpirationDate) { " (Expires: $($user.ExpirationDate.ToString('yyyy-MM-dd')))" } else { "" }
        
        Write-Host "  $status $($user.DisplayName)" -ForegroundColor White
        Write-Host "     Email: $($user.UserPrincipalName)" -ForegroundColor Gray
        Write-Host "     Role: $($script:RoleDefinitions[$user.Role].DisplayName)" -ForegroundColor Gray
        
        if ($user.Organizations.Count -gt 0) {
            Write-Host "     Orgs: $($user.Organizations -join ', ')" -ForegroundColor Gray
        }
        
        Write-Host "     Created: $($user.CreatedDate.ToString('yyyy-MM-dd')) by $($user.CreatedBy)$expiry" -ForegroundColor Gray
    }
}

# Function to export role assignments
function Export-PowerReviewRoleAssignments {
    param(
        [string]$OutputPath = ".\PowerReview-RoleAssignments.csv"
    )
    
    $users = Get-PowerReviewUsers
    $exportData = @()
    
    foreach ($user in $users.Values) {
        $exportData += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            Role = $user.Role
            RoleDisplayName = $script:RoleDefinitions[$user.Role].DisplayName
            Organizations = $user.Organizations -join "; "
            AssignedClients = $user.AssignedClients -join "; "
            Enabled = $user.Enabled
            CreatedDate = $user.CreatedDate
            CreatedBy = $user.CreatedBy
            ExpirationDate = $user.ExpirationDate
            DataScope = $user.RoleDefinition.DataScope
            RequiresMFA = $user.RoleDefinition.RequiresMFA
            RequiresPIM = $user.RoleDefinition.RequiresPIM
        }
    }
    
    $exportData | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "✅ Role assignments exported to: $OutputPath" -ForegroundColor Green
}

# Function to bulk import users
function Import-PowerReviewUsers {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvPath
    )
    
    if (-not (Test-Path $CsvPath)) {
        Write-Host "❌ CSV file not found: $CsvPath" -ForegroundColor Red
        return
    }
    
    $importUsers = Import-Csv -Path $CsvPath
    $successCount = 0
    $errorCount = 0
    
    foreach ($importUser in $importUsers) {
        try {
            $params = @{
                UserPrincipalName = $importUser.UserPrincipalName
                DisplayName = $importUser.DisplayName
                Role = $importUser.Role
            }
            
            if ($importUser.Organizations) {
                $params.Organizations = $importUser.Organizations -split ';' | ForEach-Object { $_.Trim() }
            }
            
            if ($importUser.AssignedClients) {
                $params.AssignedClients = $importUser.AssignedClients -split ';' | ForEach-Object { $_.Trim() }
            }
            
            New-PowerReviewUser @params
            $successCount++
        }
        catch {
            Write-Host "❌ Failed to import user $($importUser.UserPrincipalName): $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host "`n✅ Import complete!" -ForegroundColor Green
    Write-Host "   Success: $successCount users" -ForegroundColor Green
    Write-Host "   Failed: $errorCount users" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Gray' })
}

# Simple audit logging
function Write-AuditLog {
    param(
        [string]$Action,
        [string]$ObjectType,
        [string]$ObjectId,
        [hashtable]$Details
    )
    
    $auditEntry = @{
        Timestamp = Get-Date
        Action = $Action
        ObjectType = $ObjectType
        ObjectId = $ObjectId
        User = $env:USERNAME
        Details = $Details
    }
    
    $auditFile = ".\Logs\Audit\role-audit-$(Get-Date -Format 'yyyy-MM-dd').json"
    $auditDir = Split-Path $auditFile -Parent
    
    if (-not (Test-Path $auditDir)) {
        New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
    }
    
    $auditEntry | ConvertTo-Json -Compress | Add-Content -Path $auditFile
}

# Create sample users for workshop
function New-SampleUsers {
    Write-Host "`n🎭 Creating sample users for workshop..." -ForegroundColor Yellow
    
    # Admin
    New-PowerReviewUser -UserPrincipalName "admin@workshop.local" `
        -DisplayName "Workshop Admin" `
        -Role "PowerReview-Admin" `
        -Organizations @("Contoso", "Fabrikam", "Tailwind")
    
    # Analysts
    New-PowerReviewUser -UserPrincipalName "analyst1@workshop.local" `
        -DisplayName "Sarah Analyst" `
        -Role "PowerReview-Analyst" `
        -Organizations @("Contoso")
    
    New-PowerReviewUser -UserPrincipalName "analyst2@workshop.local" `
        -DisplayName "John Analyst" `
        -Role "PowerReview-Analyst" `
        -Organizations @("Fabrikam", "Tailwind")
    
    # Developer
    New-PowerReviewUser -UserPrincipalName "developer@workshop.local" `
        -DisplayName "Dev Contractor" `
        -Role "PowerReview-Developer" `
        -AssignedClients @("Contoso", "Fabrikam")
    
    # Viewer
    New-PowerReviewUser -UserPrincipalName "viewer@workshop.local" `
        -DisplayName "Mary Viewer" `
        -Role "PowerReview-Viewer" `
        -Organizations @("Contoso")
    
    # Executive
    New-PowerReviewUser -UserPrincipalName "executive@workshop.local" `
        -DisplayName "CEO User" `
        -Role "PowerReview-Executive" `
        -Organizations @("Contoso")
    
    # Auditor (time-limited)
    New-PowerReviewUser -UserPrincipalName "auditor@workshop.local" `
        -DisplayName "External Auditor" `
        -Role "PowerReview-Auditor" `
        -Organizations @("Contoso", "Fabrikam", "Tailwind") `
        -ExpirationDate (Get-Date).AddDays(30)
    
    Write-Host "✅ Sample users created!" -ForegroundColor Green
}

# Help and usage
function Show-RoleHelp {
    Write-Host @"

🔐 POWERREVIEW ROLE MANAGEMENT
════════════════════════════════════════════════════════════════

AVAILABLE COMMANDS:

📋 View Roles & Permissions:
   Get-PowerReviewRoles              # Show all role definitions

👤 User Management:
   New-PowerReviewUser               # Create new user
   Set-PowerReviewUserRole           # Change user role
   Add-PowerReviewUserOrganization   # Assign organizations
   Get-PowerReviewUserSummary        # Show all users

🔍 Permission Checking:
   Test-PowerReviewPermission        # Check if user has permission

📊 Import/Export:
   Export-PowerReviewRoleAssignments # Export to CSV
   Import-PowerReviewUsers           # Bulk import from CSV

🎭 Workshop Setup:
   New-SampleUsers                   # Create sample users

EXAMPLES:

# Create a new analyst
New-PowerReviewUser -UserPrincipalName "john@contoso.com" `
    -DisplayName "John Smith" `
    -Role "PowerReview-Analyst" `
    -Organizations @("Contoso")

# Check permission
Test-PowerReviewPermission -UserPrincipalName "john@contoso.com" `
    -Permission "Assessment.Create" `
    -Organization "Contoso"

# Change role
Set-PowerReviewUserRole -UserPrincipalName "john@contoso.com" `
    -NewRole "PowerReview-Admin" `
    -Justification "Promoted to admin"

ROLE SUMMARY:
  • Admin: Full access to everything
  • Analyst: Run assessments, create reports
  • Developer: Run assessments for assigned clients
  • Viewer: Read-only access to reports
  • Executive: Executive dashboards only
  • Auditor: Compliance and audit access
  • ClientPortal: External client access

"@ -ForegroundColor Cyan
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Show-RoleHelp
}