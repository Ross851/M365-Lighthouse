import type { APIRoute } from 'astro';
import path from 'path';
import fs from 'fs/promises';

export const prerender = false;

export const GET: APIRoute = async ({ params }) => {
  try {
    const { sessionId } = params;
    
    // In production, this would read from actual assessment output
    // For now, return mock data
    const results = {
      sessionId,
      timestamp: new Date().toISOString(),
      overallScore: 75,
      posture: 'Good',
      previousScore: 68,
      industryAverage: 62,
      findings: {
        critical: [
          { id: 1, title: 'Users without MFA', description: '12 users lack multi-factor authentication', category: 'Identity' },
          { id: 2, title: 'Excessive Global Admins', description: '5 global admin accounts detected (recommended: 2-3)', category: 'Privileged Access' },
          { id: 3, title: 'Missing DLP Policies', description: 'No DLP policies for credit card data', category: 'Data Protection' }
        ],
        high: [
          { id: 4, title: 'Weak Password Policy', description: 'Password complexity requirements below standard', category: 'Identity' },
          { id: 5, title: 'External Sharing Open', description: 'SharePoint external sharing unrestricted', category: 'Collaboration' },
          { id: 6, title: 'Legacy Auth Enabled', description: 'Basic authentication still active', category: 'Authentication' }
        ],
        medium: Array(15).fill(null).map((_, i) => ({
          id: 100 + i,
          title: `Medium Issue ${i + 1}`,
          description: 'Description of medium severity issue',
          category: 'Various'
        })),
        low: Array(22).fill(null).map((_, i) => ({
          id: 200 + i,
          title: `Low Issue ${i + 1}`,
          description: 'Description of low severity issue',
          category: 'Various'
        }))
      },
      categoryScores: {
        azuread: { score: 82, name: 'Azure AD & Identity' },
        exchange: { score: 91, name: 'Exchange Online' },
        sharepoint: { score: 68, name: 'SharePoint & OneDrive' },
        teams: { score: 77, name: 'Microsoft Teams' },
        dlp: { score: 65, name: 'Data Loss Prevention' },
        defender: { score: 88, name: 'Microsoft Defender' }
      },
      recommendations: [
        {
          priority: 1,
          title: 'Enable MFA for all users',
          description: 'Implement multi-factor authentication for the 12 users currently without it',
          impact: 'high',
          effort: 'low',
          category: 'Identity'
        },
        {
          priority: 2,
          title: 'Reduce Global Administrator count',
          description: 'Follow principle of least privilege by reducing global admin accounts',
          impact: 'high',
          effort: 'medium',
          category: 'Privileged Access'
        },
        {
          priority: 3,
          title: 'Configure DLP policies',
          description: 'Implement Data Loss Prevention policies for sensitive information types',
          impact: 'high',
          effort: 'high',
          category: 'Data Protection'
        }
      ],
      reports: {
        executive: `/api/reports/executive/${sessionId}`,
        technical: `/api/reports/technical/${sessionId}`,
        evidence: `/api/reports/evidence/${sessionId}`
      }
    };
    
    return new Response(JSON.stringify(results), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Results not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};