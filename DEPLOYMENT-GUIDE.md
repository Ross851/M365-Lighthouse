# PowerReview Deployment & Security Guide

## 🔒 Secure Deployment Options for Client Portals

### Overview

PowerReview generates sensitive security assessment data that must be protected. This guide provides multiple deployment options for securely sharing assessment results with C-suite executives and authorized stakeholders.

---

## 🚀 Deployment Options

### Option 1: Azure Static Web Apps with AAD Authentication (Recommended)

**Security Level: ⭐⭐⭐⭐⭐**

#### Setup Steps:

1. **Create Azure Static Web App**
   ```bash
   az staticwebapp create \
     --name "powerreview-client-portal" \
     --resource-group "rg-powerreview" \
     --location "eastus" \
     --sku "Standard"
   ```

2. **Configure Authentication**
   ```json
   {
     "auth": {
       "identityProviders": {
         "azureActiveDirectory": {
           "registration": {
             "openIdIssuer": "https://login.microsoftonline.com/{TENANT_ID}",
             "clientId": "{CLIENT_ID}"
           }
         }
       }
     },
     "routes": [
       {
         "route": "/*",
         "allowedRoles": ["authenticated"]
       }
     ]
   }
   ```

3. **Deploy Portal**
   ```powershell
   # Generate portal
   .\PowerReview-Client-Portal.ps1 `
     -AssessmentPath ".\Results" `
     -ClientName "Contoso" `
     -AuthorizedEmails @("ceo@contoso.com", "ciso@contoso.com")
   
   # Deploy to Azure
   az staticwebapp deployment start \
     --name "powerreview-client-portal" \
     --source "./ClientPortal"
   ```

4. **Set Access Restrictions**
   - Configure IP restrictions
   - Enable MFA requirement
   - Set conditional access policies

**Pros:**
- Enterprise AAD authentication
- No infrastructure management
- Automatic SSL/TLS
- Global CDN
- Audit logging

**Cons:**
- Requires Azure subscription
- Client needs AAD accounts

---

### Option 2: SharePoint Online with External Sharing

**Security Level: ⭐⭐⭐⭐**

#### Setup Steps:

1. **Create Dedicated Site**
   ```powershell
   # Create site collection
   New-SPOSite -Url "https://tenant.sharepoint.com/sites/ClientPortals" `
     -Owner "admin@tenant.com" `
     -Template "STS#3" `
     -StorageQuota 1024
   ```

2. **Configure Permissions**
   ```powershell
   # Set sharing settings
   Set-SPOSite -Identity "https://tenant.sharepoint.com/sites/ClientPortals" `
     -SharingCapability ExternalUserSharingOnly `
     -RequireAnonymousLinksExpireInDays 30
   ```

3. **Upload Portal**
   ```powershell
   # Create client folder
   Add-PnPFolder -Name "Contoso_$(Get-Date -Format 'yyyyMMdd')" `
     -Folder "Shared Documents"
   
   # Upload with unique permissions
   $file = Add-PnPFile -Path ".\portal.html" `
     -Folder "Shared Documents/Contoso_$(Get-Date -Format 'yyyyMMdd')"
   
   # Create secure sharing link
   New-PnPSharingLink -Identity $file.ServerRelativeUrl `
     -ShareType "Direct" `
     -Scope "Specific" `
     -Expiration (Get-Date).AddDays(30)
   ```

**Pros:**
- Familiar interface for clients
- Built-in version control
- Mobile friendly
- No additional licensing

**Cons:**
- Requires guest access setup
- Limited customization
- SharePoint branding

---

### Option 3: Encrypted Container (Offline Viewing)

**Security Level: ⭐⭐⭐⭐⭐**

#### Setup Steps:

1. **Create Self-Contained Package**
   ```powershell
   # Generate encrypted portal
   .\PowerReview-Client-Portal.ps1 `
     -AssessmentPath ".\Results" `
     -ClientName "Contoso" `
     -GenerateOfflinePackage
   
   # Create encrypted container
   $container = @{
     Portal = Get-Content ".\portal.html" -Raw
     Assets = Get-ChildItem ".\assets" -Recurse
     Timestamp = Get-Date
   }
   
   # Encrypt with password
   $secureString = ConvertTo-SecureString -String $container -AsPlainText -Force
   $encrypted = ConvertFrom-SecureString -SecureString $secureString
   
   # Save to file
   $encrypted | Out-File "PowerReview_Contoso_Secure.dat"
   ```

2. **Create Viewer Application**
   ```powershell
   # Bundle with portable viewer
   $viewer = @"
   <!DOCTYPE html>
   <html>
   <head>
       <title>PowerReview Secure Viewer</title>
       <script>
           function decryptAndDisplay() {
               const password = prompt('Enter password:');
               // Decrypt and display portal
           }
       </script>
   </head>
   <body onload="decryptAndDisplay()">
       <div id="portal"></div>
   </body>
   </html>
   "@
   ```

3. **Deliver via Secure Channel**
   - Encrypted USB drive
   - Secure file transfer
   - In-person delivery

**Pros:**
- No internet required
- Complete control
- No external dependencies
- Highest security

**Cons:**
- Manual distribution
- No real-time updates
- Password management

---

### Option 4: Azure Key Vault + Function App

**Security Level: ⭐⭐⭐⭐⭐**

#### Architecture:
```
Client → Function App → Key Vault → Blob Storage
         ↓
    Auth Provider
```

