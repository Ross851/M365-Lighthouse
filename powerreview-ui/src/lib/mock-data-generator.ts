/**
 * Mock Data Generator for Global Multi-Region Testing
 * Generates realistic data across all 14 supported regions for visual testing
 */

export interface MockClientData {
  clientId: string;
  organizationName: string;
  headquarters: string;
  industry: string;
  employeeCount: number;
  dataDistribution: Record<string, {
    customer: number;
    assessment: number;
    files: number;
    logs: number;
    totalGB: number;
  }>;
  complianceScores: Record<string, Record<string, number>>;
  dataFlows: Array<{
    source: string;
    target: string;
    type: 'backup' | 'sync' | 'analytics' | 'blocked';
    dataVolume: number;
    frequency: string;
    encryption: string;
    status: 'active' | 'paused' | 'error';
  }>;
  riskFactors: Array<{
    region: string;
    category: string;
    level: 'low' | 'medium' | 'high' | 'critical';
    description: string;
    impact: string;
    mitigation: string;
  }>;
  recentActivity: Array<{
    timestamp: string;
    region: string;
    action: string;
    details: string;
    userId: string;
  }>;
}

// Comprehensive mock client scenarios
export const MOCK_CLIENTS: MockClientData[] = [
  {
    clientId: 'globalcorp-apac',
    organizationName: 'GlobalCorp Asia-Pacific',
    headquarters: 'Singapore',
    industry: 'Financial Services',
    employeeCount: 15000,
    dataDistribution: {
      'singapore': { customer: 4250, assessment: 189, files: 1820, logs: 5430, totalGB: 2.8 },
      'japan': { customer: 1850, assessment: 67, files: 890, logs: 2340, totalGB: 1.2 },
      'australia': { customer: 0, assessment: 189, files: 920, logs: 1250, totalGB: 0.8 },
      'south-korea': { customer: 950, assessment: 34, files: 450, logs: 1120, totalGB: 0.6 },
      'malaysia': { customer: 0, assessment: 0, files: 320, logs: 890, totalGB: 0.3 },
      'thailand': { customer: 650, assessment: 23, files: 280, logs: 670, totalGB: 0.4 },
      'philippines': { customer: 480, assessment: 18, files: 210, logs: 540, totalGB: 0.3 },
      'indonesia': { customer: 720, assessment: 28, files: 350, logs: 780, totalGB: 0.5 },
      'vietnam': { customer: 380, assessment: 15, files: 180, logs: 420, totalGB: 0.2 }
    },
    complianceScores: {
      'singapore': { 'PDPA': 98, 'MAS': 97, 'ISO27001': 96 },
      'japan': { 'APPI': 99, 'ISMS': 98, 'ISO27001': 97 },
      'australia': { 'Privacy Act': 95, 'ISO27001': 94 },
      'south-korea': { 'PIPA': 96, 'K-ISMS': 95 },
      'malaysia': { 'PDPA MY': 93, 'ISO27001': 92 },
      'thailand': { 'PDPA TH': 94, 'ISO27001': 93 },
      'philippines': { 'DPA PH': 91, 'ISO27001': 90 },
      'indonesia': { 'UU PDP': 89, 'ISO27001': 88 },
      'vietnam': { 'Decree 13': 87, 'ISO27001': 86 }
    },
    dataFlows: [
      { source: 'singapore', target: 'australia', type: 'backup', dataVolume: 189, frequency: 'daily', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'singapore', target: 'malaysia', type: 'sync', dataVolume: 85, frequency: 'real-time', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'japan', target: 'singapore', type: 'blocked', dataVolume: 0, frequency: 'none', encryption: 'N/A', status: 'paused' },
      { source: 'south-korea', target: 'singapore', type: 'analytics', dataVolume: 12, frequency: 'weekly', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'thailand', target: 'singapore', type: 'sync', dataVolume: 45, frequency: 'hourly', encryption: 'AES-256-GCM', status: 'active' }
    ],
    riskFactors: [
      { region: 'japan', category: 'regulatory-isolation', level: 'medium', description: 'APPI requires data isolation', impact: 'No cross-border data sharing', mitigation: 'Maintain separate infrastructure' },
      { region: 'indonesia', category: 'compliance-gap', level: 'medium', description: 'UU PDP implementation pending', impact: 'Potential regulatory changes', mitigation: 'Monitor regulatory updates' },
      { region: 'singapore', category: 'data-volume', level: 'low', description: 'High data concentration in primary region', impact: 'Performance considerations', mitigation: 'Load balancing implemented' }
    ],
    recentActivity: [
      { timestamp: '2025-01-12T14:30:00Z', region: 'singapore', action: 'BACKUP_COMPLETED', details: 'Daily backup to Australia completed successfully', userId: 'admin@globalcorp.com' },
      { timestamp: '2025-01-12T14:25:00Z', region: 'thailand', action: 'DATA_SYNC', details: 'Customer data synchronized to Singapore', userId: 'thai.admin@globalcorp.com' },
      { timestamp: '2025-01-12T14:20:00Z', region: 'japan', action: 'COMPLIANCE_AUDIT', details: 'APPI compliance check completed - 99% score', userId: 'jp.auditor@globalcorp.com' }
    ]
  },
  {
    clientId: 'eurotech-global',
    organizationName: 'EuroTech Global Solutions',
    headquarters: 'Frankfurt',
    industry: 'Technology',
    employeeCount: 8500,
    dataDistribution: {
      'eu-central': { customer: 3200, assessment: 145, files: 1450, logs: 3890, totalGB: 3.2 },
      'eu-west': { customer: 1800, assessment: 89, files: 920, logs: 2340, totalGB: 1.8 },
      'uk': { customer: 950, assessment: 45, files: 560, logs: 1450, totalGB: 1.1 },
      'us-east': { customer: 2100, assessment: 98, files: 1120, logs: 2890, totalGB: 2.4 },
      'us-west': { customer: 1650, assessment: 76, files: 890, logs: 2230, totalGB: 1.9 },
      'canada': { customer: 680, assessment: 34, files: 420, logs: 980, totalGB: 0.7 },
      'singapore': { customer: 450, assessment: 23, files: 280, logs: 650, totalGB: 0.4 },
      'australia': { customer: 0, assessment: 67, files: 340, logs: 780, totalGB: 0.3 }
    },
    complianceScores: {
      'eu-central': { 'GDPR': 99, 'ISO27001': 98, 'SOC2': 97 },
      'eu-west': { 'GDPR': 98, 'ISO27001': 97, 'SOC2': 96 },
      'uk': { 'UK GDPR': 97, 'ISO27001': 96, 'SOC2': 95 },
      'us-east': { 'SOC2': 96, 'NIST': 95, 'CCPA': 94 },
      'us-west': { 'SOC2': 95, 'NIST': 94, 'CCPA': 98 },
      'canada': { 'PIPEDA': 93, 'SOC2': 92 },
      'singapore': { 'PDPA': 91, 'ISO27001': 90 },
      'australia': { 'Privacy Act': 89, 'ISO27001': 88 }
    },
    dataFlows: [
      { source: 'eu-central', target: 'eu-west', type: 'sync', dataVolume: 145, frequency: 'real-time', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'us-east', target: 'us-west', type: 'backup', dataVolume: 98, frequency: 'daily', encryption: 'FIPS-140-2', status: 'active' },
      { source: 'uk', target: 'eu-central', type: 'analytics', dataVolume: 23, frequency: 'weekly', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'singapore', target: 'australia', type: 'backup', dataVolume: 23, frequency: 'daily', encryption: 'AES-256-GCM', status: 'active' }
    ],
    riskFactors: [
      { region: 'uk', category: 'brexit-compliance', level: 'low', description: 'Post-Brexit data transfer agreements in place', impact: 'Minimal operational impact', mitigation: 'UK GDPR compliance maintained' },
      { region: 'us-west', category: 'ccpa-updates', level: 'medium', description: 'CCPA amendments require monitoring', impact: 'Potential policy updates needed', mitigation: 'Quarterly compliance review scheduled' }
    ],
    recentActivity: [
      { timestamp: '2025-01-12T15:45:00Z', region: 'eu-central', action: 'GDPR_AUDIT', details: 'Quarterly GDPR compliance audit completed - 99% score', userId: 'compliance@eurotech.eu' },
      { timestamp: '2025-01-12T15:30:00Z', region: 'us-east', action: 'DATA_MIGRATION', details: 'Customer data migrated from legacy system', userId: 'us.admin@eurotech.com' }
    ]
  },
  {
    clientId: 'manufacturing-usa',
    organizationName: 'American Manufacturing Corp',
    headquarters: 'Chicago',
    industry: 'Manufacturing',
    employeeCount: 12000,
    dataDistribution: {
      'us-east': { customer: 5200, assessment: 234, files: 2890, logs: 6780, totalGB: 4.8 },
      'us-west': { customer: 3100, assessment: 145, files: 1780, logs: 4230, totalGB: 2.9 },
      'canada': { customer: 1450, assessment: 67, files: 890, logs: 1980, totalGB: 1.3 },
      'eu-central': { customer: 0, assessment: 45, files: 280, logs: 560, totalGB: 0.2 },
      'singapore': { customer: 680, assessment: 28, files: 340, logs: 780, totalGB: 0.5 },
      'japan': { customer: 0, assessment: 0, files: 120, logs: 230, totalGB: 0.1 }
    },
    complianceScores: {
      'us-east': { 'SOC2': 97, 'NIST': 96, 'HIPAA': 95 },
      'us-west': { 'SOC2': 96, 'NIST': 95, 'CCPA': 97 },
      'canada': { 'PIPEDA': 94, 'SOC2': 93 },
      'eu-central': { 'GDPR': 91, 'ISO27001': 90 },
      'singapore': { 'PDPA': 88, 'ISO27001': 87 },
      'japan': { 'APPI': 85, 'ISO27001': 84 }
    },
    dataFlows: [
      { source: 'us-east', target: 'us-west', type: 'sync', dataVolume: 234, frequency: 'real-time', encryption: 'FIPS-140-2', status: 'active' },
      { source: 'us-east', target: 'canada', type: 'backup', dataVolume: 156, frequency: 'daily', encryption: 'CSE-approved', status: 'active' },
      { source: 'singapore', target: 'japan', type: 'analytics', dataVolume: 8, frequency: 'monthly', encryption: 'AES-256-GCM', status: 'active' }
    ],
    riskFactors: [
      { region: 'us-east', category: 'data-concentration', level: 'medium', description: 'High data volume in primary region', impact: 'Performance and DR considerations', mitigation: 'Multi-region backup strategy' },
      { region: 'singapore', category: 'growing-operations', level: 'low', description: 'Expanding APAC operations', impact: 'Increased data volume expected', mitigation: 'Capacity planning in progress' }
    ],
    recentActivity: [
      { timestamp: '2025-01-12T16:00:00Z', region: 'us-east', action: 'BULK_UPLOAD', details: 'Manufacturing data bulk upload completed', userId: 'ops@americanmfg.com' },
      { timestamp: '2025-01-12T15:45:00Z', region: 'canada', action: 'BACKUP_VERIFICATION', details: 'Daily backup integrity check passed', userId: 'ca.admin@americanmfg.com' }
    ]
  },
  {
    clientId: 'pharma-global',
    organizationName: 'Global Pharma Research Ltd',
    headquarters: 'London',
    industry: 'Pharmaceutical',
    employeeCount: 25000,
    dataDistribution: {
      'uk': { customer: 6800, assessment: 345, files: 4250, logs: 9870, totalGB: 8.9 },
      'eu-central': { customer: 4200, assessment: 189, files: 2890, logs: 6450, totalGB: 5.2 },
      'eu-west': { customer: 2800, assessment: 134, files: 1980, logs: 4320, totalGB: 3.4 },
      'us-east': { customer: 5600, assessment: 267, files: 3450, logs: 7890, totalGB: 6.8 },
      'us-west': { customer: 3200, assessment: 156, files: 2100, logs: 4560, totalGB: 3.9 },
      'canada': { customer: 1800, assessment: 89, files: 1200, logs: 2340, totalGB: 1.8 },
      'japan': { customer: 2400, assessment: 98, files: 1560, logs: 3210, totalGB: 2.7 },
      'australia': { customer: 0, assessment: 234, files: 890, logs: 1450, totalGB: 0.8 },
      'singapore': { customer: 1200, assessment: 67, files: 780, logs: 1890, totalGB: 1.2 }
    },
    complianceScores: {
      'uk': { 'UK GDPR': 99, 'GxP': 98, 'ISO27001': 97 },
      'eu-central': { 'GDPR': 98, 'GxP': 97, 'ISO27001': 96 },
      'eu-west': { 'GDPR': 97, 'GxP': 96, 'ISO27001': 95 },
      'us-east': { 'HIPAA': 99, 'FDA 21 CFR': 98, 'SOC2': 97 },
      'us-west': { 'HIPAA': 98, 'FDA 21 CFR': 97, 'CCPA': 99 },
      'canada': { 'PIPEDA': 96, 'Health Canada': 95 },
      'japan': { 'APPI': 97, 'PMDA': 96, 'ISMS': 95 },
      'australia': { 'Privacy Act': 94, 'TGA': 93 },
      'singapore': { 'PDPA': 92, 'HSA': 91 }
    },
    dataFlows: [
      { source: 'uk', target: 'eu-central', type: 'sync', dataVolume: 345, frequency: 'real-time', encryption: 'AES-256-GCM', status: 'active' },
      { source: 'us-east', target: 'us-west', type: 'backup', dataVolume: 267, frequency: 'daily', encryption: 'FIPS-140-2', status: 'active' },
      { source: 'japan', target: 'singapore', type: 'analytics', dataVolume: 34, frequency: 'weekly', encryption: 'CRYPTREC', status: 'active' },
      { source: 'australia', target: 'singapore', type: 'backup', dataVolume: 67, frequency: 'daily', encryption: 'ASD-approved', status: 'active' }
    ],
    riskFactors: [
      { region: 'uk', category: 'clinical-trial-data', level: 'high', description: 'Clinical trial data requires highest protection', impact: 'Regulatory scrutiny', mitigation: 'Enhanced encryption and access controls' },
      { region: 'japan', category: 'regulatory-changes', level: 'medium', description: 'PMDA guidelines evolving', impact: 'Compliance requirements may change', mitigation: 'Regular regulatory monitoring' }
    ],
    recentActivity: [
      { timestamp: '2025-01-12T17:15:00Z', region: 'uk', action: 'CLINICAL_DATA_UPLOAD', details: 'Phase III trial data uploaded securely', userId: 'clinical@globalpharma.co.uk' },
      { timestamp: '2025-01-12T17:00:00Z', region: 'us-east', action: 'FDA_AUDIT_PREP', details: 'FDA audit trail generated for submission', userId: 'regulatory@globalpharma.com' }
    ]
  }
];

