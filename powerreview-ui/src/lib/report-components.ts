/**
 * Report Components Library
 * Reusable components for generating comprehensive security reports
 */

export interface ReportTemplate {
    id: string;
    name: string;
    type: 'executive' | 'technical' | 'compliance' | 'security' | 'vulnerability';
    sections: ReportSection[];
    styling: ReportStyling;
    metadata: ReportMetadata;
}

export interface ReportSection {
    id: string;
    title: string;
    type: 'summary' | 'metrics' | 'findings' | 'recommendations' | 'charts' | 'tables' | 'text';
    content: any;
    order: number;
    includeInTOC: boolean;
    pageBreakBefore?: boolean;
    conditions?: SectionCondition[];
}

export interface ReportStyling {
    theme: 'professional' | 'executive' | 'technical' | 'compliance';
    colors: {
        primary: string;
        secondary: string;
        accent: string;
        success: string;
        warning: string;
        error: string;
    };
    fonts: {
        heading: string;
        body: string;
        code: string;
    };
    layout: {
        pageSize: 'A4' | 'Letter' | 'Legal';
        margins: { top: number; right: number; bottom: number; left: number; };
        headerHeight: number;
        footerHeight: number;
    };
}

export interface ReportMetadata {
    title: string;
    subtitle?: string;
    author: string;
    organization: string;
    version: string;
    generatedDate: Date;
    confidentialityLevel: 'Public' | 'Internal' | 'Confidential' | 'Restricted';
    tags: string[];
    description: string;
}

export interface SectionCondition {
    type: 'hasFindings' | 'riskLevel' | 'complianceScore' | 'custom';
    operator: 'gt' | 'lt' | 'eq' | 'ne' | 'contains';
    value: any;
}

export interface ChartConfig {
    type: 'bar' | 'line' | 'pie' | 'doughnut' | 'radar' | 'scatter' | 'gauge';
    title: string;
    data: ChartData;
    options: ChartOptions;
    responsive: boolean;
    height?: number;
    width?: number;
}

export interface ChartData {
    labels: string[];
    datasets: ChartDataset[];
}

export interface ChartDataset {
    label: string;
    data: number[];
    backgroundColor?: string | string[];
    borderColor?: string | string[];
    borderWidth?: number;
    fill?: boolean;
}

export interface ChartOptions {
    plugins?: {
        legend?: { display: boolean; position: string; };
        title?: { display: boolean; text: string; };
        tooltip?: any;
    };
    scales?: any;
    responsive?: boolean;
    maintainAspectRatio?: boolean;
}

export interface SecurityFinding {
    id: string;
    title: string;
    description: string;
    severity: 'Critical' | 'High' | 'Medium' | 'Low' | 'Informational';
    category: string;
    service: string;
    status: 'Open' | 'In Progress' | 'Resolved' | 'Accepted Risk' | 'False Positive';
    risk: {
        likelihood: number; // 1-5
        impact: number; // 1-5
        overall: number; // 1-25
    };
    remediation: {
        effort: 'Low' | 'Medium' | 'High';
        cost: 'Low' | 'Medium' | 'High';
        timeframe: string;
        steps: string[];
        powershellScript?: string;
    };
    compliance: string[];
    evidence: Evidence[];
    firstDetected: Date;
    lastSeen: Date;
    occurrences: number;
}

export interface Evidence {
    type: 'screenshot' | 'log' | 'config' | 'script_output' | 'api_response';
    title: string;
    description: string;
    content: string;
    timestamp: Date;
    source: string;
}

export interface RecommendationTier {
    tier: 'Gold' | 'Silver' | 'Bronze';
    title: string;
    description: string;
    recommendations: Recommendation[];
    estimatedCost: number;
    estimatedTimeframe: string;
    businessImpact: string;
    technicalComplexity: 'Low' | 'Medium' | 'High';
}

