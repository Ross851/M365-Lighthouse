import type { APIRoute } from 'astro';
import { spawn } from 'child_process';
import { promisify } from 'util';

interface AssessmentResult {
  id: string;
  type: string;
  organization: string;
  timestamp: string;
  findings: Finding[];
  metrics: Metrics;
  evidence: Evidence[];
  rawData?: any;
}

interface Finding {
  id: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  service: string;
  category: string;
  evidence: string;
  impact: string[];
  remediation: string[];
  references?: string[];
}

interface Metrics {
  riskScore: number;
  complianceScore: number;
  totalFindings: number;
  criticalFindings: number;
  highFindings: number;
  mediumFindings: number;
  lowFindings: number;
}

interface Evidence {
  id: string;
  type: 'powershell' | 'screenshot' | 'export';
  name: string;
  timestamp: string;
  content?: string;
  path?: string;
}

// Helper function to execute MCP server commands
async function executeMCPCommand(server: string, method: string, params: any): Promise<any> {
  return new Promise((resolve, reject) => {
    let result = '';
    let error = '';
    
    // Get MCP server config from mcp.json
    const mcpConfig = {
      'sequential-thinking': {
        command: 'python',
        args: ['/mnt/c/Users/Ross/M365-Lighthouse/mcp/sequential-thinking/main.py']
      }
    };
    
    const config = mcpConfig[server as keyof typeof mcpConfig];
    if (!config) {
      reject(new Error(`Unknown MCP server: ${server}`));
      return;
    }
    
    const child = spawn(config.command, config.args);
    
    // Send request to MCP server
    const request = JSON.stringify({ method, params }) + '\n';
    child.stdin.write(request);
    
    child.stdout.on('data', (data) => {
      result += data.toString();
    });
    
    child.stderr.on('data', (data) => {
      error += data.toString();
    });
    
    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`MCP server exited with code ${code}: ${error}`));
      } else {
        try {
          const response = JSON.parse(result.trim());
          if (response.error) {
            reject(new Error(response.error));
          } else {
            resolve(response.result);
          }
        } catch (e) {
          reject(new Error(`Failed to parse MCP response: ${result}`));
        }
      }
    });
    
    // Close stdin to signal end of input
    child.stdin.end();
  });
}

// Parse PowerShell output to extract findings
function parsePowerShellOutput(output: string, scriptName: string): Finding[] {
  const findings: Finding[] = [];
  
  // Example parsing logic - would need to be customized based on actual script output
  if (scriptName.includes('AzureAD')) {
    // Check for MFA findings
    if (output.includes('StrongAuthenticationMethods.Count -eq 0')) {
      const mfaMatch = output.match(/Count:\s*(\d+)\s*users without MFA/);
      const adminMatch = output.match(/Found:\s*(\d+)\s*admin accounts without MFA/);
      
      if (mfaMatch || adminMatch) {
        findings.push({
          id: 'AAD-001',
          severity: 'critical',
          title: 'Multi-Factor Authentication Not Enforced',
          description: `Multi-factor authentication is not enforced for ${mfaMatch?.[1] || 'many'} user accounts, including ${adminMatch?.[1] || 'some'} administrative accounts.`,
          service: 'Azure AD',
          category: 'Identity & Access',
          evidence: output.substring(0, 500),
          impact: [
            'High risk of account compromise and data breach',
            'Average breach cost: $4.45M (IBM Security Report 2023)',
            'Compliance violation for GDPR, HIPAA, SOX requirements',
            `${adminMatch?.[1] || 'Multiple'} admin accounts could provide full tenant access if compromised`
          ],
          remediation: [
            'Enable MFA for all admin accounts immediately',
            'Enable MFA for all users with licenses within 1 week',
            'Configure Conditional Access policies',
            'Monitor MFA adoption and enforce compliance'
          ]
        });
      }
    }
    
    // Check for legacy auth
    if (output.includes('legacy auth') || output.includes('SmtpClientAuthenticationDisabled')) {
      findings.push({
        id: 'AAD-002',
        severity: 'high',
        title: 'Legacy Authentication Protocols Enabled',
        description: 'Legacy authentication protocols are enabled, allowing connections that bypass modern security controls.',
        service: 'Azure AD',
        category: 'Authentication',
        evidence: output.substring(0, 500),
        impact: [
          'Security controls can be bypassed',
          'MFA and Conditional Access policies ineffective',
          'Increased risk of password spray attacks'
        ],
        remediation: [
          'Audit current legacy authentication usage',
          'Create Conditional Access policy to block legacy auth',
          'Migrate users to modern authentication methods',
          'Monitor and disable legacy protocols'
        ]
      });
    }
  }
  
  // Add more parsing logic for other services
  if (scriptName.includes('Exchange')) {
    // Parse Exchange-specific findings
  }
  
  if (scriptName.includes('SharePoint')) {
    // Parse SharePoint-specific findings
  }
  
  return findings;
}

