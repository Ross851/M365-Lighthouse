/**
 * Production Authentication & Authorization Service
 * Azure AD integration with role-based access control (RBAC)
 * Multi-factor authentication and session management
 */

import { sign, verify, JwtPayload } from 'jsonwebtoken';
import { createHash, randomBytes, timingSafeEqual } from 'crypto';
import { Client } from '@microsoft/microsoft-graph-client';
import { AuthenticationProvider } from '@microsoft/microsoft-graph-client';

interface AuthConfig {
  // Azure AD Configuration
  azureAd: {
    tenantId: string;
    clientId: string;
    clientSecret: string;
    redirectUri: string;
    scopes: string[];
  };
  
  // JWT Configuration
  jwt: {
    secret: string;
    issuer: string;
    audience: string;
    expiresIn: string;
    refreshExpiresIn: string;
  };
  
  // Session Configuration
  session: {
    maxDurationHours: number;
    idleTimeoutMinutes: number;
    maxConcurrentSessions: number;
    requireMfa: boolean;
  };
  
  // Security Configuration
  security: {
    passwordPolicy: {
      minLength: number;
      requireUppercase: boolean;
      requireLowercase: boolean;
      requireNumbers: boolean;
      requireSpecialChars: boolean;
    };
    
    lockout: {
      maxFailedAttempts: number;
      lockoutDurationMinutes: number;
      resetTimeMinutes: number;
    };
    
    encryption: {
      saltRounds: number;
      keyDerivationIterations: number;
    };
  };
}

interface User {
  userId: string;
  username: string;
  email: string;
  displayName: string;
  azureAdObjectId: string;
  authProvider: 'AzureAD' | 'Local';
  
  // Security settings
  mfaEnabled: boolean;
  mfaSecret?: string;
  lastLogin?: Date;
  failedLoginAttempts: number;
  accountLockedUntil?: Date;
  
  // Access control
  isActive: boolean;
  isAdmin: boolean;
  allowedRegions: string[];
  roles: UserRole[];
  
  // Audit fields
  createdAt: Date;
  updatedAt: Date;
  lastPasswordChange?: Date;
}

interface UserRole {
  roleId: string;
  roleName: string;
  permissions: string[];
  clientId?: string; // null for global roles
  allowedRegions?: string[]; // null for all regions
  validFrom: Date;
  validUntil?: Date; // null for permanent
}

interface AuthSession {
  sessionId: string;
  userId: string;
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
  lastActivity: Date;
  ipAddress: string;
  userAgent: string;
  mfaVerified: boolean;
  permissions: string[];
  allowedClients: string[];
  allowedRegions: string[];
}

interface LoginRequest {
  username: string;
  password: string;
  mfaCode?: string;
  ipAddress: string;
  userAgent: string;
}

interface LoginResponse {
  success: boolean;
  sessionId?: string;
  accessToken?: string;
  refreshToken?: string;
  user?: Partial<User>;
  requiresMfa?: boolean;
  error?: string;
  lockoutRemaining?: number;
}

interface PermissionContext {
  userId: string;
  clientId?: string;
  regionCode?: string;
  resourceType?: string;
  action: 'read' | 'write' | 'admin' | 'audit' | 'export';
}

export class ProductionAuthService {
  private config: AuthConfig;
  private activeSessions = new Map<string, AuthSession>();
  private sessionCleanupInterval: NodeJS.Timeout;
  private graphClient: Client;

  constructor(config: AuthConfig) {
    this.config = config;
    this.initializeGraphClient();
    this.startSessionCleanup();
  }

  /**
   * Initialize Microsoft Graph client for Azure AD integration
   */
  private initializeGraphClient(): void {
    const authProvider: AuthenticationProvider = {
      getAccessToken: async () => {
        // Implement Azure AD app-only authentication
        const tokenEndpoint = `https://login.microsoftonline.com/${this.config.azureAd.tenantId}/oauth2/v2.0/token`;
        
        const params = new URLSearchParams({
          client_id: this.config.azureAd.clientId,
          client_secret: this.config.azureAd.clientSecret,
          scope: 'https://graph.microsoft.com/.default',
          grant_type: 'client_credentials'
        });

        const response = await fetch(tokenEndpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: params
        });

        const data = await response.json();
        return data.access_token;
      }
    };

