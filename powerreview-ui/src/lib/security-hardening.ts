/**
 * PowerReview Security Hardening Engine
 * Advanced security controls, threat protection, and automated hardening
 */

export interface SecurityPolicy {
    id: string;
    name: string;
    category: 'access_control' | 'data_protection' | 'network_security' | 'application_security' | 'monitoring';
    severity: 'critical' | 'high' | 'medium' | 'low';
    enabled: boolean;
    configuration: Record<string, any>;
    lastUpdated: Date;
    autoRemediate: boolean;
}

export interface SecurityHardening {
    hardeningId: string;
    name: string;
    description: string;
    service: 'azuread' | 'exchange' | 'sharepoint' | 'teams' | 'defender' | 'purview' | 'powerplatform';
    category: 'identity' | 'email' | 'collaboration' | 'data' | 'device' | 'infrastructure';
    severity: 'critical' | 'high' | 'medium' | 'low';
    powershellScript: string;
    rollbackScript?: string;
    validationScript: string;
    prerequisites: string[];
    riskLevel: number; // 1-10
    businessImpact: 'low' | 'medium' | 'high';
    compliance: string[];
    autoApply: boolean;
    testMode: boolean;
}

export interface SecurityIncident {
    incidentId: string;
    type: 'brute_force' | 'data_exfiltration' | 'privilege_escalation' | 'malware' | 'phishing' | 'anomaly';
    severity: 'critical' | 'high' | 'medium' | 'low';
    description: string;
    source: string;
    affectedResources: string[];
    detectedAt: Date;
    status: 'open' | 'investigating' | 'contained' | 'resolved' | 'false_positive';
    responseActions: ResponseAction[];
    timeline: IncidentEvent[];
    tags: string[];
}

export interface ResponseAction {
    actionId: string;
    type: 'block_user' | 'isolate_device' | 'quarantine_email' | 'disable_app' | 'reset_password' | 'notify_admin';
    description: string;
    script: string;
    executedAt?: Date;
    status: 'pending' | 'executing' | 'completed' | 'failed';
    result?: any;
}

export interface IncidentEvent {
    timestamp: Date;
    event: string;
    severity: string;
    details: string;
    actor: string;
}

export class SecurityHardeningEngine {
    private policies: Map<string, SecurityPolicy> = new Map();
    private hardeningRules: Map<string, SecurityHardening> = new Map();
    private incidents: Map<string, SecurityIncident> = new Map();
    private isMonitoring: boolean = false;
    private eventEmitter = new EventTarget();

    constructor() {
        this.initializeSecurityPolicies();
        this.initializeHardeningRules();
        this.startSecurityMonitoring();
    }

    private initializeSecurityPolicies() {
        const defaultPolicies: SecurityPolicy[] = [
            {
                id: 'pol_mfa_enforcement',
                name: 'Multi-Factor Authentication Enforcement',
                category: 'access_control',
                severity: 'critical',
                enabled: true,
                configuration: {
                    enforceForAdmins: true,
                    enforceForUsers: true,
                    allowedMethods: ['authenticator', 'sms', 'call'],
                    gracePeriodDays: 7,
                    exemptAccounts: []
                },
                lastUpdated: new Date(),
                autoRemediate: true
            },
            {
                id: 'pol_data_encryption',
                name: 'Data Encryption at Rest and Transit',
                category: 'data_protection',
                severity: 'critical',
                enabled: true,
                configuration: {
                    encryptionStandard: 'AES-256',
                    keyRotationDays: 90,
                    encryptSharePoint: true,
                    encryptExchange: true,
                    encryptOneDrive: true
                },
                lastUpdated: new Date(),
                autoRemediate: false
            },
            {
                id: 'pol_conditional_access',
                name: 'Conditional Access Policies',
                category: 'access_control',
                severity: 'high',
                enabled: true,
                configuration: {
                    requireCompliantDevice: true,
                    blockLegacyAuth: true,
                    requireManagedApp: true,
                    riskBasedAccess: true,
                    locationBasedAccess: true
                },
                lastUpdated: new Date(),
                autoRemediate: true
            },
            {
                id: 'pol_privileged_access',
                name: 'Privileged Access Management',
                category: 'access_control',
                severity: 'critical',
                enabled: true,
                configuration: {
                    enablePIM: true,
                    requireApproval: true,
                    maxActivationHours: 8,
                    requireJustification: true,
                    enableAccessReviews: true,
                    reviewFrequencyDays: 30
                },
                lastUpdated: new Date(),
                autoRemediate: false
            },
            {
                id: 'pol_dlp_protection',
                name: 'Data Loss Prevention',
                category: 'data_protection',
                severity: 'high',
                enabled: true,
                configuration: {
                    protectPII: true,
                    protectCreditCards: true,
                    protectSSN: true,
                    blockExternalSharing: true,
                    encryptSensitiveData: true,
                    enableWatermarking: true
                },
                lastUpdated: new Date(),
                autoRemediate: true
            }
        ];

        defaultPolicies.forEach(policy => {
            this.policies.set(policy.id, policy);
        });
    }

