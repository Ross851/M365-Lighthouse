/**
 * Authentication Check API
 * Returns user role and permissions
 */

import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ request }) => {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    // No token = client access
    return new Response(JSON.stringify({
      authenticated: false,
      role: 'client',
      permissions: [
        'view-reports',
        'download-reports',
        'view-dashboards'
      ]
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  // Validate developer token
  try {
    // In production, validate against your auth system
    const isValidDeveloper = token.startsWith('dev-') || token.startsWith('admin-');
    
    if (isValidDeveloper) {
      return new Response(JSON.stringify({
        authenticated: true,
        role: 'developer',
        permissions: [
          'assessment-execution',
          'script-management',
          'database-access',
          'settings-management',
          'view-reports',
          'download-reports'
        ]
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      authenticated: false,
      role: 'client',
      permissions: ['view-reports', 'download-reports']
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Invalid token',
      role: 'client'
    }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};