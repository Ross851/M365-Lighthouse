#Requires -Version 7.0

<#
.SYNOPSIS
    Initialize Role-Based Access Control for PowerReview
.DESCRIPTION
    Sets up RBAC integration with Azure AD and creates initial role assignments
.NOTES
    Version: 1.0
#>

param(
    [switch]$UseAzureAD,
    [switch]$UseLocalAuth,
    [switch]$CreateSampleUsers,
    [switch]$ShowCurrentSetup
)

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    🔐 POWERREVIEW ACCESS CONTROL SETUP 🔐                     ║
║                                                                               ║
║                         Configure user roles and permissions                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Load role management module
. .\PowerReview-Role-Management.ps1

# Function to show current setup
function Show-CurrentAccessSetup {
    Write-Host "`n📊 CURRENT ACCESS CONTROL SETUP" -ForegroundColor Yellow
    Write-Host ("=" * 50) -ForegroundColor Yellow
    
    # Check authentication mode
    if (Test-Path ".\auth-config.json") {
        Write-Host "`n✅ Authentication Configured" -ForegroundColor Green
        $config = Get-Content ".\auth-config.json" -Raw | ConvertFrom-Json
        # Note: Config is encrypted, so we can't show details without decrypting
        Write-Host "   Mode: Configured (run with admin rights to view details)" -ForegroundColor White
    } else {
        Write-Host "`n⚠️  No authentication configured" -ForegroundColor Yellow
        Write-Host "   Using local file-based authentication" -ForegroundColor Gray
    }
    
    # Show users
    Get-PowerReviewUserSummary
    
    # Show role definitions
    Write-Host "`n📋 Available Roles:" -ForegroundColor Yellow
    foreach ($role in $script:RoleDefinitions.Keys | Sort-Object) {
        Write-Host "   • $role - $($script:RoleDefinitions[$role].DisplayName)" -ForegroundColor White
    }
}