    private initializeHardeningRules() {
        const hardeningRules: SecurityHardening[] = [
            {
                hardeningId: 'hard_aad_mfa',
                name: 'Enable MFA for All Users',
                description: 'Enforces multi-factor authentication for all user accounts',
                service: 'azuread',
                category: 'identity',
                severity: 'critical',
                powershellScript: `
# Enable MFA for all users
Connect-MsolService
$mfaSettings = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mfaSettings.RelyingParty = "*"
$mfaSettings.State = "Enabled"

Get-MsolUser -All | ForEach-Object {
    if ($_.StrongAuthenticationRequirements.Count -eq 0) {
        Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements @($mfaSettings)
        Write-Output "MFA enabled for: $($_.UserPrincipalName)"
    }
}`,
                rollbackScript: `
# Disable MFA for all users (use with caution)
Connect-MsolService
Get-MsolUser -All | ForEach-Object {
    Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements @()
    Write-Output "MFA disabled for: $($_.UserPrincipalName)"
}`,
                validationScript: `
# Validate MFA enforcement
Connect-MsolService
$usersWithoutMFA = Get-MsolUser -All | Where-Object { $_.StrongAuthenticationRequirements.Count -eq 0 }
$result = @{
    TotalUsers = (Get-MsolUser -All).Count
    UsersWithMFA = (Get-MsolUser -All | Where-Object { $_.StrongAuthenticationRequirements.Count -gt 0 }).Count
    UsersWithoutMFA = $usersWithoutMFA.Count
    CompliancePercentage = [math]::Round((1 - ($usersWithoutMFA.Count / (Get-MsolUser -All).Count)) * 100, 2)
}
return $result | ConvertTo-Json`,
                prerequisites: ['MSOnline PowerShell Module', 'Global Admin Rights'],
                riskLevel: 2,
                businessImpact: 'medium',
                compliance: ['NIST', 'ISO27001', 'GDPR'],
                autoApply: false,
                testMode: true
            },
            {
                hardeningId: 'hard_block_legacy_auth',
                name: 'Block Legacy Authentication',
                description: 'Blocks legacy authentication protocols that bypass modern security controls',
                service: 'azuread',
                category: 'identity',
                severity: 'high',
                powershellScript: `
# Block legacy authentication
Connect-AzureAD
$policyName = "Block Legacy Authentication"

# Create conditional access policy
$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "All"
$conditions.ClientAppTypes = @("exchangeActiveSync", "other")

$grantControls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$grantControls.BuiltInControls = @("block")
$grantControls.Operator = "OR"

New-AzureADMSConditionalAccessPolicy -DisplayName $policyName -State "enabled" -Conditions $conditions -GrantControls $grantControls`,
                validationScript: `
# Validate legacy auth is blocked
Connect-AzureAD
$legacyAuthPolicy = Get-AzureADMSConditionalAccessPolicy | Where-Object { $_.DisplayName -like "*Legacy*" -and $_.State -eq "enabled" }
$result = @{
    PolicyExists = $legacyAuthPolicy -ne $null
    PolicyEnabled = $legacyAuthPolicy.State -eq "enabled"
    PolicyName = $legacyAuthPolicy.DisplayName
}
return $result | ConvertTo-Json`,
                prerequisites: ['AzureAD PowerShell Module', 'Conditional Access License'],
                riskLevel: 3,
                businessImpact: 'high',
                compliance: ['NIST', 'CIS'],
                autoApply: false,
                testMode: true
            },
            {
                hardeningId: 'hard_sharepoint_external_sharing',
                name: 'Restrict SharePoint External Sharing',
                description: 'Configures SharePoint to restrict external sharing and require authentication',
                service: 'sharepoint',
                category: 'collaboration',
                severity: 'high',
                powershellScript: `
# Restrict SharePoint external sharing
Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"

# Set tenant-wide external sharing settings
Set-SPOTenant -SharingCapability ExistingExternalUserSharingOnly
Set-SPOTenant -RequireAnonymousLinksExpireInDays 30
Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount $true
Set-SPOTenant -PreventExternalUsersFromResharing $true

# Enable DLP for SharePoint
Set-SPOTenant -EnableAIPIntegration $true

Write-Output "SharePoint external sharing restrictions applied"`,
                validationScript: `
# Validate SharePoint sharing settings
Connect-SPOService -Url "https://yourtenant-admin.sharepoint.com"
$tenant = Get-SPOTenant
$result = @{
    SharingCapability = $tenant.SharingCapability
    AnonymousLinksExpire = $tenant.RequireAnonymousLinksExpireInDays
    PreventResharing = $tenant.PreventExternalUsersFromResharing
    AIPIntegration = $tenant.EnableAIPIntegration
}
return $result | ConvertTo-Json`,
                prerequisites: ['SharePoint Online Management Shell', 'SharePoint Admin Rights'],
                riskLevel: 4,
                businessImpact: 'medium',
                compliance: ['GDPR', 'HIPAA'],
                autoApply: false,
                testMode: true
            },
            {
                hardeningId: 'hard_defender_atp',
                name: 'Enable Microsoft Defender ATP',
                description: 'Configures Microsoft Defender Advanced Threat Protection with optimal settings',
                service: 'defender',
                category: 'device',
                severity: 'critical',
                powershellScript: `
# Enable Microsoft Defender ATP
Connect-ExchangeOnline

# Enable ATP Safe Attachments
New-SafeAttachmentPolicy -Name "ATP Safe Attachments Policy" -Enable $true -Action Block -Redirect $true -RedirectAddress "security@yourdomain.com"

# Enable ATP Safe Links
New-SafeLinksPolicy -Name "ATP Safe Links Policy" -IsEnabled $true -ScanUrls $true -EnableForInternalSenders $true -TrackClicks $true

# Enable Anti-Phishing
New-AntiPhishPolicy -Name "ATP Anti-Phishing Policy" -EnableMailboxIntelligence $true -EnableSimilarUsersSafetyTips $true -EnableSimilarDomainsSafetyTips $true

Write-Output "Microsoft Defender ATP policies configured"`,
                validationScript: `
# Validate Defender ATP configuration
Connect-ExchangeOnline
$result = @{
    SafeAttachments = (Get-SafeAttachmentPolicy).Count
    SafeLinks = (Get-SafeLinksPolicy).Count
    AntiPhishing = (Get-AntiPhishPolicy).Count
}
return $result | ConvertTo-Json`,
                prerequisites: ['Exchange Online Management', 'Microsoft Defender License'],
                riskLevel: 1,
                businessImpact: 'low',
                compliance: ['NIST', 'ISO27001'],
                autoApply: true,
                testMode: false
            },
            {
                hardeningId: 'hard_purview_dlp',
                name: 'Configure Data Loss Prevention',
                description: 'Sets up comprehensive DLP policies to protect sensitive data',
                service: 'purview',
                category: 'data',
                severity: 'high',
                powershellScript: `
# Configure Purview DLP policies
Connect-IPPSSession

# Create DLP policy for PII protection
$dlpPolicy = New-DlpPolicy -Name "PII Protection Policy" -Template "U.S. Personally Identifiable Information (PII) Data"
Set-DlpPolicy -Identity $dlpPolicy.Identity -Mode Enforce

# Create DLP policy for financial data
$financialPolicy = New-DlpPolicy -Name "Financial Data Protection" -Template "U.S. Financial Data"
Set-DlpPolicy -Identity $financialPolicy.Identity -Mode Enforce

# Create custom DLP rule for credit cards
New-DlpComplianceRule -Policy $financialPolicy.Identity -Name "Credit Card Protection" -ContentContainsSensitiveInformation @{Name="Credit Card Number"; minCount="1"} -BlockAccess $true

Write-Output "DLP policies configured successfully"`,
                validationScript: `
# Validate DLP configuration
Connect-IPPSSession
$policies = Get-DlpPolicy
$result = @{
    TotalPolicies = $policies.Count
    EnforcedPolicies = ($policies | Where-Object { $_.Mode -eq "Enforce" }).Count
    PolicyNames = $policies.Name
}
return $result | ConvertTo-Json`,
                prerequisites: ['Security & Compliance PowerShell', 'DLP License'],
                riskLevel: 3,
                businessImpact: 'medium',
                compliance: ['GDPR', 'HIPAA', 'PCI-DSS'],
                autoApply: false,
                testMode: true
            }
        ];

        hardeningRules.forEach(rule => {
            this.hardeningRules.set(rule.hardeningId, rule);
        });
    }

