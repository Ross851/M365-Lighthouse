import type { APIRoute } from 'astro';
import { withAuth, verifySessionOwnership } from '../../../../lib/auth-middleware';
import { getSessionManager } from '../../../../lib/session-manager';
import path from 'path';
import fs from 'fs/promises';

export const GET: APIRoute = withAuth(async ({ params, url, user }) => {
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

    // Get log type
    const logType = url.searchParams.get('type') || 'execution';
    const validLogTypes = ['execution', 'errors', 'stream', 'output'];
    
    if (!validLogTypes.includes(logType)) {
      return new Response(JSON.stringify({ 
        error: 'Invalid log type',
        validTypes: validLogTypes
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Construct log file path
    const logFiles: Record<string, string> = {
      execution: 'execution.log',
      errors: 'errors.log',
      stream: 'stream.log',
      output: 'output.json'
    };

    const logPath = path.join(session.outputPath, logFiles[logType]);

    try {
      // Check if file exists
      await fs.access(logPath);
      
      // Read log content
      const content = await fs.readFile(logPath, 'utf-8');
      
      // Parse if JSON
      let parsedContent = content;
      if (logType === 'output' || logType === 'stream') {
        try {
          parsedContent = JSON.parse(content);
        } catch {
          // Keep as string if not valid JSON
        }
      }

      return new Response(JSON.stringify({
        success: true,
        sessionId,
        logType,
        content: parsedContent,
        size: content.length,
        lastModified: (await fs.stat(logPath)).mtime
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      // File doesn't exist yet
      return new Response(JSON.stringify({
        success: true,
        sessionId,
        logType,
        content: '',
        size: 0,
        message: 'Log file not yet created'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  } catch (error) {
    console.error('Get logs error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to retrieve logs' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}, 'view.logs');