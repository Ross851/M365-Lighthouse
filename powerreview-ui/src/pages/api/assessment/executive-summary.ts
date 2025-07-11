import type { APIRoute } from 'astro';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

export const GET: APIRoute = async ({ request }) => {
  // Verify authentication
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  const token = authHeader.substring(7);
  try {
    jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Return executive summary data
  // In production, this would pull from your assessment database
  const summaryData = {
    riskScore: 78,
    financialExposure: '$7.5M',
    complianceScore: 45,
    protectedUsers: 88,
    assessmentDate: new Date().toISOString(),
    keyFindings: [
      {
        title: '12% of users lack Multi-Factor Authentication',
        severity: 'critical',
        affectedUsers: 12,
        totalUsers: 100,
        businessImpact: 'High risk of account compromise and data breach',
        estimatedExposure: '$2.1M'
      },
      {
        title: 'External sharing is unrestricted in SharePoint',
        severity: 'high',
        currentSetting: 'ExternalUserAndGuestSharing',
        recommendedSetting: 'ExistingExternalUserSharingOnly',
        businessImpact: 'Potential data leakage and loss of intellectual property',
        estimatedExposure: '$3.5M'
      },
      {
        title: 'No Data Loss Prevention policies configured',
        severity: 'high',
        policiesFound: 0,
        requiredPolicies: ['Credit Card', 'SSN', 'Health Records'],
        businessImpact: 'Sensitive data can be transmitted without oversight',
        estimatedExposure: '$2.0M'
      }
    ],
    recommendations: {
      immediate: [
        'Enable Security Defaults for all users',
        'Block legacy authentication protocols',
        'Configure audit logging'
      ],
      shortTerm: [
        'Deploy MFA to all users',
        'Implement DLP policies',
        'Configure Conditional Access'
      ],
      longTerm: [
        'Implement Zero Trust architecture',
        'Deploy advanced threat protection',
        'Establish 24/7 SOC monitoring'
      ]
    },
    complianceGaps: [
      { framework: 'GDPR', status: 'Non-compliant', requiredActions: 4 },
      { framework: 'HIPAA', status: 'At Risk', requiredActions: 7 },
      { framework: 'SOC2', status: 'Partial', requiredActions: 3 }
    ]
  };

  return new Response(JSON.stringify(summaryData), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache'
    }
  });
};