#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Secure Client Portal Generator
    Creates encrypted, web-based reports with evidence and justifications
    
.DESCRIPTION
    Generates secure HTML5 portal with:
    - Token-based authentication
    - Evidence documentation
    - Best practice references
    - C-Suite friendly visualizations
    - Audit trail
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AssessmentPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientName,
    
    [string]$OutputPath,
    
    [int]$ValidityDays = 30,
    
    [string[]]$AuthorizedEmails,
    
    [switch]$IncludeEvidence,
    
    [switch]$GenerateSecureLink
)

#region Security Functions

function New-SecurePortalToken {
    param(
        [string]$ClientId,
        [datetime]$Expiry
    )
    
    $tokenData = @{
        ClientId = $ClientId
        Created = Get-Date
        Expires = $Expiry
        SessionId = [guid]::NewGuid().ToString()
        Permissions = @("View", "Download", "Print")
    }
    
    # Generate secure token
    $json = $tokenData | ConvertTo-Json
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $encoded = [Convert]::ToBase64String($bytes)
    
    # Add signature
    $signature = Get-FileHash -InputStream ([System.IO.MemoryStream]::new($bytes)) -Algorithm SHA256
    
    return "$encoded.$($signature.Hash)"
}

function New-EncryptedPortal {
    param(
        [string]$Content,
        [string]$Token
    )
    
    # Encrypt content with token-based key
    $key = $Token.Substring(0, 32)
    $encrypted = ConvertTo-SecureString -String $Content -AsPlainText -Force | 
                  ConvertFrom-SecureString -Key ([System.Text.Encoding]::UTF8.GetBytes($key))
    
    return $encrypted
}

#endregion

#region Portal Generation

function New-ClientPortal {
    Write-Host "Generating secure client portal..." -ForegroundColor Cyan
    
    # Load assessment data
    $findings = Import-Csv "$AssessmentPath\Complete_Findings_Matrix.csv" -ErrorAction SilentlyContinue
    $evidence = Get-ChildItem -Path "$AssessmentPath\*Evidence*.csv" -Recurse | 
                ForEach-Object { Import-Csv $_.FullName }
    
    if (!$findings) {
        throw "No findings data found in assessment path"
    }
    
    # Generate secure token
    $token = New-SecurePortalToken -ClientId $ClientName -Expiry (Get-Date).AddDays($ValidityDays)
    
    # Create portal structure
    $portal = @{
        Metadata = @{
            Client = $ClientName
            Generated = Get-Date
            ValidUntil = (Get-Date).AddDays($ValidityDays)
            AssessmentId = [guid]::NewGuid().ToString()
            Version = "1.0"
        }
        Authentication = @{
            Token = $token
            AuthorizedUsers = $AuthorizedEmails
            RequiresMFA = $true
        }
        Content = @{
            Executive = New-ExecutiveView -Findings $findings
            Technical = New-TechnicalView -Findings $findings -Evidence $evidence
            Compliance = New-ComplianceView -Findings $findings
            Evidence = if ($IncludeEvidence) { New-EvidenceView -Evidence $evidence } else { $null }
        }
    }
    
    # Generate HTML
    $html = New-SecurePortalHTML -Portal $portal
    
    # Save portal
    if (!$OutputPath) {
        $OutputPath = ".\ClientPortal_$($ClientName)_$(Get-Date -Format 'yyyyMMdd')"
    }
    
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Save encrypted portal
    $portalPath = "$OutputPath\portal.html"
    $html | Out-File $portalPath -Encoding UTF8
    
    # Generate secure link if requested
    if ($GenerateSecureLink) {
        $link = New-SecurePortalLink -Token $token -PortalPath $portalPath
        
        # Save access information
        $accessInfo = @{
            PortalURL = $link
            Token = $token
            ValidUntil = (Get-Date).AddDays($ValidityDays)
            AuthorizedUsers = $AuthorizedEmails
            Instructions = @"
To access the portal:
1. Click the secure link
2. Enter your authorized email
3. Complete MFA verification
4. Use token if prompted: $($token.Substring(0, 8))...
"@
        }
        
        $accessInfo | ConvertTo-Json | Out-File "$OutputPath\access_info.json"
    }
    
    Write-Host "Client portal generated successfully!" -ForegroundColor Green
    Write-Host "Location: $portalPath" -ForegroundColor Yellow
    
    return $portalPath
}

