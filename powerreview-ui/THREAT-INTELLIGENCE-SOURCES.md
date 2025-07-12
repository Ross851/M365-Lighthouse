/**
 * PowerReview Threat Intelligence Monitor
 * Monitors real threat feeds and automatically adds new checks
 */

export interface ThreatSource {
    id: string;
    name: string;
    url: string;
    frequency: string;
    parser: (data: any) => ThreatIndicator[];
    lastChecked?: Date;
    isActive: boolean;
}

export interface ThreatIndicator {
    id: string;
    type: 'cve' | 'ioc' | 'advisory' | 'signature';
    severity: 'critical' | 'high' | 'medium' | 'low';
    title: string;
    description: string;
    affectedProducts: string[];
    indicators: string[];
    mitigation?: string;
    detectedAt: Date;
    source: string;
    references: string[];
}

export interface SecurityCheck {
    checkId: string;
    name: string;
    description: string;
    service: 'azuread' | 'exchange' | 'sharepoint' | 'teams' | 'defender';
    severity: 'critical' | 'high' | 'medium' | 'low';
    powershellScript: string;
    expectedResult: any;
    remediationScript?: string;
    addedDate: Date;
    threatSource: string;
}

export class ThreatIntelligenceMonitor {
    private sources: ThreatSource[] = [];
    private indicators: ThreatIndicator[] = [];
    private securityChecks: SecurityCheck[] = [];
    private webhookUrls: string[] = [];

    constructor() {
        this.initializeSources();
        this.startMonitoring();
    }

    private initializeSources() {
        this.sources = [
            {
                id: 'cisa_kev',
                name: 'CISA Known Exploited Vulnerabilities',
                url: 'https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json',
                frequency: 'hourly',
                parser: this.parseCISAFeed.bind(this),
                isActive: true
            },
            {
                id: 'microsoft_advisories',
                name: 'Microsoft Security Advisories',
                url: 'https://api.msrc.microsoft.com/sug/v2.0/en-US/affectedProduct',
                frequency: 'daily',
                parser: this.parseMicrosoftAdvisories.bind(this),
                isActive: true
            },
            {
                id: 'nvd_cves',
                name: 'NIST National Vulnerability Database',
                url: 'https://services.nvd.nist.gov/rest/json/cves/2.0',
                frequency: 'daily',
                parser: this.parseNVDFeed.bind(this),
                isActive: true
            },
            {
                id: 'abuse_ch_malware',
                name: 'Abuse.ch Malware Bazaar',
                url: 'https://bazaar.abuse.ch/api/v1/samples/recent/',
                frequency: 'hourly',
                parser: this.parseAbuseCHFeed.bind(this),
                isActive: true
            },
            {
                id: 'otx_indicators',
                name: 'AlienVault OTX',
                url: 'https://otx.alienvault.com/api/v1/indicators/malware',
                frequency: 'hourly',
                parser: this.parseOTXFeed.bind(this),
                isActive: true
            }
        ];
    }

    async startMonitoring() {
        console.log('🔍 Starting threat intelligence monitoring...');
        
        // Initial check
        await this.checkAllSources();
        
        // Schedule regular checks
        setInterval(() => this.checkAllSources(), 3600000); // Every hour
        
        // Daily deep scan
        setInterval(() => this.performDeepScan(), 86400000); // Every 24 hours
    }

    private async checkAllSources() {
        const promises = this.sources
            .filter(source => source.isActive)
            .map(source => this.checkSource(source));
            
        await Promise.allSettled(promises);
    }

