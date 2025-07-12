import type { APIRoute } from 'astro';
import { withAuth } from '../../../lib/auth-middleware';
import { getSessionManager } from '../../../lib/session-manager';

export const GET: APIRoute = withAuth(async ({ url, user }) => {
  try {
    const sessionManager = getSessionManager();
    
    // Check if requesting all sessions (admin only)
    const all = url.searchParams.get('all') === 'true';
    
    let sessions;
    if (all && user!.role === 'admin') {
      sessions = sessionManager.getAllSessions();
    } else {
      sessions = sessionManager.getUserSessions(user!.email);
    }

    // Optional status filter
    const status = url.searchParams.get('status');
    if (status) {
      sessions = sessions.filter(s => s.status === status);
    }

    // Return sessions with limited information for security
    const sanitizedSessions = sessions.map(session => ({
      id: session.id,
      userName: session.userName,
      tenantName: session.tenantName,
      assessments: session.assessments,
      status: session.status,
      startTime: session.startTime,
      endTime: session.endTime,
      progress: session.progress,
      results: session.results,
      error: session.error
    }));

    return new Response(JSON.stringify({
      success: true,
      sessions: sanitizedSessions,
      count: sanitizedSessions.length
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('List sessions error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to retrieve sessions' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}, 'view.own.sessions');