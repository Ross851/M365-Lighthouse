/**
 * Report Download API
 * Handles report downloads in various formats (PDF, Excel, HTML)
 */

import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ params, url }) => {
    const { reportId } = params;
    const format = url.searchParams.get('format') || 'pdf';

    if (!reportId) {
        return new Response(JSON.stringify({
            error: 'Report ID is required'
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
        });
    }

    try {
        // In a real implementation, you would fetch the report from a database
        // For demo purposes, we'll generate mock report content
        const reportContent = await generateReportContent(reportId, format);
        const filename = `report-${reportId}.${getFileExtension(format)}`;

        // Set appropriate headers for download
        const headers = new Headers();
        headers.set('Content-Disposition', `attachment; filename="${filename}"`);
        headers.set('Content-Type', getContentType(format));

        // For demo, we'll return the HTML content
        // In production, you would convert to the requested format
        return new Response(reportContent, {
            status: 200,
            headers
        });

    } catch (error) {
        console.error('Report download error:', error);
        return new Response(JSON.stringify({
            error: 'Failed to download report',
            message: error.message
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
};

async function generateReportContent(reportId: string, format: string): Promise<string> {
    // Parse report ID to determine type and organization
    const [type, organization] = reportId.split('-');
    
    const reportData = {
        id: reportId,
        type,
        organization,
        organizationName: getOrganizationName(organization),
        generatedDate: new Date(),
        metrics: {
            riskScore: 78,
            criticalFindings: 12,
            highFindings: 23,
            mediumFindings: 45,
            complianceScore: 85
        }
    };

    switch (format) {
        case 'pdf':
            return generatePDFContent(reportData);
        case 'excel':
            return generateExcelContent(reportData);
        case 'html':
            return generateHTMLContent(reportData);
        case 'powerpoint':
            return generatePowerPointContent(reportData);
        default:
            return generateHTMLContent(reportData);
    }
}

function generateHTMLContent(reportData: any): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Assessment Report - ${reportData.organizationName}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
            background: white;
        }

        .header {
            text-align: center;
            border-bottom: 3px solid #6366f1;
            padding-bottom: 2rem;
            margin-bottom: 3rem;
        }

        .header h1 {
            color: #1e293b;
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }

        .header .subtitle {
            color: #64748b;
            font-size: 1.25rem;
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.5rem;
            margin: 2rem 0;
        }

        .metric-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 1.5rem;
            text-align: center;
            transition: transform 0.2s;
        }

        .metric-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        .metric-value {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }

        .metric-label {
            color: #64748b;
            font-size: 0.875rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .risk-score { color: #dc2626; }
        .findings-count { color: #f59e0b; }
        .compliance-score { color: #10b981; }

        .section {
            margin: 3rem 0;
            padding: 2rem;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .section h2 {
            color: #1e293b;
            font-size: 1.75rem;
            margin-bottom: 1.5rem;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 0.5rem;
        }

        .finding {
            background: #fef2f2;
            border-left: 4px solid #dc2626;
            padding: 1.5rem;
            margin: 1rem 0;
            border-radius: 0 8px 8px 0;
        }

        .finding h3 {
            color: #1e293b;
            margin-bottom: 0.5rem;
        }

        .finding .severity {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .severity.critical {
            background: #dc2626;
            color: white;
        }

        .severity.high {
            background: #f59e0b;
            color: white;
        }

        .recommendation {
            background: #f0fdf4;
            border-left: 4px solid #10b981;
            padding: 1.5rem;
            margin: 1rem 0;
            border-radius: 0 8px 8px 0;
        }

        .tier-badge {
            display: inline-block;
            padding: 0.5rem 1rem;
            border-radius: 8px;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .tier-gold {
            background: linear-gradient(135deg, #fbbf24, #f59e0b);
            color: white;
        }

        .tier-silver {
            background: linear-gradient(135deg, #9ca3af, #6b7280);
            color: white;
        }

        .tier-bronze {
            background: linear-gradient(135deg, #92400e, #78350f);
            color: white;
        }

        .footer {
            margin-top: 4rem;
            padding-top: 2rem;
            border-top: 1px solid #e2e8f0;
            text-align: center;
            color: #64748b;
            font-size: 0.875rem;
        }

        .compliance-table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
        }

        .compliance-table th,
        .compliance-table td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        .compliance-table th {
            background: #f8fafc;
            font-weight: 600;
            color: #374151;
        }

        .compliance-status {
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .status-compliant {
            background: #d1fae5;
            color: #059669;
        }

        .status-partial {
            background: #fef3c7;
            color: #d97706;
        }

        .status-non-compliant {
            background: #fee2e2;
            color: #dc2626;
        }

        @media print {
            body {
                max-width: none;
                padding: 1rem;
            }
            
            .metric-card:hover {
                transform: none;
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Security Assessment Report</h1>
        <div class="subtitle">${reportData.organizationName}</div>
        <div style="margin-top: 1rem; color: #64748b;">
            Generated on ${reportData.generatedDate.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
            })}
        </div>
    </div>

    <div class="metrics-grid">
        <div class="metric-card">
            <div class="metric-value risk-score">${reportData.metrics.riskScore}%</div>
            <div class="metric-label">Risk Score</div>
        </div>
        <div class="metric-card">
            <div class="metric-value findings-count">${reportData.metrics.criticalFindings}</div>
            <div class="metric-label">Critical Findings</div>
        </div>
        <div class="metric-card">
            <div class="metric-value findings-count">${reportData.metrics.highFindings}</div>
            <div class="metric-label">High Findings</div>
        </div>
        <div class="metric-card">
            <div class="metric-value compliance-score">${reportData.metrics.complianceScore}%</div>
            <div class="metric-label">Compliance Score</div>
        </div>
    </div>

    <div class="section">
        <h2>Executive Summary</h2>
        <p>This comprehensive security assessment evaluated your Microsoft 365 environment against industry best practices and security frameworks. Our analysis identified <strong>${reportData.metrics.criticalFindings} critical</strong> and <strong>${reportData.metrics.highFindings} high-priority</strong> security findings that require immediate attention.</p>
        
        <p>Your organization's current security posture shows a risk score of <strong>${reportData.metrics.riskScore}%</strong>, indicating areas for improvement in identity management, data protection, and threat defense capabilities.</p>
        
        <p><strong>Key Focus Areas:</strong></p>
        <ul>
            <li>Identity and Access Management strengthening</li>
            <li>Advanced threat protection implementation</li>
            <li>Data loss prevention enhancement</li>
            <li>Compliance framework alignment</li>
        </ul>
    </div>

    <div class="section">
        <h2>Critical Security Findings</h2>
        
        <div class="finding">
            <h3>Multi-Factor Authentication Not Enforced</h3>
            <span class="severity critical">CRITICAL</span>
            <p><strong>Service:</strong> Azure Active Directory</p>
            <p><strong>Description:</strong> Administrative accounts do not have multi-factor authentication enforcement enabled, creating significant security vulnerability.</p>
            <p><strong>Impact:</strong> High risk of account compromise and unauthorized access to sensitive systems and data.</p>
            <p><strong>Remediation:</strong> Enable MFA enforcement for all administrative accounts immediately and implement conditional access policies.</p>
        </div>

        <div class="finding">
            <h3>Legacy Authentication Protocols Enabled</h3>
            <span class="severity high">HIGH</span>
            <p><strong>Service:</strong> Exchange Online</p>
            <p><strong>Description:</strong> Legacy authentication protocols bypass modern security controls and monitoring capabilities.</p>
            <p><strong>Impact:</strong> Potential for credential theft and bypassing of security policies.</p>
            <p><strong>Remediation:</strong> Disable legacy authentication and migrate to modern authentication protocols.</p>
        </div>

        <div class="finding">
            <h3>Insufficient Conditional Access Policies</h3>
            <span class="severity high">HIGH</span>
            <p><strong>Service:</strong> Azure Active Directory</p>
            <p><strong>Description:</strong> Limited conditional access policies provide inadequate protection against risky sign-ins.</p>
            <p><strong>Impact:</strong> Increased risk of unauthorized access from compromised or unmanaged devices.</p>
            <p><strong>Remediation:</strong> Implement comprehensive conditional access policies covering device compliance, location, and risk-based access.</p>
        </div>
    </div>

    <div class="section">
        <h2>Strategic Recommendations</h2>
        
        <div class="recommendation">
            <div class="tier-badge tier-gold">🥇 Gold Tier - Immediate (0-30 days)</div>
            <h3>Critical Security Controls</h3>
            <ul>
                <li>Implement Zero Trust architecture foundation</li>
                <li>Enable multi-factor authentication for all users</li>
                <li>Deploy Microsoft Defender for Office 365 Plan 2</li>
                <li>Configure comprehensive conditional access policies</li>
            </ul>
            <p><strong>Investment:</strong> $50,000 - $100,000 | <strong>Expected ROI:</strong> 300% within 12 months</p>
        </div>

        <div class="recommendation">
            <div class="tier-badge tier-silver">🥈 Silver Tier - Short-term (30-90 days)</div>
            <h3>Advanced Protection</h3>
            <ul>
                <li>Implement Privileged Identity Management (PIM)</li>
                <li>Enable Microsoft Cloud App Security</li>
                <li>Deploy comprehensive Data Loss Prevention policies</li>
                <li>Configure advanced threat protection</li>
            </ul>
            <p><strong>Investment:</strong> $25,000 - $50,000 | <strong>Expected ROI:</strong> 200% within 18 months</p>
        </div>

        <div class="recommendation">
            <div class="tier-badge tier-bronze">🥉 Bronze Tier - Long-term (90+ days)</div>
            <h3>Continuous Improvement</h3>
            <ul>
                <li>Enhance security awareness training programs</li>
                <li>Implement advanced compliance monitoring</li>
                <li>Deploy automated incident response capabilities</li>
                <li>Establish comprehensive security metrics dashboard</li>
            </ul>
            <p><strong>Investment:</strong> $10,000 - $25,000 | <strong>Expected ROI:</strong> 150% within 24 months</p>
        </div>
    </div>

    <div class="section">
        <h2>Compliance Status</h2>
        <table class="compliance-table">
            <thead>
                <tr>
                    <th>Framework</th>
                    <th>Current Score</th>
                    <th>Status</th>
                    <th>Key Gaps</th>
                    <th>Target Date</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>GDPR</td>
                    <td>85%</td>
                    <td><span class="compliance-status status-partial">Partially Compliant</span></td>
                    <td>Data subject rights automation</td>
                    <td>Q3 2024</td>
                </tr>
                <tr>
                    <td>ISO 27001</td>
                    <td>92%</td>
                    <td><span class="compliance-status status-compliant">Compliant</span></td>
                    <td>Documentation updates</td>
                    <td>Q4 2024</td>
                </tr>
                <tr>
                    <td>NIST CSF</td>
                    <td>78%</td>
                    <td><span class="compliance-status status-partial">Partially Compliant</span></td>
                    <td>Incident response procedures</td>
                    <td>Q3 2024</td>
                </tr>
                <tr>
                    <td>SOX</td>
                    <td>89%</td>
                    <td><span class="compliance-status status-compliant">Compliant</span></td>
                    <td>Access review frequency</td>
                    <td>Q4 2024</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="section">
        <h2>Next Steps</h2>
        <ol>
            <li><strong>Immediate Actions (Week 1):</strong> Address all critical findings, particularly MFA enforcement and legacy authentication</li>
            <li><strong>Short-term Goals (Month 1):</strong> Implement Gold tier recommendations and establish monitoring</li>
            <li><strong>Medium-term Objectives (Months 2-3):</strong> Deploy Silver tier enhancements and conduct staff training</li>
            <li><strong>Long-term Strategy (Months 4-6):</strong> Complete Bronze tier improvements and establish ongoing assessment cycles</li>
            <li><strong>Continuous Monitoring:</strong> Schedule quarterly assessments and monthly security reviews</li>
        </ol>
    </div>

    <div class="footer">
        <p><strong>PowerReview Security Assessment</strong> | Generated on ${reportData.generatedDate.toLocaleDateString()}</p>
        <p>This report contains confidential information. Distribution should be limited to authorized personnel only.</p>
        <p>For questions or support, contact: security@powerreview.com | +1 (555) 123-4567</p>
    </div>
</body>
</html>`;
}

function generatePDFContent(reportData: any): string {
    // In a real implementation, this would generate actual PDF content
    // For demo purposes, return HTML that could be converted to PDF
    return generateHTMLContent(reportData);
}

function generateExcelContent(reportData: any): string {
    // In a real implementation, this would generate Excel content
    // For demo purposes, return CSV data
    return `Finding,Severity,Service,Category,Status,Remediation
Multi-Factor Authentication Not Enforced,Critical,Azure AD,Identity & Access,Open,Enable MFA for all accounts
Legacy Authentication Enabled,High,Exchange Online,Authentication,Open,Disable legacy protocols
Insufficient Conditional Access,High,Azure AD,Access Control,Open,Implement CA policies
External Sharing Unrestricted,Medium,SharePoint,Data Protection,Open,Configure sharing policies
Missing DLP Policies,Medium,Microsoft Purview,Data Protection,In Progress,Deploy DLP rules
Guest Access Uncontrolled,Medium,Azure AD,Identity & Access,Open,Implement guest reviews`;
}

function generatePowerPointContent(reportData: any): string {
    // In a real implementation, this would generate PowerPoint content
    // For demo purposes, return a simplified presentation structure
    return `
PowerPoint Presentation: Security Assessment Report
Slide 1: Executive Summary
Slide 2: Risk Assessment Overview  
Slide 3: Critical Findings
Slide 4: High Priority Issues
Slide 5: Strategic Recommendations
Slide 6: Compliance Status
Slide 7: Implementation Timeline
Slide 8: Next Steps
Slide 9: Investment & ROI Analysis
Slide 10: Contact Information

Note: This would be a full PowerPoint presentation in a real implementation.`;
}

function getFileExtension(format: string): string {
    const extensions = {
        pdf: 'pdf',
        excel: 'xlsx',
        html: 'html',
        powerpoint: 'pptx'
    };
    return extensions[format] || 'html';
}

function getContentType(format: string): string {
    const contentTypes = {
        pdf: 'application/pdf',
        excel: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        html: 'text/html',
        powerpoint: 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    };
    return contentTypes[format] || 'text/html';
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