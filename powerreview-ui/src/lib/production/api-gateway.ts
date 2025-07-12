/**
 * Production API Gateway
 * Secure, rate-limited, authenticated API layer
 * Request/response validation, audit logging, monitoring
 */

import { Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import compression from 'compression';
import cors from 'cors';
import { authService } from './auth-service';
import { databaseService } from './database-service';

interface ApiConfig {
  // Security settings
  security: {
    enableHelmet: boolean;
    enableCors: boolean;
    corsOrigins: string[];
    enableCompression: boolean;
    enableRateLimit: boolean;
    trustProxy: boolean;
  };
  
  // Rate limiting
  rateLimit: {
    windowMs: number;
    maxRequests: number;
    skipSuccessfulRequests: boolean;
    skipFailedRequests: boolean;
    standardHeaders: boolean;
    legacyHeaders: boolean;
  };
  
  // Request validation
  validation: {
    maxRequestSize: string;
    enableRequestValidation: boolean;
    enableResponseValidation: boolean;
    stripUnknownProperties: boolean;
  };
  
  // Monitoring and logging
  monitoring: {
    enableMetrics: boolean;
    enableTracing: boolean;
    logLevel: 'debug' | 'info' | 'warn' | 'error';
    logFormat: 'json' | 'combined' | 'common';
    enableSlowRequestLogging: boolean;
    slowRequestThresholdMs: number;
  };
  
  // API versioning
  versioning: {
    enableVersioning: boolean;
    defaultVersion: string;
    supportedVersions: string[];
    versionHeader: string;
  };
}

interface ApiRequest extends Request {
  user?: {
    userId: string;
    username: string;
    email: string;
    permissions: string[];
    allowedClients: string[];
    allowedRegions: string[];
    sessionId: string;
  };
  
  requestId?: string;
  startTime?: number;
  clientId?: string;
  regionCode?: string;
}

interface ApiResponse extends Response {
  apiSuccess: (data: any, message?: string) => void;
  apiError: (error: string, statusCode?: number, details?: any) => void;
  apiValidationError: (errors: any[]) => void;
  apiNotFound: (resource?: string) => void;
  apiUnauthorized: (message?: string) => void;
  apiForbidden: (message?: string) => void;
}

interface RequestMetrics {
  requestId: string;
  method: string;
  path: string;
  statusCode: number;
  duration: number;
  timestamp: Date;
  userId?: string;
  clientId?: string;
  regionCode?: string;
  userAgent?: string;
  ipAddress?: string;
}

interface ValidationSchema {
  type: 'object' | 'array' | 'string' | 'number' | 'boolean';
  properties?: Record<string, ValidationSchema>;
  required?: string[];
  minLength?: number;
  maxLength?: number;
  pattern?: RegExp;
  enum?: any[];
  items?: ValidationSchema;
  additionalProperties?: boolean;
}

export class ProductionApiGateway {
  private config: ApiConfig;
  private metrics: RequestMetrics[] = [];
  private slowQueries = new Map<string, number>();

  constructor(config: ApiConfig) {
    this.config = config;
  }

  /**
   * Configure Express middleware stack
   */
  configureMiddleware(app: any): void {
    // Trust proxy (for load balancers)
    if (this.config.security.trustProxy) {
      app.set('trust proxy', 1);
    }

    // Security headers
    if (this.config.security.enableHelmet) {
      app.use(helmet({
        contentSecurityPolicy: {
          directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
          },
        },
        crossOriginEmbedderPolicy: false,
        hsts: {
          maxAge: 31536000,
          includeSubDomains: true,
          preload: true
        }
      }));
    }

    // CORS configuration
    if (this.config.security.enableCors) {
      app.use(cors({
        origin: this.config.security.corsOrigins,
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Version', 'X-Client-ID', 'X-Region-Code'],
        exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-Request-ID']
      }));
    }

    // Compression
    if (this.config.security.enableCompression) {
      app.use(compression({
        level: 6,
        threshold: 1024,
        filter: (req: Request, res: Response) => {
          if (req.headers['x-no-compression']) {
            return false;
          }
          return compression.filter(req, res);
        }
      }));
    }

    // Request parsing with size limits
    app.use(express.json({ 
      limit: this.config.validation.maxRequestSize,
      strict: true
    }));
    
    app.use(express.urlencoded({ 
      extended: true, 
      limit: this.config.validation.maxRequestSize 
    }));

    // Rate limiting
    if (this.config.security.enableRateLimit) {
      const limiter = rateLimit({
        windowMs: this.config.rateLimit.windowMs,
        max: this.config.rateLimit.maxRequests,
        standardHeaders: this.config.rateLimit.standardHeaders,
        legacyHeaders: this.config.rateLimit.legacyHeaders,
        skipSuccessfulRequests: this.config.rateLimit.skipSuccessfulRequests,
        skipFailedRequests: this.config.rateLimit.skipFailedRequests,
        keyGenerator: (req: Request) => {
          // Use user ID if authenticated, otherwise IP
          const apiReq = req as ApiRequest;
          return apiReq.user?.userId || req.ip;
        },
        handler: (req: Request, res: Response) => {
          const apiRes = res as ApiResponse;
          apiRes.apiError('Too many requests, please try again later', 429);
        }
      });

      app.use('/api/', limiter);
    }

    // Request ID and timing
    app.use(this.requestIdMiddleware.bind(this));

    // API versioning
    if (this.config.versioning.enableVersioning) {
      app.use(this.versioningMiddleware.bind(this));
    }

    // Authentication middleware
    app.use('/api/', this.authenticationMiddleware.bind(this));

    // Client/region extraction
    app.use('/api/', this.clientRegionMiddleware.bind(this));

    // Response helpers
    app.use(this.responseHelpersMiddleware.bind(this));

    // Request logging
    app.use(this.requestLoggingMiddleware.bind(this));
  }

  /**
   * Request ID middleware
   */
  private requestIdMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): void {
    req.requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    req.startTime = Date.now();
    
    res.setHeader('X-Request-ID', req.requestId);
    next();
  }

  /**
   * API versioning middleware
   */
  private versioningMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): void {
    const version = req.headers[this.config.versioning.versionHeader.toLowerCase()] as string || 
                   this.config.versioning.defaultVersion;
    
    if (!this.config.versioning.supportedVersions.includes(version)) {
      return res.apiError(`Unsupported API version: ${version}`, 400, {
        supportedVersions: this.config.versioning.supportedVersions
      });
    }

    req.headers['x-api-version'] = version;
    res.setHeader('X-API-Version', version);
    next();
  }

  /**
   * Authentication middleware
   */
  private async authenticationMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): Promise<void> {
    try {
      // Skip authentication for health checks and public endpoints
      if (this.isPublicEndpoint(req.path)) {
        return next();
      }

      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.apiUnauthorized('Authentication required');
      }

      const token = authHeader.substring(7);
      const validation = await authService.validateToken(token);

      if (!validation.valid) {
        return res.apiUnauthorized(validation.error || 'Invalid token');
      }

      // Extract user information from session
      req.user = {
        userId: validation.session!.userId,
        username: '', // Would be populated from session
        email: '', // Would be populated from session
        permissions: validation.session!.permissions,
        allowedClients: validation.session!.allowedClients,
        allowedRegions: validation.session!.allowedRegions,
        sessionId: validation.session!.sessionId
      };

      next();
    } catch (error) {
      console.error('Authentication middleware error:', error);
      res.apiError('Authentication failed', 500);
    }
  }

  /**
   * Client and region extraction middleware
   */
  private clientRegionMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): void {
    // Extract client ID from headers or URL params
    req.clientId = req.headers['x-client-id'] as string || req.params.clientId;
    req.regionCode = req.headers['x-region-code'] as string || req.params.regionCode;

    // Validate client access if user is not admin
    if (req.clientId && req.user && !req.user.permissions.includes('admin:all')) {
      if (!req.user.allowedClients.includes(req.clientId)) {
        return res.apiForbidden('Access denied to this client');
      }
    }

    // Validate region access
    if (req.regionCode && req.user && !req.user.permissions.includes('admin:all')) {
      if (!req.user.allowedRegions.includes(req.regionCode)) {
        return res.apiForbidden('Access denied to this region');
      }
    }

    next();
  }

  /**
   * Response helpers middleware
   */
  private responseHelpersMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): void {
    res.apiSuccess = (data: any, message?: string) => {
      res.status(200).json({
        success: true,
        message: message || 'Success',
        data,
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    res.apiError = (error: string, statusCode: number = 500, details?: any) => {
      res.status(statusCode).json({
        success: false,
        error,
        details,
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    res.apiValidationError = (errors: any[]) => {
      res.status(400).json({
        success: false,
        error: 'Validation failed',
        validationErrors: errors,
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    res.apiNotFound = (resource?: string) => {
      res.status(404).json({
        success: false,
        error: `${resource || 'Resource'} not found`,
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    res.apiUnauthorized = (message?: string) => {
      res.status(401).json({
        success: false,
        error: message || 'Unauthorized',
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    res.apiForbidden = (message?: string) => {
      res.status(403).json({
        success: false,
        error: message || 'Forbidden',
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
    };

    next();
  }

  /**
   * Request logging middleware
   */
  private requestLoggingMiddleware(req: ApiRequest, res: ApiResponse, next: NextFunction): void {
    const originalSend = res.send;
    
    res.send = function(data) {
      const duration = Date.now() - (req.startTime || 0);
      
      // Log slow requests
      if (duration > this.config.monitoring.slowRequestThresholdMs) {
        console.warn('Slow request detected:', {
          requestId: req.requestId,
          method: req.method,
          path: req.path,
          duration,
          userId: req.user?.userId
        });
      }

      // Store metrics
      this.recordMetrics({
        requestId: req.requestId!,
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        duration,
        timestamp: new Date(),
        userId: req.user?.userId,
        clientId: req.clientId,
        regionCode: req.regionCode,
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip
      });

      // Audit logging for sensitive operations
      if (this.isSensitiveOperation(req)) {
        this.logSensitiveOperation(req, res, duration);
      }

      return originalSend.call(this, data);
    }.bind(this);

    next();
  }

  /**
   * Permission validation middleware
   */
  createPermissionMiddleware(requiredPermission: string) {
    return async (req: ApiRequest, res: ApiResponse, next: NextFunction): Promise<void> => {
      if (!req.user) {
        return res.apiUnauthorized();
      }

      const hasPermission = await authService.checkPermission({
        userId: req.user.userId,
        clientId: req.clientId,
        regionCode: req.regionCode,
        action: this.extractActionFromPermission(requiredPermission),
        resourceType: this.extractResourceFromPermission(requiredPermission)
      });

      if (!hasPermission) {
        return res.apiForbidden('Insufficient permissions');
      }

      next();
    };
  }

  /**
   * Request validation middleware
   */
  createValidationMiddleware(schema: ValidationSchema) {
    return (req: ApiRequest, res: ApiResponse, next: NextFunction): void => {
      if (!this.config.validation.enableRequestValidation) {
        return next();
      }

      const validationResult = this.validateData(req.body, schema);
      
      if (!validationResult.valid) {
        return res.apiValidationError(validationResult.errors);
      }

      // Strip unknown properties if configured
      if (this.config.validation.stripUnknownProperties) {
        req.body = this.stripUnknownProperties(req.body, schema);
      }

      next();
    };
  }

  /**
   * Data validation
   */
  private validateData(data: any, schema: ValidationSchema): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Type validation
    if (schema.type === 'object' && typeof data !== 'object') {
      errors.push('Expected object');
      return { valid: false, errors };
    }

    if (schema.type === 'array' && !Array.isArray(data)) {
      errors.push('Expected array');
      return { valid: false, errors };
    }

    if (schema.type === 'string' && typeof data !== 'string') {
      errors.push('Expected string');
      return { valid: false, errors };
    }

    if (schema.type === 'number' && typeof data !== 'number') {
      errors.push('Expected number');
      return { valid: false, errors };
    }

    if (schema.type === 'boolean' && typeof data !== 'boolean') {
      errors.push('Expected boolean');
      return { valid: false, errors };
    }

    // Object property validation
    if (schema.type === 'object' && schema.properties) {
      // Check required properties
      if (schema.required) {
        for (const prop of schema.required) {
          if (!(prop in data)) {
            errors.push(`Missing required property: ${prop}`);
          }
        }
      }

      // Validate properties
      for (const [prop, propSchema] of Object.entries(schema.properties)) {
        if (prop in data) {
          const propValidation = this.validateData(data[prop], propSchema);
          if (!propValidation.valid) {
            errors.push(...propValidation.errors.map(err => `${prop}: ${err}`));
          }
        }
      }
    }

    // String validation
    if (schema.type === 'string') {
      if (schema.minLength && data.length < schema.minLength) {
        errors.push(`String too short (minimum ${schema.minLength})`);
      }
      
      if (schema.maxLength && data.length > schema.maxLength) {
        errors.push(`String too long (maximum ${schema.maxLength})`);
      }
      
      if (schema.pattern && !schema.pattern.test(data)) {
        errors.push('String does not match required pattern');
      }
      
      if (schema.enum && !schema.enum.includes(data)) {
        errors.push(`Value must be one of: ${schema.enum.join(', ')}`);
      }
    }

    // Array validation
    if (schema.type === 'array' && schema.items) {
      for (let i = 0; i < data.length; i++) {
        const itemValidation = this.validateData(data[i], schema.items);
        if (!itemValidation.valid) {
          errors.push(...itemValidation.errors.map(err => `[${i}]: ${err}`));
        }
      }
    }

    return { valid: errors.length === 0, errors };
  }

  /**
   * Strip unknown properties from data
   */
  private stripUnknownProperties(data: any, schema: ValidationSchema): any {
    if (schema.type !== 'object' || !schema.properties) {
      return data;
    }

    const stripped: any = {};
    
    for (const prop in schema.properties) {
      if (prop in data) {
        stripped[prop] = data[prop];
      }
    }

    return stripped;
  }

  /**
   * Record request metrics
   */
  private recordMetrics(metrics: RequestMetrics): void {
    if (!this.config.monitoring.enableMetrics) {
      return;
    }

    this.metrics.push(metrics);

    // Keep only recent metrics (last 1000 requests)
    if (this.metrics.length > 1000) {
      this.metrics = this.metrics.slice(-1000);
    }

    // Track slow queries
    if (metrics.duration > this.config.monitoring.slowRequestThresholdMs) {
      const key = `${metrics.method} ${metrics.path}`;
      this.slowQueries.set(key, (this.slowQueries.get(key) || 0) + 1);
    }
  }

  /**
   * Get API metrics
   */
  getMetrics(): {
    totalRequests: number;
    averageResponseTime: number;
    errorRate: number;
    slowRequests: number;
    requestsByStatus: Record<number, number>;
    requestsByPath: Record<string, number>;
    slowestEndpoints: Array<{ endpoint: string; count: number }>;
  } {
    const total = this.metrics.length;
    
    if (total === 0) {
      return {
        totalRequests: 0,
        averageResponseTime: 0,
        errorRate: 0,
        slowRequests: 0,
        requestsByStatus: {},
        requestsByPath: {},
        slowestEndpoints: []
      };
    }

    const errors = this.metrics.filter(m => m.statusCode >= 400).length;
    const slowRequests = this.metrics.filter(m => m.duration > this.config.monitoring.slowRequestThresholdMs).length;
    const totalDuration = this.metrics.reduce((sum, m) => sum + m.duration, 0);

    const requestsByStatus: Record<number, number> = {};
    const requestsByPath: Record<string, number> = {};

    this.metrics.forEach(m => {
      requestsByStatus[m.statusCode] = (requestsByStatus[m.statusCode] || 0) + 1;
      requestsByPath[m.path] = (requestsByPath[m.path] || 0) + 1;
    });

    const slowestEndpoints = Array.from(this.slowQueries.entries())
      .map(([endpoint, count]) => ({ endpoint, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    return {
      totalRequests: total,
      averageResponseTime: Math.round(totalDuration / total),
      errorRate: Math.round((errors / total) * 100),
      slowRequests,
      requestsByStatus,
      requestsByPath,
      slowestEndpoints
    };
  }

  /**
   * Health check endpoint
   */
  async healthCheck(): Promise<{ status: 'healthy' | 'unhealthy'; services: Record<string, any> }> {
    const dbHealth = await databaseService.healthCheck();
    const metrics = this.getMetrics();

    const status = dbHealth.status === 'healthy' && metrics.errorRate < 10 ? 'healthy' : 'unhealthy';

    return {
      status,
      services: {
        database: dbHealth,
        api: {
          status: metrics.errorRate < 10 ? 'healthy' : 'unhealthy',
          metrics: {
            totalRequests: metrics.totalRequests,
            errorRate: metrics.errorRate,
            averageResponseTime: metrics.averageResponseTime
          }
        }
      }
    };
  }

  // Utility methods
  private isPublicEndpoint(path: string): boolean {
    const publicPaths = ['/health', '/api/health', '/api/auth/login', '/api/auth/callback'];
    return publicPaths.includes(path);
  }

  private isSensitiveOperation(req: ApiRequest): boolean {
    const sensitivePaths = ['/api/client', '/api/assessment', '/api/storage', '/api/export'];
    return sensitivePaths.some(path => req.path.startsWith(path));
  }

  private async logSensitiveOperation(req: ApiRequest, res: ApiResponse, duration: number): Promise<void> {
    await databaseService.logAudit({
      eventType: `API_${req.method}_${this.getResourceType(req.path)}`,
      eventCategory: 'API',
      severity: res.statusCode >= 400 ? 'WARN' : 'INFO',
      userId: req.user?.userId,
      clientId: req.clientId,
      regionCode: req.regionCode,
      resourceType: this.getResourceType(req.path),
      eventDescription: `API ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`,
      operationResult: res.statusCode < 400 ? 'SUCCESS' : 'FAILED',
      ipAddress: req.ip,
      userAgent: req.headers['user-agent']
    });
  }

  private getResourceType(path: string): string {
    if (path.includes('/client')) return 'CLIENT';
    if (path.includes('/assessment')) return 'ASSESSMENT';
    if (path.includes('/storage')) return 'STORAGE';
    if (path.includes('/export')) return 'EXPORT';
    return 'API';
  }

  private extractActionFromPermission(permission: string): 'read' | 'write' | 'admin' | 'audit' | 'export' {
    return permission.split(':')[0] as any;
  }

  private extractResourceFromPermission(permission: string): string | undefined {
    const parts = permission.split(':');
    return parts.length > 1 ? parts[1] : undefined;
  }
}

// Factory function
export function createApiGateway(environment: 'development' | 'staging' | 'production'): ProductionApiGateway {
  const config: ApiConfig = {
    security: {
      enableHelmet: environment === 'production',
      enableCors: true,
      corsOrigins: environment === 'production' 
        ? (process.env.CORS_ORIGINS?.split(',') || [])
        : ['http://localhost:3000', 'http://localhost:4321'],
      enableCompression: true,
      enableRateLimit: environment !== 'development',
      trustProxy: environment === 'production'
    },
    
    rateLimit: {
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
      maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
      skipSuccessfulRequests: false,
      skipFailedRequests: false,
      standardHeaders: true,
      legacyHeaders: false
    },
    
    validation: {
      maxRequestSize: process.env.MAX_REQUEST_SIZE || '10mb',
      enableRequestValidation: true,
      enableResponseValidation: environment !== 'production', // Disable in prod for performance
      stripUnknownProperties: true
    },
    
    monitoring: {
      enableMetrics: true,
      enableTracing: environment === 'production',
      logLevel: (process.env.LOG_LEVEL as any) || 'info',
      logFormat: environment === 'production' ? 'json' : 'combined',
      enableSlowRequestLogging: true,
      slowRequestThresholdMs: parseInt(process.env.SLOW_REQUEST_THRESHOLD_MS || '1000')
    },
    
    versioning: {
      enableVersioning: true,
      defaultVersion: 'v1',
      supportedVersions: ['v1'],
      versionHeader: 'X-API-Version'
    }
  };

  return new ProductionApiGateway(config);
}

// Export singleton
export const apiGateway = createApiGateway(
  (process.env.NODE_ENV as 'development' | 'staging' | 'production') || 'development'
);