#### Implementation:
```powershell
# Function App code
function Get-SecurePortal {
    param($Request)
    
    # Validate token
    $token = $Request.Headers.Authorization
    if (!(Test-PortalToken $token)) {
        return @{ StatusCode = 401 }
    }
    
    # Get portal from Key Vault
    $secret = Get-AzKeyVaultSecret -VaultName "kv-powerreview" `
      -Name "portal-$($Request.Query.ClientId)"
    
    # Return decrypted content
    return @{
        StatusCode = 200
        Body = $secret.SecretValueText
        Headers = @{
            "Content-Type" = "text/html"
            "Cache-Control" = "no-store"
        }
    }
}
```

---

## 🛡️ Security Best Practices

### 1. **Data Classification**
```powershell
# Tag all assessment data
$classification = @{
    Level = "Highly Confidential"
    Handling = "C-Suite Only"
    Retention = "90 days"
    Encryption = "Required"
}
```

### 2. **Access Control Matrix**

| Role | Portal Access | Evidence Access | Download | Print |
|------|--------------|-----------------|----------|-------|
| C-Suite | ✅ Full | ❌ Summary Only | ✅ Yes | ✅ Yes |
| Security Team | ✅ Full | ✅ Full | ✅ Yes | ❌ No |
| External Auditor | ✅ Limited | ❌ No | ❌ No | ❌ No |

### 3. **Encryption Standards**
- **At Rest:** AES-256
- **In Transit:** TLS 1.3
- **Key Management:** Azure Key Vault or HSM
- **Password Policy:** 16+ characters, complexity required

### 4. **Audit Requirements**
```powershell
# Log all access
$auditLog = @{
    Timestamp = Get-Date
    User = $Request.User
    Action = "ViewPortal"
    IPAddress = $Request.IPAddress
    Location = Get-GeoLocation $Request.IPAddress
    Device = $Request.UserAgent
}

# Send to SIEM
Send-AuditLog -Log $auditLog -Destination "https://siem.company.com"
```

---

## 📊 Monitoring & Compliance

### Security Monitoring Dashboard
```powershell
# Monitor portal access
Get-PortalMetrics | ForEach-Object {
    if ($_.FailedAttempts -gt 3) {
        Send-Alert -Type "Security" -Message "Multiple failed login attempts"
    }
    
    if ($_.AccessLocation -notin $AllowedCountries) {
        Send-Alert -Type "Security" -Message "Access from unauthorized location"
    }
}
```

### Compliance Checklist
- [ ] Data residency requirements met
- [ ] Encryption standards implemented
- [ ] Access logging enabled
- [ ] Retention policies configured
- [ ] Right to erasure supported
- [ ] Breach notification ready

---

## 🚨 Incident Response

### If Portal is Compromised:

1. **Immediate Actions**
   ```powershell
   # Revoke all access
   Revoke-PortalAccess -All
   
   # Generate incident report
   New-IncidentReport -Type "DataExposure" -Severity "High"
   
   # Notify stakeholders
   Send-Notification -Recipients $SecurityTeam -Priority "Urgent"
   ```

2. **Investigation**
   - Review access logs
   - Identify exposure window
   - Determine data accessed
   - Document timeline

3. **Remediation**
   - Reset all credentials
   - Re-encrypt data
   - Deploy new portal
   - Update security controls

---

## 📱 Client Access Instructions

### For C-Suite Users:

```markdown
# Accessing Your Security Assessment

1. **Check Your Email**
   - Look for email from: noreply@powerreview-secure.com
   - Subject: "Your Confidential Security Assessment is Ready"

2. **Access the Portal**
   - Click the secure link (valid for 30 days)
   - Enter your corporate email address
   - Enter the access code from the email

3. **Complete MFA**
   - Approve the push notification on your phone
   - Or enter the code from your authenticator app

4. **Navigate the Report**
   - Executive Summary: High-level findings and business impact
   - Technical Details: Detailed security issues (optional)
   - Compliance: Regulatory implications
   - Roadmap: Recommended actions and timeline

5. **Security Notes**
   - Do not share the link or access code
   - Portal expires in 30 days
   - Sessions timeout after 30 minutes
   - Downloads are watermarked

For support: security@yourcompany.com
```

---

## 🔧 Troubleshooting

### Common Issues:

1. **"Access Denied" Error**
   - Verify email is authorized
   - Check token hasn't expired
   - Ensure MFA is configured

2. **Portal Won't Load**
   - Clear browser cache
   - Try incognito/private mode
   - Check firewall settings

3. **Can't Download Report**
   - Verify download permissions
   - Check browser popup blocker
   - Try different browser

---

## 📋 Deployment Checklist

Before deploying client portal:

- [ ] Assessment data validated
- [ ] Evidence redacted appropriately 
- [ ] Client emails verified
- [ ] Deployment method selected
- [ ] Security controls configured
- [ ] Access credentials generated
- [ ] Monitoring enabled
- [ ] Incident response ready
- [ ] Client instructions prepared
- [ ] Support contact provided

---

## 🏆 Recommended Architecture

For enterprise deployments, we recommend:

1. **Frontend:** Azure Static Web Apps
2. **Authentication:** Azure AD B2B
3. **Storage:** Azure Blob with encryption
4. **Secrets:** Azure Key Vault
5. **Monitoring:** Application Insights
6. **WAF:** Azure Front Door
7. **Backup:** Geo-redundant storage

This provides:
- 99.95% availability SLA
- Global distribution
- Enterprise authentication
- Complete audit trail
- Regulatory compliance
- Disaster recovery

---

*Remember: Security is not a feature, it's a requirement. Every deployment decision should prioritize protecting client data.*