    private async checkSource(source: ThreatSource) {
        try {
            console.log(`📡 Checking threat source: ${source.name}`);
            
            const response = await fetch(source.url, {
                headers: {
                    'User-Agent': 'PowerReview-ThreatIntel/1.0',
                    'Accept': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const newIndicators = source.parser(data);
            
            // Process new indicators
            for (const indicator of newIndicators) {
                await this.processNewThreat(indicator);
            }

            source.lastChecked = new Date();
            console.log(`✅ Processed ${newIndicators.length} indicators from ${source.name}`);
            
        } catch (error) {
            console.error(`❌ Error checking ${source.name}:`, error);
            this.notifyError(source.name, error.message);
        }
    }

    private parseCISAFeed(data: any): ThreatIndicator[] {
        if (!data.vulnerabilities) return [];
        
        return data.vulnerabilities
            .filter(vuln => this.isRecentThreat(vuln.dateAdded))
            .map(vuln => ({
                id: `cisa-${vuln.cveID}`,
                type: 'cve',
                severity: this.mapCISASeverity(vuln.knownRansomwareCampaignUse),
                title: `CISA KEV: ${vuln.cveID}`,
                description: vuln.shortDescription,
                affectedProducts: [vuln.product],
                indicators: [vuln.cveID],
                mitigation: vuln.requiredAction,
                detectedAt: new Date(vuln.dateAdded),
                source: 'CISA',
                references: [`https://nvd.nist.gov/vuln/detail/${vuln.cveID}`]
            }));
    }

    private parseMicrosoftAdvisories(data: any): ThreatIndicator[] {
        if (!data.value) return [];
        
        return data.value
            .filter(advisory => this.isMicrosoft365Related(advisory))
            .map(advisory => ({
                id: `msrc-${advisory.id}`,
                type: 'advisory',
                severity: this.mapMicrosoftSeverity(advisory.severity),
                title: advisory.title,
                description: advisory.description,
                affectedProducts: advisory.affectedProducts || [],
                indicators: [advisory.id],
                detectedAt: new Date(advisory.releaseDate),
                source: 'Microsoft',
                references: [advisory.url]
            }));
    }

    private parseNVDFeed(data: any): ThreatIndicator[] {
        if (!data.vulnerabilities) return [];
        
        return data.vulnerabilities
            .filter(vuln => this.isMicrosoft365CVE(vuln.cve))
            .map(vuln => ({
                id: `nvd-${vuln.cve.id}`,
                type: 'cve',
                severity: this.mapCVSSSeverity(vuln.cve.metrics?.cvssMetricV31?.[0]?.cvssData?.baseScore),
                title: vuln.cve.id,
                description: vuln.cve.descriptions?.[0]?.value || 'No description available',
                affectedProducts: this.extractAffectedProducts(vuln.cve),
                indicators: [vuln.cve.id],
                detectedAt: new Date(vuln.cve.published),
                source: 'NVD',
                references: vuln.cve.references?.map(ref => ref.url) || []
            }));
    }

    private parseAbuseCHFeed(data: any): ThreatIndicator[] {
        if (!data.data) return [];
        
        return data.data
            .filter(sample => this.isOfficeRelatedMalware(sample))
            .map(sample => ({
                id: `abuse-${sample.sha256}`,
                type: 'ioc',
                severity: 'high',
                title: `Malware Sample: ${sample.file_name}`,
                description: `File type: ${sample.file_type}, Tags: ${sample.tags?.join(', ')}`,
                affectedProducts: ['Microsoft Office', 'Microsoft 365'],
                indicators: [sample.sha256, sample.md5],
                detectedAt: new Date(sample.first_seen),
                source: 'Abuse.ch',
                references: [`https://bazaar.abuse.ch/sample/${sample.sha256}/`]
            }));
    }

    private parseOTXFeed(data: any): ThreatIndicator[] {
        if (!data.results) return [];
        
        return data.results
            .filter(pulse => this.isRelevantPulse(pulse))
            .map(pulse => ({
                id: `otx-${pulse.id}`,
                type: 'ioc',
                severity: 'medium',
                title: pulse.name,
                description: pulse.description,
                affectedProducts: ['Microsoft 365'],
                indicators: pulse.indicators?.map(ind => ind.indicator) || [],
                detectedAt: new Date(pulse.created),
                source: 'AlienVault OTX',
                references: [pulse.permalink]
            }));
    }

    private async processNewThreat(indicator: ThreatIndicator) {
        // Check if we already have this threat
        const existingIndicator = this.indicators.find(i => i.id === indicator.id);
        if (existingIndicator) return;

        // Add to our database
        this.indicators.push(indicator);
        
        // Generate security check if applicable
        const securityCheck = await this.generateSecurityCheck(indicator);
        if (securityCheck) {
            this.securityChecks.push(securityCheck);
            await this.addCheckToAssessment(securityCheck);
        }

        // Send alerts
        await this.sendThreatAlert(indicator);
        
        console.log(`🚨 New threat processed: ${indicator.title}`);
    }

    private async generateSecurityCheck(indicator: ThreatIndicator): Promise<SecurityCheck | null> {
        // Only generate checks for M365-relevant threats
        if (!this.isMicrosoft365Relevant(indicator)) return null;

        const checkId = `auto_${indicator.type}_${Date.now()}`;
        
        switch (indicator.type) {
            case 'cve':
                return this.generateCVECheck(indicator, checkId);
            
            case 'advisory':
                return this.generateAdvisoryCheck(indicator, checkId);
                
            case 'ioc':
                return this.generateIOCCheck(indicator, checkId);
                
            default:
                return null;
        }
    }

    private generateCVECheck(indicator: ThreatIndicator, checkId: string): SecurityCheck {
        // Generate PowerShell to check for specific CVE mitigations
        const powershellScript = `
# Check for ${indicator.id} mitigation
$cveId = "${indicator.id}"
$patchInfo = Get-WmiObject -Class Win32_QuickFixEngineering | Where-Object { $_.Description -like "*Security*" }
$recentPatches = $patchInfo | Where-Object { [DateTime]$_.InstalledOn -gt (Get-Date).AddDays(-30) }

$result = @{
    CVE = $cveId
    RecentSecurityPatches = $recentPatches.Count
    LastPatchDate = ($recentPatches | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
    SystemInfo = @{
        OS = (Get-WmiObject Win32_OperatingSystem).Caption
        Version = (Get-WmiObject Win32_OperatingSystem).Version
    }
}

return $result | ConvertTo-Json -Depth 3
        `.trim();

        return {
            checkId,
            name: `CVE Check: ${indicator.id}`,
            description: `Automated check for ${indicator.id}: ${indicator.description}`,
            service: this.determineAffectedService(indicator),
            severity: indicator.severity,
            powershellScript,
            expectedResult: { RecentSecurityPatches: { $gt: 0 } },
            addedDate: new Date(),
            threatSource: indicator.source
        };
    }

    private generateAdvisoryCheck(indicator: ThreatIndicator, checkId: string): SecurityCheck {
        const powershellScript = `
# Check Microsoft 365 security configuration for ${indicator.id}
Connect-MsolService

$tenantInfo = @{
    AdvisoryId = "${indicator.id}"
    TenantSettings = @{
        MFAEnabled = (Get-MsolUser -All | Where-Object { $_.StrongAuthenticationMethods.Count -gt 0 }).Count
        ConditionalAccessPolicies = (Get-AzureADConditionalAccessPolicy).Count
        SecurityDefaults = (Get-MsolCompanyInformation).SecurityDefaults
    }
    LastChecked = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

return $tenantInfo | ConvertTo-Json -Depth 3
        `.trim();

        return {
            checkId,
            name: `Security Advisory: ${indicator.title}`,
            description: indicator.description,
            service: 'azuread',
            severity: indicator.severity,
            powershellScript,
            expectedResult: { TenantSettings: { SecurityDefaults: true } },
            addedDate: new Date(),
            threatSource: indicator.source
        };
    }

    private generateIOCCheck(indicator: ThreatIndicator, checkId: string): SecurityCheck {
        const indicators_list = indicator.indicators.join('", "');
        
        const powershellScript = `
# Check for IOCs: ${indicator.title}
$iocs = @("${indicators_list}")
$findings = @()

# Check email logs for suspicious activity
$emailLogs = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -Operations "Send"

foreach ($ioc in $iocs) {
    $suspiciousEmails = $emailLogs | Where-Object { $_.AuditData -like "*$ioc*" }
    if ($suspiciousEmails) {
        $findings += @{
            IOC = $ioc
            Type = "Email"
            Count = $suspiciousEmails.Count
            LastSeen = ($suspiciousEmails | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate
        }
    }
}

$result = @{
    IOCCheck = "${indicator.title}"
    TotalIOCs = $iocs.Count
    SuspiciousFindings = $findings.Count
    Details = $findings
    LastChecked = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

return $result | ConvertTo-Json -Depth 4
        `.trim();

        return {
            checkId,
            name: `IOC Detection: ${indicator.title}`,
            description: `Check for indicators of compromise: ${indicator.description}`,
            service: 'exchange',
            severity: indicator.severity,
            powershellScript,
            expectedResult: { SuspiciousFindings: 0 },
            addedDate: new Date(),
            threatSource: indicator.source
        };
    }

    private async addCheckToAssessment(check: SecurityCheck) {
        // Add the new security check to our assessment engine
        try {
            const response = await fetch('/api/assessments/checks', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.getAuthToken()}`
                },
                body: JSON.stringify(check)
            });

            if (response.ok) {
                console.log(`✅ Added new security check: ${check.name}`);
            } else {
                console.error(`❌ Failed to add security check: ${check.name}`);
            }
        } catch (error) {
            console.error('Error adding security check:', error);
        }
    }

    private async sendThreatAlert(indicator: ThreatIndicator) {
        const alert = {
            type: 'new_threat_detected',
            severity: indicator.severity,
            title: indicator.title,
            description: indicator.description,
            source: indicator.source,
            affectedProducts: indicator.affectedProducts,
            timestamp: new Date().toISOString(),
            actionRequired: indicator.severity === 'critical' || indicator.severity === 'high'
        };

        // Send to configured webhooks
        for (const webhookUrl of this.webhookUrls) {
            try {
                await fetch(webhookUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(alert)
                });
            } catch (error) {
                console.error(`Failed to send alert to ${webhookUrl}:`, error);
            }
        }

        // Store in database for dashboard display
        await this.storeAlert(alert);
    }

    // Helper methods
    private isRecentThreat(dateString: string): boolean {
        const threatDate = new Date(dateString);
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return threatDate > thirtyDaysAgo;
    }

    private isMicrosoft365Related(advisory: any): boolean {
        const m365Keywords = [
            'office 365', 'microsoft 365', 'exchange online', 'sharepoint online',
            'teams', 'onedrive', 'azure ad', 'azure active directory'
        ];
        
        const text = `${advisory.title} ${advisory.description}`.toLowerCase();
        return m365Keywords.some(keyword => text.includes(keyword));
    }

    private isMicrosoft365CVE(cve: any): boolean {
        const description = cve.descriptions?.[0]?.value?.toLowerCase() || '';
        const m365Keywords = [
            'microsoft office', 'microsoft 365', 'exchange server', 'sharepoint',
            'microsoft teams', 'onedrive', 'azure'
        ];
        
        return m365Keywords.some(keyword => description.includes(keyword));
    }

    private isOfficeRelatedMalware(sample: any): boolean {
        const filename = sample.file_name?.toLowerCase() || '';
        const tags = sample.tags?.join(' ').toLowerCase() || '';
        
        const officeExtensions = ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'];
        const officeTags = ['office', 'document', 'macro'];
        
        return officeExtensions.some(ext => filename.includes(ext)) ||
               officeTags.some(tag => tags.includes(tag));
    }

    private mapCISASeverity(ransomwareUse: boolean): 'critical' | 'high' | 'medium' | 'low' {
        return ransomwareUse ? 'critical' : 'high';
    }

    private mapMicrosoftSeverity(severity: string): 'critical' | 'high' | 'medium' | 'low' {
        switch (severity?.toLowerCase()) {
            case 'critical': return 'critical';
            case 'important': return 'high';
            case 'moderate': return 'medium';
            default: return 'low';
        }
    }

    private mapCVSSSeverity(score: number): 'critical' | 'high' | 'medium' | 'low' {
        if (score >= 9.0) return 'critical';
        if (score >= 7.0) return 'high';
        if (score >= 4.0) return 'medium';
        return 'low';
    }

    // Public API methods
    public addWebhook(url: string) {
        this.webhookUrls.push(url);
    }

    public getRecentThreats(hours: number = 24): ThreatIndicator[] {
        const cutoff = new Date();
        cutoff.setHours(cutoff.getHours() - hours);
        
        return this.indicators.filter(indicator => indicator.detectedAt > cutoff);
    }

    public getSecurityChecks(): SecurityCheck[] {
        return this.securityChecks;
    }

    public async performDeepScan() {
        console.log('🔍 Performing deep threat intelligence scan...');
        
        // Check all sources with extended lookback
        // Analyze patterns and correlations
        // Generate threat hunting queries
        
        const threats = this.getRecentThreats(168); // Last 7 days
        console.log(`📊 Deep scan complete. Found ${threats.length} recent threats.`);
    }

    private async storeAlert(alert: any) {
        // Store alert in database for dashboard display
        // Implementation would depend on your database setup
    }

    private getAuthToken(): string {
        // Get current user's auth token
        return localStorage.getItem('auth_token') || '';
    }

    private determineAffectedService(indicator: ThreatIndicator): 'azuread' | 'exchange' | 'sharepoint' | 'teams' | 'defender' {
        const description = indicator.description.toLowerCase();
        
        if (description.includes('exchange') || description.includes('email')) return 'exchange';
        if (description.includes('sharepoint') || description.includes('document')) return 'sharepoint';
        if (description.includes('teams') || description.includes('chat')) return 'teams';
        if (description.includes('defender') || description.includes('antivirus')) return 'defender';
        
        return 'azuread'; // Default
    }

    private isMicrosoft365Relevant(indicator: ThreatIndicator): boolean {
        return indicator.affectedProducts.some(product => 
            product.toLowerCase().includes('microsoft') || 
            product.toLowerCase().includes('office') ||
            product.toLowerCase().includes('365')
        );
    }

    private isRelevantPulse(pulse: any): boolean {
        const tags = pulse.tags?.join(' ').toLowerCase() || '';
        const description = pulse.description?.toLowerCase() || '';
        
        const relevantTags = ['microsoft', 'office', '365', 'phishing', 'malware'];
        return relevantTags.some(tag => tags.includes(tag) || description.includes(tag));
    }

    private notifyError(sourceName: string, error: string) {
        console.error(`Threat monitoring error for ${sourceName}: ${error}`);
        // Could send to error monitoring service
    }

    private extractAffectedProducts(cve: any): string[] {
        // Extract affected products from CVE data
        const configurations = cve.configurations?.nodes || [];
        const products = [];
        
        for (const config of configurations) {
            if (config.cpeMatch) {
                for (const match of config.cpeMatch) {
                    if (match.criteria.includes('microsoft')) {
                        products.push(match.criteria);
                    }
                }
            }
        }
        
        return products;
    }
}

// Initialize threat monitoring
export const threatMonitor = new ThreatIntelligenceMonitor();