# Function to setup Azure AD integration
function Initialize-AzureADIntegration {
    Write-Host "`n🔷 Setting up Azure AD Integration..." -ForegroundColor Cyan
    
    Write-Host @"

This will configure PowerReview to use Azure AD for authentication.

Prerequisites:
1. Azure AD tenant with appropriate permissions
2. Registered application in Azure AD
3. Required API permissions granted

"@ -ForegroundColor Yellow
    
    $tenantId = Read-Host "Enter your Azure AD Tenant ID"
    $clientId = Read-Host "Enter your App Registration Client ID"
    
    # Create Azure AD group mappings
    Write-Host "`n📁 Creating Azure AD Group Mappings..." -ForegroundColor Yellow
    Write-Host "Map Azure AD groups to PowerReview roles:" -ForegroundColor Gray
    
    $groupMappings = @{}
    foreach ($role in $script:RoleDefinitions.Keys) {
        $groupName = Read-Host "   Azure AD group for '$($script:RoleDefinitions[$role].DisplayName)' (or press Enter to skip)"
        if ($groupName) {
            $groupMappings[$role] = $groupName
        }
    }
    
    # Save configuration
    $azureConfig = @{
        AuthenticationType = "AzureAD"
        TenantId = $tenantId
        ClientId = $clientId
        GroupMappings = $groupMappings
        RequireMFA = $true
        ConditionalAccess = @{
            RequireCompliantDevice = $false
            AllowedLocations = @("*")
        }
    }
    
    # Save to auth config
    $azureConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\azure-ad-config.json" -Encoding UTF8
    
    Write-Host "`n✅ Azure AD integration configured!" -ForegroundColor Green
    
    # Create PowerShell module for Azure AD auth
    $authModule = @'
# PowerReview Azure AD Authentication

function Connect-PowerReviewAzureAD {
    param(
        [string]$TenantId,
        [string]$ClientId
    )
    
    # Connect to Azure AD
    Connect-AzureAD -TenantId $TenantId -ClientId $ClientId
    
    # Cache connection
    $script:AzureADConnected = $true
}

function Get-PowerReviewUserFromAzureAD {
    param(
        [string]$UserPrincipalName
    )
    
    if (-not $script:AzureADConnected) {
        throw "Not connected to Azure AD. Run Connect-PowerReviewAzureAD first."
    }
    
    # Get user from Azure AD
    $azureUser = Get-AzureADUser -ObjectId $UserPrincipalName
    
    # Get user groups
    $userGroups = Get-AzureADUserMembership -ObjectId $azureUser.ObjectId | 
        Select-Object -ExpandProperty DisplayName
    
    # Map to PowerReview role
    $config = Get-Content ".\azure-ad-config.json" -Raw | ConvertFrom-Json
    $userRole = $null
    
    foreach ($role in $config.GroupMappings.PSObject.Properties) {
        if ($userGroups -contains $role.Value) {
            $userRole = $role.Name
            break
        }
    }
    
    if (-not $userRole) {
        throw "User not in any authorized groups"
    }
    
    # Create/update local user object
    $params = @{
        UserPrincipalName = $UserPrincipalName
        DisplayName = $azureUser.DisplayName
        Role = $userRole
    }
    
    # Check if user exists
    $users = Get-PowerReviewUsers
    if ($users.ContainsKey($UserPrincipalName)) {
        Set-PowerReviewUserRole @params
    } else {
        New-PowerReviewUser @params
    }
    
    return Get-PowerReviewUsers[$UserPrincipalName]
}

function Test-PowerReviewAzureADAuth {
    param(
        [string]$UserPrincipalName,
        [string]$Permission,
        [string]$Organization
    )
    
    try {
        # Get user from Azure AD
        $user = Get-PowerReviewUserFromAzureAD -UserPrincipalName $UserPrincipalName
        
        # Test permission
        return Test-PowerReviewPermission -UserPrincipalName $UserPrincipalName `
            -Permission $Permission -Organization $Organization
    }
    catch {
        Write-Host "❌ Authentication failed: $_" -ForegroundColor Red
        return $false
    }
}
'@
    
    $authModule | Out-File -FilePath ".\PowerReview-AzureAD-Auth.psm1" -Encoding UTF8
    Write-Host "✅ Azure AD authentication module created" -ForegroundColor Green
}

# Function to setup local authentication
function Initialize-LocalAuthentication {
    Write-Host "`n🏠 Setting up Local Authentication..." -ForegroundColor Cyan
    
    Write-Host @"

This will configure PowerReview to use local user management.
Perfect for workshops, POCs, and environments without Azure AD.

"@ -ForegroundColor Yellow
    
    # Create auth configuration
    $localConfig = @{
        AuthenticationType = "Local"
        RequireMFA = $false
        PasswordPolicy = @{
            MinimumLength = 8
            RequireUppercase = $true
            RequireLowercase = $true
            RequireNumbers = $true
            RequireSpecialCharacters = $true
        }
        SessionTimeout = 480  # 8 hours
    }
    
    $localConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\local-auth-config.json" -Encoding UTF8
    
    Write-Host "✅ Local authentication configured!" -ForegroundColor Green
    
    # Create simple auth module
    $localAuthModule = @'
# PowerReview Local Authentication

$script:AuthenticatedUsers = @{}

function Connect-PowerReviewLocal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$true)]
        [SecureString]$Password
    )
    
    # Simple password check for workshop (in production, use proper hashing)
    $users = Get-PowerReviewUsers
    
    if (-not $users.ContainsKey($UserPrincipalName)) {
        throw "User not found"
    }
    
    # For workshop, any non-empty password works
    if ($Password.Length -eq 0) {
        throw "Password required"
    }
    
    # Create session
    $sessionId = [Guid]::NewGuid().ToString()
    $script:AuthenticatedUsers[$sessionId] = @{
        UserPrincipalName = $UserPrincipalName
        LoginTime = Get-Date
        LastActivity = Get-Date
    }
    
    # Set session variable
    $env:POWERREVIEW_SESSION = $sessionId
    
    Write-Host "✅ Logged in as: $UserPrincipalName" -ForegroundColor Green
    return $sessionId
}

