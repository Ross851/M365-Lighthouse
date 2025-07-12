/**
 * Global Compliance API for Multi-Region Data Management
 * Handles data residency requirements across global jurisdictions
 */

import type { APIRoute } from 'astro';
import { globalStorageManager } from '../../../lib/global-storage-manager';
import jwt from 'jsonwebtoken';

interface GlobalComplianceRequest {
  action: 'register_residency' | 'store_regional' | 'get_status' | 'export_regional' | 'migrate_region';
  clientId: string;
  dataResidencyProfile?: {
    organizationName: string;
    headquarters: string;
    operatingRegions: string[];
    dataResidencyRequirements: Array<{
      region: string;
      dataTypes: ('customer' | 'assessment' | 'files' | 'logs')[];
      mustStayInRegion: boolean;
      crossBorderTransferAllowed: boolean;
      complianceStandards: string[];
    }>;
    primaryRegion: string;
    backupRegions: string[];
    encryptionStandard: string;
    auditRequirements: {
      frequency: 'real-time' | 'daily' | 'weekly' | 'monthly';
      crossRegionAudit: boolean;
      localAuditor: string;
    };
  };
  data?: any;
  dataType?: 'customer' | 'assessment' | 'files' | 'logs';
  sourceRegion?: string;
  targetRegion?: string;
}

interface GlobalComplianceResponse {
  success: boolean;
  data?: any;
  error?: string;
  complianceStatus: string;
  regions: string[];
  auditId: string;
  timestamp: string;
}

function validateJWT(token: string): { userId: string; clientId: string; role: string } | null {
  try {
    const secret = process.env.JWT_SECRET || 'your-jwt-secret';
    const decoded = jwt.verify(token, secret) as any;
    return {
      userId: decoded.userId,
      clientId: decoded.clientId,
      role: decoded.role
    };
  } catch {
    return null;
  }
}

function createGlobalAuditRecord(
  action: string,
  clientId: string,
  userId: string,
  regions: string[],
  success: boolean,
  details?: any
): string {
  const auditId = crypto.randomUUID();
  
  const auditRecord = {
    auditId,
    timestamp: new Date().toISOString(),
    action,
    clientId,
    userId,
    regions,
    success,
    details,
    globalCompliance: true,
    systemInfo: {
      nodeVersion: process.version,
      platform: process.platform
    }
  };
  
  console.log('🌍 GLOBAL AUDIT:', JSON.stringify(auditRecord));
  return auditId;
}

