import type { APIRoute } from 'astro';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import fs from 'fs/promises';

const execAsync = promisify(exec);

export const POST: APIRoute = async ({ request }) => {
  try {
    const { assessments, config } = await request.json();
    
    // Validate authentication (in production, verify JWT)
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Create a unique session ID
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const outputPath = path.join(process.cwd(), 'assessment-outputs', sessionId);
    
    // Create output directory
    await fs.mkdir(outputPath, { recursive: true });
    
    // Build PowerShell command
    const scriptPath = path.join(process.cwd(), '..', 'PowerReview-Complete.ps1');
    const assessmentList = assessments.join(',');
    
    const psCommand = `
      $config = @{
        TenantName = '${config.tenant}'
        SharePointUrl = '${config.sharepointUrl}'
        ExchangeUrl = '${config.exchangeUrl}'
        OutputPath = '${outputPath}'
        Assessments = '${assessmentList}'.Split(',')
      }
      
      & '${scriptPath}' -Config $config -OutputFormat JSON
    `;
    
    // Start the assessment in background
    exec(`powershell -ExecutionPolicy Bypass -Command "${psCommand}"`, {
      cwd: path.join(process.cwd(), '..')
    }, (error, stdout, stderr) => {
      // This runs async - we'll track progress separately
      if (error) {
        console.error('Assessment error:', error);
      }
    });
    
    return new Response(JSON.stringify({ 
      success: true,
      sessionId,
      message: 'Assessment started successfully'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Start assessment error:', error);
    return new Response(JSON.stringify({ error: 'Failed to start assessment' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};