    public async performSecurityAssessment(): Promise<{
        overallScore: number;
        findings: Array<{
            category: string;
            severity: string;
            finding: string;
            recommendation: string;
            hardeningRule?: string;
        }>;
        policies: SecurityPolicy[];
        recommendations: string[];
    }> {
        const findings = [];
        const recommendations = [];
        let totalScore = 0;
        let maxScore = 0;

        // Assess each security policy
        for (const [policyId, policy] of this.policies) {
            maxScore += 100;
            
            if (policy.enabled) {
                totalScore += 80; // Base score for enabled policy
                
                // Additional scoring based on configuration
                switch (policy.category) {
                    case 'access_control':
                        if (policy.configuration.enforceForAdmins && policy.configuration.enforceForUsers) {
                            totalScore += 20;
                        }
                        break;
                    case 'data_protection':
                        if (policy.configuration.encryptionStandard === 'AES-256') {
                            totalScore += 15;
                        }
                        break;
                }
            } else {
                findings.push({
                    category: policy.category,
                    severity: policy.severity,
                    finding: `${policy.name} is disabled`,
                    recommendation: `Enable ${policy.name} to improve security posture`,
                    hardeningRule: this.findRelatedHardeningRule(policy.id)
                });
            }
        }

        // Generate recommendations based on findings
        if (findings.length > 0) {
            recommendations.push("Enable all critical security policies immediately");
            recommendations.push("Review and update security policy configurations");
            recommendations.push("Implement automated policy monitoring");
        }

        const overallScore = Math.round((totalScore / maxScore) * 100);

        return {
            overallScore,
            findings,
            policies: Array.from(this.policies.values()),
            recommendations
        };
    }