export interface Recommendation {
    id: string;
    title: string;
    description: string;
    priority: number;
    category: string;
    implementation: {
        steps: string[];
        powershellScripts?: string[];
        configurationChanges?: string[];
        thirdPartyTools?: string[];
    };
    benefits: string[];
    risks: string[];
    dependencies: string[];
    validation: string[];
    cost: {
        licensing: number;
        implementation: number;
        ongoing: number;
    };
    timeframe: {
        planning: string;
        implementation: string;
        testing: string;
    };
}

export interface ComplianceFramework {
    name: string;
    version: string;
    description: string;
    requirements: ComplianceRequirement[];
    overallScore: number;
    status: 'Compliant' | 'Partially Compliant' | 'Non-Compliant' | 'Not Assessed';
}

export interface ComplianceRequirement {
    id: string;
    title: string;
    description: string;
    category: string;
    mandatory: boolean;
    status: 'Compliant' | 'Partially Compliant' | 'Non-Compliant' | 'Not Assessed';
    score: number;
    evidence: Evidence[];
    gaps: string[];
    remediationSteps: string[];
}

export class ReportGenerator {
    private templates: Map<string, ReportTemplate> = new Map();
    
    constructor() {
        this.initializeDefaultTemplates();
    }

    private initializeDefaultTemplates() {
        // Executive Summary Template
        const executiveTemplate: ReportTemplate = {
            id: 'executive-summary',
            name: 'Executive Summary Report',
            type: 'executive',
            sections: [
                {
                    id: 'cover',
                    title: 'Executive Summary',
                    type: 'summary',
                    content: {},
                    order: 1,
                    includeInTOC: false
                },
                {
                    id: 'dashboard',
                    title: 'Security Dashboard',
                    type: 'metrics',
                    content: {},
                    order: 2,
                    includeInTOC: true
                },
                {
                    id: 'risk-assessment',
                    title: 'Risk Assessment Overview',
                    type: 'charts',
                    content: {},
                    order: 3,
                    includeInTOC: true
                },
                {
                    id: 'key-findings',
                    title: 'Key Security Findings',
                    type: 'findings',
                    content: {},
                    order: 4,
                    includeInTOC: true
                },
                {
                    id: 'recommendations',
                    title: 'Strategic Recommendations',
                    type: 'recommendations',
                    content: {},
                    order: 5,
                    includeInTOC: true
                },
                {
                    id: 'compliance',
                    title: 'Compliance Status',
                    type: 'tables',
                    content: {},
                    order: 6,
                    includeInTOC: true
                }
            ],
            styling: this.getExecutiveStyling(),
            metadata: {
                title: 'Executive Security Assessment Report',
                author: 'PowerReview Security Team',
                organization: '',
                version: '1.0',
                generatedDate: new Date(),
                confidentialityLevel: 'Confidential',
                tags: ['security', 'executive', 'assessment'],
                description: 'High-level security assessment report for executive stakeholders'
            }
        };

        // Technical Analysis Template
        const technicalTemplate: ReportTemplate = {
            id: 'technical-analysis',
            name: 'Technical Security Analysis',
            type: 'technical',
            sections: [
                {
                    id: 'methodology',
                    title: 'Assessment Methodology',
                    type: 'text',
                    content: {},
                    order: 1,
                    includeInTOC: true
                },
                {
                    id: 'infrastructure',
                    title: 'Infrastructure Analysis',
                    type: 'tables',
                    content: {},
                    order: 2,
                    includeInTOC: true
                },
                {
                    id: 'detailed-findings',
                    title: 'Detailed Security Findings',
                    type: 'findings',
                    content: {},
                    order: 3,
                    includeInTOC: true
                },
                {
                    id: 'technical-recommendations',
                    title: 'Technical Recommendations',
                    type: 'recommendations',
                    content: {},
                    order: 4,
                    includeInTOC: true
                },
                {
                    id: 'scripts',
                    title: 'PowerShell Remediation Scripts',
                    type: 'text',
                    content: {},
                    order: 5,
                    includeInTOC: true
                }
            ],
            styling: this.getTechnicalStyling(),
            metadata: {
                title: 'Technical Security Analysis Report',
                author: 'PowerReview Technical Team',
                organization: '',
                version: '1.0',
                generatedDate: new Date(),
                confidentialityLevel: 'Internal',
                tags: ['security', 'technical', 'analysis'],
                description: 'Detailed technical security analysis with remediation guidance'
            }
        };

        this.templates.set(executiveTemplate.id, executiveTemplate);
        this.templates.set(technicalTemplate.id, technicalTemplate);
    }