// Generate realistic activity data
export function generateRecentActivity(clientId: string, hours: number = 24): Array<{
  timestamp: string;
  region: string;
  action: string;
  details: string;
  userId: string;
  severity: 'info' | 'warning' | 'success' | 'error';
}> {
  const activities = [];
  const client = MOCK_CLIENTS.find(c => c.clientId === clientId);
  if (!client) return [];

  const regions = Object.keys(client.dataDistribution);
  const actionTypes = [
    'DATA_BACKUP', 'COMPLIANCE_SCAN', 'USER_ACCESS', 'FILE_UPLOAD',
    'SYNC_COMPLETED', 'AUDIT_LOG', 'ENCRYPTION_CHECK', 'POLICY_UPDATE',
    'HEALTH_CHECK', 'PERFORMANCE_ALERT', 'DATA_EXPORT', 'MIGRATION_STATUS'
  ];

  for (let i = 0; i < 50; i++) {
    const hoursAgo = Math.floor(Math.random() * hours);
    const timestamp = new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString();
    const region = regions[Math.floor(Math.random() * regions.length)];
    const action = actionTypes[Math.floor(Math.random() * actionTypes.length)];
    
    activities.push({
      timestamp,
      region,
      action,
      details: generateActionDetail(action, region),
      userId: generateUserId(client.organizationName),
      severity: generateSeverity(action)
    });
  }

  return activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
}