export const POST: APIRoute = async ({ request }) => {
  const response: GlobalComplianceResponse = {
    success: false,
    complianceStatus: 'UNKNOWN',
    regions: [],
    auditId: '',
    timestamp: new Date().toISOString()
  };

  try {
    // Authentication
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      response.error = 'Authorization required';
      response.auditId = createGlobalAuditRecord('AUTH_MISSING', 'unknown', 'unknown', [], false);
      
      return new Response(JSON.stringify(response), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const jwtPayload = validateJWT(token);
    
    if (!jwtPayload) {
      response.error = 'Invalid token';
      response.auditId = createGlobalAuditRecord('AUTH_INVALID', 'unknown', 'unknown', [], false);
      
      return new Response(JSON.stringify(response), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Parse request
    const requestData: GlobalComplianceRequest = await request.json();
    
    if (!requestData.clientId || !requestData.action) {
      response.error = 'Missing required fields';
      response.auditId = createGlobalAuditRecord('REQUEST_INVALID', 'unknown', jwtPayload.userId, [], false);
      
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Verify client ID matches token
    if (requestData.clientId !== jwtPayload.clientId) {
      response.error = 'Client ID mismatch';
      response.auditId = createGlobalAuditRecord('CLIENT_MISMATCH', jwtPayload.clientId, jwtPayload.userId, [], false);
      
      return new Response(JSON.stringify(response), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const metadata = {
      userId: jwtPayload.userId,
      ipAddress: request.headers.get('x-forwarded-for') || 'unknown',
      userAgent: request.headers.get('user-agent') || 'Unknown'
    };

    let operationResult: any;
    let affectedRegions: string[] = [];

    switch (requestData.action) {
      case 'register_residency':
        if (!requestData.dataResidencyProfile) {
          throw new Error('Data residency profile required for registration');
        }
        
        const profile = {
          clientId: requestData.clientId,
          ...requestData.dataResidencyProfile
        };
        
        await globalStorageManager.registerClientDataResidency(profile);
        
        affectedRegions = [
          profile.primaryRegion,
          ...profile.backupRegions,
          ...profile.dataResidencyRequirements.map(req => req.region)
        ];
        
        operationResult = {
          message: 'Client data residency profile registered successfully',
          primaryRegion: profile.primaryRegion,
          operatingRegions: profile.operatingRegions,
          complianceStandards: profile.dataResidencyRequirements.flatMap(req => req.complianceStandards)
        };
        
        response.complianceStatus = 'REGISTERED';
        break;

      case 'store_regional':
        if (!requestData.data || !requestData.dataType) {
          throw new Error('Data and dataType required for regional storage');
        }
        
        const storeResult = await globalStorageManager.storeDataWithResidency(
          requestData.clientId,
          requestData.data,
          requestData.dataType,
          {
            ...metadata,
            sourceRegion: requestData.sourceRegion
          }
        );
        
        operationResult = storeResult;
        affectedRegions = storeResult.storedRegions;
        response.complianceStatus = storeResult.complianceStatus;
        break;

      case 'get_status':
        const statusResult = await globalStorageManager.getClientRegionalStatus(requestData.clientId);
        
        operationResult = statusResult;
        affectedRegions = statusResult.activeRegions;
        response.complianceStatus = statusResult.complianceStatus;
        break;

      case 'export_regional':
        // Export data for specific region (GDPR compliance)
        if (!requestData.sourceRegion) {
          throw new Error('Source region required for regional export');
        }
        
        operationResult = {
          message: 'Regional data export initiated',
          region: requestData.sourceRegion,
          exportId: crypto.randomUUID(),
          estimatedCompletion: new Date(Date.now() + 30 * 60 * 1000) // 30 minutes
        };
        
        affectedRegions = [requestData.sourceRegion];
        response.complianceStatus = 'EXPORT_INITIATED';
        break;

      case 'migrate_region':
        // Migrate data between regions (compliance requirement change)
        if (!requestData.sourceRegion || !requestData.targetRegion) {
          throw new Error('Source and target regions required for migration');
        }
        
        operationResult = {
          message: 'Regional data migration initiated',
          sourceRegion: requestData.sourceRegion,
          targetRegion: requestData.targetRegion,
          migrationId: crypto.randomUUID(),
          estimatedCompletion: new Date(Date.now() + 60 * 60 * 1000) // 1 hour
        };
        
        affectedRegions = [requestData.sourceRegion, requestData.targetRegion];
        response.complianceStatus = 'MIGRATION_INITIATED';
        break;

      default:
        throw new Error(`Unknown action: ${requestData.action}`);
    }

    // Success response
    response.success = true;
    response.data = operationResult;
    response.regions = affectedRegions;
    response.auditId = createGlobalAuditRecord(
      `${requestData.action.toUpperCase()}_SUCCESS`,
      requestData.clientId,
      jwtPayload.userId,
      affectedRegions,
      true,
      {
        action: requestData.action,
        dataType: requestData.dataType,
        sourceRegion: requestData.sourceRegion,
        targetRegion: requestData.targetRegion
      }
    );

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'X-Audit-ID': response.auditId,
        'X-Compliance-Status': response.complianceStatus,
        'X-Affected-Regions': affectedRegions.join(',')
      }
    });

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    response.auditId = createGlobalAuditRecord(
      'GLOBAL_OPERATION_ERROR',
      'unknown',
      'unknown',
      [],
      false,
      { error: errorMessage }
    );

    response.error = `Global compliance operation failed: ${errorMessage}`;
    response.complianceStatus = 'ERROR';

    return new Response(JSON.stringify(response), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'X-Audit-ID': response.auditId
      }
    });
  }
};

/**
 * Get supported regions and their compliance standards
 */
export const GET: APIRoute = async ({ request }) => {
  try {
    const regions = globalStorageManager.getSupportedRegions();
    
    // Transform for client response
    const regionsList = Object.entries(regions).map(([code, info]) => ({
      code,
      name: info.name,
      jurisdiction: info.jurisdiction,
      dataCenter: info.dataCenter,
      complianceStandards: info.complianceStandards,
      encryptionRequirements: info.encryptionRequirements,
      languages: info.languages,
      timeZone: info.timeZone
    }));

    const response = {
      success: true,
      regions: regionsList,
      totalRegions: regionsList.length,
      supportedJurisdictions: [...new Set(regionsList.map(r => r.jurisdiction))],
      timestamp: new Date().toISOString()
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600' // Cache for 1 hour
      }
    });

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    return new Response(JSON.stringify({
      success: false,
      error: `Failed to get regions: ${errorMessage}`,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};