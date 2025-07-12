/**
 * Authentication Helper for PowerReview
 * Manages developer vs client access
 */

export interface AuthUser {
  email: string;
  role: 'developer' | 'client' | 'admin';
  permissions: string[];
  organization?: string;
  token?: string;
}

export class AuthHelper {
  private static readonly DEVELOPER_FEATURES = [
    'assessment-execution',
    'script-management', 
    'database-access',
    'settings-management',
    'user-management',
    'api-access'
  ];
  
  private static readonly CLIENT_FEATURES = [
    'view-reports',
    'download-reports',
    'view-dashboards',
    'view-recommendations'
  ];
  
  /**
   * Check if user is authenticated as developer
   */
  static isDeveloper(): boolean {
    const auth = this.getAuth();
    return auth?.role === 'developer' || auth?.role === 'admin';
  }
  
  /**
   * Check if user is a client (no auth required)
   */
  static isClient(): boolean {
    const auth = this.getAuth();
    return !auth || auth.role === 'client';
  }
  
  /**
   * Get current authentication
   */
  static getAuth(): AuthUser | null {
    try {
      const authStr = localStorage.getItem('powerreview_auth');
      if (!authStr) return null;
      
      const auth = JSON.parse(authStr);
      return auth;
    } catch {
      return null;
    }
  }
  
  /**
   * Set authentication (for developers only)
   */
  static setAuth(user: AuthUser): void {
    localStorage.setItem('powerreview_auth', JSON.stringify(user));
  }
  
  /**
   * Clear authentication
   */
  static clearAuth(): void {
    localStorage.removeItem('powerreview_auth');
  }
  
  /**
   * Check if user has permission for a feature
   */
  static hasPermission(feature: string): boolean {
    const auth = this.getAuth();
    
    // Clients have access to client features without auth
    if (this.CLIENT_FEATURES.includes(feature)) {
      return true;
    }
    
    // Developer features require authentication
    if (this.DEVELOPER_FEATURES.includes(feature)) {
      return this.isDeveloper();
    }
    
    // Check specific permissions
    return auth?.permissions?.includes(feature) || false;
  }
  
  /**
   * Get accessible routes based on user role
   */
  static getAccessibleRoutes(): string[] {
    if (this.isDeveloper()) {
      return [
        '/executive-dashboard',
        '/assessment',
        '/assessment-execution',
        '/ai-assistant',
        '/reports',
        '/settings',
        '/threat-monitoring',
        '/security-hardening',
        '/preflight',
        '/results'
      ];
    } else {
      // Clients can access these without login
      return [
        '/reports',
        '/executive-dashboard',
        '/sample-reports',
        '/documentation',
        '/home'
      ];
    }
  }
  
  /**
   * Redirect based on authentication status
   */
  static redirectToAppropriateRoute(): string {
    if (this.isDeveloper()) {
      return '/assessment';
    } else {
      return '/reports';
    }
  }
  
  /**
   * Create a client access token for report viewing
   */
  static createClientAccess(reportId: string, organizationId: string): string {
    const clientToken = {
      type: 'client-access',
      reportId,
      organizationId,
      created: Date.now(),
      expires: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 days
    };
    
    return btoa(JSON.stringify(clientToken));
  }
  
  /**
   * Validate client access token
   */
  static validateClientAccess(token: string): boolean {
    try {
      const decoded = JSON.parse(atob(token));
      return decoded.type === 'client-access' && decoded.expires > Date.now();
    } catch {
      return false;
    }
  }
}