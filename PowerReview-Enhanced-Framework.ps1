#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Enhanced Framework - Enterprise Multi-Tenant Assessment Platform
    
.DESCRIPTION
    Comprehensive M365 and Azure assessment with deep analysis capabilities
    Features:
    - Multi-tenant support (unlimited tenants)
    - Deep dive analysis modes
    - Secure encrypted storage
    - MCP integration support
    - Automated evidence collection
    - Advanced reporting with AI insights
    
.EXAMPLE
    # Basic assessment
    .\PowerReview-Enhanced-Framework.ps1 -TenantConfig ".\tenants.json"
    
.EXAMPLE
    # Deep analysis with secure storage
    .\PowerReview-Enhanced-Framework.ps1 -TenantConfig ".\tenants.json" -DeepAnalysis -SecureStorage
    
.EXAMPLE
    # Specific modules with custom depth
    .\PowerReview-Enhanced-Framework.ps1 -TenantConfig ".\tenants.json" -Modules @("Purview","Security") -AnalysisDepth "Forensic"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantConfig,
    
    [string[]]$Modules = @("Purview", "PowerPlatform", "SharePoint", "Security", "AzureLandingZone", "Compliance", "DataGovernance"),
    
    [ValidateSet("Basic", "Standard", "Deep", "Forensic")]
    [string]$AnalysisDepth = "Deep",
    
    [switch]$DeepAnalysis,
    
    [switch]$SecureStorage,
    
    [string]$VaultPath,
    
    [switch]$UseMCP,
    
    [string]$OutputPath,
    
    [switch]$AutoRemediate,
    
    [int]$DaysToAnalyze = 90,
    
    [switch]$IncludeHistoricalData,
    
    [switch]$GenerateEvidence,
    
    [switch]$ComplianceMode
)

#region Enhanced Configuration
$script:Version = "3.0.0-Enhanced"
$script:StartTime = Get-Date
$script:MCPAvailable = $false
$script:SecureVault = $null
$script:TenantData = @{}
$script:GlobalFindings = @()
$script:GlobalMetrics = @{}
$script:ComplianceFrameworks = @("GDPR", "HIPAA", "SOC2", "ISO27001", "NIST")

# Analysis depth configurations
$script:AnalysisConfig = @{
    Basic = @{
        DaysToAnalyze = 30
        SampleSize = 100
        IncludeInactive = $false
    }
    Standard = @{
        DaysToAnalyze = 90
        SampleSize = 1000
        IncludeInactive = $true
    }
    Deep = @{
        DaysToAnalyze = 180
        SampleSize = 5000
        IncludeInactive = $true
        AnalyzePatterns = $true
    }
    Forensic = @{
        DaysToAnalyze = 365
        SampleSize = -1  # All data
        IncludeInactive = $true
        AnalyzePatterns = $true
        CollectEvidence = $true
        DetailedLogging = $true
    }
}

#endregion

#region Enhanced Logging with Secure Storage
function Write-SecureLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "SECURITY", "COMPLIANCE")]
        [string]$Level = "INFO",
        [string]$TenantId = "Global",
        [switch]$Sensitive
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = [PSCustomObject]@{
        Timestamp = $timestamp
        Level = $Level
        TenantId = $TenantId
        Message = $Message
        Sensitive = $Sensitive
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
    
    # Console output
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "SECURITY" { "Magenta" }
        "COMPLIANCE" { "Cyan" }
        default { "White" }
    }
    
    if (!$Sensitive) {
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
    else {
        Write-Host "[$timestamp] [$Level] [REDACTED - Check secure log]" -ForegroundColor $color
    }
    
    # Secure file logging
    if ($script:SecureStorage -and $script:SecureVault) {
        Add-SecureLogEntry -Entry $logEntry
    }
    else {
        # Standard file logging
        $logPath = Join-Path $script:OutputPath "Logs\PowerReview_$(Get-Date -Format 'yyyyMMdd').log"
        $logEntry | ConvertTo-Json -Compress | Add-Content -Path $logPath
    }
}

#endregion

#region Secure Storage Implementation
function Initialize-SecureStorage {
    param([string]$VaultPath)
    
    Write-SecureLog "Initializing secure storage..." "SECURITY"
    
    if (!$VaultPath) {
        $VaultPath = Join-Path $env:LOCALAPPDATA "PowerReview\Vault"
    }
    
    if (!(Test-Path $VaultPath)) {
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
        
        # Set restrictive permissions
        $acl = Get-Acl $VaultPath
        $acl.SetAccessRuleProtection($true, $false)
        $permission = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($permission)
        Set-Acl -Path $VaultPath -AclObject $acl
    }
    
    $script:SecureVault = @{
        Path = $VaultPath
        Key = New-EncryptionKey
        Initialized = $true
    }
    
    Write-SecureLog "Secure storage initialized at: $VaultPath" "SECURITY"
}

function New-EncryptionKey {
    # Generate encryption key based on machine and user
    $machineId = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
    $userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $combined = "$machineId-$userId-PowerReview"
    
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combined)
    $hash = $sha256.ComputeHash($bytes)
    
    return [Convert]::ToBase64String($hash)
}

function Save-SecureData {
    param(
        [string]$Name,
        [object]$Data,
        [string]$TenantId
    )
    
    if (!$script:SecureVault.Initialized) {
        throw "Secure vault not initialized"
    }
    
    $filePath = Join-Path $script:SecureVault.Path "$TenantId-$Name-$(Get-Date -Format 'yyyyMMdd-HHmmss').vault"
    
    # Convert to JSON and encrypt
    $json = $Data | ConvertTo-Json -Depth 100 -Compress
    $encrypted = ConvertTo-SecureString -String $json -AsPlainText -Force | ConvertFrom-SecureString -Key ([Convert]::FromBase64String($script:SecureVault.Key))
    
    # Save with metadata
    $vaultData = @{
        Metadata = @{
            Name = $Name
            TenantId = $TenantId
            Timestamp = Get-Date
            DataType = $Data.GetType().FullName
            Checksum = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($json))) -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        }
        EncryptedData = $encrypted
    }
    
    $vaultData | ConvertTo-Json | Out-File -FilePath $filePath -Encoding UTF8
    
    Write-SecureLog "Secure data saved: $Name for tenant $TenantId" "SECURITY" -Sensitive
}

#endregion

