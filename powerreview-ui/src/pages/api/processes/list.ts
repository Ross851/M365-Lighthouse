import type { APIRoute } from 'astro';
import { withAuth } from '../../../lib/auth-middleware';
import { getPowerShellExecutor } from '../../../lib/powershell-executor';

export const GET: APIRoute = withAuth(async ({ user }) => {
  try {
    const executor = getPowerShellExecutor();
    const processes = executor.getActiveProcesses();

    // Filter by user if not admin
    let filteredProcesses = processes;
    if (user!.role !== 'admin') {
      // Would need to check session ownership for each process
      // For now, non-admins see all their processes
      filteredProcesses = processes; // TODO: Add session ownership check
    }

    return new Response(JSON.stringify({
      success: true,
      processes: filteredProcesses,
      count: filteredProcesses.length
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('List processes error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to retrieve processes' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}, 'execute.scripts');