    private getExecutiveStyling(): ReportStyling {
        return {
            theme: 'executive',
            colors: {
                primary: '#1e293b',
                secondary: '#64748b',
                accent: '#6366f1',
                success: '#10b981',
                warning: '#f59e0b',
                error: '#dc2626'
            },
            fonts: {
                heading: 'Inter, system-ui, sans-serif',
                body: 'Inter, system-ui, sans-serif',
                code: 'JetBrains Mono, Consolas, monospace'
            },
            layout: {
                pageSize: 'A4',
                margins: { top: 72, right: 72, bottom: 72, left: 72 },
                headerHeight: 60,
                footerHeight: 40
            }
        };
    }

    private getTechnicalStyling(): ReportStyling {
        return {
            theme: 'technical',
            colors: {
                primary: '#0f172a',
                secondary: '#475569',
                accent: '#3b82f6',
                success: '#059669',
                warning: '#d97706',
                error: '#b91c1c'
            },
            fonts: {
                heading: 'Inter, system-ui, sans-serif',
                body: 'Inter, system-ui, sans-serif',
                code: 'JetBrains Mono, Consolas, monospace'
            },
            layout: {
                pageSize: 'A4',
                margins: { top: 54, right: 54, bottom: 54, left: 54 },
                headerHeight: 50,
                footerHeight: 30
            }
        };
    }

    public generateExecutiveSummary(data: any): string {
        const template = this.templates.get('executive-summary');
        if (!template) throw new Error('Executive template not found');

        return this.buildHTMLReport(template, data);
    }

    public generateTechnicalReport(data: any): string {
        const template = this.templates.get('technical-analysis');
        if (!template) throw new Error('Technical template not found');

        return this.buildHTMLReport(template, data);
    }

    private buildHTMLReport(template: ReportTemplate, data: any): string {
        const styles = this.generateCSS(template.styling);
        const header = this.generateHeader(template.metadata);
        const toc = this.generateTableOfContents(template.sections);
        const content = this.generateContent(template.sections, data);
        const footer = this.generateFooter(template.metadata);

        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${template.metadata.title}</title>
    <style>${styles}</style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    ${header}
    ${toc}
    ${content}
    ${footer}
    <script>
        // Initialize charts after page load
        document.addEventListener('DOMContentLoaded', function() {
            initializeCharts();
        });
    </script>
</body>
</html>`;
    }

    private generateCSS(styling: ReportStyling): string {
        return `
            @page {
                size: ${styling.layout.pageSize};
                margin: ${styling.layout.margins.top}px ${styling.layout.margins.right}px ${styling.layout.margins.bottom}px ${styling.layout.margins.left}px;
            }

            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: ${styling.fonts.body};
                line-height: 1.6;
                color: ${styling.colors.primary};
                background: white;
            }

            .page-break {
                page-break-before: always;
            }

            .header {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                height: ${styling.layout.headerHeight}px;
                background: ${styling.colors.primary};
                color: white;
                padding: 1rem;
                z-index: 1000;
            }

            .footer {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                height: ${styling.layout.footerHeight}px;
                background: ${styling.colors.secondary};
                color: white;
                padding: 0.5rem 1rem;
                font-size: 0.875rem;
                z-index: 1000;
            }

            .content {
                margin-top: ${styling.layout.headerHeight + 20}px;
                margin-bottom: ${styling.layout.footerHeight + 20}px;
            }

            h1, h2, h3, h4, h5, h6 {
                font-family: ${styling.fonts.heading};
                font-weight: 600;
                margin-bottom: 1rem;
                color: ${styling.colors.primary};
            }

            h1 { font-size: 2.5rem; }
            h2 { font-size: 2rem; border-bottom: 2px solid ${styling.colors.accent}; padding-bottom: 0.5rem; }
            h3 { font-size: 1.5rem; }
            h4 { font-size: 1.25rem; }