function generateActionDetail(action: string, region: string): string {
  const details: Record<string, string[]> = {
    'DATA_BACKUP': [
      `Daily backup completed successfully to ${region}`,
      `Incremental backup finished - 98% efficiency`,
      `Cross-region backup verified and encrypted`
    ],
    'COMPLIANCE_SCAN': [
      `Compliance scan completed - 99% score`,
      `Regional compliance check passed all requirements`,
      `Automated compliance verification successful`
    ],
    'USER_ACCESS': [
      `Administrator logged in from ${region}`,
      `User permissions updated for regional access`,
      `Multi-factor authentication completed`
    ],
    'FILE_UPLOAD': [
      `Assessment files uploaded securely`,
      `Document batch processed and encrypted`,
      `Customer files stored with regional compliance`
    ]
  };

  const actionDetails = details[action] || ['System operation completed'];
  return actionDetails[Math.floor(Math.random() * actionDetails.length)];
}

function generateUserId(orgName: string): string {
  const domain = orgName.toLowerCase().replace(/[^a-z]/g, '').substring(0, 8);
  const users = ['admin', 'ops', 'security', 'compliance', 'audit'];
  const user = users[Math.floor(Math.random() * users.length)];
  return `${user}@${domain}.com`;
}

function generateSeverity(action: string): 'info' | 'warning' | 'success' | 'error' {
  const severityMap: Record<string, 'info' | 'warning' | 'success' | 'error'> = {
    'DATA_BACKUP': 'success',
    'COMPLIANCE_SCAN': 'success',
    'USER_ACCESS': 'info',
    'FILE_UPLOAD': 'info',
    'SYNC_COMPLETED': 'success',
    'AUDIT_LOG': 'info',
    'ENCRYPTION_CHECK': 'success',
    'POLICY_UPDATE': 'warning',
    'HEALTH_CHECK': 'success',
    'PERFORMANCE_ALERT': 'warning',
    'DATA_EXPORT': 'info',
    'MIGRATION_STATUS': 'info'
  };

  return severityMap[action] || 'info';
}

