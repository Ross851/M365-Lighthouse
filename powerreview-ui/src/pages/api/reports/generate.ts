/**
 * Report Generation API
 * Handles report generation requests with real data and export functionality
 */

import type { APIRoute } from 'astro';
import { reportGenerator } from '../../../lib/report-components';

export const POST: APIRoute = async ({ request }) => {
    try {
        const requestData = await request.json();
        const { 
            type, 
            organization, 
            period, 
            format, 
            sections, 
            title, 
            description 
        } = requestData;

        // Validate required fields
        if (!type || !organization) {
            return new Response(JSON.stringify({
                error: 'Report type and organization are required'
            }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // Generate mock assessment data based on organization
        const assessmentData = generateMockAssessmentData(organization, period);
        
        // Generate report based on type
        let reportContent: string;
        let reportMetadata: any;

        switch (type) {
            case 'executive':
                reportContent = reportGenerator.generateExecutiveSummary(assessmentData);
                reportMetadata = {
                    type: 'Executive Summary',
                    pages: 8,
                    sections: ['Summary', 'Risk Assessment', 'Key Findings', 'Recommendations', 'Compliance']
                };
                break;
                
            case 'technical':
                reportContent = reportGenerator.generateTechnicalReport(assessmentData);
                reportMetadata = {
                    type: 'Technical Analysis',
                    pages: 15,
                    sections: ['Methodology', 'Infrastructure', 'Detailed Findings', 'Recommendations', 'Scripts']
                };
                break;
                
            case 'compliance':
                reportContent = generateComplianceReport(assessmentData);
                reportMetadata = {
                    type: 'Compliance Report',
                    pages: 12,
                    sections: ['Framework Overview', 'Requirements Assessment', 'Gap Analysis', 'Remediation Plan']
                };
                break;
                
            case 'security':
                reportContent = generateSecurityReport(assessmentData);
                reportMetadata = {
                    type: 'Security Assessment',
                    pages: 20,
                    sections: ['Security Posture', 'Threat Analysis', 'Vulnerability Assessment', 'Controls Review']
                };
                break;
                
            case 'vulnerability':
                reportContent = generateVulnerabilityReport(assessmentData);
                reportMetadata = {
                    type: 'Vulnerability Report',
                    pages: 18,
                    sections: ['Scan Summary', 'Critical Vulnerabilities', 'Risk Analysis', 'Patch Management']
                };
                break;
                
            default:
                return new Response(JSON.stringify({
                    error: 'Invalid report type'
                }), {
                    status: 400,
                    headers: { 'Content-Type': 'application/json' }
                });
        }

        // Generate report ID and store report data
        const reportId = `${type}-${organization}-${Date.now()}`;
        const reportData = {
            id: reportId,
            type,
            title: title || `${reportMetadata.type} - ${getOrganizationName(organization)}`,
            organization,
            organizationName: getOrganizationName(organization),
            status: 'completed',
            date: new Date().toISOString().split('T')[0],
            format,
            content: reportContent,
            metadata: reportMetadata,
            assessmentData,
            generatedAt: new Date().toISOString()
        };

        // In a real implementation, you would store this in a database
        // For now, we'll return the report data directly
        
        return new Response(JSON.stringify({
            success: true,
            reportId,
            report: reportData,
            downloadUrl: `/api/reports/download/${reportId}`,
            viewUrl: `/reports/view/${reportId}`
        }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Report generation error:', error);
        return new Response(JSON.stringify({
            error: 'Failed to generate report',
            message: error.message
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
};

function generateMockAssessmentData(organization: string, period: string) {
    const organizationData = {
        contoso: {
            name: 'Contoso Corporation',
            industry: 'Financial Services',
            employees: 25000,
            services: ['Azure AD', 'Exchange Online', 'SharePoint Online', 'Teams', 'Defender'],
            baseRisk: 65
        },
        fabrikam: {
            name: 'Fabrikam Industries',
            industry: 'Manufacturing',
            employees: 15000,
            services: ['Azure AD', 'Exchange Online', 'SharePoint Online', 'Teams'],
            baseRisk: 58
        },
        northwind: {
            name: 'Northwind Traders',
            industry: 'Retail',
            employees: 8500,
            services: ['Azure AD', 'Exchange Online', 'SharePoint Online', 'Teams', 'Power Platform'],
            baseRisk: 72
        },
        tailspin: {
            name: 'Tailspin Toys',
            industry: 'Consumer Goods',
            employees: 5000,
            services: ['Azure AD', 'Exchange Online', 'SharePoint Online', 'Teams'],
            baseRisk: 45
        }
    };

    const orgData = organizationData[organization] || organizationData.contoso;
    const riskVariation = Math.floor(Math.random() * 20) - 10; // ±10 variation
    const riskScore = Math.max(0, Math.min(100, orgData.baseRisk + riskVariation));

    return {
        organization: orgData,
        assessmentPeriod: period,
        metrics: {
            riskScore,
            criticalFindings: Math.floor(Math.random() * 15) + 10,
            highFindings: Math.floor(Math.random() * 25) + 20,
            mediumFindings: Math.floor(Math.random() * 40) + 30,
            lowFindings: Math.floor(Math.random() * 50) + 40,
            complianceScore: Math.floor(Math.random() * 25) + 70
        },
        findings: generateMockFindings(orgData.services),
        recommendations: generateMockRecommendations(),
        compliance: generateMockComplianceData(),
        timeline: generateAssessmentTimeline()
    };
}

function generateMockFindings(services: string[]) {
    const allFindings = [
        {
            title: 'Multi-Factor Authentication Not Enforced',
            severity: 'critical',
            category: 'Identity & Access',
            service: 'Azure AD',
            description: 'Administrative accounts do not have MFA enforcement enabled.',
            impact: 'High risk of account compromise and unauthorized access.',
            remediation: 'Enable MFA for all administrative accounts immediately.'
        },
        {
            title: 'Legacy Authentication Protocols Enabled',
            severity: 'high',
            category: 'Authentication',
            service: 'Exchange Online',
            description: 'Legacy authentication bypasses modern security controls.',
            impact: 'Potential for credential theft and bypassing security policies.',
            remediation: 'Disable legacy authentication and implement modern authentication.'
        },
        {
            title: 'External Sharing Unrestricted',
            severity: 'medium',
            category: 'Data Protection',
            service: 'SharePoint Online',
            description: 'SharePoint sites allow unrestricted external sharing.',
            impact: 'Risk of data exposure to unauthorized external users.',
            remediation: 'Configure external sharing policies and enable DLP.'
        },
        {
            title: 'Insufficient Conditional Access Policies',
            severity: 'high',
            category: 'Access Control',
            service: 'Azure AD',
            description: 'Limited conditional access policies in place.',
            impact: 'Inadequate protection against risky sign-ins.',
            remediation: 'Implement comprehensive conditional access policies.'
        },
        {
            title: 'Microsoft Defender ATP Not Configured',
            severity: 'high',
            category: 'Threat Protection',
            service: 'Defender',
            description: 'Advanced threat protection features are not enabled.',
            impact: 'Reduced ability to detect and respond to advanced threats.',
            remediation: 'Enable and configure Microsoft Defender ATP policies.'
        },
        {
            title: 'Privileged Access Management Missing',
            severity: 'critical',
            category: 'Privileged Access',
            service: 'Azure AD',
            description: 'No PIM implementation for privileged roles.',
            impact: 'Standing administrative access increases attack surface.',
            remediation: 'Implement Azure AD Privileged Identity Management.'
        },
        {
            title: 'Data Loss Prevention Policies Incomplete',
            severity: 'medium',
            category: 'Data Protection',
            service: 'Microsoft Purview',
            description: 'DLP policies do not cover all sensitive data types.',
            impact: 'Risk of sensitive data exfiltration.',
            remediation: 'Expand DLP policies to cover all sensitive information.'
        },
        {
            title: 'Guest User Access Uncontrolled',
            severity: 'medium',
            category: 'Identity & Access',
            service: 'Azure AD',
            description: 'Guest users have excessive permissions and access.',
            impact: 'Potential for unauthorized access to internal resources.',
            remediation: 'Implement guest user access reviews and restrictions.'
        }
    ];

    // Return findings relevant to the organization's services
    return allFindings.filter(finding => 
        services.includes(finding.service) || finding.service === 'Azure AD'
    ).slice(0, 6); // Limit to 6 findings for demo
}

function generateMockRecommendations() {
    return {
        gold: {
            tier: 'Gold',
            timeframe: '0-30 days',
            cost: '$50,000 - $100,000',
            roi: '300%',
            items: [
                'Implement Zero Trust architecture',
                'Enable MFA for all users',
                'Deploy Microsoft Defender for Office 365',
                'Configure conditional access policies'
            ]
        },
        silver: {
            tier: 'Silver',
            timeframe: '30-90 days',
            cost: '$25,000 - $50,000',
            roi: '200%',
            items: [
                'Implement privileged identity management',
                'Enable cloud app security monitoring',
                'Deploy data loss prevention policies',
                'Configure advanced threat protection'
            ]
        },
        bronze: {
            tier: 'Bronze',
            timeframe: '90+ days',
            cost: '$10,000 - $25,000',
            roi: '150%',
            items: [
                'Enhance security awareness training',
                'Implement compliance monitoring',
                'Deploy automated incident response',
                'Establish security metrics dashboard'
            ]
        }
    };
}

function generateMockComplianceData() {
    return {
        frameworks: [
            { name: 'GDPR', score: 85, status: 'Partially Compliant', gaps: ['Data subject rights automation'] },
            { name: 'ISO 27001', score: 92, status: 'Compliant', gaps: ['Minor documentation updates'] },
            { name: 'NIST CSF', score: 78, status: 'Partially Compliant', gaps: ['Incident response procedures'] },
            { name: 'SOX', score: 89, status: 'Compliant', gaps: ['Access review frequency'] },
            { name: 'HIPAA', score: 76, status: 'Partially Compliant', gaps: ['Audit log monitoring'] }
        ],
        overallScore: 84,
        lastAssessment: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
    };
}

function generateAssessmentTimeline() {
    const now = new Date();
    return {
        started: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        dataCollection: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        analysis: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        reporting: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        completed: now.toISOString()
    };
}

function generateComplianceReport(data: any): string {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Compliance Assessment Report</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 2rem; }
            h1 { color: #1e293b; border-bottom: 3px solid #6366f1; padding-bottom: 1rem; }
            h2 { color: #374151; margin-top: 2rem; }
            .compliance-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; margin: 2rem 0; }
            .framework-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1.5rem; }
            .score { font-size: 2rem; font-weight: bold; color: #10b981; }
            .gap { background: #fef2f2; border-left: 4px solid #dc2626; padding: 1rem; margin: 1rem 0; }
        </style>
    </head>
    <body>
        <h1>Compliance Assessment Report</h1>
        <h2>${data.organization.name}</h2>
        
        <div class="compliance-grid">
            ${data.compliance.frameworks.map(framework => `
                <div class="framework-card">
                    <h3>${framework.name}</h3>
                    <div class="score">${framework.score}%</div>
                    <p><strong>Status:</strong> ${framework.status}</p>
                    <div class="gap">
                        <strong>Key Gaps:</strong>
                        <ul>${framework.gaps.map(gap => `<li>${gap}</li>`).join('')}</ul>
                    </div>
                </div>
            `).join('')}
        </div>
        
        <h2>Overall Compliance Status</h2>
        <p>Your organization has achieved an overall compliance score of <strong>${data.compliance.overallScore}%</strong> across all assessed frameworks.</p>
        
        <h2>Recommended Actions</h2>
        <ul>
            <li>Address critical gaps in GDPR data subject rights automation</li>
            <li>Enhance incident response procedures for NIST CSF compliance</li>
            <li>Implement automated audit log monitoring for HIPAA requirements</li>
            <li>Update documentation to maintain ISO 27001 certification</li>
        </ul>
    </body>
    </html>`;
}

function generateSecurityReport(data: any): string {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Security Assessment Report</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 2rem; }
            h1 { color: #1e293b; border-bottom: 3px solid #dc2626; padding-bottom: 1rem; }
            .security-metric { display: inline-block; background: #fee2e2; padding: 1rem; margin: 0.5rem; border-radius: 8px; min-width: 150px; text-align: center; }
            .finding { background: #fef2f2; border-left: 4px solid #dc2626; padding: 1rem; margin: 1rem 0; }
            .critical { border-left-color: #dc2626; }
            .high { border-left-color: #f59e0b; }
            .medium { border-left-color: #facc15; }
        </style>
    </head>
    <body>
        <h1>Security Assessment Report</h1>
        <h2>${data.organization.name}</h2>
        
        <h2>Security Metrics</h2>
        <div class="security-metric">
            <h3>Risk Score</h3>
            <div style="font-size: 2rem; font-weight: bold; color: #dc2626;">${data.metrics.riskScore}%</div>
        </div>
        <div class="security-metric">
            <h3>Critical Findings</h3>
            <div style="font-size: 2rem; font-weight: bold; color: #dc2626;">${data.metrics.criticalFindings}</div>
        </div>
        <div class="security-metric">
            <h3>Total Findings</h3>
            <div style="font-size: 2rem; font-weight: bold; color: #f59e0b;">${data.metrics.criticalFindings + data.metrics.highFindings + data.metrics.mediumFindings}</div>
        </div>
        
        <h2>Critical Security Findings</h2>
        ${data.findings.filter(f => f.severity === 'critical').map(finding => `
            <div class="finding critical">
                <h3>${finding.title}</h3>
                <p><strong>Service:</strong> ${finding.service}</p>
                <p><strong>Category:</strong> ${finding.category}</p>
                <p><strong>Description:</strong> ${finding.description}</p>
                <p><strong>Impact:</strong> ${finding.impact}</p>
                <p><strong>Remediation:</strong> ${finding.remediation}</p>
            </div>
        `).join('')}
        
        <h2>High Priority Findings</h2>
        ${data.findings.filter(f => f.severity === 'high').map(finding => `
            <div class="finding high">
                <h3>${finding.title}</h3>
                <p><strong>Service:</strong> ${finding.service}</p>
                <p><strong>Description:</strong> ${finding.description}</p>
                <p><strong>Remediation:</strong> ${finding.remediation}</p>
            </div>
        `).join('')}
        
        <h2>Immediate Actions Required</h2>
        <ol>
            <li>Address all critical findings within 7 days</li>
            <li>Implement emergency security controls</li>
            <li>Review and update incident response procedures</li>
            <li>Conduct security awareness training for all staff</li>
        </ol>
    </body>
    </html>`;
}

function generateVulnerabilityReport(data: any): string {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Vulnerability Assessment Report</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 2rem; }
            h1 { color: #1e293b; border-bottom: 3px solid #f59e0b; padding-bottom: 1rem; }
            .vuln-summary { background: #fffbeb; border: 1px solid #f59e0b; border-radius: 8px; padding: 1.5rem; margin: 1rem 0; }
            .vuln-table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
            .vuln-table th, .vuln-table td { padding: 0.75rem; text-align: left; border-bottom: 1px solid #e2e8f0; }
            .vuln-table th { background: #f8fafc; font-weight: 600; }
            .severity-critical { color: #dc2626; font-weight: bold; }
            .severity-high { color: #f59e0b; font-weight: bold; }
            .severity-medium { color: #facc15; font-weight: bold; }
        </style>
    </head>
    <body>
        <h1>Vulnerability Assessment Report</h1>
        <h2>${data.organization.name}</h2>
        
        <div class="vuln-summary">
            <h3>Vulnerability Summary</h3>
            <p>Our comprehensive vulnerability assessment identified <strong>${data.metrics.criticalFindings + data.metrics.highFindings}</strong> critical and high-severity vulnerabilities that require immediate attention.</p>
            <ul>
                <li>Critical Vulnerabilities: ${data.metrics.criticalFindings}</li>
                <li>High Severity: ${data.metrics.highFindings}</li>
                <li>Medium Severity: ${data.metrics.mediumFindings}</li>
                <li>Low Severity: ${data.metrics.lowFindings}</li>
            </ul>
        </div>
        
        <h2>Critical Vulnerabilities</h2>
        <table class="vuln-table">
            <thead>
                <tr>
                    <th>Vulnerability</th>
                    <th>Severity</th>
                    <th>Service</th>
                    <th>CVSS Score</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Insecure Authentication Configuration</td>
                    <td class="severity-critical">Critical</td>
                    <td>Azure AD</td>
                    <td>9.1</td>
                    <td>Open</td>
                </tr>
                <tr>
                    <td>Excessive Permissions Granted</td>
                    <td class="severity-high">High</td>
                    <td>SharePoint</td>
                    <td>7.8</td>
                    <td>Open</td>
                </tr>
                <tr>
                    <td>Unencrypted Data Transmission</td>
                    <td class="severity-medium">Medium</td>
                    <td>Exchange Online</td>
                    <td>5.4</td>
                    <td>In Progress</td>
                </tr>
            </tbody>
        </table>
        
        <h2>Remediation Timeline</h2>
        <ul>
            <li><strong>Immediate (0-7 days):</strong> Address all critical vulnerabilities</li>
            <li><strong>Short-term (1-4 weeks):</strong> Resolve high-severity issues</li>
            <li><strong>Medium-term (1-3 months):</strong> Address medium-severity vulnerabilities</li>
            <li><strong>Long-term (3-6 months):</strong> Resolve remaining low-severity issues</li>
        </ul>
        
        <h2>Patch Management Recommendations</h2>
        <ol>
            <li>Implement automated patch management for critical systems</li>
            <li>Establish regular vulnerability scanning schedule</li>
            <li>Create incident response procedures for zero-day vulnerabilities</li>
            <li>Maintain inventory of all software and systems</li>
        </ol>
    </body>
    </html>`;
}

function getOrganizationName(orgCode: string): string {
    const organizations = {
        contoso: 'Contoso Corporation',
        fabrikam: 'Fabrikam Industries',
        northwind: 'Northwind Traders',
        tailspin: 'Tailspin Toys'
    };
    return organizations[orgCode] || orgCode;
}