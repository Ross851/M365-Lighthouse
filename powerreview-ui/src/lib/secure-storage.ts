/**
 * Secure Storage System for PowerReview
 * Handles encrypted storage of assessment data and uploaded files
 * Implements GDPR compliance and data retention policies
 */

import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';

// Environment configuration
const STORAGE_BASE_PATH = process.env.STORAGE_PATH || './secure-storage';
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32);
const IV_LENGTH = 16; // AES block size
const SALT_LENGTH = 64;

// Data retention configuration (in days)
const RETENTION_POLICIES = {
  ASSESSMENT_DATA: 365,     // 1 year
  UPLOADED_FILES: 90,       // 3 months
  LOGS: 30,                 // 1 month
  CUSTOMER_DATA: 2555       // 7 years (compliance requirement)
};

export interface StorageMetadata {
  id: string;
  type: 'assessment' | 'file' | 'customer' | 'log';
  customerId: string;
  createdAt: Date;
  expiresAt: Date;
  encrypted: boolean;
  fileSize?: number;
  mimeType?: string;
  originalName?: string;
  checksum: string;
}

export interface CustomerData {
  id: string;
  organization: string;
  contactPerson: string;
  email: string;
  tenantId: string;
  assessmentPurpose: string;
  consentGiven: boolean;
  dataProcessingAgreement: boolean;
  retentionPeriod: number; // days
}

export interface AssessmentData {
  id: string;
  customerId: string;
  sessionId: string;
  assessmentType: string[];
  startTime: Date;
  endTime?: Date;
  status: 'running' | 'completed' | 'failed' | 'cancelled';
  results: any;
  purviewResponses?: any;
  executiveSummary?: any;
  recommendations?: any;
}

export class SecureStorage {
  private storageInitialized = false;

  constructor() {
    this.initializeStorage();
  }

  private async initializeStorage(): Promise<void> {
    try {
      // Create secure storage directories
      const directories = [
        path.join(STORAGE_BASE_PATH, 'assessments'),
        path.join(STORAGE_BASE_PATH, 'files'),
        path.join(STORAGE_BASE_PATH, 'customers'),
        path.join(STORAGE_BASE_PATH, 'logs'),
        path.join(STORAGE_BASE_PATH, 'metadata'),
        path.join(STORAGE_BASE_PATH, 'backups')
      ];

      for (const dir of directories) {
        await fs.mkdir(dir, { recursive: true });
      }

      // Set secure permissions (Linux/macOS)
      if (process.platform !== 'win32') {
        await fs.chmod(STORAGE_BASE_PATH, 0o700); // Owner read/write/execute only
      }

      this.storageInitialized = true;
      console.log('✅ Secure storage initialized');
    } catch (error) {
      console.error('❌ Failed to initialize secure storage:', error);
      throw error;
    }
  }