    public async applyHardening(hardeningId: string, testMode: boolean = true): Promise<{
        success: boolean;
        result?: any;
        error?: string;
        rollbackScript?: string;
    }> {
        const hardening = this.hardeningRules.get(hardeningId);
        if (!hardening) {
            return { success: false, error: 'Hardening rule not found' };
        }

        try {
            // In a real implementation, this would execute the PowerShell script
            // For demo purposes, we'll simulate the execution
            
            if (testMode) {
                // Simulate test execution
                await this.simulateScriptExecution(hardening.validationScript);
                return {
                    success: true,
                    result: `Test mode: ${hardening.name} validation completed`,
                    rollbackScript: hardening.rollbackScript
                };
            } else {
                // Simulate actual execution
                await this.simulateScriptExecution(hardening.powershellScript);
                
                // Log the action
                this.logSecurityAction(hardeningId, 'applied', hardening.name);
                
                return {
                    success: true,
                    result: `${hardening.name} applied successfully`,
                    rollbackScript: hardening.rollbackScript
                };
            }
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    public async validateHardening(hardeningId: string): Promise<{
        success: boolean;
        compliant: boolean;
        details: any;
        score: number;
    }> {
        const hardening = this.hardeningRules.get(hardeningId);
        if (!hardening) {
            return { success: false, compliant: false, details: null, score: 0 };
        }

        try {
            // Simulate validation execution
            const result = await this.simulateValidation(hardening);
            
            return {
                success: true,
                compliant: result.compliant,
                details: result.details,
                score: result.score
            };
        } catch (error) {
            return { success: false, compliant: false, details: error.message, score: 0 };
        }
    }

    public detectThreat(threatData: any): SecurityIncident {
        const incidentId = `inc_${Date.now()}`;
        
        const incident: SecurityIncident = {
            incidentId,
            type: this.classifyThreat(threatData),
            severity: this.calculateThreatSeverity(threatData),
            description: threatData.description || 'Security threat detected',
            source: threatData.source || 'Unknown',
            affectedResources: threatData.affectedResources || [],
            detectedAt: new Date(),
            status: 'open',
            responseActions: [],
            timeline: [{
                timestamp: new Date(),
                event: 'Threat Detected',
                severity: this.calculateThreatSeverity(threatData),
                details: threatData.description || 'Automated threat detection',
                actor: 'Security Engine'
            }],
            tags: threatData.tags || []
        };

        this.incidents.set(incidentId, incident);
        this.generateResponseActions(incident);
        
        // Emit security event
        this.eventEmitter.dispatchEvent(new CustomEvent('threat-detected', {
            detail: incident
        }));

        return incident;
    }

    public async respondToIncident(incidentId: string, actionId: string): Promise<{
        success: boolean;
        result?: any;
        error?: string;
    }> {
        const incident = this.incidents.get(incidentId);
        if (!incident) {
            return { success: false, error: 'Incident not found' };
        }

        const action = incident.responseActions.find(a => a.actionId === actionId);
        if (!action) {
            return { success: false, error: 'Response action not found' };
        }

        try {
            action.status = 'executing';
            action.executedAt = new Date();

            // Simulate script execution
            const result = await this.simulateScriptExecution(action.script);
            
            action.status = 'completed';
            action.result = result;

            // Update incident timeline
            incident.timeline.push({
                timestamp: new Date(),
                event: `Response Action: ${action.type}`,
                severity: 'medium',
                details: action.description,
                actor: 'Security Engine'
            });

            return { success: true, result };
        } catch (error) {
            action.status = 'failed';
            return { success: false, error: error.message };
        }
    }

    private startSecurityMonitoring() {
        this.isMonitoring = true;
        
        // Simulate continuous monitoring
        setInterval(() => {
            this.performContinuousMonitoring();
        }, 60000); // Check every minute
    }

    private async performContinuousMonitoring() {
        // Simulate threat detection
        const randomEvents = [
            { type: 'login_anomaly', severity: 'medium', source: 'Azure AD' },
            { type: 'file_access', severity: 'low', source: 'SharePoint' },
            { type: 'suspicious_email', severity: 'high', source: 'Exchange' },
            { type: 'privilege_escalation', severity: 'critical', source: 'Azure AD' }
        ];

        // Random chance of detecting a threat
        if (Math.random() < 0.1) { // 10% chance per minute
            const event = randomEvents[Math.floor(Math.random() * randomEvents.length)];
            this.detectThreat({
                description: `${event.type} detected in ${event.source}`,
                source: event.source,
                severity: event.severity,
                tags: [event.type, event.source.toLowerCase()]
            });
        }
    }

    private classifyThreat(threatData: any): SecurityIncident['type'] {
        const description = threatData.description?.toLowerCase() || '';
        
        if (description.includes('brute force') || description.includes('login')) return 'brute_force';
        if (description.includes('exfiltration') || description.includes('download')) return 'data_exfiltration';
        if (description.includes('privilege') || description.includes('escalation')) return 'privilege_escalation';
        if (description.includes('malware') || description.includes('virus')) return 'malware';
        if (description.includes('phishing') || description.includes('suspicious email')) return 'phishing';
        
        return 'anomaly';
    }

    private calculateThreatSeverity(threatData: any): 'critical' | 'high' | 'medium' | 'low' {
        if (threatData.severity) return threatData.severity;
        
        const description = threatData.description?.toLowerCase() || '';
        
        if (description.includes('critical') || description.includes('privilege escalation')) return 'critical';
        if (description.includes('high') || description.includes('malware')) return 'high';
        if (description.includes('medium') || description.includes('suspicious')) return 'medium';
        
        return 'low';
    }

    private generateResponseActions(incident: SecurityIncident) {
        const actions: ResponseAction[] = [];

        switch (incident.type) {
            case 'brute_force':
                actions.push({
                    actionId: `action_${Date.now()}_1`,
                    type: 'block_user',
                    description: 'Block the attacking user account',
                    script: 'Set-AzureADUser -ObjectId $userId -AccountEnabled $false',
                    status: 'pending'
                });
                break;

            case 'privilege_escalation':
                actions.push({
                    actionId: `action_${Date.now()}_2`,
                    type: 'reset_password',
                    description: 'Force password reset for affected user',
                    script: 'Set-AzureADUserPassword -ObjectId $userId -ForceChangePasswordNextLogin $true',
                    status: 'pending'
                });
                break;

            case 'phishing':
                actions.push({
                    actionId: `action_${Date.now()}_3`,
                    type: 'quarantine_email',
                    description: 'Quarantine suspicious emails',
                    script: 'New-ComplianceSearchAction -SearchName "PhishingSearch" -Purge -PurgeType SoftDelete',
                    status: 'pending'
                });
                break;

            case 'malware':
                actions.push({
                    actionId: `action_${Date.now()}_4`,
                    type: 'isolate_device',
                    description: 'Isolate infected device',
                    script: 'Invoke-MgDeviceManagementManagedDeviceShutDown -ManagedDeviceId $deviceId',
                    status: 'pending'
                });
                break;
        }

        // Always add notification action
        actions.push({
            actionId: `action_${Date.now()}_notify`,
            type: 'notify_admin',
            description: 'Notify security administrators',
            script: 'Send-MailMessage -To "security@company.com" -Subject "Security Incident" -Body $incidentDetails',
            status: 'pending'
        });

        incident.responseActions = actions;
    }

    private async simulateScriptExecution(script: string): Promise<any> {
        // Simulate script execution delay
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        // Simulate success/failure
        if (Math.random() < 0.9) { // 90% success rate
            return {
                success: true,
                output: 'Script executed successfully',
                timestamp: new Date().toISOString()
            };
        } else {
            throw new Error('Script execution failed');
        }
    }

    private async simulateValidation(hardening: SecurityHardening): Promise<{
        compliant: boolean;
        details: any;
        score: number;
    }> {
        // Simulate validation logic
        await new Promise(resolve => setTimeout(resolve, 500));
        
        const compliant = Math.random() > 0.3; // 70% compliance rate
        const score = compliant ? Math.floor(80 + Math.random() * 20) : Math.floor(Math.random() * 50);
        
        return {
            compliant,
            details: {
                validationTime: new Date().toISOString(),
                hardeningName: hardening.name,
                service: hardening.service,
                complianceScore: score
            },
            score
        };
    }

    private findRelatedHardeningRule(policyId: string): string | undefined {
        // Map policies to hardening rules
        const policyToHardening: Record<string, string> = {
            'pol_mfa_enforcement': 'hard_aad_mfa',
            'pol_conditional_access': 'hard_block_legacy_auth',
            'pol_dlp_protection': 'hard_purview_dlp'
        };

        return policyToHardening[policyId];
    }

    private logSecurityAction(hardeningId: string, action: string, description: string) {
        console.log(`[Security] ${new Date().toISOString()} - ${action.toUpperCase()}: ${description} (${hardeningId})`);
        
        // In a real implementation, this would log to a security audit system
    }

    // Public API methods
    public getSecurityPolicies(): SecurityPolicy[] {
        return Array.from(this.policies.values());
    }

    public getHardeningRules(): SecurityHardening[] {
        return Array.from(this.hardeningRules.values());
    }

    public getSecurityIncidents(status?: SecurityIncident['status']): SecurityIncident[] {
        const incidents = Array.from(this.incidents.values());
        return status ? incidents.filter(i => i.status === status) : incidents;
    }

    public updateSecurityPolicy(policyId: string, updates: Partial<SecurityPolicy>): boolean {
        const policy = this.policies.get(policyId);
        if (!policy) return false;

        Object.assign(policy, updates, { lastUpdated: new Date() });
        this.policies.set(policyId, policy);
        return true;
    }

    public addEventListener(event: string, handler: EventListener) {
        this.eventEmitter.addEventListener(event, handler);
    }

    public removeEventListener(event: string, handler: EventListener) {
        this.eventEmitter.removeEventListener(event, handler);
    }
}

// Initialize security hardening engine
export const securityEngine = new SecurityHardeningEngine();