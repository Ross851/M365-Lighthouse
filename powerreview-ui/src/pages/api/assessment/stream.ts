import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ request, url }) => {
  const sessionId = url.searchParams.get('sessionId');
  
  if (!sessionId) {
    return new Response('Session ID required', { status: 400 });
  }
  
  // Set up Server-Sent Events
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      // Send initial connection message
      controller.enqueue(encoder.encode(`data: ${JSON.stringify({
        type: 'connected',
        message: 'Connected to assessment stream'
      })}\n\n`));
      
      // Simulate assessment progress
      const assessmentSteps = [
        { type: 'log', message: '[INFO] Initializing PowerReview Security Assessment Framework v2.0' },
        { type: 'log', message: '[INFO] Connecting to Microsoft 365 tenant...' },
        { type: 'progress', assessment: 'azuread', status: 'starting' },
        { type: 'log', message: '[SUCCESS] Connected to tenant: contoso.onmicrosoft.com' },
        { type: 'metric', name: 'users-scanned', value: 245 },
        { type: 'log', message: '[INFO] Scanning Azure AD configuration...' },
        { type: 'log', message: '[WARN] Found 12 users without MFA enabled' },
        { type: 'metric', name: 'issues-found', value: 12 },
        { type: 'progress', assessment: 'azuread', status: 'completed', duration: '15:23' },
        { type: 'progress', assessment: 'exchange', status: 'starting' },
        { type: 'log', message: '[INFO] Analyzing Exchange Online policies...' },
        { type: 'metric', name: 'policies-checked', value: 47 },
        { type: 'log', message: '[SUCCESS] ATP policies configured correctly' },
        { type: 'metric', name: 'secure-score', value: 75 },
        { type: 'progress', assessment: 'exchange', status: 'completed', duration: '20:45' },
        { type: 'complete', message: 'Assessment completed successfully' }
      ];
      
      // Send updates periodically
      for (const step of assessmentSteps) {
        await new Promise(resolve => setTimeout(resolve, 2000)); // 2 second delay
        
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(step)}\n\n`));
        
        if (step.type === 'complete') {
          controller.close();
          break;
        }
      }
    }
  });
  
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*'
    }
  });
};