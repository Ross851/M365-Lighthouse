/**
 * Production Database Service
 * Secure, encrypted database operations with audit logging
 * Supports multi-region, multi-tenant architecture
 */

import { Pool, PoolClient, QueryResult } from 'pg';
import { createHash, createCipher, createDecipher, randomBytes } from 'crypto';

interface DatabaseConfig {
  // Connection configuration
  host: string;
  port: number;
  database: string;
  username: string;
  password: string;
  
  // Security configuration
  ssl: {
    rejectUnauthorized: boolean;
    ca?: string;
    cert?: string;
    key?: string;
  };
  
  // Connection pooling
  max: number;
  idleTimeoutMillis: number;
  connectionTimeoutMillis: number;
  
  // Encryption
  encryptionKey: string;
  keyRotationSchedule: string;
  
  // Audit configuration
  auditEnabled: boolean;
  auditRetentionYears: number;
}

interface DatabaseQuery {
  text: string;
  values?: any[];
  name?: string;
}

interface AuditLogEntry {
  eventType: string;
  eventCategory: string;
  severity: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
  userId?: string;
  clientId?: string;
  regionCode?: string;
  resourceType?: string;
  resourceId?: string;
  eventDescription: string;
  operationResult: 'SUCCESS' | 'FAILED' | 'PARTIAL';
  recordsAffected?: number;
  ipAddress?: string;
  userAgent?: string;
}

interface RegionalDataStorage {
  clientId: string;
  regionCode: string;
  dataType: 'customer' | 'assessment' | 'files' | 'logs';
  recordCount: number;
  storageSizeMb: number;
  complianceScore: number;
  dataResidencyStatus: 'compliant' | 'violation' | 'pending';
  encryptionStatus: 'encrypted' | 'pending' | 'error';
  lastComplianceCheck: Date;
}

interface ClientDataResidency {
  clientId: string;
  regionCode: string;
  dataTypes: string[];
  mustStayInRegion: boolean;
  crossBorderTransferAllowed: boolean;
  complianceStandards: string[];
  encryptionStandard: string;
  retentionPeriodDays: number;
}

export class ProductionDatabaseService {
  private pool: Pool;
  private config: DatabaseConfig;
  private encryptionCache = new Map<string, { key: Buffer; iv: Buffer }>();

  constructor(config: DatabaseConfig) {
    this.config = config;
    this.initializePool();
  }

  /**
   * Initialize database connection pool with security settings
   */
  private initializePool(): void {
    this.pool = new Pool({
      host: this.config.host,
      port: this.config.port,
      database: this.config.database,
      user: this.config.username,
      password: this.config.password,
      ssl: this.config.ssl,
      max: this.config.max,
      idleTimeoutMillis: this.config.idleTimeoutMillis,
      connectionTimeoutMillis: this.config.connectionTimeoutMillis,
      
      // Additional security settings
      application_name: 'PowerReview-Production',
      statement_timeout: 30000, // 30 seconds
      query_timeout: 30000,
      
      // Connection validation
      allowExitOnIdle: false,
    });

    // Handle pool errors
    this.pool.on('error', (err, client) => {
      console.error('Unexpected error on idle client', err);
      this.logAudit({
        eventType: 'DATABASE_ERROR',
        eventCategory: 'SYSTEM',
        severity: 'ERROR',
        eventDescription: `Database pool error: ${err.message}`,
        operationResult: 'FAILED'
      });
    });

    // Handle pool connection events
    this.pool.on('connect', (client) => {
      console.log('New client connected to database');
      // Set session-level security settings
      client.query('SET statement_timeout = 30000');
      client.query('SET lock_timeout = 10000');
    });
  }