    this.graphClient = Client.initWithMiddleware({ authProvider });
  }

  /**
   * Authenticate user with Azure AD
   */
  async authenticateWithAzureAd(authCode: string, ipAddress: string, userAgent: string): Promise<LoginResponse> {
    try {
      // Exchange authorization code for tokens
      const tokenResponse = await this.exchangeCodeForTokens(authCode);
      
      if (!tokenResponse.success) {
        return { success: false, error: 'Failed to exchange authorization code' };
      }

      // Get user info from Azure AD
      const userInfo = await this.getUserFromAzureAd(tokenResponse.accessToken!);
      
      if (!userInfo) {
        return { success: false, error: 'Failed to retrieve user information' };
      }

      // Find or create user in our system
      let user = await this.findUserByAzureId(userInfo.id);
      
      if (!user) {
        user = await this.createUserFromAzureAd(userInfo);
      } else {
        // Update user info from Azure AD
        await this.updateUserFromAzureAd(user.userId, userInfo);
      }

      // Check if account is locked
      if (user.accountLockedUntil && user.accountLockedUntil > new Date()) {
        const remainingMinutes = Math.ceil((user.accountLockedUntil.getTime() - Date.now()) / (1000 * 60));
        return { 
          success: false, 
          error: 'Account is locked',
          lockoutRemaining: remainingMinutes
        };
      }

      // Check if MFA is required
      if (this.config.session.requireMfa && !user.mfaEnabled) {
        return {
          success: false,
          requiresMfa: true,
          error: 'Multi-factor authentication setup required'
        };
      }

      // Create session
      const session = await this.createSession(user, ipAddress, userAgent);
      
      // Log successful login
      await this.logAuthEvent('LOGIN_SUCCESS', user.userId, ipAddress, userAgent);
      
      return {
        success: true,
        sessionId: session.sessionId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: this.sanitizeUserForResponse(user)
      };

    } catch (error) {
      await this.logAuthEvent('LOGIN_ERROR', undefined, ipAddress, userAgent, 
        error instanceof Error ? error.message : 'Unknown error');
      
      return { 
        success: false, 
        error: 'Authentication failed' 
      };
    }
  }

  /**
   * Authenticate user with username/password (local auth)
   */
  async authenticateLocal(request: LoginRequest): Promise<LoginResponse> {
    try {
      // Find user by username
      const user = await this.findUserByUsername(request.username);
      
      if (!user) {
        await this.logAuthEvent('LOGIN_FAILED_USER_NOT_FOUND', undefined, request.ipAddress, request.userAgent);
        return { success: false, error: 'Invalid credentials' };
      }

      // Check if account is locked
      if (user.accountLockedUntil && user.accountLockedUntil > new Date()) {
        const remainingMinutes = Math.ceil((user.accountLockedUntil.getTime() - Date.now()) / (1000 * 60));
        return { 
          success: false, 
          error: 'Account is locked',
          lockoutRemaining: remainingMinutes
        };
      }

      // Verify password
      const passwordValid = await this.verifyPassword(request.password, user.userId);
      
      if (!passwordValid) {
        // Increment failed attempts
        await this.incrementFailedAttempts(user.userId);
        
        await this.logAuthEvent('LOGIN_FAILED_INVALID_PASSWORD', user.userId, request.ipAddress, request.userAgent);
        return { success: false, error: 'Invalid credentials' };
      }

      // Verify MFA if enabled
      if (user.mfaEnabled) {
        if (!request.mfaCode) {
          return { success: false, requiresMfa: true };
        }
        
        const mfaValid = await this.verifyMfaCode(user.userId, request.mfaCode);
        if (!mfaValid) {
          await this.logAuthEvent('LOGIN_FAILED_INVALID_MFA', user.userId, request.ipAddress, request.userAgent);
          return { success: false, error: 'Invalid MFA code' };
        }
      }

      // Reset failed attempts on successful login
      await this.resetFailedAttempts(user.userId);

      // Create session
      const session = await this.createSession(user, request.ipAddress, request.userAgent);
      
      // Log successful login
      await this.logAuthEvent('LOGIN_SUCCESS', user.userId, request.ipAddress, request.userAgent);
      
      return {
        success: true,
        sessionId: session.sessionId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: this.sanitizeUserForResponse(user)
      };

    } catch (error) {
      await this.logAuthEvent('LOGIN_ERROR', undefined, request.ipAddress, request.userAgent,
        error instanceof Error ? error.message : 'Unknown error');
      
      return { 
        success: false, 
        error: 'Authentication failed' 
      };
    }
  }

  /**
   * Create a new authenticated session
   */
  private async createSession(user: User, ipAddress: string, userAgent: string): Promise<AuthSession> {
    const sessionId = randomBytes(32).toString('hex');
    
    // Generate JWT tokens
    const tokenPayload = {
      userId: user.userId,
      username: user.username,
      email: user.email,
      sessionId,
      permissions: this.getAllUserPermissions(user),
      allowedClients: this.getAllowedClients(user),
      allowedRegions: user.allowedRegions
    };

    const accessToken = sign(tokenPayload, this.config.jwt.secret, {
      issuer: this.config.jwt.issuer,
      audience: this.config.jwt.audience,
      expiresIn: this.config.jwt.expiresIn,
      algorithm: 'HS256'
    });

    const refreshToken = sign(
      { userId: user.userId, sessionId, type: 'refresh' },
      this.config.jwt.secret,
      {
        issuer: this.config.jwt.issuer,
        audience: this.config.jwt.audience,
        expiresIn: this.config.jwt.refreshExpiresIn,
        algorithm: 'HS256'
      }
    );

    const session: AuthSession = {
      sessionId,
      userId: user.userId,
      accessToken,
      refreshToken,
      expiresAt: new Date(Date.now() + this.config.session.maxDurationHours * 60 * 60 * 1000),
      lastActivity: new Date(),
      ipAddress,
      userAgent,
      mfaVerified: user.mfaEnabled ? true : false,
      permissions: tokenPayload.permissions,
      allowedClients: tokenPayload.allowedClients,
      allowedRegions: user.allowedRegions
    };

    // Store session
    this.activeSessions.set(sessionId, session);

    // Limit concurrent sessions
    await this.enforceSessionLimits(user.userId);

    // Update user last login
    await this.updateUserLastLogin(user.userId);

    return session;
  }

  /**
   * Validate access token and return session
   */
  async validateToken(token: string): Promise<{ valid: boolean; session?: AuthSession; error?: string }> {
    try {
      // Verify JWT token
      const decoded = verify(token, this.config.jwt.secret, {
        issuer: this.config.jwt.issuer,
        audience: this.config.jwt.audience,
        algorithms: ['HS256']
      }) as JwtPayload;

      const sessionId = decoded.sessionId as string;
      const session = this.activeSessions.get(sessionId);

      if (!session) {
        return { valid: false, error: 'Session not found' };
      }

      // Check if session has expired
      if (session.expiresAt < new Date()) {
        this.activeSessions.delete(sessionId);
        return { valid: false, error: 'Session expired' };
      }

      // Check idle timeout
      const idleTimeoutMs = this.config.session.idleTimeoutMinutes * 60 * 1000;
      if (Date.now() - session.lastActivity.getTime() > idleTimeoutMs) {
        this.activeSessions.delete(sessionId);
        return { valid: false, error: 'Session idle timeout' };
      }

      // Update last activity
      session.lastActivity = new Date();

      return { valid: true, session };

    } catch (error) {
      return { 
        valid: false, 
        error: error instanceof Error ? error.message : 'Token validation failed' 
      };
    }
  }

  /**
   * Check if user has permission for specific action
   */
  async checkPermission(context: PermissionContext): Promise<boolean> {
    try {
      const user = await this.findUserById(context.userId);
      if (!user || !user.isActive) {
        return false;
      }

      // Admin users have all permissions
      if (user.isAdmin) {
        return true;
      }

      // Check role-based permissions
      const requiredPermission = this.buildPermissionString(context);
      const userPermissions = this.getAllUserPermissions(user);

      // Check exact permission match
      if (userPermissions.includes(requiredPermission)) {
        return true;
      }

      // Check wildcard permissions
      const wildcardPermissions = [
        `${context.action}:all`,
        'admin:all',
        '*:all'
      ];

      return wildcardPermissions.some(perm => userPermissions.includes(perm));

    } catch (error) {
      console.error('Permission check failed:', error);
      return false;
    }
  }

  /**
   * Build permission string from context
   */
  private buildPermissionString(context: PermissionContext): string {
    let permission = context.action;
    
    if (context.clientId) {
      permission += `:client:${context.clientId}`;
    }
    
    if (context.regionCode) {
      permission += `:region:${context.regionCode}`;
    }
    
    if (context.resourceType) {
      permission += `:${context.resourceType}`;
    }

    return permission;
  }

  /**
   * Get all permissions for a user
   */
  private getAllUserPermissions(user: User): string[] {
    const permissions = new Set<string>();

    user.roles.forEach(role => {
      role.permissions.forEach(permission => {
        permissions.add(permission);
      });
    });

    return Array.from(permissions);
  }

  /**
   * Get allowed clients for a user
   */
  private getAllowedClients(user: User): string[] {
    const clients = new Set<string>();

    user.roles.forEach(role => {
      if (role.clientId) {
        clients.add(role.clientId);
      }
    });

    // If no specific clients, return empty array (admin users get access via permissions)
    return Array.from(clients);
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshToken(refreshToken: string): Promise<{ success: boolean; accessToken?: string; error?: string }> {
    try {
      const decoded = verify(refreshToken, this.config.jwt.secret) as JwtPayload;
      
      if (decoded.type !== 'refresh') {
        return { success: false, error: 'Invalid refresh token' };
      }

      const sessionId = decoded.sessionId as string;
      const session = this.activeSessions.get(sessionId);

      if (!session) {
        return { success: false, error: 'Session not found' };
      }

      // Generate new access token
      const user = await this.findUserById(session.userId);
      if (!user) {
        return { success: false, error: 'User not found' };
      }

      const tokenPayload = {
        userId: user.userId,
        username: user.username,
        email: user.email,
        sessionId,
        permissions: this.getAllUserPermissions(user),
        allowedClients: this.getAllowedClients(user),
        allowedRegions: user.allowedRegions
      };

      const newAccessToken = sign(tokenPayload, this.config.jwt.secret, {
        issuer: this.config.jwt.issuer,
        audience: this.config.jwt.audience,
        expiresIn: this.config.jwt.expiresIn,
        algorithm: 'HS256'
      });

      // Update session
      session.accessToken = newAccessToken;
      session.lastActivity = new Date();

      return { success: true, accessToken: newAccessToken };

    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Token refresh failed' 
      };
    }
  }

  /**
   * Logout user and invalidate session
   */
  async logout(sessionId: string, ipAddress: string, userAgent: string): Promise<void> {
    const session = this.activeSessions.get(sessionId);
    
    if (session) {
      this.activeSessions.delete(sessionId);
      await this.logAuthEvent('LOGOUT', session.userId, ipAddress, userAgent);
    }
  }

  /**
   * Setup MFA for user
   */
  async setupMfa(userId: string): Promise<{ secret: string; qrCode: string }> {
    const secret = randomBytes(20).toString('base32');
    const user = await this.findUserById(userId);
    
    if (!user) {
      throw new Error('User not found');
    }

    // Store MFA secret (encrypted)
    await this.storeMfaSecret(userId, secret);

    // Generate QR code URL for authenticator apps
    const qrCode = `otpauth://totp/PowerReview:${user.email}?secret=${secret}&issuer=PowerReview&algorithm=SHA1&digits=6&period=30`;

    await this.logAuthEvent('MFA_SETUP_INITIATED', userId);

    return { secret, qrCode };
  }

  /**
   * Verify MFA code
   */
  private async verifyMfaCode(userId: string, code: string): Promise<boolean> {
    const secret = await this.getMfaSecret(userId);
    if (!secret) {
      return false;
    }

    // Implement TOTP verification
    const window = 1; // Allow 1 time step tolerance
    const timeStep = 30; // 30 seconds
    const currentTime = Math.floor(Date.now() / 1000 / timeStep);

    for (let i = -window; i <= window; i++) {
      const expectedCode = this.generateTotpCode(secret, currentTime + i);
      if (timingSafeEqual(Buffer.from(code), Buffer.from(expectedCode))) {
        return true;
      }
    }

    return false;
  }

  /**
   * Generate TOTP code
   */
  private generateTotpCode(secret: string, timeStep: number): string {
    // Simplified TOTP implementation
    // In production, use a proper TOTP library like 'otplib'
    const key = Buffer.from(secret, 'base32');
    const time = Buffer.alloc(8);
    time.writeUInt32BE(timeStep, 4);
    
    const hmac = createHash('sha1');
    hmac.update(key);
    hmac.update(time);
    const hash = hmac.digest();
    
    const offset = hash[hash.length - 1] & 0x0f;
    const code = ((hash[offset] & 0x7f) << 24) |
                 ((hash[offset + 1] & 0xff) << 16) |
                 ((hash[offset + 2] & 0xff) << 8) |
                 (hash[offset + 3] & 0xff);
    
    return (code % 1000000).toString().padStart(6, '0');
  }

  /**
   * Start session cleanup background task
   */
  private startSessionCleanup(): void {
    this.sessionCleanupInterval = setInterval(() => {
      const now = new Date();
      const sessionsToRemove: string[] = [];

      for (const [sessionId, session] of this.activeSessions) {
        // Remove expired sessions
        if (session.expiresAt < now) {
          sessionsToRemove.push(sessionId);
          continue;
        }

        // Remove idle sessions
        const idleTimeoutMs = this.config.session.idleTimeoutMinutes * 60 * 1000;
        if (now.getTime() - session.lastActivity.getTime() > idleTimeoutMs) {
          sessionsToRemove.push(sessionId);
        }
      }

      sessionsToRemove.forEach(sessionId => {
        this.activeSessions.delete(sessionId);
      });

      if (sessionsToRemove.length > 0) {
        console.log(`Cleaned up ${sessionsToRemove.length} expired sessions`);
      }
    }, 60000); // Run every minute
  }

  /**
   * Log authentication events for audit
   */
  private async logAuthEvent(
    eventType: string,
    userId?: string,
    ipAddress?: string,
    userAgent?: string,
    details?: string
  ): Promise<void> {
    // This would integrate with the audit logging system
    console.log('Auth Event:', {
      eventType,
      userId,
      ipAddress,
      userAgent,
      details,
      timestamp: new Date().toISOString()
    });
  }

  // Placeholder methods - these would integrate with the database service
  private async findUserByAzureId(azureId: string): Promise<User | null> { return null; }
  private async findUserByUsername(username: string): Promise<User | null> { return null; }
  private async findUserById(userId: string): Promise<User | null> { return null; }
  private async createUserFromAzureAd(userInfo: any): Promise<User> { throw new Error('Not implemented'); }
  private async updateUserFromAzureAd(userId: string, userInfo: any): Promise<void> { }
  private async verifyPassword(password: string, userId: string): Promise<boolean> { return false; }
  private async incrementFailedAttempts(userId: string): Promise<void> { }
  private async resetFailedAttempts(userId: string): Promise<void> { }
  private async updateUserLastLogin(userId: string): Promise<void> { }
  private async enforceSessionLimits(userId: string): Promise<void> { }
  private async storeMfaSecret(userId: string, secret: string): Promise<void> { }
  private async getMfaSecret(userId: string): Promise<string | null> { return null; }
  private async exchangeCodeForTokens(authCode: string): Promise<{ success: boolean; accessToken?: string }> { return { success: false }; }
  private async getUserFromAzureAd(accessToken: string): Promise<any> { return null; }

  private sanitizeUserForResponse(user: User): Partial<User> {
    return {
      userId: user.userId,
      username: user.username,
      email: user.email,
      displayName: user.displayName,
      isAdmin: user.isAdmin,
      allowedRegions: user.allowedRegions,
      lastLogin: user.lastLogin
    };
  }

  /**
   * Graceful shutdown
   */
  async shutdown(): Promise<void> {
    if (this.sessionCleanupInterval) {
      clearInterval(this.sessionCleanupInterval);
    }
    
    // Log all active sessions out
    for (const sessionId of this.activeSessions.keys()) {
      this.activeSessions.delete(sessionId);
    }
    
    console.log('Authentication service shut down');
  }
}