function Test-PowerReviewLocalAuth {
    param(
        [string]$SessionId = $env:POWERREVIEW_SESSION
    )
    
    if (-not $SessionId -or -not $script:AuthenticatedUsers.ContainsKey($SessionId)) {
        return $false
    }
    
    $session = $script:AuthenticatedUsers[$SessionId]
    
    # Check timeout (8 hours)
    if ((Get-Date) - $session.LastActivity -gt [TimeSpan]::FromHours(8)) {
        Remove-PowerReviewSession -SessionId $SessionId
        return $false
    }
    
    # Update last activity
    $session.LastActivity = Get-Date
    
    return $true
}

function Get-CurrentPowerReviewUser {
    param(
        [string]$SessionId = $env:POWERREVIEW_SESSION
    )
    
    if (Test-PowerReviewLocalAuth -SessionId $SessionId) {
        $session = $script:AuthenticatedUsers[$SessionId]
        return Get-PowerReviewUsers[$session.UserPrincipalName]
    }
    
    return $null
}

function Remove-PowerReviewSession {
    param(
        [string]$SessionId = $env:POWERREVIEW_SESSION
    )
    
    if ($script:AuthenticatedUsers.ContainsKey($SessionId)) {
        $script:AuthenticatedUsers.Remove($SessionId)
    }
    
    $env:POWERREVIEW_SESSION = $null
}
'@
    
    $localAuthModule | Out-File -FilePath ".\PowerReview-Local-Auth.psm1" -Encoding UTF8
    Write-Host "✅ Local authentication module created" -ForegroundColor Green
}

# Function to create initial admin
function New-InitialAdmin {
    Write-Host "`n👤 Creating Initial Administrator..." -ForegroundColor Yellow
    
    $adminEmail = Read-Host "Enter admin email address"
    $adminName = Read-Host "Enter admin display name"
    
    New-PowerReviewUser -UserPrincipalName $adminEmail `
        -DisplayName $adminName `
        -Role "PowerReview-Admin" `
        -Organizations @("All")
    
    Write-Host "`n✅ Initial admin created!" -ForegroundColor Green
    Write-Host "   Remember to set up authentication method (Azure AD or Local)" -ForegroundColor Yellow
}

# Function to create CSV template
function New-UserImportTemplate {
    $template = @"
UserPrincipalName,DisplayName,Role,Organizations,AssignedClients
john.smith@contoso.com,John Smith,PowerReview-Analyst,"Contoso;Fabrikam",
jane.doe@contoso.com,Jane Doe,PowerReview-Developer,,"Contoso;Northwind;AdventureWorks"
bob.wilson@contoso.com,Bob Wilson,PowerReview-Viewer,Contoso,
sarah.johnson@external.com,Sarah Johnson,PowerReview-Auditor,"Contoso;Fabrikam;Tailwind",
mike.brown@contoso.com,Mike Brown,PowerReview-Executive,Contoso,
"@
    
    $template | Out-File -FilePath ".\PowerReview-User-Import-Template.csv" -Encoding UTF8
    Write-Host "✅ User import template created: PowerReview-User-Import-Template.csv" -ForegroundColor Green
}