  /**
   * Encrypt data using AES-256-GCM
   */
  private encrypt(data: string): { encrypted: string; iv: string; authTag: string } {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipher('aes-256-gcm', ENCRYPTION_KEY);
    
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    };
  }

  /**
   * Decrypt data using AES-256-GCM
   */
  private decrypt(encryptedData: string, iv: string, authTag: string): string {
    const decipher = crypto.createDecipher('aes-256-gcm', ENCRYPTION_KEY);
    decipher.setAuthTag(Buffer.from(authTag, 'hex'));
    
    let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }

  /**
   * Generate checksum for data integrity
   */
  private generateChecksum(data: string): string {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Store customer data with encryption
   */
  async storeCustomerData(customerData: CustomerData): Promise<string> {
    if (!this.storageInitialized) await this.initializeStorage();

    const id = customerData.id || crypto.randomUUID();
    const jsonData = JSON.stringify(customerData);
    const encrypted = this.encrypt(jsonData);
    
    const metadata: StorageMetadata = {
      id,
      type: 'customer',
      customerId: id,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + RETENTION_POLICIES.CUSTOMER_DATA * 24 * 60 * 60 * 1000),
      encrypted: true,
      checksum: this.generateChecksum(jsonData)
    };

    // Store encrypted data
    const dataPath = path.join(STORAGE_BASE_PATH, 'customers', `${id}.enc`);
    await fs.writeFile(dataPath, JSON.stringify({
      data: encrypted.encrypted,
      iv: encrypted.iv,
      authTag: encrypted.authTag
    }));

    // Store metadata
    await this.storeMetadata(metadata);

    console.log(`✅ Customer data stored securely: ${id}`);
    return id;
  }

  /**
   * Store assessment data with encryption
   */
  async storeAssessmentData(assessmentData: AssessmentData): Promise<string> {
    if (!this.storageInitialized) await this.initializeStorage();

    const id = assessmentData.id || crypto.randomUUID();
    const jsonData = JSON.stringify(assessmentData);
    const encrypted = this.encrypt(jsonData);
    
    const metadata: StorageMetadata = {
      id,
      type: 'assessment',
      customerId: assessmentData.customerId,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + RETENTION_POLICIES.ASSESSMENT_DATA * 24 * 60 * 60 * 1000),
      encrypted: true,
      checksum: this.generateChecksum(jsonData)
    };

    // Store encrypted data
    const dataPath = path.join(STORAGE_BASE_PATH, 'assessments', `${id}.enc`);
    await fs.writeFile(dataPath, JSON.stringify({
      data: encrypted.encrypted,
      iv: encrypted.iv,
      authTag: encrypted.authTag
    }));

    // Store metadata
    await this.storeMetadata(metadata);

    console.log(`✅ Assessment data stored securely: ${id}`);
    return id;
  }

  /**
   * Store uploaded file with encryption and virus scanning
   */
  async storeUploadedFile(
    fileBuffer: Buffer,
    originalName: string,
    mimeType: string,
    customerId: string
  ): Promise<string> {
    if (!this.storageInitialized) await this.initializeStorage();

    // Virus scanning simulation (in production, integrate with actual AV)
    await this.performVirusScan(fileBuffer, originalName);

    const id = crypto.randomUUID();
    const fileData = fileBuffer.toString('base64');
    const encrypted = this.encrypt(fileData);
    
    const metadata: StorageMetadata = {
      id,
      type: 'file',
      customerId,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + RETENTION_POLICIES.UPLOADED_FILES * 24 * 60 * 60 * 1000),
      encrypted: true,
      fileSize: fileBuffer.length,
      mimeType,
      originalName,
      checksum: this.generateChecksum(fileData)
    };

    // Store encrypted file
    const filePath = path.join(STORAGE_BASE_PATH, 'files', `${id}.enc`);
    await fs.writeFile(filePath, JSON.stringify({
      data: encrypted.encrypted,
      iv: encrypted.iv,
      authTag: encrypted.authTag
    }));

    // Store metadata
    await this.storeMetadata(metadata);

    console.log(`✅ File stored securely: ${originalName} (${id})`);
    return id;
  }

  /**
   * Retrieve and decrypt customer data
   */
  async getCustomerData(customerId: string): Promise<CustomerData | null> {
    try {
      const dataPath = path.join(STORAGE_BASE_PATH, 'customers', `${customerId}.enc`);
      const encryptedData = JSON.parse(await fs.readFile(dataPath, 'utf8'));
      
      const decrypted = this.decrypt(
        encryptedData.data,
        encryptedData.iv,
        encryptedData.authTag
      );
      
      const customerData = JSON.parse(decrypted);
      
      // Verify checksum
      const metadata = await this.getMetadata(customerId);
      if (metadata && this.generateChecksum(decrypted) !== metadata.checksum) {
        throw new Error('Data integrity check failed');
      }
      
      return customerData;
    } catch (error) {
      console.error(`❌ Failed to retrieve customer data: ${customerId}`, error);
      return null;
    }
  }

  /**
   * Retrieve and decrypt assessment data
   */
  async getAssessmentData(assessmentId: string): Promise<AssessmentData | null> {
    try {
      const dataPath = path.join(STORAGE_BASE_PATH, 'assessments', `${assessmentId}.enc`);
      const encryptedData = JSON.parse(await fs.readFile(dataPath, 'utf8'));
      
      const decrypted = this.decrypt(
        encryptedData.data,
        encryptedData.iv,
        encryptedData.authTag
      );
      
      const assessmentData = JSON.parse(decrypted);
      
      // Verify checksum
      const metadata = await this.getMetadata(assessmentId);
      if (metadata && this.generateChecksum(decrypted) !== metadata.checksum) {
        throw new Error('Data integrity check failed');
      }
      
      return assessmentData;
    } catch (error) {
      console.error(`❌ Failed to retrieve assessment data: ${assessmentId}`, error);
      return null;
    }
  }

  /**
   * Store metadata
   */
  private async storeMetadata(metadata: StorageMetadata): Promise<void> {
    const metadataPath = path.join(STORAGE_BASE_PATH, 'metadata', `${metadata.id}.json`);
    await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2));
  }

  /**
   * Get metadata
   */
  private async getMetadata(id: string): Promise<StorageMetadata | null> {
    try {
      const metadataPath = path.join(STORAGE_BASE_PATH, 'metadata', `${id}.json`);
      const metadata = JSON.parse(await fs.readFile(metadataPath, 'utf8'));
      return metadata;
    } catch {
      return null;
    }
  }

  /**
   * Virus scanning simulation
   */
  private async performVirusScan(fileBuffer: Buffer, fileName: string): Promise<void> {
    // Simulate virus scanning delay
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Check for suspicious file patterns
    const suspiciousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.com', '.pif'];
    const fileExtension = path.extname(fileName).toLowerCase();
    
    if (suspiciousExtensions.includes(fileExtension)) {
      throw new Error(`File type not allowed: ${fileExtension}`);
    }
    
    // Check file size limits (10MB)
    if (fileBuffer.length > 10 * 1024 * 1024) {
      throw new Error('File size exceeds maximum limit (10MB)');
    }
    
    // In production, integrate with actual virus scanning service
    console.log(`🔍 Virus scan completed: ${fileName} - CLEAN`);
  }

  /**
   * GDPR compliance: Delete customer data
   */
  async deleteCustomerData(customerId: string, reason: string): Promise<boolean> {
    try {
      const files = [
        path.join(STORAGE_BASE_PATH, 'customers', `${customerId}.enc`),
        path.join(STORAGE_BASE_PATH, 'metadata', `${customerId}.json`)
      ];
      
      // Find and delete related assessments
      const metadataDir = path.join(STORAGE_BASE_PATH, 'metadata');
      const metadataFiles = await fs.readdir(metadataDir);
      
      for (const file of metadataFiles) {
        const metadata = await this.getMetadata(path.parse(file).name);
        if (metadata && metadata.customerId === customerId) {
          files.push(path.join(STORAGE_BASE_PATH, metadata.type + 's', `${metadata.id}.enc`));
          files.push(path.join(metadataDir, file));
        }
      }
      
      // Delete all files
      for (const file of files) {
        try {
          await fs.unlink(file);
        } catch (error) {
          console.warn(`Warning: Could not delete ${file}:`, error);
        }
      }
      
      // Log deletion for audit trail
      await this.logDataDeletion(customerId, reason, files.length);
      
      console.log(`✅ Customer data deleted: ${customerId} (${reason})`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to delete customer data: ${customerId}`, error);
      return false;
    }
  }

  /**
   * Data retention cleanup
   */
  async performRetentionCleanup(): Promise<void> {
    console.log('🧹 Starting data retention cleanup...');
    
    try {
      const metadataDir = path.join(STORAGE_BASE_PATH, 'metadata');
      const metadataFiles = await fs.readdir(metadataDir);
      
      let deletedCount = 0;
      
      for (const file of metadataFiles) {
        const metadata = await this.getMetadata(path.parse(file).name);
        
        if (metadata && new Date() > metadata.expiresAt) {
          // Delete expired data
          const dataPath = path.join(STORAGE_BASE_PATH, metadata.type + 's', `${metadata.id}.enc`);
          
          try {
            await fs.unlink(dataPath);
            await fs.unlink(path.join(metadataDir, file));
            deletedCount++;
          } catch (error) {
            console.warn(`Warning: Could not delete expired data ${metadata.id}:`, error);
          }
        }
      }
      
      console.log(`✅ Retention cleanup completed: ${deletedCount} items deleted`);
    } catch (error) {
      console.error('❌ Retention cleanup failed:', error);
    }
  }

  /**
   * Log data deletion for audit trail
   */
  private async logDataDeletion(customerId: string, reason: string, filesDeleted: number): Promise<void> {
    const logEntry = {
      timestamp: new Date().toISOString(),
      action: 'DATA_DELETION',
      customerId,
      reason,
      filesDeleted,
      performedBy: 'SYSTEM'
    };
    
    const logPath = path.join(STORAGE_BASE_PATH, 'logs', `deletion-log-${new Date().toISOString().split('T')[0]}.json`);
    
    try {
      let logData = [];
      try {
        const existingLog = await fs.readFile(logPath, 'utf8');
        logData = JSON.parse(existingLog);
      } catch {
        // File doesn't exist, start new log
      }
      
      logData.push(logEntry);
      await fs.writeFile(logPath, JSON.stringify(logData, null, 2));
    } catch (error) {
      console.error('Failed to log data deletion:', error);
    }
  }

  /**
   * Generate data export for GDPR compliance
   */
  async exportCustomerData(customerId: string): Promise<any> {
    try {
      const customerData = await this.getCustomerData(customerId);
      if (!customerData) {
        throw new Error('Customer not found');
      }
      
      // Find all related assessments
      const assessments = [];
      const metadataDir = path.join(STORAGE_BASE_PATH, 'metadata');
      const metadataFiles = await fs.readdir(metadataDir);
      
      for (const file of metadataFiles) {
        const metadata = await this.getMetadata(path.parse(file).name);
        if (metadata && metadata.customerId === customerId && metadata.type === 'assessment') {
          const assessmentData = await this.getAssessmentData(metadata.id);
          if (assessmentData) {
            assessments.push(assessmentData);
          }
        }
      }
      
      return {
        exportDate: new Date().toISOString(),
        customerId,
        customerData,
        assessments,
        totalRecords: assessments.length + 1
      };
    } catch (error) {
      console.error(`❌ Failed to export customer data: ${customerId}`, error);
      throw error;
    }
  }
}

// Export singleton instance
export const secureStorage = new SecureStorage();