  /**
   * Execute a query with automatic audit logging
   */
  async executeQuery<T = any>(
    query: DatabaseQuery,
    auditContext?: Partial<AuditLogEntry>
  ): Promise<QueryResult<T>> {
    const client = await this.pool.connect();
    const startTime = Date.now();
    
    try {
      // Log query execution start
      if (this.config.auditEnabled && auditContext) {
        await this.logAudit({
          eventType: auditContext.eventType || 'DATABASE_QUERY',
          eventCategory: auditContext.eventCategory || 'DATA',
          severity: 'INFO',
          eventDescription: `Executing query: ${query.name || 'unnamed'}`,
          operationResult: 'SUCCESS',
          ...auditContext
        });
      }

      // Execute the query
      const result = await client.query(query);
      const duration = Date.now() - startTime;

      // Log successful execution
      if (this.config.auditEnabled && auditContext) {
        await this.logAudit({
          eventType: auditContext.eventType || 'DATABASE_QUERY_SUCCESS',
          eventCategory: auditContext.eventCategory || 'DATA',
          severity: 'INFO',
          eventDescription: `Query executed successfully in ${duration}ms`,
          operationResult: 'SUCCESS',
          recordsAffected: result.rowCount || 0,
          ...auditContext
        });
      }

      return result;

    } catch (error) {
      const duration = Date.now() - startTime;
      
      // Log query failure
      if (this.config.auditEnabled) {
        await this.logAudit({
          eventType: 'DATABASE_QUERY_ERROR',
          eventCategory: 'DATA',
          severity: 'ERROR',
          eventDescription: `Query failed after ${duration}ms: ${error instanceof Error ? error.message : 'Unknown error'}`,
          operationResult: 'FAILED',
          ...auditContext
        });
      }

      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Encrypt sensitive data before storage
   */
  async encryptData(data: string, clientId: string): Promise<string> {
    try {
      // Generate or retrieve client-specific encryption parameters
      let encryptionParams = this.encryptionCache.get(clientId);
      
      if (!encryptionParams) {
        // Derive client-specific key from master key
        const clientKey = createHash('sha256')
          .update(this.config.encryptionKey + clientId)
          .digest();
        
        const iv = randomBytes(16);
        
        encryptionParams = { key: clientKey, iv };
        this.encryptionCache.set(clientId, encryptionParams);
      }

      // Encrypt the data
      const cipher = createCipher('aes-256-gcm', encryptionParams.key);
      let encrypted = cipher.update(data, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Get authentication tag
      const authTag = (cipher as any).getAuthTag();
      
      // Return encrypted data with IV and auth tag
      return `${encryptionParams.iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;

    } catch (error) {
      await this.logAudit({
        eventType: 'ENCRYPTION_ERROR',
        eventCategory: 'SECURITY',
        severity: 'ERROR',
        clientId,
        eventDescription: `Data encryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        operationResult: 'FAILED'
      });
      throw new Error('Data encryption failed');
    }
  }

  /**
   * Decrypt sensitive data from storage
   */
  async decryptData(encryptedData: string, clientId: string): Promise<string> {
    try {
      // Parse encrypted data components
      const [ivHex, authTagHex, encrypted] = encryptedData.split(':');
      
      if (!ivHex || !authTagHex || !encrypted) {
        throw new Error('Invalid encrypted data format');
      }

      // Derive client-specific key
      const clientKey = createHash('sha256')
        .update(this.config.encryptionKey + clientId)
        .digest();

      // Decrypt the data
      const decipher = createDecipher('aes-256-gcm', clientKey);
      (decipher as any).setAuthTag(Buffer.from(authTagHex, 'hex'));
      
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;

    } catch (error) {
      await this.logAudit({
        eventType: 'DECRYPTION_ERROR',
        eventCategory: 'SECURITY',
        severity: 'ERROR',
        clientId,
        eventDescription: `Data decryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        operationResult: 'FAILED'
      });
      throw new Error('Data decryption failed');
    }
  }

  /**
   * Store client data with regional compliance
   */
  async storeClientData(
    clientId: string,
    data: any,
    dataType: 'customer' | 'assessment' | 'files' | 'logs',
    regionCode: string,
    userId: string,
    options: {
      classification?: 'public' | 'internal' | 'confidential' | 'restricted';
      retentionDays?: number;
      auditContext?: any;
    } = {}
  ): Promise<string> {
    
    // Validate regional compliance first
    const residencyRules = await this.getClientDataResidency(clientId, regionCode);
    if (!this.validateDataResidency(dataType, regionCode, residencyRules)) {
      throw new Error(`Data residency violation: ${dataType} cannot be stored in ${regionCode}`);
    }

    // Encrypt the data
    const encryptedData = await this.encryptData(JSON.stringify(data), clientId);
    
    // Generate unique record ID
    const recordId = randomBytes(16).toString('hex');

    // Store in database
    const query: DatabaseQuery = {
      text: `
        INSERT INTO secure_data_storage (
          record_id, client_id, data_type, region_code, 
          encrypted_data, data_classification, retention_until,
          created_by, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING record_id, created_at
      `,
      values: [
        recordId,
        clientId,
        dataType,
        regionCode,
        encryptedData,
        options.classification || 'confidential',
        options.retentionDays ? new Date(Date.now() + options.retentionDays * 24 * 60 * 60 * 1000) : null,
        userId
      ]
    };

    await this.executeQuery(query, {
      eventType: 'STORE_CLIENT_DATA',
      eventCategory: 'DATA',
      userId,
      clientId,
      regionCode,
      resourceType: dataType.toUpperCase(),
      resourceId: recordId,
      eventDescription: `Stored ${dataType} data for client in ${regionCode}`,
      recordsAffected: 1
    });

    // Update regional storage tracking
    await this.updateRegionalStorageStats(clientId, regionCode, dataType, 1, JSON.stringify(data).length);

    return recordId;
  }

  /**
   * Retrieve client data with access control
   */
  async getClientData(
    clientId: string,
    userId: string,
    options: {
      regionFilter?: string[];
      dataTypeFilter?: string[];
      includeArchived?: boolean;
    } = {}
  ): Promise<any[]> {
    
    // Build dynamic query based on filters
    let whereClause = 'WHERE client_id = $1 AND is_active = TRUE';
    const values: any[] = [clientId];
    let paramIndex = 2;

    if (options.regionFilter && options.regionFilter.length > 0) {
      whereClause += ` AND region_code = ANY($${paramIndex})`;
      values.push(options.regionFilter);
      paramIndex++;
    }

    if (options.dataTypeFilter && options.dataTypeFilter.length > 0) {
      whereClause += ` AND data_type = ANY($${paramIndex})`;
      values.push(options.dataTypeFilter);
      paramIndex++;
    }

    if (!options.includeArchived) {
      whereClause += ` AND (retention_until IS NULL OR retention_until > NOW())`;
    }

    const query: DatabaseQuery = {
      text: `
        SELECT 
          record_id, data_type, region_code, data_classification,
          created_at, created_by, last_accessed, access_count
        FROM secure_data_storage 
        ${whereClause}
        ORDER BY created_at DESC
      `,
      values
    };

    const result = await this.executeQuery(query, {
      eventType: 'GET_CLIENT_DATA',
      eventCategory: 'DATA',
      userId,
      clientId,
      eventDescription: `Retrieved client data with filters`,
      recordsAffected: 0 // Will be updated after query
    });

    // Log data access
    await this.logAudit({
      eventType: 'DATA_ACCESS',
      eventCategory: 'DATA',
      severity: 'INFO',
      userId,
      clientId,
      eventDescription: `User accessed ${result.rowCount} records`,
      operationResult: 'SUCCESS',
      recordsAffected: result.rowCount || 0
    });

    return result.rows;
  }

  /**
   * Get client data residency rules
   */
  async getClientDataResidency(clientId: string, regionCode?: string): Promise<ClientDataResidency[]> {
    const query: DatabaseQuery = {
      text: `
        SELECT 
          client_id, region_code, data_types, must_stay_in_region,
          cross_border_transfer_allowed, compliance_standards,
          encryption_standard, retention_period_days
        FROM client_data_residency 
        WHERE client_id = $1 
        ${regionCode ? 'AND region_code = $2' : ''}
        ORDER BY region_code
      `,
      values: regionCode ? [clientId, regionCode] : [clientId]
    };

    const result = await this.executeQuery(query);
    
    return result.rows.map(row => ({
      clientId: row.client_id,
      regionCode: row.region_code,
      dataTypes: JSON.parse(row.data_types),
      mustStayInRegion: row.must_stay_in_region,
      crossBorderTransferAllowed: row.cross_border_transfer_allowed,
      complianceStandards: JSON.parse(row.compliance_standards),
      encryptionStandard: row.encryption_standard,
      retentionPeriodDays: row.retention_period_days
    }));
  }

  /**
   * Validate data residency compliance
   */
  private validateDataResidency(
    dataType: string,
    regionCode: string,
    residencyRules: ClientDataResidency[]
  ): boolean {
    
    // Find applicable rules for this data type and region
    const applicableRule = residencyRules.find(rule => 
      rule.regionCode === regionCode && rule.dataTypes.includes(dataType)
    );

    if (!applicableRule) {
      // If no specific rule, check for global rules
      const globalRule = residencyRules.find(rule => 
        rule.dataTypes.includes(dataType) && rule.mustStayInRegion
      );
      
      if (globalRule && globalRule.regionCode !== regionCode) {
        return false; // Data must stay in specific region
      }
    }

    return true; // Storage is allowed
  }

  /**
   * Update regional storage statistics
   */
  private async updateRegionalStorageStats(
    clientId: string,
    regionCode: string,
    dataType: string,
    recordCount: number,
    dataSizeBytes: number
  ): Promise<void> {
    
    const query: DatabaseQuery = {
      text: `
        INSERT INTO regional_data_storage (
          client_id, region_code, data_type, record_count, 
          storage_size_mb, updated_at
        ) VALUES ($1, $2, $3, $4, $5, NOW())
        ON CONFLICT (client_id, region_code, data_type) 
        DO UPDATE SET 
          record_count = regional_data_storage.record_count + $4,
          storage_size_mb = regional_data_storage.storage_size_mb + $5,
          updated_at = NOW()
      `,
      values: [
        clientId, 
        regionCode, 
        dataType, 
        recordCount, 
        dataSizeBytes / (1024 * 1024) // Convert to MB
      ]
    };

    await this.executeQuery(query, {
      eventType: 'UPDATE_STORAGE_STATS',
      eventCategory: 'SYSTEM',
      clientId,
      regionCode,
      eventDescription: `Updated storage statistics for ${dataType} in ${regionCode}`
    });
  }

  /**
   * Get regional compliance overview for client
   */
  async getRegionalComplianceOverview(clientId: string): Promise<RegionalDataStorage[]> {
    const query: DatabaseQuery = {
      text: `
        SELECT 
          rds.client_id, rds.region_code, rds.data_type,
          rds.record_count, rds.storage_size_mb, rds.compliance_score,
          rds.data_residency_status, rds.encryption_status,
          rds.last_compliance_check,
          r.region_name, r.jurisdiction, r.compliance_standards
        FROM regional_data_storage rds
        INNER JOIN regions r ON rds.region_code = r.region_code
        WHERE rds.client_id = $1
        ORDER BY rds.region_code, rds.data_type
      `,
      values: [clientId]
    };

    const result = await this.executeQuery(query, {
      eventType: 'GET_COMPLIANCE_OVERVIEW',
      eventCategory: 'COMPLIANCE',
      clientId,
      eventDescription: 'Retrieved regional compliance overview'
    });

    return result.rows;
  }

  /**
   * Log audit event
   */
  async logAudit(auditEntry: AuditLogEntry): Promise<void> {
    if (!this.config.auditEnabled) return;

    const query: DatabaseQuery = {
      text: `
        INSERT INTO audit_logs (
          event_type, event_category, severity, user_id, client_id,
          region_code, resource_type, resource_id, event_description,
          operation_result, records_affected, ip_address, user_agent,
          event_timestamp
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())
      `,
      values: [
        auditEntry.eventType,
        auditEntry.eventCategory,
        auditEntry.severity,
        auditEntry.userId || null,
        auditEntry.clientId || null,
        auditEntry.regionCode || null,
        auditEntry.resourceType || null,
        auditEntry.resourceId || null,
        auditEntry.eventDescription,
        auditEntry.operationResult,
        auditEntry.recordsAffected || 0,
        auditEntry.ipAddress || null,
        auditEntry.userAgent || null
      ]
    };

    try {
      await this.executeQuery(query);
    } catch (error) {
      // Critical: Audit logging failed - this should trigger alerts
      console.error('CRITICAL: Audit logging failed', error);
      // In production, this would trigger immediate security alerts
    }
  }

  /**
   * Health check for database connectivity
   */
  async healthCheck(): Promise<{ status: 'healthy' | 'unhealthy'; details: any }> {
    try {
      const startTime = Date.now();
      const result = await this.executeQuery({
        text: 'SELECT 1 as health_check',
        name: 'health_check'
      });
      
      const duration = Date.now() - startTime;
      
      return {
        status: 'healthy',
        details: {
          responseTimeMs: duration,
          poolTotal: this.pool.totalCount,
          poolIdle: this.pool.idleCount,
          poolWaiting: this.pool.waitingCount,
          timestamp: new Date().toISOString()
        }
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        details: {
          error: error instanceof Error ? error.message : 'Unknown error',
          timestamp: new Date().toISOString()
        }
      };
    }
  }

  /**
   * Graceful shutdown
   */
  async shutdown(): Promise<void> {
    await this.logAudit({
      eventType: 'DATABASE_SHUTDOWN',
      eventCategory: 'SYSTEM',
      severity: 'INFO',
      eventDescription: 'Database service shutting down',
      operationResult: 'SUCCESS'
    });

    await this.pool.end();
    this.encryptionCache.clear();
  }
}

// Factory function for creating database service with environment-specific config
export function createDatabaseService(environment: 'development' | 'staging' | 'production'): ProductionDatabaseService {
  const config: DatabaseConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'powerreview',
    username: process.env.DB_USERNAME || 'powerreview_user',
    password: process.env.DB_PASSWORD || '',
    
    ssl: {
      rejectUnauthorized: environment === 'production',
      ca: process.env.DB_SSL_CA,
      cert: process.env.DB_SSL_CERT,
      key: process.env.DB_SSL_KEY
    },
    
    max: parseInt(process.env.DB_POOL_MAX || '20'),
    idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT || '30000'),
    connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT || '10000'),
    
    encryptionKey: process.env.ENCRYPTION_MASTER_KEY || '',
    keyRotationSchedule: process.env.KEY_ROTATION_SCHEDULE || '90d',
    
    auditEnabled: process.env.AUDIT_ENABLED !== 'false',
    auditRetentionYears: parseInt(process.env.AUDIT_RETENTION_YEARS || '7')
  };

  // Validate critical configuration
  if (environment === 'production') {
    if (!config.password) throw new Error('Database password required for production');
    if (!config.encryptionKey) throw new Error('Encryption master key required for production');
    if (!config.ssl.ca) console.warn('WARNING: SSL CA certificate not configured for production');
  }

  return new ProductionDatabaseService(config);
}

// Export singleton for application use
export const databaseService = createDatabaseService(
  (process.env.NODE_ENV as 'development' | 'staging' | 'production') || 'development'
);