# Function to test access
function Test-AccessControl {
    Write-Host "`n🧪 Testing Access Control..." -ForegroundColor Yellow
    
    # Create test users if needed
    $users = Get-PowerReviewUsers
    if ($users.Count -eq 0) {
        Write-Host "Creating test users..." -ForegroundColor Gray
        New-SampleUsers
    }
    
    # Test scenarios
    $testScenarios = @(
        @{
            User = "admin@workshop.local"
            Permission = "User.Create"
            Organization = "Contoso"
            Expected = $true
        },
        @{
            User = "analyst1@workshop.local"
            Permission = "Assessment.Create"
            Organization = "Contoso"
            Expected = $true
        },
        @{
            User = "analyst1@workshop.local"
            Permission = "Assessment.Create"
            Organization = "Fabrikam"
            Expected = $false  # Not assigned to Fabrikam
        },
        @{
            User = "viewer@workshop.local"
            Permission = "Assessment.Create"
            Organization = "Contoso"
            Expected = $false  # Viewers can't create
        },
        @{
            User = "developer@workshop.local"
            Permission = "Questionnaire.Create"
            Organization = "Contoso"
            Expected = $true  # Assigned client
        }
    )
    
    Write-Host "`nRunning permission tests:" -ForegroundColor Cyan
    $passed = 0
    $failed = 0
    
    foreach ($test in $testScenarios) {
        $result = Test-PowerReviewPermission -UserPrincipalName $test.User `
            -Permission $test.Permission -Organization $test.Organization
        
        if ($result -eq $test.Expected) {
            Write-Host "✅ PASS: $($test.User) - $($test.Permission) on $($test.Organization)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "❌ FAIL: $($test.User) - $($test.Permission) on $($test.Organization) (Expected: $($test.Expected), Got: $result)" -ForegroundColor Red
            $failed++
        }
    }
    
    Write-Host "`nTest Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
}

# Quick setup function
function Start-QuickRBACSetup {
    Write-Host "`n⚡ Quick RBAC Setup for Workshops" -ForegroundColor Cyan
    
    # Setup local auth
    Initialize-LocalAuthentication
    
    # Create sample users
    New-SampleUsers
    
    # Create import template
    New-UserImportTemplate
    
    # Show summary
    Get-PowerReviewUserSummary
    
    Write-Host @"

✅ RBAC Quick Setup Complete!

Created:
  • 7 sample users with different roles
  • Local authentication configured
  • Import template for bulk users

To use in your scripts:
  1. Load auth module: Import-Module .\PowerReview-Local-Auth.psm1
  2. Login: Connect-PowerReviewLocal -UserPrincipalName "admin@workshop.local" -Password (Read-Host -AsSecureString)
  3. Check permissions: Test-PowerReviewPermission -UserPrincipalName "user@domain" -Permission "Assessment.Create"

"@ -ForegroundColor Green
}

# Main menu
function Show-RBACMenu {
    Write-Host "`nSelect setup option:" -ForegroundColor Yellow
    Write-Host "[1] Quick Setup (Workshop/Local)" -ForegroundColor Cyan
    Write-Host "[2] Azure AD Integration" -ForegroundColor Cyan
    Write-Host "[3] Create Initial Admin" -ForegroundColor Cyan
    Write-Host "[4] Import Users from CSV" -ForegroundColor Cyan
    Write-Host "[5] Test Access Control" -ForegroundColor Cyan
    Write-Host "[6] Show Current Setup" -ForegroundColor Cyan
    Write-Host "[Q] Quit" -ForegroundColor Gray
    
    $choice = Read-Host "`nYour choice"
    
    switch ($choice) {
        "1" { Start-QuickRBACSetup }
        "2" { Initialize-AzureADIntegration }
        "3" { New-InitialAdmin }
        "4" { 
            $csvPath = Read-Host "Enter CSV file path"
            Import-PowerReviewUsers -CsvPath $csvPath
        }
        "5" { Test-AccessControl }
        "6" { Show-CurrentAccessSetup }
        "Q" { return }
        default { Write-Host "Invalid choice" -ForegroundColor Red }
    }
}

# Main execution
if ($ShowCurrentSetup) {
    Show-CurrentAccessSetup
}
elseif ($UseAzureAD) {
    Initialize-AzureADIntegration
}
elseif ($UseLocalAuth) {
    Initialize-LocalAuthentication
}
elseif ($CreateSampleUsers) {
    New-SampleUsers
}
else {
    Show-RBACMenu
}

Write-Host @"

📚 Role Management Commands:
  • Get-PowerReviewRoles - Show all roles
  • Get-PowerReviewUserSummary - Show all users
  • New-PowerReviewUser - Create user
  • Test-PowerReviewPermission - Check permission

"@ -ForegroundColor Cyan