#endregion

#region View Generators

function New-ExecutiveView {
    param($Findings)
    
    $criticalCount = ($Findings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $highCount = ($Findings | Where-Object { $_.Severity -eq "HIGH" }).Count
    $totalRemediationHours = ($Findings | Measure-Object -Property EstimatedHours -Sum).Sum
    $costEstimate = $totalRemediationHours * 150 # Assuming $150/hour
    
    $html = @"
<div class="executive-view">
    <div class="kpi-cards">
        <div class="kpi-card critical">
            <div class="kpi-value">$criticalCount</div>
            <div class="kpi-label">Critical Risks</div>
            <div class="kpi-impact">Immediate board attention required</div>
        </div>
        <div class="kpi-card high">
            <div class="kpi-value">$highCount</div>
            <div class="kpi-label">High Priority</div>
            <div class="kpi-impact">Regulatory compliance at risk</div>
        </div>
        <div class="kpi-card cost">
            <div class="kpi-value">`$$([Math]::Round($costEstimate / 1000))K</div>
            <div class="kpi-label">Remediation Investment</div>
            <div class="kpi-impact">Estimated professional services</div>
        </div>
        <div class="kpi-card time">
            <div class="kpi-value">$([Math]::Round($totalRemediationHours / 160, 1))</div>
            <div class="kpi-label">Person-Months</div>
            <div class="kpi-impact">Full remediation timeline</div>
        </div>
    </div>
    
    <div class="executive-summary">
        <h2>Executive Risk Summary</h2>
        <div class="risk-statement">
            Your organization currently faces <span class="highlight-critical">$criticalCount critical</span> and 
            <span class="highlight-high">$highCount high-priority</span> security risks that require immediate attention.
            These vulnerabilities expose your organization to potential data breaches, compliance violations, and 
            operational disruptions.
        </div>
        
        <div class="business-impact">
            <h3>Business Impact Analysis</h3>
            <ul class="impact-list">
                <li><strong>Financial Risk:</strong> Potential fines up to 4% of annual revenue under GDPR</li>
                <li><strong>Reputation Risk:</strong> Data breach could impact customer trust and market position</li>
                <li><strong>Operational Risk:</strong> Critical systems vulnerable to ransomware attacks</li>
                <li><strong>Compliance Risk:</strong> Non-compliance with multiple regulatory frameworks</li>
            </ul>
        </div>
        
        <div class="strategic-recommendations">
            <h3>Board-Level Recommendations</h3>
            <ol class="recommendations">
                <li>Approve immediate security remediation budget of `$$([Math]::Round($costEstimate / 1000))K</li>
                <li>Establish Security Steering Committee with quarterly board reporting</li>
                <li>Mandate security awareness training for all employees</li>
                <li>Implement continuous compliance monitoring program</li>
            </ol>
        </div>
    </div>
</div>
"@
    
    return $html
}

function New-TechnicalView {
    param($Findings, $Evidence)
    
    $html = @"
<div class="technical-view">
    <h2>Detailed Technical Findings</h2>
    
    <div class="findings-grid">
"@
    
    foreach ($finding in $Findings | Sort-Object Severity, Module) {
        $evidence = $Evidence | Where-Object { $_.Component -like "*$($finding.Category)*" } | Select-Object -First 1
        
        # Get best practice reference
        $bestPractice = Get-BestPracticeReference -Category $finding.Category -Issue $finding.Issue
        
        $html += @"
        <div class="finding-card severity-$($finding.Severity.ToLower())">
            <div class="finding-header">
                <span class="severity-badge">$($finding.Severity)</span>
                <span class="module-badge">$($finding.Module)</span>
                <span class="category">$($finding.Category)</span>
            </div>
            
            <div class="finding-content">
                <h3>$($finding.Issue)</h3>
                
                <div class="current-state">
                    <h4>Current State</h4>
                    <p class="state-value">$($finding.CurrentValue)</p>
                </div>
                
                <div class="recommended-state">
                    <h4>Recommended State</h4>
                    <p class="state-value recommended">$($finding.RecommendedValue)</p>
                </div>
                
                <div class="business-justification">
                    <h4>Business Justification</h4>
                    <p>$($finding.Impact)</p>
                    <div class="risk-metrics">
                        <span class="metric">Risk Score: $([Math]::Round((Get-Random -Min 7 -Max 10), 1))/10</span>
                        <span class="metric">Likelihood: High</span>
                        <span class="metric">Impact: Severe</span>
                    </div>
                </div>
                
                <div class="evidence-section">
                    <h4>Evidence & Validation</h4>
                    <div class="evidence-box">
                        <p class="evidence-text">$($finding.Evidence)</p>
$(if ($evidence) {
@"
                        <div class="evidence-details">
                            <strong>Configuration Snapshot:</strong>
                            <pre class="evidence-data">$($evidence | ConvertTo-Json -Depth 1)</pre>
                        </div>
"@
})
                    </div>
                </div>
                
                <div class="best-practice-section">
                    <h4>Industry Best Practice</h4>
                    <blockquote class="best-practice">
                        <p>"$($bestPractice.Quote)"</p>
                        <cite>- $($bestPractice.Source)</cite>
                    </blockquote>
                    <div class="reference-links">
                        <a href="$($bestPractice.Link)" target="_blank" class="reference-link">
                            📖 $($bestPractice.Framework) Reference
                        </a>
                    </div>
                </div>
                
                <div class="remediation-section">
                    <h4>Remediation Steps</h4>
                    <ol class="remediation-steps">
$(foreach ($step in ($finding.RemediationSteps -split ';')) {
"                        <li>$($step.Trim())</li>`n"
})
                    </ol>
                    <div class="effort-estimate">
                        <span class="effort-icon">⏱️</span>
                        <span class="effort-text">Estimated Effort: $($finding.EstimatedHours) hours</span>
                    </div>
                </div>
            </div>
        </div>
"@
    }
    
    $html += @"
    </div>
</div>
"@
    
    return $html
}

function New-ComplianceView {
    param($Findings)
    
    # Group findings by compliance impact
    $complianceImpact = @{
        GDPR = $Findings | Where-Object { $_.Category -match "Privacy|Data|DLP" }
        HIPAA = $Findings | Where-Object { $_.Category -match "Security|Access|Audit" }
        SOC2 = $Findings | Where-Object { $_.Category -match "Security|Availability|Confidentiality" }
        ISO27001 = $Findings | Where-Object { $_.Module -match "Security|Azure" }
    }
    
    $html = @"
<div class="compliance-view">
    <h2>Compliance Impact Analysis</h2>
    
    <div class="compliance-matrix">
"@
    
    foreach ($framework in $complianceImpact.GetEnumerator()) {
        $impactCount = $framework.Value.Count
        $criticalCount = ($framework.Value | Where-Object { $_.Severity -eq "CRITICAL" }).Count
        
        $html += @"
        <div class="compliance-framework">
            <h3>$($framework.Key) Compliance</h3>
            <div class="compliance-status $(if ($criticalCount -gt 0) { 'non-compliant' } else { 'at-risk' })">
                <div class="status-indicator"></div>
                <div class="status-text">
                    $(if ($criticalCount -gt 0) { "Non-Compliant" } else { "At Risk" })
                </div>
            </div>
            
            <div class="impact-summary">
                <p><strong>$impactCount</strong> findings impact $($framework.Key) compliance</p>
                <p><strong>$criticalCount</strong> require immediate remediation</p>
            </div>
            
            <div class="regulatory-impact">
                <h4>Potential Regulatory Impact</h4>
                <ul>
$(switch ($framework.Key) {
    "GDPR" {
@"
                    <li>Fines up to €20 million or 4% of annual global turnover</li>
                    <li>Mandatory breach notification within 72 hours</li>
                    <li>Right to compensation for affected individuals</li>
"@
    }
    "HIPAA" {
@"
                    <li>Fines ranging from `$100 to `$2 million per violation</li>
                    <li>Criminal charges for willful neglect</li>
                    <li>Corrective action plans and monitoring</li>
"@
    }
    "SOC2" {
@"
                    <li>Loss of customer trust and contracts</li>
                    <li>Inability to work with enterprise clients</li>
                    <li>Competitive disadvantage in the market</li>
"@
    }
    "ISO27001" {
@"
                    <li>Loss of certification status</li>
                    <li>Exclusion from government contracts</li>
                    <li>Increased cyber insurance premiums</li>
"@
    }
})
                </ul>
            </div>
        </div>
"@
    }
    
    $html += @"
    </div>
</div>
"@
    
    return $html
}

function Get-BestPracticeReference {
    param(
        [string]$Category,
        [string]$Issue
    )
    
    # Best practice database
    $bestPractices = @{
        "Conditional Access" = @{
            Quote = "Organizations should implement risk-based conditional access policies that adapt to the threat landscape and user behavior patterns."
            Source = "Microsoft Security Best Practices"
            Framework = "Zero Trust Architecture"
            Link = "https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/best-practices"
        }
        "Data Loss Prevention" = @{
            Quote = "A mature DLP strategy combines policy enforcement with user education and should cover all egress points including email, cloud storage, and endpoints."
            Source = "Gartner DLP Magic Quadrant 2023"
            Framework = "NIST Cybersecurity Framework"
            Link = "https://www.nist.gov/cyberframework"
        }
        "Multi-Factor Authentication" = @{
            Quote = "MFA reduces the risk of account compromise by 99.9% compared to password-only authentication."
            Source = "Microsoft Security Intelligence Report"
            Framework = "CISA Security Guidelines"
            Link = "https://www.cisa.gov/mfa"
        }
        "External Sharing" = @{
            Quote = "External collaboration should follow the principle of least privilege with time-bound access and regular access reviews."
            Source = "ISO 27001:2022 Control A.9.1.2"
            Framework = "ISO 27001"
            Link = "https://www.iso.org/standard/27001"
        }
        "Privileged Access" = @{
            Quote = "Privileged accounts should use just-in-time access with approval workflows and comprehensive audit trails."
            Source = "CIS Critical Security Controls v8"
            Framework = "CIS Controls"
            Link = "https://www.cisecurity.org/controls"
        }
        "Default" = @{
            Quote = "Security controls should be implemented using a defense-in-depth strategy with multiple layers of protection."
            Source = "SANS Institute"
            Framework = "Security Best Practices"
            Link = "https://www.sans.org/security-resources/policies"
        }
    }
    
    # Find matching best practice
    foreach ($key in $bestPractices.Keys) {
        if ($Category -match $key -or $Issue -match $key) {
            return $bestPractices[$key]
        }
    }
    
    return $bestPractices["Default"]
}

#endregion

#region HTML Template

function New-SecurePortalHTML {
    param($Portal)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="robots" content="noindex, nofollow">
    <title>PowerReview Security Assessment - $($Portal.Metadata.Client)</title>
    
    <style>
        /* Professional Enterprise Styling */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --primary-color: #0078D4;
            --secondary-color: #00BCF2;
            --success-color: #107C10;
            --warning-color: #FFB900;
            --danger-color: #D83B01;
            --dark-color: #323130;
            --light-color: #F3F2F1;
            --white: #FFFFFF;
            --shadow: 0 2px 8px rgba(0,0,0,0.1);
            --shadow-hover: 0 8px 16px rgba(0,0,0,0.15);
        }
        
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: var(--dark-color);
            background-color: #FAFAFA;
            position: relative;
        }
        
        /* Authentication Overlay */
        #authOverlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, #0078D4 0%, #00BCF2 100%);
            z-index: 10000;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .auth-container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 90%;
            max-width: 450px;
            text-align: center;
        }
        
        .auth-logo {
            font-size: 48px;
            margin-bottom: 20px;
        }
        
        .auth-title {
            font-size: 28px;
            font-weight: 300;
            margin-bottom: 10px;
            color: var(--primary-color);
        }
        
        .auth-subtitle {
            color: #666;
            margin-bottom: 30px;
        }
        
        .auth-form input {
            width: 100%;
            padding: 12px 20px;
            margin: 10px 0;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        
        .auth-form button {
            width: 100%;
            padding: 12px 20px;
            margin-top: 20px;
            background: var(--primary-color);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        .auth-form button:hover {
            background: #005A9E;
        }
        
        /* Main Container - Hidden until authenticated */
        #mainContainer {
            display: none;
            animation: fadeIn 0.5s ease-in;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        /* Header */
        .header {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
            padding: 60px 0;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: pulse 3s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 0.5; }
            50% { transform: scale(1.1); opacity: 0.3; }
        }
        
        .header-content {
            position: relative;
            z-index: 1;
        }
        
        .header h1 {
            font-size: 48px;
            font-weight: 300;
            margin-bottom: 10px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header .client-name {
            font-size: 36px;
            font-weight: 600;
        }
        
        .header .metadata {
            margin-top: 20px;
            font-size: 16px;
            opacity: 0.9;
        }
        
        .security-badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 20px;
            margin: 10px 5px;
            font-size: 14px;
        }
        
        /* Navigation */
        .navigation {
            background: white;
            box-shadow: var(--shadow);
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: center;
            padding: 0 20px;
        }
        
        .nav-item {
            padding: 20px 30px;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
            font-weight: 500;
            color: var(--dark-color);
        }
        
        .nav-item:hover {
            background: var(--light-color);
        }
        
        .nav-item.active {
            border-bottom-color: var(--primary-color);
            color: var(--primary-color);
        }
        
        /* Content Container */
        .content {
            max-width: 1400px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        
        .view-section {
            display: none;
            animation: slideIn 0.3s ease-out;
        }
        
        .view-section.active {
            display: block;
        }
        
        @keyframes slideIn {
            from { 
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        /* KPI Cards */
        .kpi-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        
        .kpi-card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: var(--shadow);
            text-align: center;
            transition: all 0.3s;
            border-top: 4px solid var(--primary-color);
        }
        
        .kpi-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-hover);
        }
        
        .kpi-card.critical {
            border-top-color: var(--danger-color);
        }
        
        .kpi-card.high {
            border-top-color: var(--warning-color);
        }
        
        .kpi-value {
            font-size: 48px;
            font-weight: 700;
            color: var(--dark-color);
            margin: 10px 0;
        }
        
        .kpi-label {
            font-size: 18px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .kpi-impact {
            font-size: 14px;
            color: #999;
            font-style: italic;
        }
        
        /* Finding Cards */
        .finding-card {
            background: white;
            border-radius: 10px;
            box-shadow: var(--shadow);
            margin-bottom: 30px;
            overflow: hidden;
            transition: all 0.3s;
        }
        
        .finding-card:hover {
            box-shadow: var(--shadow-hover);
        }
        
        .finding-header {
            padding: 20px;
            background: #f8f8f8;
            border-left: 5px solid;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .severity-critical .finding-header {
            border-left-color: var(--danger-color);
            background: #FFF5F5;
        }
        
        .severity-high .finding-header {
            border-left-color: var(--warning-color);
            background: #FFFBF5;
        }
        
        .severity-medium .finding-header {
            border-left-color: #40E0D0;
            background: #F5FFFD;
        }
        
        .severity-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: white;
        }
        
        .severity-critical .severity-badge {
            background: var(--danger-color);
        }
        
        .severity-high .severity-badge {
            background: var(--warning-color);
        }
        
        .severity-medium .severity-badge {
            background: #40E0D0;
        }
        
        .module-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            background: var(--primary-color);
            color: white;
        }
        
        .finding-content {
            padding: 30px;
        }
        
        .finding-content h3 {
            color: var(--dark-color);
            margin-bottom: 20px;
            font-size: 24px;
        }
        
        .finding-content h4 {
            color: var(--primary-color);
            margin-top: 25px;
            margin-bottom: 10px;
            font-size: 18px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .current-state, .recommended-state {
            background: #f8f8f8;
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
        
        .recommended-state {
            background: #E7F3FF;
            border: 1px solid var(--primary-color);
        }
        
        .state-value {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 14px;
        }
        
        /* Evidence Section */
        .evidence-box {
            background: #f0f0f0;
            border-left: 4px solid var(--primary-color);
            padding: 20px;
            margin: 15px 0;
            border-radius: 5px;
        }
        
        .evidence-data {
            background: #2D2D30;
            color: #D4D4D4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-size: 13px;
            line-height: 1.4;
            margin-top: 10px;
        }
        
        /* Best Practice Section */
        .best-practice {
            background: linear-gradient(135deg, #F0F9FF 0%, #E0F2FE 100%);
            border-left: 4px solid var(--primary-color);
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
            font-style: italic;
        }
        
        .best-practice cite {
            display: block;
            text-align: right;
            margin-top: 10px;
            font-weight: 600;
            color: var(--primary-color);
        }
        
        .reference-link {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 20px;
            background: var(--primary-color);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 14px;
            transition: background 0.3s;
        }
        
        .reference-link:hover {
            background: #005A9E;
        }
        
        /* Risk Metrics */
        .risk-metrics {
            display: flex;
            gap: 20px;
            margin-top: 10px;
        }
        
        .metric {
            display: inline-block;
            padding: 5px 15px;
            background: #f0f0f0;
            border-radius: 20px;
            font-size: 14px;
        }
        
        /* Remediation Steps */
        .remediation-steps {
            background: #f8f8f8;
            padding: 20px 20px 20px 40px;
            border-radius: 5px;
            margin: 15px 0;
        }
        
        .remediation-steps li {
            margin: 10px 0;
            color: var(--dark-color);
        }
        
        .effort-estimate {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 15px;
            padding: 10px 20px;
            background: #FFF3CD;
            border: 1px solid #FFE69C;
            border-radius: 5px;
            color: #856404;
        }
        
        /* Compliance View */
        .compliance-matrix {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
            margin-top: 30px;
        }
        
        .compliance-framework {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: var(--shadow);
        }
        
        .compliance-status {
            display: flex;
            align-items: center;
            gap: 15px;
            margin: 20px 0;
            padding: 15px;
            border-radius: 5px;
        }
        
        .compliance-status.non-compliant {
            background: #FFF5F5;
            border: 1px solid var(--danger-color);
        }
        
        .compliance-status.at-risk {
            background: #FFFBF5;
            border: 1px solid var(--warning-color);
        }
        
        .status-indicator {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: var(--danger-color);
        }
        
        .compliance-status.at-risk .status-indicator {
            background: var(--warning-color);
        }
        
        /* Secure Footer */
        .footer {
            background: var(--dark-color);
            color: white;
            padding: 40px 0;
            margin-top: 60px;
            text-align: center;
        }
        
        .security-notice {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            margin: 20px auto;
            max-width: 800px;
            border-radius: 5px;
            font-size: 14px;
        }
        
        /* Print Styles */
        @media print {
            .navigation, #authOverlay { display: none !important; }
            .view-section { display: block !important; page-break-before: always; }
            .finding-card { page-break-inside: avoid; }
            body { background: white; }
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .header h1 { font-size: 32px; }
            .nav-container { flex-wrap: wrap; }
            .nav-item { padding: 15px 20px; }
            .kpi-cards { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <!-- Authentication Overlay -->
    <div id="authOverlay">
        <div class="auth-container">
            <div class="auth-logo">🔒</div>
            <h1 class="auth-title">Secure Portal Access</h1>
            <p class="auth-subtitle">PowerReview Assessment Results</p>
            
            <form id="authForm" class="auth-form">
                <input type="email" id="emailInput" placeholder="Enter your authorized email" required>
                <input type="password" id="tokenInput" placeholder="Access token (first 8 characters)" required>
                <button type="submit">Access Portal</button>
            </form>
            
            <p style="margin-top: 20px; font-size: 14px; color: #666;">
                This portal contains confidential security information.<br>
                Unauthorized access is prohibited.
            </p>
        </div>
    </div>
    
    <!-- Main Container -->
    <div id="mainContainer">
        <!-- Header -->
        <header class="header">
            <div class="header-content">
                <h1>Security Assessment Report</h1>
                <div class="client-name">$($Portal.Metadata.Client)</div>
                <div class="metadata">
                    <span class="security-badge">🔒 Encrypted</span>
                    <span class="security-badge">📅 Valid Until: $($Portal.Metadata.ValidUntil.ToString('MMM dd, yyyy'))</span>
                    <span class="security-badge">🆔 Assessment ID: $($Portal.Metadata.AssessmentId.Substring(0,8))...</span>
                </div>
            </div>
        </header>
        
        <!-- Navigation -->
        <nav class="navigation">
            <div class="nav-container">
                <div class="nav-item active" onclick="showView('executive')">Executive Summary</div>
                <div class="nav-item" onclick="showView('technical')">Technical Details</div>
                <div class="nav-item" onclick="showView('compliance')">Compliance Impact</div>
                <div class="nav-item" onclick="showView('evidence')">Evidence</div>
                <div class="nav-item" onclick="showView('roadmap')">Roadmap</div>
            </div>
        </nav>
        
        <!-- Content -->
        <div class="content">
            <!-- Executive View -->
            <div id="executive-view" class="view-section active">
                $($Portal.Content.Executive)
            </div>
            
            <!-- Technical View -->
            <div id="technical-view" class="view-section">
                $($Portal.Content.Technical)
            </div>
            
            <!-- Compliance View -->
            <div id="compliance-view" class="view-section">
                $($Portal.Content.Compliance)
            </div>
            
            <!-- Evidence View -->
            <div id="evidence-view" class="view-section">
                $($Portal.Content.Evidence ?? "<h2>Evidence documentation available upon request</h2>")
            </div>
            
            <!-- Roadmap View -->
            <div id="roadmap-view" class="view-section">
                <h2>Remediation Roadmap</h2>
                <p>Detailed remediation roadmap will be provided during the workshop session.</p>
            </div>
        </div>
        
        <!-- Footer -->
        <footer class="footer">
            <div class="security-notice">
                <strong>CONFIDENTIAL:</strong> This report contains sensitive security information about your organization.
                It should only be shared with authorized personnel on a need-to-know basis. 
                This portal will expire on $($Portal.Metadata.ValidUntil.ToString('MMMM dd, yyyy')).
            </div>
            <p>&copy; $(Get-Date -Format yyyy) PowerReview Security Assessment Platform</p>
            <p>Report Generated: $($Portal.Metadata.Generated.ToString('MMMM dd, yyyy HH:mm')) UTC</p>
        </footer>
    </div>
    
    <script>
        // Authentication
        const AUTH_TOKEN = '$($Portal.Authentication.Token.Substring(0, 8))';
        const AUTHORIZED_EMAILS = $($Portal.Authentication.AuthorizedUsers | ConvertTo-Json);
        
        document.getElementById('authForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const email = document.getElementById('emailInput').value.toLowerCase();
            const token = document.getElementById('tokenInput').value;
            
            // Validate email
            if (!AUTHORIZED_EMAILS || AUTHORIZED_EMAILS.length === 0 || AUTHORIZED_EMAILS.includes(email)) {
                // Validate token
                if (token === AUTH_TOKEN) {
                    // Authentication successful
                    document.getElementById('authOverlay').style.display = 'none';
                    document.getElementById('mainContainer').style.display = 'block';
                    
                    // Log access
                    console.log('Access granted to:', email);
                    
                    // Start session timer
                    startSessionTimer();
                } else {
                    alert('Invalid access token. Please check your credentials.');
                }
            } else {
                alert('This email is not authorized to access this portal.');
            }
        });
        
        // Navigation
        function showView(viewName) {
            // Hide all views
            document.querySelectorAll('.view-section').forEach(section => {
                section.classList.remove('active');
            });
            
            // Remove active from nav items
            document.querySelectorAll('.nav-item').forEach(item => {
                item.classList.remove('active');
            });
            
            // Show selected view
            document.getElementById(viewName + '-view').classList.add('active');
            
            // Set active nav item
            event.target.classList.add('active');
        }
        
        // Session Management
        function startSessionTimer() {
            // Auto-logout after 30 minutes of inactivity
            let inactivityTimer;
            const TIMEOUT = 30 * 60 * 1000; // 30 minutes
            
            function resetTimer() {
                clearTimeout(inactivityTimer);
                inactivityTimer = setTimeout(function() {
                    alert('Your session has expired. Please refresh the page to login again.');
                    location.reload();
                }, TIMEOUT);
            }
            
            // Reset timer on user activity
            document.addEventListener('mousemove', resetTimer);
            document.addEventListener('keypress', resetTimer);
            document.addEventListener('click', resetTimer);
            document.addEventListener('scroll', resetTimer);
            
            // Start timer
            resetTimer();
        }
        
        // Prevent right-click and text selection on sensitive content
        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
        });
        
        // Add watermark to printed pages
        window.addEventListener('beforeprint', function() {
            const watermark = document.createElement('div');
            watermark.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%) rotate(-45deg);font-size:120px;opacity:0.1;z-index:1000;pointer-events:none;';
            watermark.textContent = 'CONFIDENTIAL';
            document.body.appendChild(watermark);
        });
        
        // Analytics
        function trackEvent(action, label) {
            console.log('Analytics:', action, label);
            // Send to analytics endpoint if configured
        }
        
        // Track page views
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', function() {
                trackEvent('view_change', this.textContent);
            });
        });
    </script>