// Calculate metrics based on findings
function calculateMetrics(findings: Finding[]): Metrics {
  const criticalFindings = findings.filter(f => f.severity === 'critical').length;
  const highFindings = findings.filter(f => f.severity === 'high').length;
  const mediumFindings = findings.filter(f => f.severity === 'medium').length;
  const lowFindings = findings.filter(f => f.severity === 'low').length;
  
  // Calculate risk score (weighted by severity)
  const totalWeight = criticalFindings * 10 + highFindings * 5 + mediumFindings * 2 + lowFindings * 1;
  const maxWeight = findings.length * 10; // If all were critical
  const riskScore = maxWeight > 0 ? Math.round((totalWeight / maxWeight) * 100) : 0;
  
  // Calculate compliance score (inverse of risk with adjustments)
  const complianceScore = Math.max(0, Math.min(100, 100 - riskScore + 10));
  
  return {
    riskScore,
    complianceScore,
    totalFindings: findings.length,
    criticalFindings,
    highFindings,
    mediumFindings,
    lowFindings
  };
}

export const GET: APIRoute = async ({ url }) => {
  try {
    const reportId = url.searchParams.get('id');
    const assessmentType = url.searchParams.get('type') || 'full';
    const useCache = url.searchParams.get('cache') !== 'false';
    
    // Check for cached results first
    if (useCache && reportId) {
      // In a real implementation, check a database or file system for cached results
      // For now, we'll simulate with some demo data
    }
    
    // Run assessment using MCP server
    const assessmentResult = await executeMCPCommand('sequential-thinking', 'run_assessment', {
      type: assessmentType,
      parameters: {
        TenantId: url.searchParams.get('tenantId') || 'demo-tenant',
        IncludeScreenshots: true,
        ExportResults: true
      }
    });
    
    // Parse results and extract findings
    const allFindings: Finding[] = [];
    const evidence: Evidence[] = [];
    
    for (const scriptResult of assessmentResult.results) {
      if (scriptResult.success && scriptResult.stdout) {
        const scriptFindings = parsePowerShellOutput(scriptResult.stdout, scriptResult.script);
        allFindings.push(...scriptFindings);
        
        // Add PowerShell evidence
        evidence.push({
          id: `ps-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          type: 'powershell',
          name: scriptResult.script.split('/').pop() || 'Unknown Script',
          timestamp: new Date(scriptResult.timestamp * 1000).toISOString(),
          content: scriptResult.stdout
        });
      }
    }
    
    // Calculate metrics
    const metrics = calculateMetrics(allFindings);
    
    // Build assessment result
    const result: AssessmentResult = {
      id: reportId || `ASSESS-${Date.now()}`,
      type: assessmentType,
      organization: url.searchParams.get('org') || 'Unknown Organization',
      timestamp: new Date().toISOString(),
      findings: allFindings,
      metrics,
      evidence,
      rawData: assessmentResult
    };
    
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache'
      }
    });
    
  } catch (error) {
    console.error('Assessment error:', error);
    
    // Return demo data as fallback
    const demoData: AssessmentResult = {
      id: 'DEMO-001',
      type: 'demo',
      organization: 'Demo Organization',
      timestamp: new Date().toISOString(),
      findings: [
        {
          id: 'DEMO-AAD-001',
          severity: 'critical',
          title: 'Multi-Factor Authentication Not Enforced (Demo)',
          description: 'This is demo data. In a real assessment, this would show actual MFA status from your tenant.',
          service: 'Azure AD',
          category: 'Identity & Access',
          evidence: 'Demo evidence: Get-MsolUser -All | Where {$_.StrongAuthenticationMethods.Count -eq 0}',
          impact: ['Demo impact: High risk of account compromise'],
          remediation: ['Demo remediation: Enable MFA for all users']
        }
      ],
      metrics: {
        riskScore: 75,
        complianceScore: 85,
        totalFindings: 1,
        criticalFindings: 1,
        highFindings: 0,
        mediumFindings: 0,
        lowFindings: 0
      },
      evidence: [
        {
          id: 'demo-ps-001',
          type: 'powershell',
          name: 'Demo PowerShell Output',
          timestamp: new Date().toISOString(),
          content: 'Demo PowerShell output would appear here'
        }
      ]
    };
    
    return new Response(JSON.stringify(demoData), {
      status: 200,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const { scripts, parameters } = body;
    
    // Execute scripts in parallel using MCP
    const results = await executeMCPCommand('sequential-thinking', 'execute_parallel', {
      scripts,
      parameters
    });
    
    return new Response(JSON.stringify({ success: true, results }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ 
      success: false, 
      error: error instanceof Error ? error.message : 'Unknown error' 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
};