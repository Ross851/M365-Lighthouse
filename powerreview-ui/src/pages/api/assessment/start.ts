import type { APIRoute } from 'astro';
import { withAuth } from '../../../lib/auth-middleware';
import { getSessionManager } from '../../../lib/session-manager';
import { getPowerShellExecutor } from '../../../lib/powershell-executor';
import { getWebSocketServer } from '../../../lib/websocket-server';

export const POST: APIRoute = withAuth(async ({ request, user }) => {
  try {
    const { assessments, config } = await request.json();
    
    // Validate inputs
    if (!assessments || !Array.isArray(assessments) || assessments.length === 0) {
      return new Response(JSON.stringify({ 
        error: 'At least one assessment must be selected' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (!config?.tenant) {
      return new Response(JSON.stringify({ 
        error: 'Tenant configuration is required' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Create session
    const sessionManager = getSessionManager();
    const session = await sessionManager.createSession(
      user!.email,
      user!.name,
      config.tenant,
      assessments
    );

    // Start the assessment execution
    const executor = getPowerShellExecutor();
    const wsServer = getWebSocketServer();

    // Notify WebSocket clients
    wsServer.sendToSession(session.id, {
      type: 'session-created',
      session: {
        id: session.id,
        assessments,
        tenant: config.tenant,
        status: 'starting'
      }
    });

    // Update session status
    await sessionManager.updateSession(session.id, { status: 'running' });

    // Execute PowerShell script asynchronously
    executor.execute({
      sessionId: session.id,
      script: 'PowerReview-WebBridge.ps1',
      parameters: {
        SessionId: session.id,
        ConfigJson: JSON.stringify({
          TenantName: config.tenant,
          SharePointUrl: config.sharepointUrl || '',
          ExchangeUrl: config.exchangeUrl || '',
          Assessments: assessments,
          OutputPath: session.outputPath
        })
      },
      streamOutput: true,
      timeout: 30 * 60 * 1000 // 30 minutes timeout
    }).then(async (result) => {
      // Assessment completed successfully
      console.log(`Assessment ${session.id} completed successfully`);
      
      // Parse results if available
      let assessmentResults;
      try {
        const resultsPath = `${session.outputPath}/results.json`;
        const fs = await import('fs/promises');
        const resultsData = await fs.readFile(resultsPath, 'utf-8');
        const parsedResults = JSON.parse(resultsData);
        
        assessmentResults = {
          overallScore: parsedResults.overallScore || 0,
          issuesFound: parsedResults.totalIssues || 0,
          recommendations: parsedResults.recommendations?.length || 0,
          criticalFindings: parsedResults.criticalFindings || 0
        };
      } catch (error) {
        console.error('Failed to parse results:', error);
      }

      await sessionManager.completeSession(session.id, assessmentResults);
      
      // Notify WebSocket clients
      wsServer.sendToSession(session.id, {
        type: 'session-completed',
        sessionId: session.id,
        results: assessmentResults
      });
    }).catch(async (error) => {
      // Assessment failed
      console.error(`Assessment ${session.id} failed:`, error);
      await sessionManager.failSession(session.id, error.message);
      
      // Notify WebSocket clients
      wsServer.sendToSession(session.id, {
        type: 'session-failed',
        sessionId: session.id,
        error: error.message
      });
    });

    // Return immediate response
    return new Response(JSON.stringify({ 
      success: true,
      sessionId: session.id,
      message: 'Assessment started successfully',
      websocketUrl: `ws://localhost:8080`,
      session: {
        id: session.id,
        status: session.status,
        assessments: session.assessments,
        tenant: session.tenantName
      }
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Start assessment error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to start assessment',
      details: error instanceof Error ? error.message : 'Unknown error'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}, 'execute.scripts');