            p {
                margin-bottom: 1rem;
            }

            .metric-card {
                background: #f8fafc;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                padding: 1.5rem;
                text-align: center;
                margin-bottom: 1rem;
            }

            .metric-value {
                font-size: 2rem;
                font-weight: 700;
                color: ${styling.colors.accent};
                margin-bottom: 0.5rem;
            }

            .metric-label {
                font-size: 0.875rem;
                color: ${styling.colors.secondary};
            }

            .finding {
                background: white;
                border: 1px solid #e2e8f0;
                border-left: 4px solid;
                border-radius: 8px;
                padding: 1.5rem;
                margin-bottom: 1rem;
            }

            .finding.critical { border-left-color: ${styling.colors.error}; }
            .finding.high { border-left-color: #f59e0b; }
            .finding.medium { border-left-color: ${styling.colors.warning}; }
            .finding.low { border-left-color: ${styling.colors.success}; }

            .finding-title {
                font-size: 1.125rem;
                font-weight: 600;
                margin-bottom: 0.5rem;
            }

            .finding-severity {
                display: inline-block;
                padding: 0.25rem 0.75rem;
                border-radius: 9999px;
                font-size: 0.75rem;
                font-weight: 600;
                margin-bottom: 1rem;
            }

            .severity-critical {
                background: #fee2e2;
                color: ${styling.colors.error};
            }

            .severity-high {
                background: #fef3c7;
                color: #f59e0b;
            }

            .severity-medium {
                background: #fef9c3;
                color: ${styling.colors.warning};
            }

            .severity-low {
                background: #dcfce7;
                color: ${styling.colors.success};
            }

            .recommendation {
                background: #f0fdf4;
                border: 1px solid #bbf7d0;
                border-radius: 8px;
                padding: 1.5rem;
                margin-bottom: 1rem;
            }

            .recommendation-tier {
                font-size: 1.125rem;
                font-weight: 600;
                margin-bottom: 1rem;
            }

            .tier-gold { color: #d97706; }
            .tier-silver { color: #6b7280; }
            .tier-bronze { color: #92400e; }

            .chart-container {
                margin: 2rem 0;
                text-align: center;
            }

            .chart-container canvas {
                max-height: 400px;
            }

            code, pre {
                font-family: ${styling.fonts.code};
                background: #1e293b;
                color: #e2e8f0;
                padding: 0.5rem;
                border-radius: 4px;
                font-size: 0.875rem;
            }

            pre {
                padding: 1rem;
                margin: 1rem 0;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                margin: 1rem 0;
            }

            th, td {
                padding: 0.75rem;
                text-align: left;
                border-bottom: 1px solid #e2e8f0;
            }

            th {
                background: ${styling.colors.primary};
                color: white;
                font-weight: 600;
            }

            tr:hover {
                background: #f8fafc;
            }

            .toc {
                margin: 2rem 0;
                padding: 1.5rem;
                background: #f8fafc;
                border-radius: 8px;
            }

            .toc ul {
                list-style: none;
            }

            .toc li {
                margin: 0.5rem 0;
            }

            .toc a {
                color: ${styling.colors.accent};
                text-decoration: none;
            }

            .toc a:hover {
                text-decoration: underline;
            }

            @media print {
                .header, .footer {
                    position: fixed;
                }
                
                .page-break {
                    page-break-before: always;
                }
            }
        `;
    }

    private generateHeader(metadata: ReportMetadata): string {
        return `
        <div class="header">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h1 style="margin: 0; font-size: 1.5rem; color: white;">${metadata.title}</h1>
                    <p style="margin: 0; opacity: 0.8;">${metadata.organization}</p>
                </div>
                <div style="text-align: right;">
                    <p style="margin: 0; font-size: 0.875rem;">${metadata.confidentialityLevel}</p>
                    <p style="margin: 0; font-size: 0.875rem;">${metadata.generatedDate.toLocaleDateString()}</p>
                </div>
            </div>
        </div>`;
    }

    private generateTableOfContents(sections: ReportSection[]): string {
        const tocItems = sections
            .filter(section => section.includeInTOC)
            .map(section => `<li><a href="#${section.id}">${section.title}</a></li>`)
            .join('');

        return `
        <div class="content">
            <div class="toc">
                <h2>Table of Contents</h2>
                <ul>
                    ${tocItems}
                </ul>
            </div>
        </div>`;
    }

    private generateContent(sections: ReportSection[], data: any): string {
        return sections
            .sort((a, b) => a.order - b.order)
            .map(section => this.generateSection(section, data))
            .join('');
    }

    private generateSection(section: ReportSection, data: any): string {
        const pageBreak = section.pageBreakBefore ? '<div class="page-break"></div>' : '';
        
        let content = '';
        switch (section.type) {
            case 'summary':
                content = this.generateSummarySection(data);
                break;
            case 'metrics':
                content = this.generateMetricsSection(data);
                break;
            case 'charts':
                content = this.generateChartsSection(data);
                break;
            case 'findings':
                content = this.generateFindingsSection(data);
                break;
            case 'recommendations':
                content = this.generateRecommendationsSection(data);
                break;
            case 'tables':
                content = this.generateTablesSection(data);
                break;
            default:
                content = '<p>Section content not implemented.</p>';
        }

        return `
        ${pageBreak}
        <div class="content">
            <section id="${section.id}">
                <h2>${section.title}</h2>
                ${content}
            </section>
        </div>`;
    }

    private generateSummarySection(data: any): string {
        return `
        <div class="summary">
            <p><strong>Assessment Overview:</strong> This report presents a comprehensive security assessment of your Microsoft 365 environment, conducted on ${new Date().toLocaleDateString()}.</p>
            
            <p><strong>Scope:</strong> The assessment covered all major Microsoft 365 services including Azure Active Directory, Exchange Online, SharePoint Online, Microsoft Teams, and Microsoft Defender for Office 365.</p>
            
            <p><strong>Key Highlights:</strong></p>
            <ul>
                <li>Overall security posture assessment</li>
                <li>Risk-based prioritization of findings</li>
                <li>Compliance framework alignment</li>
                <li>Strategic recommendations with ROI analysis</li>
                <li>Actionable remediation guidance</li>
            </ul>
        </div>`;
    }

    private generateMetricsSection(data: any): string {
        const metrics = data?.metrics || {
            riskScore: 78,
            criticalFindings: 23,
            highFindings: 45,
            mediumFindings: 67,
            lowFindings: 89,
            complianceScore: 72
        };

        return `
        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin: 2rem 0;">
            <div class="metric-card">
                <div class="metric-value" style="color: #dc2626;">${metrics.riskScore}%</div>
                <div class="metric-label">Overall Risk Score</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" style="color: #f59e0b;">${metrics.criticalFindings + metrics.highFindings}</div>
                <div class="metric-label">Critical & High Findings</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" style="color: #10b981;">${metrics.complianceScore}%</div>
                <div class="metric-label">Compliance Score</div>
            </div>
        </div>
        
        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin: 2rem 0;">
            <div class="metric-card">
                <div class="metric-value" style="color: #dc2626;">${metrics.criticalFindings}</div>
                <div class="metric-label">Critical</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" style="color: #f59e0b;">${metrics.highFindings}</div>
                <div class="metric-label">High</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" style="color: #facc15;">${metrics.mediumFindings}</div>
                <div class="metric-label">Medium</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" style="color: #10b981;">${metrics.lowFindings}</div>
                <div class="metric-label">Low</div>
            </div>
        </div>`;
    }

    private generateChartsSection(data: any): string {
        return `
        <div class="chart-container">
            <h3>Risk Distribution by Category</h3>
            <canvas id="riskChart" width="400" height="200"></canvas>
        </div>
        
        <div class="chart-container">
            <h3>Compliance Framework Status</h3>
            <canvas id="complianceChart" width="400" height="200"></canvas>
        </div>
        
        <script>
            function initializeCharts() {
                // Risk Distribution Chart
                const riskCtx = document.getElementById('riskChart');
                if (riskCtx) {
                    new Chart(riskCtx, {
                        type: 'doughnut',
                        data: {
                            labels: ['Critical', 'High', 'Medium', 'Low'],
                            datasets: [{
                                data: [23, 45, 67, 89],
                                backgroundColor: ['#dc2626', '#f59e0b', '#facc15', '#10b981']
                            }]
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                legend: { position: 'bottom' }
                            }
                        }
                    });
                }
                
                // Compliance Chart
                const complianceCtx = document.getElementById('complianceChart');
                if (complianceCtx) {
                    new Chart(complianceCtx, {
                        type: 'bar',
                        data: {
                            labels: ['GDPR', 'HIPAA', 'SOX', 'ISO 27001', 'NIST'],
                            datasets: [{
                                label: 'Compliance Score (%)',
                                data: [85, 72, 78, 80, 75],
                                backgroundColor: '#6366f1'
                            }]
                        },
                        options: {
                            responsive: true,
                            scales: {
                                y: { beginAtZero: true, max: 100 }
                            }
                        }
                    });
                }
            }
        </script>`;
    }

    private generateFindingsSection(data: any): string {
        const findings = data?.findings || [
            {
                title: 'Multi-Factor Authentication Not Enforced',
                severity: 'critical',
                description: 'Administrative accounts do not have MFA enforcement enabled, creating significant security risk.',
                category: 'Identity & Access',
                service: 'Azure AD'
            },
            {
                title: 'Legacy Authentication Enabled',
                severity: 'high',
                description: 'Legacy authentication protocols are still enabled, bypassing modern security controls.',
                category: 'Authentication',
                service: 'Exchange Online'
            },
            {
                title: 'External Sharing Unrestricted',
                severity: 'medium',
                description: 'SharePoint sites allow unrestricted external sharing without proper controls.',
                category: 'Data Protection',
                service: 'SharePoint Online'
            }
        ];

        return findings.map(finding => `
            <div class="finding ${finding.severity}">
                <div class="finding-title">${finding.title}</div>
                <span class="finding-severity severity-${finding.severity}">${finding.severity.toUpperCase()}</span>
                <p><strong>Service:</strong> ${finding.service}</p>
                <p><strong>Category:</strong> ${finding.category}</p>
                <p><strong>Description:</strong> ${finding.description}</p>
                <p><strong>Risk Impact:</strong> This finding poses a ${finding.severity} risk to your organization's security posture and should be addressed according to the recommended timeline.</p>
            </div>
        `).join('');
    }

    private generateRecommendationsSection(data: any): string {
        return `
        <div class="recommendation">
            <div class="recommendation-tier tier-gold">🥇 Gold Tier Recommendations (Immediate - 30 days)</div>
            <ul>
                <li>Implement Zero Trust architecture across all services</li>
                <li>Enable multi-factor authentication for all users</li>
                <li>Deploy Microsoft Defender for Office 365 Plan 2</li>
                <li>Configure comprehensive conditional access policies</li>
            </ul>
            <p><strong>Estimated Investment:</strong> $50,000 - $100,000</p>
            <p><strong>Expected ROI:</strong> 300% within 12 months through reduced security incidents</p>
        </div>
        
        <div class="recommendation">
            <div class="recommendation-tier tier-silver">🥈 Silver Tier Recommendations (60-90 days)</div>
            <ul>
                <li>Implement advanced threat protection policies</li>
                <li>Enable cloud app security monitoring</li>
                <li>Deploy privileged identity management</li>
                <li>Configure data loss prevention policies</li>
            </ul>
            <p><strong>Estimated Investment:</strong> $25,000 - $50,000</p>
            <p><strong>Expected ROI:</strong> 200% within 18 months</p>
        </div>
        
        <div class="recommendation">
            <div class="recommendation-tier tier-bronze">🥉 Bronze Tier Recommendations (90+ days)</div>
            <ul>
                <li>Enhance security awareness training</li>
                <li>Implement advanced compliance monitoring</li>
                <li>Deploy automated incident response</li>
                <li>Establish security metrics dashboard</li>
            </ul>
            <p><strong>Estimated Investment:</strong> $10,000 - $25,000</p>
            <p><strong>Expected ROI:</strong> 150% within 24 months</p>
        </div>`;
    }

    private generateTablesSection(data: any): string {
        return `
        <h3>Compliance Framework Status</h3>
        <table>
            <thead>
                <tr>
                    <th>Framework</th>
                    <th>Version</th>
                    <th>Status</th>
                    <th>Score</th>
                    <th>Key Gaps</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>GDPR</td>
                    <td>2018</td>
                    <td style="color: #f59e0b;">Partially Compliant</td>
                    <td>85%</td>
                    <td>Data subject rights automation</td>
                </tr>
                <tr>
                    <td>ISO 27001</td>
                    <td>2013</td>
                    <td style="color: #10b981;">Compliant</td>
                    <td>92%</td>
                    <td>Minor documentation updates</td>
                </tr>
                <tr>
                    <td>NIST CSF</td>
                    <td>1.1</td>
                    <td style="color: #f59e0b;">Partially Compliant</td>
                    <td>78%</td>
                    <td>Incident response procedures</td>
                </tr>
                <tr>
                    <td>SOX</td>
                    <td>2002</td>
                    <td style="color: #10b981;">Compliant</td>
                    <td>89%</td>
                    <td>Access review frequency</td>
                </tr>
            </tbody>
        </table>
        
        <h3>Security Controls Implementation Status</h3>
        <table>
            <thead>
                <tr>
                    <th>Control Category</th>
                    <th>Implemented</th>
                    <th>Partially Implemented</th>
                    <th>Not Implemented</th>
                    <th>Overall Status</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Identity & Access Management</td>
                    <td>12</td>
                    <td>8</td>
                    <td>3</td>
                    <td style="color: #f59e0b;">Needs Improvement</td>
                </tr>
                <tr>
                    <td>Data Protection</td>
                    <td>15</td>
                    <td>5</td>
                    <td>2</td>
                    <td style="color: #10b981;">Good</td>
                </tr>
                <tr>
                    <td>Threat Protection</td>
                    <td>18</td>
                    <td>4</td>
                    <td>1</td>
                    <td style="color: #10b981;">Excellent</td>
                </tr>
                <tr>
                    <td>Compliance & Governance</td>
                    <td>10</td>
                    <td>12</td>
                    <td>6</td>
                    <td style="color: #dc2626;">Requires Attention</td>
                </tr>
            </tbody>
        </table>`;
    }

    private generateFooter(metadata: ReportMetadata): string {
        return `
        <div class="footer">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <span>${metadata.title} v${metadata.version}</span>
                </div>
                <div>
                    <span>Generated by PowerReview | Page <span class="page-number"></span></span>
                </div>
            </div>
        </div>`;
    }

    public exportToPDF(htmlContent: string, filename: string): Promise<Blob> {
        // This would integrate with a PDF generation library
        // For now, return a mock implementation
        return new Promise((resolve) => {
            const blob = new Blob([htmlContent], { type: 'text/html' });
            resolve(blob);
        });
    }

    public exportToExcel(data: any, filename: string): Promise<Blob> {
        // This would integrate with an Excel generation library
        // For now, return a mock implementation
        const csvContent = this.generateCSV(data);
        const blob = new Blob([csvContent], { type: 'text/csv' });
        return Promise.resolve(blob);
    }

    private generateCSV(data: any): string {
        // Mock CSV generation
        return `Finding,Severity,Category,Service,Status
Multi-Factor Authentication Not Enforced,Critical,Identity & Access,Azure AD,Open
Legacy Authentication Enabled,High,Authentication,Exchange Online,Open
External Sharing Unrestricted,Medium,Data Protection,SharePoint Online,Open`;
    }

    public getAvailableTemplates(): ReportTemplate[] {
        return Array.from(this.templates.values());
    }

    public getTemplate(templateId: string): ReportTemplate | undefined {
        return this.templates.get(templateId);
    }
}

// Export a singleton instance
export const reportGenerator = new ReportGenerator();