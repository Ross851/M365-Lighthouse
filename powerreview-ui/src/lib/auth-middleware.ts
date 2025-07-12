import jwt from 'jsonwebtoken';
import type { APIContext } from 'astro';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

export interface AuthUser {
  email: string;
  name: string;
  role: string;
}

export interface AuthContext extends APIContext {
  user?: AuthUser;
}

// Role-based permissions
export const PERMISSIONS = {
  admin: [
    'execute.scripts',
    'view.all.sessions',
    'terminate.sessions',
    'manage.users',
    'view.logs',
    'export.reports'
  ],
  developer: [
    'execute.scripts',
    'view.own.sessions',
    'terminate.own.sessions',
    'view.logs',
    'export.reports'
  ],
  viewer: [
    'view.own.sessions',
    'export.reports'
  ]
} as const;

export function verifyToken(token: string): AuthUser | null {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    return {
      email: decoded.email,
      name: decoded.name,
      role: decoded.role
    };
  } catch (error) {
    return null;
  }
}

export function hasPermission(user: AuthUser, permission: string): boolean {
  const rolePermissions = PERMISSIONS[user.role as keyof typeof PERMISSIONS];
  return rolePermissions ? rolePermissions.includes(permission as any) : false;
}

export async function requireAuth(
  context: APIContext,
  requiredPermission?: string
): Promise<AuthUser> {
  const authHeader = context.request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Response(JSON.stringify({ error: 'Authorization header required' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  const token = authHeader.substring(7);
  const user = verifyToken(token);

  if (!user) {
    throw new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Check permission if specified
  if (requiredPermission && !hasPermission(user, requiredPermission)) {
    throw new Response(JSON.stringify({ 
      error: 'Insufficient permissions',
      required: requiredPermission,
      userRole: user.role
    }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Add user to context
  (context as AuthContext).user = user;
  
  return user;
}

// Middleware wrapper for API routes
export function withAuth(
  handler: (context: AuthContext) => Promise<Response>,
  requiredPermission?: string
) {
  return async (context: APIContext) => {
    try {
      const user = await requireAuth(context, requiredPermission);
      (context as AuthContext).user = user;
      return handler(context as AuthContext);
    } catch (error) {
      if (error instanceof Response) {
        return error;
      }
      return new Response(JSON.stringify({ error: 'Authentication failed' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  };
}

// Session ownership verification
export function verifySessionOwnership(
  user: AuthUser,
  sessionId: string,
  sessionUserId: string
): boolean {
  // Admins can access all sessions
  if (user.role === 'admin') {
    return true;
  }
  
  // Other users can only access their own sessions
  return user.email === sessionUserId;
}