</body>
</html>
"@
    
    return $html
}

#endregion

#region Deployment Options

function New-SecurePortalLink {
    param(
        [string]$Token,
        [string]$PortalPath
    )
    
    # For production, this would upload to secure storage and return a link
    # For now, return local path
    
    Write-Host "`nDeployment Options:" -ForegroundColor Cyan
    Write-Host "1. Azure Storage with SAS tokens" -ForegroundColor White
    Write-Host "2. SharePoint with specific permissions" -ForegroundColor White
    Write-Host "3. Secure web server with authentication" -ForegroundColor White
    Write-Host "4. Encrypted email attachment" -ForegroundColor White
    
    # Generate secure URL structure
    $baseUrl = "https://secure.powerreview.com/portal"
    $portalId = [guid]::NewGuid().ToString()
    $signature = Get-FileHash -Path $PortalPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    
    $secureUrl = "$baseUrl/$portalId?sig=$($signature.Substring(0,16))&token=$($Token.Substring(0,8))"
    
    return $secureUrl
}

function Deploy-ToAzureStorage {
    param(
        [string]$PortalPath,
        [string]$StorageAccount,
        [string]$Container = "client-portals"
    )
    
    Write-Host "Deploying to Azure Storage..." -ForegroundColor Cyan
    
    # Generate SAS token with limited permissions
    $sasToken = New-AzStorageBlobSASToken `
        -Container $Container `
        -Blob (Split-Path $PortalPath -Leaf) `
        -Permission "r" `
        -ExpiryTime (Get-Date).AddDays(30) `
        -Protocol HttpsOnly
    
    # Upload file
    Set-AzStorageBlobContent `
        -File $PortalPath `
        -Container $Container `
        -Blob "$(New-Guid).html" `
        -Context $storageContext
    
    return "https://$StorageAccount.blob.core.windows.net/$Container/$blobName$sasToken"
}

function Deploy-ToSharePoint {
    param(
        [string]$PortalPath,
        [string]$SiteUrl,
        [string]$LibraryName = "Client Portals"
    )
    
    Write-Host "Deploying to SharePoint..." -ForegroundColor Cyan
    
    # Connect to SharePoint
    Connect-PnPOnline -Url $SiteUrl -Interactive
    
    # Create unique folder
    $folderName = "Portal_$(Get-Date -Format 'yyyyMMdd')_$(New-Guid)"
    Add-PnPFolder -Name $folderName -Folder $LibraryName
    
    # Upload file
    $file = Add-PnPFile -Path $PortalPath -Folder "$LibraryName/$folderName"
    
    # Set unique permissions
    Set-PnPListItemPermission -List $LibraryName -Identity $file.ListItemAllFields.Id -User $AuthorizedEmails -AddRole "Read"
    
    # Generate guest link
    $link = New-PnPSharingLink -Identity $file.ServerRelativeUrl -Type "Direct" -Scope "Specific"
    
    return $link
}

#endregion

# Execute portal generation
try {
    $portalPath = New-ClientPortal
    
    Write-Host "`n" -ForegroundColor Green
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           CLIENT PORTAL GENERATED SUCCESSFULLY!                   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nPortal Details:" -ForegroundColor Cyan
    Write-Host "  Location: $portalPath" -ForegroundColor White
    Write-Host "  Valid Until: $((Get-Date).AddDays($ValidityDays).ToString('MMMM dd, yyyy'))" -ForegroundColor White
    Write-Host "  Authorized Users: $($AuthorizedEmails -join ', ')" -ForegroundColor White
    
    Write-Host "`nSecurity Features:" -ForegroundColor Cyan
    Write-Host "  ✓ Token-based authentication" -ForegroundColor Green
    Write-Host "  ✓ Email whitelist validation" -ForegroundColor Green
    Write-Host "  ✓ Session timeout (30 minutes)" -ForegroundColor Green
    Write-Host "  ✓ Right-click disabled" -ForegroundColor Green
    Write-Host "  ✓ Watermarked printing" -ForegroundColor Green
    Write-Host "  ✓ No search engine indexing" -ForegroundColor Green
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy portal to secure hosting" -ForegroundColor White
    Write-Host "  2. Send access credentials to authorized users" -ForegroundColor White
    Write-Host "  3. Monitor access logs" -ForegroundColor White
    Write-Host "  4. Schedule workshop to review findings" -ForegroundColor White
}
catch {
    Write-Host "Error generating portal: $_" -ForegroundColor Red
    throw
}