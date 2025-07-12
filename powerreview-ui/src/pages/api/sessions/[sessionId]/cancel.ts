import type { APIRoute } from 'astro';
import { withAuth, verifySessionOwnership } from '../../../../lib/auth-middleware';
import { getSessionManager } from '../../../../lib/session-manager';
import { getPowerShellExecutor } from '../../../../lib/powershell-executor';
import { getWebSocketServer } from '../../../../lib/websocket-server';

export const POST: APIRoute = withAuth(async ({ params, user }) => {
  try {
    const sessionId = params.sessionId;
    if (!sessionId) {
      return new Response(JSON.stringify({ 
        error: 'Session ID is required' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const sessionManager = getSessionManager();
    const session = sessionManager.getSession(sessionId);

    if (!session) {
      return new Response(JSON.stringify({ 
        error: 'Session not found' 
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Verify ownership
    if (!verifySessionOwnership(user!, sessionId, session.userId)) {
      return new Response(JSON.stringify({ 
        error: 'Access denied' 
      }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Check if session can be cancelled
    if (session.status !== 'running' && session.status !== 'pending') {
      return new Response(JSON.stringify({ 
        error: 'Session cannot be cancelled in current state',
        currentStatus: session.status
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Terminate PowerShell processes
    const executor = getPowerShellExecutor();
    await executor.terminateSession(sessionId);

    // Update session status
    await sessionManager.cancelSession(sessionId);

    // Notify WebSocket clients
    const wsServer = getWebSocketServer();
    wsServer.sendToSession(sessionId, {
      type: 'session-cancelled',
      sessionId,
      timestamp: new Date().toISOString()
    });

    return new Response(JSON.stringify({
      success: true,
      message: 'Session cancelled successfully',
      sessionId
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Cancel session error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to cancel session' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}, 'terminate.own.sessions');