#region Multi-Tenant Configuration Loader
function Import-TenantConfiguration {
    param([string]$ConfigPath)
    
    Write-SecureLog "Loading tenant configuration from: $ConfigPath" "INFO"
    
    if (!(Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Validate configuration
    if (!$config.Tenants -or $config.Tenants.Count -eq 0) {
        throw "No tenants defined in configuration"
    }
    
    # Process each tenant
    foreach ($tenant in $config.Tenants) {
        $script:TenantData[$tenant.Id] = @{
            Name = $tenant.Name
            Id = $tenant.Id
            Domains = $tenant.Domains
            AdminUser = $tenant.AdminUser
            Modules = if ($tenant.Modules) { $tenant.Modules } else { $script:Modules }
            CustomSettings = $tenant.CustomSettings
            ComplianceRequirements = $tenant.ComplianceRequirements
            Connections = @{}
            Findings = @()
            Evidence = @()
            Metrics = @{}
        }
    }
    
    Write-SecureLog "Loaded configuration for $($config.Tenants.Count) tenants" "SUCCESS"
    return $config
}

#endregion

#region MCP Integration
function Initialize-MCPIntegration {
    Write-SecureLog "Initializing MCP integration..." "INFO"
    
    try {
        # Check for available MCP servers
        $mcpServers = @{
            "azure-mcp" = Test-Path "C:\Program Files\azure-mcp\mcp.exe"
            "m365-mcp" = Test-Path "C:\Program Files\m365-mcp\mcp.exe"
            "github-mcp" = Test-Path "C:\Program Files\github-mcp\mcp.exe"
        }
        
        $availableServers = $mcpServers.GetEnumerator() | Where-Object { $_.Value } | Select-Object -ExpandProperty Key
        
        if ($availableServers.Count -gt 0) {
            $script:MCPAvailable = $true
            $script:MCPServers = $availableServers
            Write-SecureLog "MCP servers available: $($availableServers -join ', ')" "SUCCESS"
        }
        else {
            Write-SecureLog "No MCP servers found - continuing without MCP integration" "WARN"
        }
    }
    catch {
        Write-SecureLog "MCP initialization failed: $_" "ERROR"
    }
}

function Invoke-MCPQuery {
    param(
        [string]$Server,
        [string]$Query,
        [hashtable]$Parameters
    )
    
    if (!$script:MCPAvailable) {
        return $null
    }
    
    try {
        # Construct MCP query
        $mcpRequest = @{
            query = $Query
            parameters = $Parameters
            timestamp = Get-Date
        } | ConvertTo-Json
        
        # Execute via MCP
        $result = & "C:\Program Files\$Server\mcp.exe" query $mcpRequest
        
        return $result | ConvertFrom-Json
    }
    catch {
        Write-SecureLog "MCP query failed: $_" "ERROR"
        return $null
    }
}

#endregion

#region Enhanced Deep Analysis Functions

function Invoke-DeepPurviewAnalysis {
    param(
        [string]$TenantId,
        [string]$OutputPath
    )
    
    Write-SecureLog "Starting DEEP Purview analysis for tenant: $TenantId" "INFO" $TenantId
    
    $findings = @()
    $evidence = @()
    $metrics = @{}
    
    try {
        # 1. Comprehensive DLP Analysis
        Write-SecureLog "Performing comprehensive DLP analysis..." "INFO" $TenantId
        
        $dlpPolicies = Get-DlpCompliancePolicy
        $dlpRules = Get-DlpComplianceRule
        $dlpIncidents = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$DaysToAnalyze) -EndDate (Get-Date) -RecordType DLPRuleMatch -ResultSize 5000
        
        # Analyze DLP effectiveness
        $dlpMetrics = @{
            TotalPolicies = $dlpPolicies.Count
            ActivePolicies = ($dlpPolicies | Where-Object { $_.Enabled }).Count
            TotalRules = $dlpRules.Count
            IncidentsLast90Days = $dlpIncidents.Count
            FalsePositiveRate = 0
            BlockedTransactions = 0
        }
        
        # Deep dive into each policy
        foreach ($policy in $dlpPolicies) {
            $policyRules = $dlpRules | Where-Object { $_.Policy -eq $policy.Name }
            $policyIncidents = $dlpIncidents | Where-Object { $_.AuditData -like "*$($policy.Name)*" }
            
            $evidence += [PSCustomObject]@{
                Component = "DLP Policy Deep Analysis"
                PolicyName = $policy.Name
                Enabled = $policy.Enabled
                Mode = $policy.Mode
                Workloads = $policy.Workload -join ", "
                RuleCount = $policyRules.Count
                IncidentCount = $policyIncidents.Count
                LastIncident = if ($policyIncidents) { ($policyIncidents | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate } else { "Never" }
                Effectiveness = if ($policyIncidents.Count -gt 0) { "Active" } else { "No activity" }
            }
            
            # Check for policy gaps
            if ($policy.Mode -ne "Enforce" -and $policyIncidents.Count -gt 10) {
                $findings += [PSCustomObject]@{
                    Module = "Purview"
                    Category = "DLP Optimization"
                    Severity = "HIGH"
                    Issue = "High-activity DLP policy not enforced"
                    Impact = "Policy detecting issues but not blocking"
                    CurrentValue = "$($policyIncidents.Count) incidents in test mode"
                    RecommendedValue = "Switch to Enforce mode"
                    Evidence = "Policy: $($policy.Name)"
                    RemediationSteps = "Review incidents, tune rules, then enforce"
                    EstimatedHours = 8
                    TenantId = $TenantId
                    DeepAnalysis = $true
                }
            }
        }
        
        # 2. Advanced Sensitivity Label Analysis
        Write-SecureLog "Analyzing sensitivity label usage patterns..." "INFO" $TenantId
        
        $labels = Get-Label
        $labelPolicies = Get-LabelPolicy
        
        # Get label usage statistics (requires Graph API)
        $labelUsageData = @()
        foreach ($label in $labels) {
            try {
                # Query for documents with this label
                $searchQuery = "sensitivity:""$($label.DisplayName)"""
                $searchResults = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/search/query" -Body @{
                    requests = @(@{
                        entityTypes = @("driveItem", "message")
                        query = @{ queryString = $searchQuery }
                        size = 1
                    })
                }
                
                $labelUsageData += [PSCustomObject]@{
                    LabelName = $label.DisplayName
                    LabelId = $label.Guid
                    Priority = $label.Priority
                    UsageCount = $searchResults.value[0].hitsContainers[0].total
                    Encryption = $label.EncryptionEnabled
                    Watermark = $label.ApplyWatermark
                    Protection = $label.ContentMarkingEnabled
                }
            }
            catch {
                Write-SecureLog "Could not get usage data for label: $($label.DisplayName)" "WARN" $TenantId
            }
        }
        
        # Label adoption analysis
        $totalLabeledContent = ($labelUsageData | Measure-Object -Property UsageCount -Sum).Sum
        if ($totalLabeledContent -lt 1000) {
            $findings += [PSCustomObject]@{
                Module = "Purview"
                Category = "Information Protection"
                Severity = "HIGH"
                Issue = "Low sensitivity label adoption"
                Impact = "Content not properly classified"
                CurrentValue = "$totalLabeledContent labeled items"
                RecommendedValue = "Widespread label adoption"
                Evidence = "Label usage statistics"
                RemediationSteps = "Auto-labeling policies, user training, mandatory labeling"
                EstimatedHours = 40
                TenantId = $TenantId
                DeepAnalysis = $true
            }
        }
        
        # 3. Retention Policy Effectiveness
        Write-SecureLog "Analyzing retention policy effectiveness..." "INFO" $TenantId
        
        $retentionPolicies = Get-RetentionCompliancePolicy
        $retentionLabels = Get-ComplianceTag
        
        foreach ($policy in $retentionPolicies) {
            # Check policy application
            $policyStatus = Get-RetentionCompliancePolicy -Identity $policy.Identity -DistributionDetail
            
            $evidence += [PSCustomObject]@{
                Component = "Retention Policy Analysis"
                PolicyName = $policy.Name
                Enabled = $policy.Enabled
                RetentionAction = $policy.RetentionAction
                RetentionDuration = $policy.RetentionDuration
                Workloads = $policy.Workload -join ", "
                Status = $policyStatus.DistributionStatus
                LastModified = $policy.WhenChangedUTC
                AppliedLocations = ($policyStatus.DistributionResults | Measure-Object).Count
            }
        }
        
        # 4. Insider Risk Deep Dive (if licensed)
        Write-SecureLog "Performing insider risk analysis..." "INFO" $TenantId
        
        try {
            $insiderRiskPolicies = Get-InsiderRiskPolicy
            $insiderRiskCases = Get-InsiderRiskCase -All
            
            if ($insiderRiskPolicies.Count -eq 0) {
                $findings += [PSCustomObject]@{
                    Module = "Purview"
                    Category = "Insider Risk"
                    Severity = "HIGH"
                    Issue = "No insider risk management configured"
                    Impact = "Cannot detect insider threats"
                    CurrentValue = "0 policies"
                    RecommendedValue = "Implement insider risk program"
                    Evidence = "No policies found"
                    RemediationSteps = @(
                        "Enable insider risk management",
                        "Configure HR connector",
                        "Create data theft policy",
                        "Create data leak policy",
                        "Set up security violation policy"
                    ) -join "; "
                    EstimatedHours = 60
                    TenantId = $TenantId
                    DeepAnalysis = $true
                }
            }
            else {
                # Analyze insider risk effectiveness
                $riskMetrics = @{
                    TotalPolicies = $insiderRiskPolicies.Count
                    ActivePolicies = ($insiderRiskPolicies | Where-Object { $_.Enabled }).Count
                    TotalCases = $insiderRiskCases.Count
                    OpenCases = ($insiderRiskCases | Where-Object { $_.Status -eq "Open" }).Count
                    HighRiskUsers = ($insiderRiskCases | Where-Object { $_.RiskLevel -eq "High" } | Select-Object -ExpandProperty UserId -Unique).Count
                }
                
                $metrics["InsiderRisk"] = $riskMetrics
            }
        }
        catch {
            Write-SecureLog "Insider risk analysis requires E5 licensing or add-on" "WARN" $TenantId
        }
        
        # 5. Data Classification Insights
        Write-SecureLog "Analyzing data classification patterns..." "INFO" $TenantId
        
        # Get classification insights from audit logs
        $classificationEvents = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -Operations "FileSensitivityLabelChanged", "FileSensitivityLabelApplied" -ResultSize 5000
        
        if ($classificationEvents) {
            $classificationPatterns = $classificationEvents | ForEach-Object {
                $auditData = $_.AuditData | ConvertFrom-Json
                [PSCustomObject]@{
                    Timestamp = $_.CreationDate
                    User = $_.UserIds
                    Operation = $_.Operations
                    Label = $auditData.SensitivityLabelId
                    Location = $auditData.ObjectId
                }
            } | Group-Object Label
            
            $evidence += [PSCustomObject]@{
                Component = "Classification Patterns"
                TotalClassificationEvents = $classificationEvents.Count
                UniqueUsers = ($classificationEvents | Select-Object -ExpandProperty UserIds -Unique).Count
                MostUsedLabels = ($classificationPatterns | Sort-Object Count -Descending | Select-Object -First 5).Name -join ", "
                ClassificationTrend = "See detailed report"
            }
        }
        
        # 6. Communication Compliance Analysis
        Write-SecureLog "Checking communication compliance..." "INFO" $TenantId
        
        try {
            $commPolicies = Get-SupervisoryReviewPolicyV2
            
            if ($commPolicies.Count -eq 0) {
                $findings += [PSCustomObject]@{
                    Module = "Purview"
                    Category = "Communication Compliance"
                    Severity = "MEDIUM"
                    Issue = "No communication compliance policies"
                    Impact = "Cannot monitor inappropriate communications"
                    CurrentValue = "Not configured"
                    RecommendedValue = "Implement communication monitoring"
                    Evidence = "No policies found"
                    RemediationSteps = "Configure policies for harassment, threats, regulatory compliance"
                    EstimatedHours = 24
                    TenantId = $TenantId
                    DeepAnalysis = $true
                }
            }
        }
        catch {
            Write-SecureLog "Communication compliance check skipped - may require additional licensing" "WARN" $TenantId
        }
        
        # 7. Information Barriers Assessment
        Write-SecureLog "Analyzing information barriers..." "INFO" $TenantId
        
        try {
            $ibPolicies = Get-InformationBarrierPolicy
            $ibSegments = Get-OrganizationSegment
            
            if ($ibPolicies.Count -gt 0) {
                $evidence += [PSCustomObject]@{
                    Component = "Information Barriers"
                    TotalPolicies = $ibPolicies.Count
                    ActivePolicies = ($ibPolicies | Where-Object { $_.State -eq "Active" }).Count
                    TotalSegments = $ibSegments.Count
                    LastProcessed = ($ibPolicies | Sort-Object WhenChangedUTC -Descending | Select-Object -First 1).WhenChangedUTC
                }
            }
        }
        catch {
            Write-SecureLog "Information barriers not configured" "INFO" $TenantId
        }
        
        # 8. Advanced eDiscovery Readiness
        Write-SecureLog "Assessing eDiscovery readiness..." "INFO" $TenantId
        
        $eDiscoveryCases = Get-ComplianceCase
        $custodians = @()
        $holds = @()
        
        foreach ($case in $eDiscoveryCases) {
            $caseCustodians = Get-CaseCustodian -Case $case.Identity
            $caseHolds = Get-CaseHoldPolicy -Case $case.Identity
            $custodians += $caseCustodians
            $holds += $caseHolds
        }
        
        $evidence += [PSCustomObject]@{
            Component = "eDiscovery Readiness"
            TotalCases = $eDiscoveryCases.Count
            ActiveCases = ($eDiscoveryCases | Where-Object { $_.Status -eq "Active" }).Count
            TotalCustodians = $custodians.Count
            TotalHolds = $holds.Count
            OldestCase = if ($eDiscoveryCases) { ($eDiscoveryCases | Sort-Object CreatedDateTime | Select-Object -First 1).CreatedDateTime } else { "N/A" }
        }
        
        # Save deep analysis results
        if ($script:SecureStorage) {
            Save-SecureData -Name "PurviewDeepAnalysis" -Data @{
                Findings = $findings
                Evidence = $evidence
                Metrics = $metrics
                Timestamp = Get-Date
            } -TenantId $TenantId
        }
        
        # Export detailed reports
        $findings | Export-Csv "$OutputPath\Purview_Deep_Findings.csv" -NoTypeInformation
        $evidence | Export-Csv "$OutputPath\Purview_Deep_Evidence.csv" -NoTypeInformation
        $labelUsageData | Export-Csv "$OutputPath\Purview_Label_Usage.csv" -NoTypeInformation
        
        # Update tenant data
        $script:TenantData[$TenantId].Findings += $findings
        $script:TenantData[$TenantId].Evidence += $evidence
        $script:TenantData[$TenantId].Metrics["Purview"] = $metrics
        
        Write-SecureLog "Deep Purview analysis completed - Found $($findings.Count) issues" "SUCCESS" $TenantId
        
    }
    catch {
        Write-SecureLog "Deep Purview analysis failed: $_" "ERROR" $TenantId
        throw
    }
}

function Invoke-DeepSecurityAnalysis {
    param(
        [string]$TenantId,
        [string]$OutputPath
    )
    
    Write-SecureLog "Starting DEEP Security analysis for tenant: $TenantId" "INFO" $TenantId
    
    $findings = @()
    $evidence = @()
    $securityScore = 100
    
    try {
        # 1. Advanced Conditional Access Analysis
        Write-SecureLog "Performing advanced CA policy analysis..." "INFO" $TenantId
        
        $caPolicies = Get-MgIdentityConditionalAccessPolicy -All
        $namedLocations = Get-MgIdentityConditionalAccessNamedLocation -All
        
        # Analyze policy coverage
        $policyMatrix = @{
            "MFA for Admins" = $false
            "MFA for All Users" = $false
            "Block Legacy Auth" = $false
            "Require Compliant Device" = $false
            "Block Risky Sign-ins" = $false
            "Block Unknown Locations" = $false
            "Session Controls" = $false
        }
        
        foreach ($policy in $caPolicies) {
            # Deep policy analysis
            $conditions = $policy.Conditions
            $controls = $policy.GrantControls
            
            # Check for admin MFA
            if ($conditions.Users.IncludeRoles -and $controls.BuiltInControls -contains "mfa") {
                $policyMatrix["MFA for Admins"] = $true
            }
            
            # Check for legacy auth block
            if ($conditions.ClientAppTypes -contains "other" -and $policy.State -eq "enabled") {
                $policyMatrix["Block Legacy Auth"] = $true
            }
            
            # Analyze policy effectiveness
            $evidence += [PSCustomObject]@{
                Component = "CA Policy Deep Dive"
                PolicyName = $policy.DisplayName
                State = $policy.State
                CreatedDate = $policy.CreatedDateTime
                ModifiedDate = $policy.ModifiedDateTime
                UserScope = if ($conditions.Users.IncludeUsers -contains "All") { "All Users" } else { "Specific Users/Groups" }
                AppScope = if ($conditions.Applications.IncludeApplications -contains "All") { "All Apps" } else { "Specific Apps" }
                LocationRestrictions = $conditions.Locations.IncludeLocations.Count -gt 0
                DeviceRequirements = $conditions.Devices -ne $null
                GrantControls = $controls.BuiltInControls -join ", "
                SessionControls = if ($policy.SessionControls) { "Configured" } else { "None" }
            }
        }
        
        # Generate findings based on gaps
        foreach ($requirement in $policyMatrix.GetEnumerator()) {
            if (!$requirement.Value) {
                $severity = if ($requirement.Key -like "*Admin*" -or $requirement.Key -like "*Legacy*") { "CRITICAL" } else { "HIGH" }
                
                $findings += [PSCustomObject]@{
                    Module = "Security"
                    Category = "Conditional Access"
                    Severity = $severity
                    Issue = "Missing CA policy: $($requirement.Key)"
                    Impact = "Security gap in access control"
                    CurrentValue = "Not configured"
                    RecommendedValue = "Implement $($requirement.Key) policy"
                    Evidence = "Policy gap analysis"
                    RemediationSteps = "Create and test CA policy for $($requirement.Key)"
                    EstimatedHours = 8
                    TenantId = $TenantId
                    DeepAnalysis = $true
                }
                
                $securityScore -= if ($severity -eq "CRITICAL") { 15 } else { 10 }
            }
        }
        
        # 2. Identity Protection Deep Dive
        Write-SecureLog "Analyzing identity protection signals..." "INFO" $TenantId
        
        $riskDetections = Get-MgRiskDetection -Filter "riskEventDateTime ge $(Get-Date.AddDays(-$DaysToAnalyze).ToString('yyyy-MM-dd'))" -All
        $riskyUsers = Get-MgRiskyUser -All
        $riskySignIns = Get-MgRiskySignIn -All
        
        # Risk pattern analysis
        $riskPatterns = $riskDetections | Group-Object RiskEventType | Sort-Object Count -Descending
        
        $evidence += [PSCustomObject]@{
            Component = "Identity Protection"
            TotalRiskDetections = $riskDetections.Count
            UniqueRiskTypes = $riskPatterns.Count
            TopRiskType = if ($riskPatterns) { $riskPatterns[0].Name } else { "None" }
            RiskyUsers = $riskyUsers.Count
            RiskySignIns = $riskySignIns.Count
            HighRiskUsers = ($riskyUsers | Where-Object { $_.RiskLevel -eq "high" }).Count
        }
        
        if ($riskyUsers.Count -gt 50) {
            $findings += [PSCustomObject]@{
                Module = "Security"
                Category = "Identity Protection"
                Severity = "HIGH"
                Issue = "High number of risky users"
                Impact = "Potential account compromises"
                CurrentValue = "$($riskyUsers.Count) risky users"
                RecommendedValue = "Investigate and remediate risky users"
                Evidence = "Identity Protection detections"
                RemediationSteps = @(
                    "Review risky users",
                    "Force password reset for high-risk users",
                    "Require MFA re-registration",
                    "Investigate risk detections"
                ) -join "; "
                EstimatedHours = 16
                TenantId = $TenantId
                DeepAnalysis = $true
            }
        }
        
        # 3. Privileged Identity Management Analysis
        Write-SecureLog "Analyzing PIM configuration..." "INFO" $TenantId
        
        try {
            $pimRoles = Get-MgRoleManagementDirectoryRoleDefinition -All
            $eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All
            $activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All
            
            # Analyze privileged access
            $privilegedRoles = $pimRoles | Where-Object { 
                $_.DisplayName -like "*Admin*" -or 
                $_.DisplayName -like "*Security*" -or
                $_.RolePermissions.AllowedResourceActions -contains "microsoft.directory/users/password/update"
            }
            
            $permanentAdmins = $activeAssignments | Where-Object {
                $_.ScheduleInfo.Expiration.Type -eq "noExpiration" -and
                $privilegedRoles.Id -contains $_.RoleDefinitionId
            }
            
            if ($permanentAdmins.Count -gt 5) {
                $findings += [PSCustomObject]@{
                    Module = "Security"
                    Category = "Privileged Access"
                    Severity = "CRITICAL"
                    Issue = "Excessive permanent admin assignments"
                    Impact = "Increased risk of privilege abuse"
                    CurrentValue = "$($permanentAdmins.Count) permanent admins"
                    RecommendedValue = "Use PIM eligible assignments"
                    Evidence = "PIM configuration analysis"
                    RemediationSteps = @(
                        "Convert permanent to eligible assignments",
                        "Implement approval workflows",
                        "Set maximum activation duration",
                        "Enable MFA for activation"
                    ) -join "; "
                    EstimatedHours = 24
                    TenantId = $TenantId
                    DeepAnalysis = $true
                }
                
                $securityScore -= 20
            }
            
            $evidence += [PSCustomObject]@{
                Component = "PIM Configuration"
                TotalPrivilegedRoles = $privilegedRoles.Count
                EligibleAssignments = $eligibleAssignments.Count
                ActiveAssignments = $activeAssignments.Count
                PermanentAdmins = $permanentAdmins.Count
                RolesWithApproval = ($eligibleAssignments | Where-Object { $_.ScheduleInfo.Approval }).Count
            }
        }
        catch {
            Write-SecureLog "PIM analysis requires Azure AD P2 licensing" "WARN" $TenantId
        }
        
        # 4. Security Defaults and Policies
        Write-SecureLog "Checking security baselines..." "INFO" $TenantId
        
        $securityDefaults = Get-MgPolicyIdentitySecurityDefaultsEnforcementPolicy
        $authMethods = Get-MgPolicyAuthenticationMethodPolicy
        
        if (!$securityDefaults.IsEnabled -and $caPolicies.Count -lt 5) {
            $findings += [PSCustomObject]@{
                Module = "Security"
                Category = "Security Baseline"
                Severity = "CRITICAL"
                Issue = "Neither security defaults nor comprehensive CA policies"
                Impact = "Basic security controls missing"
                CurrentValue = "Minimal security configuration"
                RecommendedValue = "Enable security defaults or implement CA policies"
                Evidence = "Security policy analysis"
                RemediationSteps = "Enable security defaults or create comprehensive CA policy set"
                EstimatedHours = 16
                TenantId = $TenantId
                DeepAnalysis = $true
            }
            
            $securityScore -= 25
        }
        
        # 5. Advanced Threat Hunting
        Write-SecureLog "Performing threat hunting analysis..." "INFO" $TenantId
        
        # Get suspicious activities
        $suspiciousActivities = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -Operations @(
            "UserLoggedIn",
            "UserLoginFailed",
            "MailboxLogin",
            "FileAccessed",
            "FileDeleted",
            "FileDownloaded"
        ) -ResultSize 5000 | Where-Object {
            $_.AuditData -like "*TorAnonymizer*" -or
            $_.AuditData -like "*ImpossibleTravel*" -or
            $_.AuditData -like "*UnfamiliarLocation*" -or
            $_.AuditData -like "*SuspiciousActivity*"
        }
        
        if ($suspiciousActivities.Count -gt 0) {
            $evidence += [PSCustomObject]@{
                Component = "Threat Indicators"
                SuspiciousActivities = $suspiciousActivities.Count
                UniqueUsers = ($suspiciousActivities | Select-Object -ExpandProperty UserIds -Unique).Count
                TimeRange = "Last 30 days"
                TopActivity = ($suspiciousActivities | Group-Object Operations | Sort-Object Count -Descending | Select-Object -First 1).Name
            }
            
            # Save suspicious activities for forensics
            if ($script:SecureStorage) {
                Save-SecureData -Name "SuspiciousActivities" -Data $suspiciousActivities -TenantId $TenantId
            }
        }
        
        # 6. App Permissions Analysis
        Write-SecureLog "Analyzing application permissions..." "INFO" $TenantId
        
        $apps = Get-MgApplication -All
        $servicePrincipals = Get-MgServicePrincipal -All
        
        $riskyApps = @()
        foreach ($app in $apps) {
            $sp = $servicePrincipals | Where-Object { $_.AppId -eq $app.AppId }
            if ($sp) {
                $permissions = $sp.AppRoleAssignments
                $highRiskPermissions = $permissions | Where-Object {
                    $_.ResourceDisplayName -like "*Graph*" -and (
                        $_.AppRoleId -in @(
                            "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9", # Application.ReadWrite.All
                            "06b708a9-e830-4db3-a914-8e69da51d44f", # AppRoleAssignment.ReadWrite.All
                            "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"  # RoleManagement.ReadWrite.Directory
                        )
                    )
                }
                
                if ($highRiskPermissions) {
                    $riskyApps += [PSCustomObject]@{
                        AppName = $app.DisplayName
                        AppId = $app.AppId
                        Publisher = $app.PublisherDomain
                        RiskLevel = "High"
                        Permissions = ($highRiskPermissions.AppRoleId -join ", ")
                    }
                }
            }
        }
        
        if ($riskyApps.Count -gt 0) {
            $findings += [PSCustomObject]@{
                Module = "Security"
                Category = "Application Permissions"
                Severity = "HIGH"
                Issue = "Applications with high-risk permissions"
                Impact = "Potential for unauthorized access"
                CurrentValue = "$($riskyApps.Count) risky applications"
                RecommendedValue = "Review and restrict app permissions"
                Evidence = "App permission analysis"
                RemediationSteps = @(
                    "Review high-risk applications",
                    "Remove unnecessary permissions",
                    "Implement app governance policies",
                    "Regular permission audits"
                ) -join "; "
                EstimatedHours = 16
                TenantId = $TenantId
                DeepAnalysis = $true
            }
            
            $evidence += [PSCustomObject]@{
                Component = "Application Security"
                TotalApps = $apps.Count
                ServicePrincipals = $servicePrincipals.Count
                RiskyApps = $riskyApps.Count
                AppCategories = ($apps | Group-Object SignInAudience).Name -join ", "
            }
        }
        
        # Calculate final security score
        $script:TenantData[$TenantId].Metrics["SecurityScore"] = [Math]::Max(0, $securityScore)
        
        # Export results
        $findings | Export-Csv "$OutputPath\Security_Deep_Findings.csv" -NoTypeInformation
        $evidence | Export-Csv "$OutputPath\Security_Deep_Evidence.csv" -NoTypeInformation
        if ($riskyApps) {
            $riskyApps | Export-Csv "$OutputPath\Security_Risky_Apps.csv" -NoTypeInformation
        }
        
        # Update tenant data
        $script:TenantData[$TenantId].Findings += $findings
        $script:TenantData[$TenantId].Evidence += $evidence
        
        Write-SecureLog "Deep Security analysis completed - Security Score: $securityScore/100" "SUCCESS" $TenantId
        
    }
    catch {
        Write-SecureLog "Deep Security analysis failed: $_" "ERROR" $TenantId
        throw
    }
}

function Invoke-DeepComplianceAnalysis {
    param(
        [string]$TenantId,
        [string]$OutputPath,
        [string[]]$Frameworks = @("GDPR", "HIPAA", "SOC2")
    )
    
    Write-SecureLog "Starting DEEP Compliance analysis for frameworks: $($Frameworks -join ', ')" "COMPLIANCE" $TenantId
    
    $complianceFindings = @()
    $complianceGaps = @()
    $complianceScore = @{}
    
    try {
        foreach ($framework in $Frameworks) {
            Write-SecureLog "Analyzing $framework compliance..." "COMPLIANCE" $TenantId
            
            switch ($framework) {
                "GDPR" {
                    # GDPR Compliance Checks
                    $gdprChecks = @{
                        "Data Subject Rights" = Test-GDPRDataSubjectRights -TenantId $TenantId
                        "Consent Management" = Test-GDPRConsentManagement -TenantId $TenantId
                        "Data Retention" = Test-GDPRDataRetention -TenantId $TenantId
                        "Data Portability" = Test-GDPRDataPortability -TenantId $TenantId
                        "Privacy by Design" = Test-GDPRPrivacyByDesign -TenantId $TenantId
                        "Breach Notification" = Test-GDPRBreachNotification -TenantId $TenantId
                        "DPO Assignment" = Test-GDPRDPOAssignment -TenantId $TenantId
                        "Cross-Border Transfers" = Test-GDPRCrossBorderTransfers -TenantId $TenantId
                    }
                    
                    $gdprScore = ($gdprChecks.Values | Where-Object { $_.Compliant } | Measure-Object).Count / $gdprChecks.Count * 100
                    $complianceScore[$framework] = [Math]::Round($gdprScore, 2)
                    
                    foreach ($check in $gdprChecks.GetEnumerator()) {
                        if (!$check.Value.Compliant) {
                            $complianceGaps += [PSCustomObject]@{
                                Framework = "GDPR"
                                Requirement = $check.Key
                                Article = $check.Value.Article
                                Status = "Non-Compliant"
                                Gap = $check.Value.Gap
                                Remediation = $check.Value.Remediation
                                EstimatedEffort = $check.Value.EffortHours
                                TenantId = $TenantId
                            }
                        }
                    }
                }
                
                "HIPAA" {
                    # HIPAA Compliance Checks
                    $hipaaChecks = @{
                        "Access Controls" = Test-HIPAAAccessControls -TenantId $TenantId
                        "Audit Controls" = Test-HIPAAAuditControls -TenantId $TenantId
                        "Integrity Controls" = Test-HIPAAIntegrityControls -TenantId $TenantId
                        "Transmission Security" = Test-HIPAATransmissionSecurity -TenantId $TenantId
                        "Administrative Safeguards" = Test-HIPAAAdministrativeSafeguards -TenantId $TenantId
                        "Physical Safeguards" = Test-HIPAAPhysicalSafeguards -TenantId $TenantId
                        "Technical Safeguards" = Test-HIPAATechnicalSafeguards -TenantId $TenantId
                        "Business Associates" = Test-HIPAABusinessAssociates -TenantId $TenantId
                    }
                    
                    $hipaaScore = ($hipaaChecks.Values | Where-Object { $_.Compliant } | Measure-Object).Count / $hipaaChecks.Count * 100
                    $complianceScore[$framework] = [Math]::Round($hipaaScore, 2)
                }
                
                "SOC2" {
                    # SOC2 Trust Principles
                    $soc2Checks = @{
                        "Security" = Test-SOC2Security -TenantId $TenantId
                        "Availability" = Test-SOC2Availability -TenantId $TenantId
                        "Processing Integrity" = Test-SOC2ProcessingIntegrity -TenantId $TenantId
                        "Confidentiality" = Test-SOC2Confidentiality -TenantId $TenantId
                        "Privacy" = Test-SOC2Privacy -TenantId $TenantId
                    }
                    
                    $soc2Score = ($soc2Checks.Values | Where-Object { $_.Compliant } | Measure-Object).Count / $soc2Checks.Count * 100
                    $complianceScore[$framework] = [Math]::Round($soc2Score, 2)
                }
            }
        }
        
        # Generate compliance findings
        foreach ($gap in $complianceGaps) {
            $complianceFindings += [PSCustomObject]@{
                Module = "Compliance"
                Category = $gap.Framework
                Severity = if ($gap.Framework -eq "HIPAA") { "CRITICAL" } else { "HIGH" }
                Issue = "$($gap.Framework) Gap: $($gap.Requirement)"
                Impact = "Non-compliance with $($gap.Framework) requirements"
                CurrentValue = $gap.Gap
                RecommendedValue = "Implement $($gap.Requirement)"
                Evidence = "Compliance assessment"
                RemediationSteps = $gap.Remediation
                EstimatedHours = $gap.EstimatedEffort
                TenantId = $TenantId
                DeepAnalysis = $true
            }
        }
        
        # Export compliance results
        $complianceGaps | Export-Csv "$OutputPath\Compliance_Gaps.csv" -NoTypeInformation
        $complianceFindings | Export-Csv "$OutputPath\Compliance_Findings.csv" -NoTypeInformation
        
        # Generate compliance report
        $complianceReport = @{
            AssessmentDate = Get-Date
            TenantId = $TenantId
            FrameworkScores = $complianceScore
            TotalGaps = $complianceGaps.Count
            CriticalGaps = ($complianceGaps | Where-Object { $_.Framework -eq "HIPAA" }).Count
            EstimatedRemediationEffort = ($complianceGaps | Measure-Object -Property EstimatedEffort -Sum).Sum
        }
        
        $complianceReport | ConvertTo-Json -Depth 10 | Out-File "$OutputPath\Compliance_Report.json"
        
        # Update tenant data
        $script:TenantData[$TenantId].Findings += $complianceFindings
        $script:TenantData[$TenantId].Metrics["Compliance"] = $complianceScore
        
        Write-SecureLog "Deep Compliance analysis completed" "COMPLIANCE" $TenantId
        
    }
    catch {
        Write-SecureLog "Deep Compliance analysis failed: $_" "ERROR" $TenantId
        throw
    }
}

#endregion

#region Compliance Test Functions

function Test-GDPRDataSubjectRights {
    param([string]$TenantId)
    
    $result = @{
        Compliant = $false
        Article = "Article 15-22"
        Gap = ""
        Remediation = ""
        EffortHours = 0
    }
    
    try {
        # Check for DSR tools configuration
        $eDiscovery = Get-ComplianceCase | Where-Object { $_.Name -like "*DSR*" -or $_.Name -like "*Data Subject*" }
        $contentSearch = Get-ComplianceSearch | Where-Object { $_.Name -like "*DSR*" }
        
        if ($eDiscovery.Count -gt 0 -or $contentSearch.Count -gt 0) {
            $result.Compliant = $true
        }
        else {
            $result.Gap = "No DSR process configured"
            $result.Remediation = "Implement eDiscovery cases or content searches for DSR"
            $result.EffortHours = 24
        }
    }
    catch {
        $result.Gap = "Unable to verify DSR capabilities"
        $result.EffortHours = 16
    }
    
    return $result
}

function Test-GDPRDataRetention {
    param([string]$TenantId)
    
    $result = @{
        Compliant = $false
        Article = "Article 5(e)"
        Gap = ""
        Remediation = ""
        EffortHours = 0
    }
    
    $retentionPolicies = Get-RetentionCompliancePolicy
    $hasDataMinimization = $false
    
    foreach ($policy in $retentionPolicies) {
        if ($policy.RetentionAction -eq "Delete" -and $policy.RetentionDuration -le 2555) { # 7 years max
            $hasDataMinimization = $true
            break
        }
    }
    
    if ($hasDataMinimization) {
        $result.Compliant = $true
    }
    else {
        $result.Gap = "No data minimization policies"
        $result.Remediation = "Implement retention policies with deletion"
        $result.EffortHours = 32
    }
    
    return $result
}

function Test-HIPAAAccessControls {
    param([string]$TenantId)
    
    $result = @{
        Compliant = $false
        Section = "164.312(a)(1)"
        Gap = ""
        Remediation = ""
        EffortHours = 0
    }
    
    # Check for appropriate access controls
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All
    $mfaPolicies = $caPolicies | Where-Object { $_.GrantControls.BuiltInControls -contains "mfa" }
    
    if ($mfaPolicies.Count -gt 0) {
        $result.Compliant = $true
    }
    else {
        $result.Gap = "No MFA enforcement for PHI access"
        $result.Remediation = "Implement MFA for all users accessing PHI"
        $result.EffortHours = 16
    }
    
    return $result
}

function Test-SOC2Security {
    param([string]$TenantId)
    
    $result = @{
        Compliant = $false
        Principle = "Security"
        Gap = ""
        Remediation = ""
        EffortHours = 0
    }
    
    # Check multiple security controls
    $securityChecks = @{
        MFA = (Get-MgReportAuthenticationMethodUserRegistrationDetail | Where-Object { $_.IsMfaRegistered }).Count -gt 0
        ConditionalAccess = (Get-MgIdentityConditionalAccessPolicy).Count -gt 5
        AuditLogging = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    }
    
    $passedChecks = ($securityChecks.Values | Where-Object { $_ -eq $true }).Count
    
    if ($passedChecks -eq $securityChecks.Count) {
        $result.Compliant = $true
    }
    else {
        $result.Gap = "Missing security controls"
        $result.Remediation = "Implement comprehensive security controls"
        $result.EffortHours = 40
    }
    
    return $result
}

#endregion

#region Advanced Report Generation

function New-EnhancedExecutiveReport {
    param(
        [string]$OutputPath,
        [hashtable]$AllTenantData
    )
    
    Write-SecureLog "Generating enhanced executive report..." "INFO"
    
    # Aggregate data across all tenants
    $totalFindings = 0
    $criticalFindings = 0
    $totalEffort = 0
    $tenantScores = @{}
    
    foreach ($tenant in $AllTenantData.GetEnumerator()) {
        $tenantFindings = $tenant.Value.Findings
        $totalFindings += $tenantFindings.Count
        $criticalFindings += ($tenantFindings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
        $totalEffort += ($tenantFindings | Measure-Object -Property EstimatedHours -Sum).Sum
        
        # Calculate tenant score
        $score = 100
        $score -= ($tenantFindings | Where-Object { $_.Severity -eq "CRITICAL" }).Count * 10
        $score -= ($tenantFindings | Where-Object { $_.Severity -eq "HIGH" }).Count * 5
        $score -= ($tenantFindings | Where-Object { $_.Severity -eq "MEDIUM" }).Count * 2
        $tenantScores[$tenant.Key] = [Math]::Max(0, $score)
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Enhanced Executive Report</title>
    <meta charset="UTF-8">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { 
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            background: #f5f5f5;
        }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: linear-gradient(135deg, #0078D4 0%, #00BCF2 50%, #40E0D0 100%);
            color: white;
            padding: 80px 40px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
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
        
        .header h1 { 
            font-size: 56px; 
            font-weight: 300; 
            margin-bottom: 10px;
            position: relative;
            z-index: 1;
        }
        
        .header h2 { 
            font-size: 24px; 
            font-weight: 400; 
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 30px;
            margin: 40px 0;
        }
        
        .metric-card {
            background: white;
            padding: 35px;
            border-radius: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            text-align: center;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .metric-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 5px;
            background: linear-gradient(90deg, #0078D4, #00BCF2);
        }
        
        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 40px rgba(0,0,0,0.15);
        }
        
        .metric-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .metric-value {
            font-size: 48px;
            font-weight: 700;
            margin: 15px 0;
            background: linear-gradient(135deg, #0078D4, #00BCF2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .metric-label {
            font-size: 16px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .critical { color: #D83B01; }
        .high { color: #FF8C00; }
        .medium { color: #FFB900; }
        .low { color: #107C10; }
        
        .tenant-comparison {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            margin: 40px 0;
        }
        
        .tenant-score-bar {
            display: flex;
            align-items: center;
            margin: 20px 0;
        }
        
        .tenant-name {
            width: 200px;
            font-weight: 600;
        }
        
        .score-bar {
            flex: 1;
            height: 30px;
            background: #e0e0e0;
            border-radius: 15px;
            position: relative;
            overflow: hidden;
        }
        
        .score-fill {
            height: 100%;
            background: linear-gradient(90deg, #D83B01 0%, #FFB900 50%, #107C10 100%);
            border-radius: 15px;
            transition: width 1s ease;
            position: relative;
        }
        
        .score-text {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            font-weight: 600;
            color: white;
        }
        
        .insights-section {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            margin: 40px 0;
        }
        
        .insight-card {
            background: #f8f9fa;
            padding: 25px;
            margin: 20px 0;
            border-left: 5px solid #0078D4;
            border-radius: 10px;
        }
        
        .chart-container {
            height: 400px;
            margin: 30px 0;
            background: white;
            padding: 20px;
            border-radius: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }
        
        .recommendation-card {
            background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
            padding: 30px;
            margin: 20px 0;
            border-radius: 15px;
            border-left: 5px solid #0078D4;
        }
        
        .footer {
            text-align: center;
            padding: 40px;
            color: #666;
            font-size: 14px;
            margin-top: 60px;
        }
        
        @media print {
            .header { padding: 40px 20px; }
            .metric-card { break-inside: avoid; }
            .chart-container { break-inside: avoid; }
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="header">
        <h1>PowerReview Enhanced Assessment</h1>
        <h2>Multi-Tenant Executive Report</h2>
        <p style="margin-top: 20px; font-size: 18px;">Generated: $(Get-Date -Format "MMMM dd, yyyy HH:mm")</p>
    </div>
    
    <div class="container">
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-icon">🏢</div>
                <div class="metric-label">Tenants Assessed</div>
                <div class="metric-value">$($AllTenantData.Count)</div>
                <p>Comprehensive Analysis</p>
            </div>
            
            <div class="metric-card">
                <div class="metric-icon">⚠️</div>
                <div class="metric-label">Total Findings</div>
                <div class="metric-value">$totalFindings</div>
                <p>Across All Tenants</p>
            </div>
            
            <div class="metric-card">
                <div class="metric-icon">🚨</div>
                <div class="metric-label">Critical Issues</div>
                <div class="metric-value critical">$criticalFindings</div>
                <p>Immediate Action Required</p>
            </div>
            
            <div class="metric-card">
                <div class="metric-icon">⏱️</div>
                <div class="metric-label">Total Effort</div>
                <div class="metric-value">$([Math]::Round($totalEffort / 160, 1))</div>
                <p>Person-Months</p>
            </div>
        </div>
        
        <div class="tenant-comparison">
            <h2>Tenant Security Posture Comparison</h2>
            <p style="color: #666; margin-bottom: 30px;">Higher scores indicate better security posture</p>
$(
    foreach ($tenant in $tenantScores.GetEnumerator() | Sort-Object Value -Descending) {
        $score = $tenant.Value
        $color = if ($score -ge 80) { "#107C10" } elseif ($score -ge 60) { "#FFB900" } else { "#D83B01" }
        @"
            <div class="tenant-score-bar">
                <div class="tenant-name">$($AllTenantData[$tenant.Key].Name)</div>
                <div class="score-bar">
                    <div class="score-fill" style="width: $score%; background: $color;">
                        <span class="score-text">$score%</span>
                    </div>
                </div>
            </div>
"@
    }
)
        </div>
        
        <div class="insights-section">
            <h2>Executive Insights</h2>
            
            <div class="insight-card">
                <h3>🎯 Primary Risk Areas</h3>
                <ul style="margin-top: 15px; padding-left: 20px;">
$(
    $riskAreas = $AllTenantData.Values.Findings | Group-Object Module | Sort-Object Count -Descending | Select-Object -First 3
    foreach ($area in $riskAreas) {
        $criticalCount = ($area.Group | Where-Object { $_.Severity -eq "CRITICAL" }).Count
        "<li><strong>$($area.Name):</strong> $($area.Count) issues ($criticalCount critical)</li>"
    }
)
                </ul>
            </div>
            
            <div class="insight-card">
                <h3>💡 Strategic Recommendations</h3>
                <ol style="margin-top: 15px; padding-left: 20px;">
                    <li>Implement a phased remediation approach focusing on critical security gaps first</li>
                    <li>Establish a centralized governance framework across all tenants</li>
                    <li>Deploy automated compliance monitoring and reporting</li>
                    <li>Invest in security awareness training for administrators</li>
                    <li>Consider consolidating tenant management for improved efficiency</li>
                </ol>
            </div>
            
            <div class="insight-card">
                <h3>📊 Compliance Overview</h3>
$(
    $complianceData = @{}
    foreach ($tenant in $AllTenantData.GetEnumerator()) {
        if ($tenant.Value.Metrics.Compliance) {
            foreach ($framework in $tenant.Value.Metrics.Compliance.GetEnumerator()) {
                if (!$complianceData[$framework.Key]) {
                    $complianceData[$framework.Key] = @()
                }
                $complianceData[$framework.Key] += $framework.Value
            }
        }
    }
    
    foreach ($framework in $complianceData.GetEnumerator()) {
        $avgScore = [Math]::Round(($framework.Value | Measure-Object -Average).Average, 1)
        $color = if ($avgScore -ge 80) { "#107C10" } elseif ($avgScore -ge 60) { "#FFB900" } else { "#D83B01" }
        "<p style='margin: 10px 0;'><strong>$($framework.Key):</strong> <span style='color: $color; font-weight: bold;'>$avgScore%</span> average compliance</p>"
    }
)
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="findingsChart"></canvas>
        </div>
        
        <div class="chart-container">
            <canvas id="modulesChart"></canvas>
        </div>
        
        <div class="recommendation-card">
            <h3>🚀 Next Steps</h3>
            <ol style="margin-top: 20px; padding-left: 20px; line-height: 2;">
                <li><strong>Week 1-2:</strong> Address all critical security findings</li>
                <li><strong>Week 3-4:</strong> Implement baseline security policies across all tenants</li>
                <li><strong>Month 2:</strong> Deploy governance framework and automation</li>
                <li><strong>Month 3:</strong> Conduct compliance remediation</li>
                <li><strong>Ongoing:</strong> Establish regular assessment schedule</li>
            </ol>
        </div>
        
        <div class="recommendation-card">
            <h3>💰 Investment Summary</h3>
            <ul style="margin-top: 20px; padding-left: 20px;">
                <li><strong>Technical Effort:</strong> $([Math]::Round($totalEffort, 0)) hours ($([Math]::Round($totalEffort / 160, 1)) person-months)</li>
                <li><strong>Estimated Timeline:</strong> 3-6 months for full remediation</li>
                <li><strong>Resources Required:</strong> 
                    <ul style="margin-top: 10px;">
                        <li>2-3 Security Engineers</li>
                        <li>1-2 M365 Administrators</li>
                        <li>1 Project Manager</li>
                        <li>Compliance Specialist (part-time)</li>
                    </ul>
                </li>
                <li><strong>Budget Considerations:</strong>
                    <ul style="margin-top: 10px;">
                        <li>License upgrades (E5/E5 Compliance)</li>
                        <li>Third-party security tools</li>
                        <li>Training and certification</li>
                        <li>Potential consulting engagement</li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
    
    <div class="footer">
        <p><strong>PowerReview Enhanced Framework v$($script:Version)</strong></p>
        <p>This document contains confidential security information</p>
        <p>© $(Get-Date -Format yyyy) - Assessment ID: $(New-Guid)</p>
    </div>
    
    <script>
        // Findings by Severity Chart
        const findingsCtx = document.getElementById('findingsChart').getContext('2d');
        new Chart(findingsCtx, {
            type: 'bar',
            data: {
                labels: ['Critical', 'High', 'Medium', 'Low'],
                datasets: [{
                    label: 'Number of Findings',
                    data: [
                        $criticalFindings,
                        $(($AllTenantData.Values.Findings | Where-Object { $_.Severity -eq "HIGH" }).Count),
                        $(($AllTenantData.Values.Findings | Where-Object { $_.Severity -eq "MEDIUM" }).Count),
                        $(($AllTenantData.Values.Findings | Where-Object { $_.Severity -eq "LOW" }).Count)
                    ],
                    backgroundColor: ['#D83B01', '#FF8C00', '#FFB900', '#107C10'],
                    borderRadius: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        display: true,
                        text: 'Findings by Severity',
                        font: { size: 18 }
                    },
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { stepSize: 1 }
                    }
                }
            }
        });
        
        // Findings by Module Chart
        const modulesCtx = document.getElementById('modulesChart').getContext('2d');
        const moduleData = {};
        $(
            $moduleGroups = $AllTenantData.Values.Findings | Group-Object Module
            foreach ($module in $moduleGroups) {
                "moduleData['$($module.Name)'] = $($module.Count);"
            }
        )
        
        new Chart(modulesCtx, {
            type: 'doughnut',
            data: {
                labels: Object.keys(moduleData),
                datasets: [{
                    data: Object.values(moduleData),
                    backgroundColor: [
                        '#0078D4', '#00BCF2', '#40E0D0', '#FF8C00', 
                        '#FFB900', '#107C10', '#5C2D91', '#B4009E'
                    ],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        display: true,
                        text: 'Findings Distribution by Module',
                        font: { size: 18 }
                    },
                    legend: {
                        position: 'right',
                        labels: {
                            padding: 15,
                            font: { size: 12 }
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $html | Out-File "$OutputPath\Executive_Report_Enhanced.html" -Encoding UTF8
    Write-SecureLog "Enhanced executive report generated" "SUCCESS"
}

function New-TenantDetailedReport {
    param(
        [string]$TenantId,
        [hashtable]$TenantData,
        [string]$OutputPath
    )
    
    Write-SecureLog "Generating detailed report for tenant: $TenantId" "INFO" $TenantId
    
    # Create tenant-specific detailed report
    $findings = $TenantData.Findings
    $evidence = $TenantData.Evidence
    $metrics = $TenantData.Metrics
    
    $markdown = @"
# PowerReview Detailed Assessment Report

## Tenant: $($TenantData.Name)
**Tenant ID:** $TenantId  
**Assessment Date:** $(Get-Date -Format "MMMM dd, yyyy")  
**Analysis Depth:** $AnalysisDepth

---

## Executive Summary

This detailed report provides comprehensive findings from the PowerReview assessment of your Microsoft 365 and Azure environment.

### Key Metrics
- **Total Findings:** $($findings.Count)
- **Critical Issues:** $(($findings | Where-Object { $_.Severity -eq "CRITICAL" }).Count)
- **Security Score:** $($metrics.SecurityScore ?? "N/A")/100
- **Estimated Remediation Effort:** $(($findings | Measure-Object -Property EstimatedHours -Sum).Sum) hours

---

## Detailed Findings by Module

$(
    $moduleGroups = $findings | Group-Object Module | Sort-Object Name
    foreach ($module in $moduleGroups) {
        @"

### $($module.Name)

**Total Issues:** $($module.Count)

$(
        $severityGroups = $module.Group | Group-Object Severity
        foreach ($severity in @("CRITICAL", "HIGH", "MEDIUM", "LOW")) {
            $count = ($severityGroups | Where-Object { $_.Name -eq $severity }).Count
            if ($count -gt 0) {
                "- **$severity**: $count issues`n"
            }
        }
)

#### Detailed Findings:

$(
        foreach ($finding in ($module.Group | Sort-Object Severity, Category)) {
            @"

##### $($finding.Issue)
- **Severity:** $($finding.Severity)
- **Category:** $($finding.Category)
- **Impact:** $($finding.Impact)
- **Current State:** $($finding.CurrentValue)
- **Recommended State:** $($finding.RecommendedValue)
- **Remediation Steps:** $($finding.RemediationSteps)
- **Estimated Effort:** $($finding.EstimatedHours) hours
- **Evidence:** $($finding.Evidence)

"@
        }
)
"@
    }
)

---

## Evidence Summary

### Configuration Evidence

$(
    $configEvidence = $evidence | Where-Object { $_.Component -like "*Config*" -or $_.Component -like "*Policy*" }
    if ($configEvidence) {
        "| Component | Key Configuration | Value |`n|-----------|------------------|-------|"
        foreach ($item in $configEvidence | Select-Object -First 20) {
            $props = $item.PSObject.Properties | Where-Object { $_.Name -notin @("Component", "TenantId", "Timestamp") }
            foreach ($prop in $props | Select-Object -First 3) {
                "`n| $($item.Component) | $($prop.Name) | $($prop.Value) |"
            }
        }
    }
)

### Security Metrics

$(
    if ($metrics.SecurityScore) {
        "- **Overall Security Score:** $($metrics.SecurityScore)/100`n"
    }
    if ($metrics.Compliance) {
        "- **Compliance Scores:**`n"
        foreach ($framework in $metrics.Compliance.GetEnumerator()) {
            "  - $($framework.Key): $($framework.Value)%`n"
        }
    }
)

---

## Remediation Roadmap

### Phase 1: Critical Issues (0-30 Days)

$(
    $phase1 = $findings | Where-Object { $_.Severity -eq "CRITICAL" } | Sort-Object EstimatedHours
    $phase1Effort = ($phase1 | Measure-Object -Property EstimatedHours -Sum).Sum
    
    "**Total Effort:** $phase1Effort hours`n`n"
    
    foreach ($item in $phase1) {
        "1. **$($item.Issue)**`n   - Module: $($item.Module)`n   - Effort: $($item.EstimatedHours) hours`n"
    }
)

### Phase 2: High Priority (30-60 Days)

$(
    $phase2 = $findings | Where-Object { $_.Severity -eq "HIGH" } | Sort-Object EstimatedHours | Select-Object -First 10
    $phase2Effort = ($phase2 | Measure-Object -Property EstimatedHours -Sum).Sum
    
    "**Total Effort:** $phase2Effort hours`n`n"
    
    foreach ($item in $phase2) {
        "1. **$($item.Issue)**`n   - Module: $($item.Module)`n   - Effort: $($item.EstimatedHours) hours`n"
    }
)

### Phase 3: Optimization (60-90 Days)

Focus on medium and low priority items to optimize your environment.

---

## Appendix

### Assessment Methodology
- **Analysis Depth:** $AnalysisDepth
- **Data Collection Period:** $DaysToAnalyze days
- **Modules Assessed:** $($moduleGroups.Name -join ", ")

### Next Steps
1. Review this report with your security team
2. Prioritize remediation based on risk and effort
3. Allocate resources for implementation
4. Schedule follow-up assessment in 6 months

---

*Generated by PowerReview Enhanced Framework v$($script:Version)*
"@
    
    $markdown | Out-File "$OutputPath\Tenant_Detailed_Report.md" -Encoding UTF8
    
    # Also generate a PDF if possible (requires additional tools)
    if (Get-Command pandoc -ErrorAction SilentlyContinue) {
        try {
            pandoc "$OutputPath\Tenant_Detailed_Report.md" -o "$OutputPath\Tenant_Detailed_Report.pdf" --pdf-engine=xelatex
            Write-SecureLog "PDF report generated" "SUCCESS" $TenantId
        }
        catch {
            Write-SecureLog "PDF generation failed: $_" "WARN" $TenantId
        }
    }
}

#endregion

#region Main Execution

try {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║         PowerReview Enhanced Framework v$($script:Version)         ║
║            Enterprise Multi-Tenant Assessment Platform            ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Initialize components
    if ($SecureStorage) {
        Initialize-SecureStorage -VaultPath $VaultPath
    }
    
    if ($UseMCP) {
        Initialize-MCPIntegration
    }
    
    # Load tenant configuration
    $config = Import-TenantConfiguration -ConfigPath $TenantConfig
    
    # Set output path
    if (!$OutputPath) {
        $OutputPath = ".\PowerReview_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    $script:OutputPath = $OutputPath
    
    # Create output structure
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Create subdirectories for each tenant
    foreach ($tenant in $script:TenantData.GetEnumerator()) {
        $tenantPath = Join-Path $OutputPath $tenant.Value.Name.Replace(" ", "_")
        New-Item -ItemType Directory -Path $tenantPath -Force | Out-Null
        
        # Create module subdirectories
        foreach ($module in $Modules) {
            New-Item -ItemType Directory -Path "$tenantPath\$module" -Force | Out-Null
        }
    }
    
    # Process each tenant
    foreach ($tenant in $script:TenantData.GetEnumerator()) {
        Write-SecureLog "════════════════════════════════════════════════════════" "INFO"
        Write-SecureLog "Processing Tenant: $($tenant.Value.Name)" "INFO" $tenant.Key
        Write-SecureLog "════════════════════════════════════════════════════════" "INFO"
        
        $tenantPath = Join-Path $OutputPath $tenant.Value.Name.Replace(" ", "_")
        
        try {
            # Connect to tenant services
            Connect-M365Services -TenantId $tenant.Key
            
            # Run selected modules
            if ("Purview" -in $tenant.Value.Modules) {
                if ($DeepAnalysis -or $AnalysisDepth -in @("Deep", "Forensic")) {
                    Invoke-DeepPurviewAnalysis -TenantId $tenant.Key -OutputPath "$tenantPath\Purview"
                }
                else {
                    # Run standard Purview assessment
                    Invoke-PurviewAssessment -OutputPath "$tenantPath\Purview"
                }
            }
            
            if ("Security" -in $tenant.Value.Modules) {
                if ($DeepAnalysis -or $AnalysisDepth -in @("Deep", "Forensic")) {
                    Invoke-DeepSecurityAnalysis -TenantId $tenant.Key -OutputPath "$tenantPath\Security"
                }
                else {
                    # Run standard Security assessment
                    Invoke-SecurityAssessment -OutputPath "$tenantPath\Security"
                }
            }
            
            if ("Compliance" -in $tenant.Value.Modules -and $ComplianceMode) {
                Invoke-DeepComplianceAnalysis -TenantId $tenant.Key -OutputPath "$tenantPath\Compliance" -Frameworks $tenant.Value.ComplianceRequirements
            }
            
            # Generate tenant-specific reports
            New-TenantDetailedReport -TenantId $tenant.Key -TenantData $tenant.Value -OutputPath $tenantPath
            
            Write-SecureLog "Completed assessment for tenant: $($tenant.Value.Name)" "SUCCESS" $tenant.Key
        }
        catch {
            Write-SecureLog "Failed to assess tenant $($tenant.Value.Name): $_" "ERROR" $tenant.Key
        }
        finally {
            # Disconnect from tenant
            Disconnect-M365Services
        }
    }
    
    # Generate consolidated reports
    Write-SecureLog "Generating consolidated reports..." "INFO"
    New-EnhancedExecutiveReport -OutputPath $OutputPath -AllTenantData $script:TenantData
    
    # Save secure assessment data
    if ($SecureStorage) {
        Save-SecureData -Name "AssessmentComplete" -Data @{
            TenantData = $script:TenantData
            GlobalFindings = $script:GlobalFindings
            GlobalMetrics = $script:GlobalMetrics
            CompletionTime = Get-Date
        } -TenantId "Global"
    }
    
    # Display summary
    $duration = (Get-Date) - $script:StartTime
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              ASSESSMENT COMPLETE!                                 ║" -ForegroundColor Green  
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Duration: $([Math]::Round($duration.TotalMinutes, 1)) minutes"
    Write-Host "  Tenants Assessed: $($script:TenantData.Count)"
    Write-Host "  Total Findings: $($script:TenantData.Values.Findings.Count)"
    Write-Host "  Analysis Depth: $AnalysisDepth"
    Write-Host "  Output Location: $OutputPath" -ForegroundColor Yellow
    
    if ($SecureStorage) {
        Write-Host "`nSecure Data:" -ForegroundColor Cyan
        Write-Host "  Vault Location: $($script:SecureVault.Path)" -ForegroundColor Yellow
        Write-Host "  Encrypted Artifacts: $(Get-ChildItem $script:SecureVault.Path -Filter "*.vault" | Measure-Object | Select-Object -ExpandProperty Count)"
    }
    
    Write-Host "`nKey Deliverables:" -ForegroundColor Cyan
    Write-Host "  Executive Report: $OutputPath\Executive_Report_Enhanced.html" -ForegroundColor Green
    Write-Host "  Tenant Reports: $OutputPath\[TenantName]\Tenant_Detailed_Report.md" -ForegroundColor Green
    
    # Open executive report
    Start-Process "$OutputPath\Executive_Report_Enhanced.html"
}
catch {
    Write-SecureLog "Assessment failed: $_" "ERROR"
    throw
}
finally {
    Write-SecureLog "PowerReview session completed" "INFO"
}

#endregion