// Factory function for creating auth service
export function createAuthService(environment: 'development' | 'staging' | 'production'): ProductionAuthService {
  const config: AuthConfig = {
    azureAd: {
      tenantId: process.env.AZURE_AD_TENANT_ID || '',
      clientId: process.env.AZURE_AD_CLIENT_ID || '',
      clientSecret: process.env.AZURE_AD_CLIENT_SECRET || '',
      redirectUri: process.env.AZURE_AD_REDIRECT_URI || '',
      scopes: ['openid', 'profile', 'email', 'User.Read']
    },
    
    jwt: {
      secret: process.env.JWT_SECRET || '',
      issuer: process.env.JWT_ISSUER || 'PowerReview',
      audience: process.env.JWT_AUDIENCE || 'PowerReview-API',
      expiresIn: process.env.JWT_EXPIRES_IN || '1h',
      refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
    },
    
    session: {
      maxDurationHours: parseInt(process.env.SESSION_MAX_HOURS || '8'),
      idleTimeoutMinutes: parseInt(process.env.SESSION_IDLE_TIMEOUT || '30'),
      maxConcurrentSessions: parseInt(process.env.MAX_CONCURRENT_SESSIONS || '3'),
      requireMfa: process.env.REQUIRE_MFA === 'true'
    },
    
    security: {
      passwordPolicy: {
        minLength: parseInt(process.env.PASSWORD_MIN_LENGTH || '12'),
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: true
      },
      
      lockout: {
        maxFailedAttempts: parseInt(process.env.MAX_FAILED_ATTEMPTS || '5'),
        lockoutDurationMinutes: parseInt(process.env.LOCKOUT_DURATION || '15'),
        resetTimeMinutes: parseInt(process.env.LOCKOUT_RESET_TIME || '60')
      },
      
      encryption: {
        saltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS || '12'),
        keyDerivationIterations: parseInt(process.env.KEY_DERIVATION_ITERATIONS || '100000')
      }
    }
  };

  // Validate critical configuration for production
  if (environment === 'production') {
    if (!config.azureAd.tenantId) throw new Error('Azure AD Tenant ID required for production');
    if (!config.jwt.secret) throw new Error('JWT secret required for production');
    if (config.jwt.secret.length < 32) throw new Error('JWT secret must be at least 32 characters');
  }

  return new ProductionAuthService(config);
}

// Export singleton
export const authService = createAuthService(
  (process.env.NODE_ENV as 'development' | 'staging' | 'production') || 'development'
);