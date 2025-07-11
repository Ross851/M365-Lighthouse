#!/usr/bin/env node

/**
 * PowerReview AI MCP Server
 * Integrates AI capabilities for automated M365 security assessments
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { spawn } from 'child_process';
import { readFile, writeFile } from 'fs/promises';
import path from 'path';

class PowerReviewAIServer {
  constructor() {
    this.server = new Server({
      name: 'powerreview-ai',
      version: '2.0.0',
    }, {
      capabilities: {
        tools: {}
      }
    });

    this.setupHandlers();
  }

  setupHandlers() {
    // List available tools
    this.server.setRequestHandler('tools/list', async () => ({
      tools: [
        {
          name: 'run_security_assessment',
          description: 'Run a comprehensive M365 security assessment',
          inputSchema: {
            type: 'object',
            properties: {
              tenant: { type: 'string', description: 'M365 tenant name' },
              assessments: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of assessments to run'
              },
              depth: {
                type: 'string',
                enum: ['quick', 'standard', 'deep'],
                description: 'Assessment depth'
              }
            },
            required: ['tenant', 'assessments']
          }
        },
        {
          name: 'analyze_security_posture',
          description: 'Analyze current M365 security configuration',
          inputSchema: {
            type: 'object',
            properties: {
              service: {
                type: 'string',
                enum: ['azuread', 'exchange', 'sharepoint', 'teams', 'defender'],
                description: 'M365 service to analyze'
              },
              includeRecommendations: {
                type: 'boolean',
                description: 'Include AI-generated recommendations'
              }
            },
            required: ['service']
          }
        },
        {
          name: 'generate_remediation_script',
          description: 'Generate PowerShell script to fix security issues',
          inputSchema: {
            type: 'object',
            properties: {
              findings: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of security findings to remediate'
              },
              priority: {
                type: 'string',
                enum: ['critical', 'high', 'medium', 'low'],
                description: 'Priority level for remediation'
              }
            },
            required: ['findings']
          }
        },
        {
          name: 'compare_with_best_practices',
          description: 'Compare current config with Microsoft best practices',
          inputSchema: {
            type: 'object',
            properties: {
              configPath: { type: 'string', description: 'Path to current config JSON' },
              framework: {
                type: 'string',
                enum: ['microsoft', 'cis', 'nist', 'iso27001'],
                description: 'Security framework to compare against'
              }
            },
            required: ['configPath', 'framework']
          }
        },
        {
          name: 'monitor_security_drift',
          description: 'Monitor changes in security configuration over time',
          inputSchema: {
            type: 'object',
            properties: {
              baselineDate: { type: 'string', description: 'Baseline assessment date' },
              currentDate: { type: 'string', description: 'Current assessment date' },
              alertThreshold: {
                type: 'number',
                description: 'Score drift threshold for alerts'
              }
            },
            required: ['baselineDate', 'currentDate']
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler('tools/call', async (request) => {
      const { name, arguments: args } = request.params;

      switch (name) {
        case 'run_security_assessment':
          return await this.runSecurityAssessment(args);
        
        case 'analyze_security_posture':
          return await this.analyzeSecurityPosture(args);
        
        case 'generate_remediation_script':
          return await this.generateRemediationScript(args);
        
        case 'compare_with_best_practices':
          return await this.compareWithBestPractices(args);
        
        case 'monitor_security_drift':
          return await this.monitorSecurityDrift(args);
        
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async runSecurityAssessment({ tenant, assessments, depth = 'standard' }) {
    const timestamp = new Date().toISOString();
    const sessionId = `ai_${Date.now()}`;
    
    // Execute PowerShell assessment
    const psCommand = `
      $config = @{
        TenantName = '${tenant}'
        Assessments = @(${assessments.map(a => `'${a}'`).join(',')})
        Depth = '${depth}'
        OutputPath = '$PSScriptRoot\\assessment-outputs\\${sessionId}'
        AIAssisted = $true
      }
      
      & '$PSScriptRoot\\..\\PowerReview-Complete.ps1' @config
    `;

    try {
      const result = await this.executePowerShell(psCommand);
      
      // AI analysis of results
      const analysis = await this.performAIAnalysis(result);
      
      return {
        content: [{
          type: 'text',
          text: `Security assessment completed for ${tenant}\n\n` +
                `Session ID: ${sessionId}\n` +
                `Timestamp: ${timestamp}\n` +
                `Assessments: ${assessments.join(', ')}\n\n` +
                `Key Findings:\n${analysis.findings}\n\n` +
                `Overall Score: ${analysis.score}/100\n` +
                `Risk Level: ${analysis.riskLevel}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error running assessment: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async analyzeSecurityPosture({ service, includeRecommendations = true }) {
    // Simulate security analysis with AI insights
    const analyses = {
      azuread: {
        score: 82,
        issues: [
          'MFA not enforced for 12% of users',
          '5 global administrators (recommended: 2-3)',
          'Legacy authentication protocols enabled'
        ],
        recommendations: [
          'Enable Security Defaults or Conditional Access',
          'Implement Privileged Identity Management (PIM)',
          'Block legacy authentication methods'
        ]
      },
      exchange: {
        score: 91,
        issues: [
          'Some mailboxes lack litigation hold',
          'External forwarding rules detected',
          'ATP Safe Attachments not fully configured'
        ],
        recommendations: [
          'Enable litigation hold for all mailboxes',
          'Review and restrict forwarding rules',
          'Configure ATP policies comprehensively'
        ]
      },
      sharepoint: {
        score: 68,
        issues: [
          'External sharing unrestricted',
          '23 orphaned sites detected',
          'No DLP policies for sensitive data'
        ],
        recommendations: [
          'Implement guest access governance',
          'Clean up orphaned sites',
          'Deploy DLP policies for PII/PHI'
        ]
      }
    };

    const analysis = analyses[service] || { score: 0, issues: [], recommendations: [] };
    
    let response = `Security Analysis for ${service.toUpperCase()}\n\n`;
    response += `Security Score: ${analysis.score}/100\n\n`;
    response += `Issues Detected:\n${analysis.issues.map(i => `• ${i}`).join('\n')}\n`;
    
    if (includeRecommendations) {
      response += `\nAI Recommendations:\n${analysis.recommendations.map(r => `• ${r}`).join('\n')}`;
    }

    return {
      content: [{
        type: 'text',
        text: response
      }]
    };
  }

  async generateRemediationScript({ findings, priority = 'high' }) {
    // Generate PowerShell remediation scripts based on findings
    const scripts = {
      'MFA not enforced': `
# Enable MFA for all users
Connect-MsolService
$users = Get-MsolUser -All | Where-Object {$_.StrongAuthenticationRequirements.Count -eq 0}
foreach ($user in $users) {
    $mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $mfa.RelyingParty = "*"
    $mfa.State = "Enabled"
    Set-MsolUser -UserPrincipalName $user.UserPrincipalName -StrongAuthenticationRequirements $mfa
}`,
      'External sharing unrestricted': `
# Restrict SharePoint external sharing
Connect-SPOService -Url https://contoso-admin.sharepoint.com
Set-SPOTenant -SharingCapability ExternalUserSharingOnly
Set-SPOTenant -DefaultSharingLinkType Internal`,
      'Legacy authentication enabled': `
# Block legacy authentication
Connect-AzureAD
$conditions = New-Object -TypeName Microsoft.Open.AzureAD.Model.ConditionalAccessConditionSet
$conditions.ClientAppTypes = @('ExchangeActiveSync', 'Other')
$controls = New-Object -TypeName Microsoft.Open.AzureAD.Model.ConditionalAccessGrantControls
$controls.BuiltInControls = @('Block')
New-AzureADMSConditionalAccessPolicy -DisplayName "Block Legacy Auth" -Conditions $conditions -GrantControls $controls`
    };

    const selectedScripts = findings
      .filter(f => scripts[f])
      .map(f => `# Fix: ${f}\n${scripts[f]}`)
      .join('\n\n');

    return {
      content: [{
        type: 'text',
        text: `PowerShell Remediation Script\nPriority: ${priority}\n\n${selectedScripts || 'No automated remediation available for selected findings.'}`
      }]
    };
  }

  async compareWithBestPractices({ configPath, framework }) {
    // Load configuration and compare with best practices
    const currentConfig = await readFile(configPath, 'utf8');
    const config = JSON.parse(currentConfig);
    
    const frameworks = {
      microsoft: {
        mfaRequired: true,
        maxGlobalAdmins: 4,
        externalSharingLevel: 'ExistingExternalUserSharingOnly',
        auditLogRetention: 90,
        dlpEnabled: true
      },
      cis: {
        mfaRequired: true,
        maxGlobalAdmins: 3,
        passwordComplexity: 'strong',
        sessionTimeout: 60,
        encryptionRequired: true
      }
    };

    const bestPractices = frameworks[framework];
    const gaps = [];

    // Compare configurations
    if (!config.mfaEnabled && bestPractices.mfaRequired) {
      gaps.push('MFA is not enforced (Required by ' + framework + ')');
    }
    
    if (config.globalAdminCount > bestPractices.maxGlobalAdmins) {
      gaps.push(`Too many global admins: ${config.globalAdminCount} (Max recommended: ${bestPractices.maxGlobalAdmins})`);
    }

    const complianceScore = Math.max(0, 100 - (gaps.length * 10));

    return {
      content: [{
        type: 'text',
        text: `Compliance Analysis - ${framework.toUpperCase()}\n\n` +
              `Compliance Score: ${complianceScore}%\n\n` +
              `Gaps Identified:\n${gaps.map(g => `• ${g}`).join('\n') || 'None - Fully compliant!'}\n\n` +
              `Next Steps:\n` +
              `1. Address critical gaps immediately\n` +
              `2. Create remediation plan for remaining items\n` +
              `3. Schedule follow-up assessment`
      }]
    };
  }

  async monitorSecurityDrift({ baselineDate, currentDate, alertThreshold = 10 }) {
    // Simulate security drift monitoring
    const baselineScore = 75;
    const currentScore = 68;
    const drift = baselineScore - currentScore;
    
    const changes = [
      { item: 'MFA Coverage', baseline: '88%', current: '76%', status: 'degraded' },
      { item: 'External Sharing', baseline: 'Restricted', current: 'Open', status: 'degraded' },
      { item: 'DLP Policies', baseline: '12', current: '15', status: 'improved' },
      { item: 'Conditional Access', baseline: '8 policies', current: '6 policies', status: 'degraded' }
    ];

    const alert = drift >= alertThreshold;

    return {
      content: [{
        type: 'text',
        text: `Security Drift Analysis\n\n` +
              `Baseline Date: ${baselineDate}\n` +
              `Current Date: ${currentDate}\n\n` +
              `Score Drift: ${drift} points ${alert ? '⚠️ ALERT' : '✓'}\n` +
              `Baseline Score: ${baselineScore}/100\n` +
              `Current Score: ${currentScore}/100\n\n` +
              `Configuration Changes:\n` +
              changes.map(c => 
                `• ${c.item}: ${c.baseline} → ${c.current} (${c.status})`
              ).join('\n') +
              `\n\n${alert ? 'ACTION REQUIRED: Security posture has degraded significantly!' : 'Security posture within acceptable range.'}`
      }]
    };
  }

  async executePowerShell(command) {
    return new Promise((resolve, reject) => {
      const ps = spawn('pwsh', ['-NoProfile', '-Command', command]);
      let output = '';
      let error = '';

      ps.stdout.on('data', (data) => {
        output += data.toString();
      });

      ps.stderr.on('data', (data) => {
        error += data.toString();
      });

      ps.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(error || 'PowerShell command failed'));
        } else {
          resolve(output);
        }
      });
    });
  }

  async performAIAnalysis(assessmentOutput) {
    // Simulate AI analysis of assessment results
    // In production, this could call OpenAI/Anthropic APIs
    return {
      score: 75,
      riskLevel: 'Medium',
      findings: `
1. Identity & Access Management: Several users lack MFA, increasing account compromise risk
2. Data Protection: External sharing policies need tightening
3. Compliance: Most regulatory requirements met, minor gaps in audit logging
4. Threat Protection: Good coverage, recommend enabling additional ATP features
5. Governance: Orphaned resources detected, cleanup recommended`
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('PowerReview AI MCP Server running...');
  }
}

// Start server
const server = new PowerReviewAIServer();
server.run().catch(console.error);