// Generate compliance trend data
export function generateComplianceTrends(clientId: string, days: number = 30): Array<{
  date: string;
  region: string;
  score: number;
  standard: string;
}> {
  const trends = [];
  const client = MOCK_CLIENTS.find(c => c.clientId === clientId);
  if (!client) return [];

  for (let day = 0; day < days; day++) {
    const date = new Date(Date.now() - day * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    
    Object.entries(client.complianceScores).forEach(([region, scores]) => {
      Object.entries(scores).forEach(([standard, baseScore]) => {
        // Add slight random variation to simulate realistic trends
        const variation = (Math.random() - 0.5) * 4; // ±2 points variation
        const score = Math.max(80, Math.min(100, baseScore + variation));
        
        trends.push({
          date,
          region,
          score: Math.round(score * 10) / 10,
          standard
        });
      });
    });
  }

  return trends;
}

// Export selected client for dashboard
export function getClientData(clientId: string): MockClientData | null {
  return MOCK_CLIENTS.find(c => c.clientId === clientId) || null;
}

// Get all available clients
export function getAllClients(): Array<{ id: string; name: string; headquarters: string; industry: string }> {
  return MOCK_CLIENTS.map(client => ({
    id: client.clientId,
    name: client.organizationName,
    headquarters: client.headquarters,
    industry: client.industry
  }));
}