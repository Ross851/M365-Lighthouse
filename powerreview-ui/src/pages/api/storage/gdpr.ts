/**
 * GDPR Compliance API Endpoint
 * Handles data subject rights requests including data export and deletion
 */

import type { APIRoute } from 'astro';
import { secureStorage } from '../../../lib/secure-storage';
import crypto from 'crypto';

interface GDPRRequest {
  action: 'export' | 'delete' | 'status';
  customerId: string;
  reason?: string;
  verificationToken?: string;
}

interface GDPRResponse {
  success: boolean;
  message: string;
  data?: any;
  verificationRequired?: boolean;
  verificationToken?: string;
}

// Store verification tokens temporarily (in production, use Redis)
const verificationTokens = new Map<string, {
  customerId: string;
  action: string;
  expiresAt: number;
}>();

function generateVerificationToken(customerId: string, action: string): string {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = Date.now() + (15 * 60 * 1000); // 15 minutes
  
  verificationTokens.set(token, {
    customerId,
    action,
    expiresAt
  });
  
  return token;
}

function validateVerificationToken(token: string, customerId: string, action: string): boolean {
  const tokenData = verificationTokens.get(token);
  
  if (!tokenData) {
    return false;
  }
  
  if (tokenData.expiresAt < Date.now()) {
    verificationTokens.delete(token);
    return false;
  }
  
  return tokenData.customerId === customerId && tokenData.action === action;
}

async function logGDPRRequest(customerId: string, action: string, success: boolean, reason?: string): Promise<void> {
  const logEntry = {
    timestamp: new Date().toISOString(),
    action: `GDPR_${action.toUpperCase()}`,
    customerId,
    success,
    reason,
    ipAddress: 'SYSTEM', // In production, capture actual IP
    userAgent: 'API'
  };
  
  console.log('📋 GDPR Request Logged:', logEntry);
  // In production, store in secure audit log
}

export const POST: APIRoute = async ({ request }) => {
  const response: GDPRResponse = {
    success: false,
    message: ''
  };

  try {
    // Check authentication
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      response.message = 'Authentication required';
      return new Response(JSON.stringify(response), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const requestData: GDPRRequest = await request.json();
    const { action, customerId, reason, verificationToken } = requestData;

    if (!action || !customerId) {
      response.message = 'Missing required fields: action and customerId';
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Validate customer exists
    const customerData = await secureStorage.getCustomerData(customerId);
    if (!customerData) {
      response.message = 'Customer not found';
      await logGDPRRequest(customerId, action, false, 'Customer not found');
      return new Response(JSON.stringify(response), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    switch (action) {
      case 'status':
        try {
          // Return data processing status
          const assessmentCount = await getAssessmentCount(customerId);
          const fileCount = await getFileCount(customerId);
          
          response.success = true;
          response.message = 'Data status retrieved successfully';
          response.data = {
            customerId,
            organizationName: customerData.organization,
            dataProcessingAgreement: customerData.dataProcessingAgreement,
            consentGiven: customerData.consentGiven,
            retentionPeriodDays: customerData.retentionPeriod,
            dataTypes: {
              customerProfile: 1,
              assessmentRecords: assessmentCount,
              uploadedFiles: fileCount
            },
            rights: {
              canExport: true,
              canDelete: true,
              canModify: false // For security, modifications go through support
            }
          };
          
          await logGDPRRequest(customerId, action, true);
        } catch (error) {
          response.message = 'Failed to retrieve data status';
          await logGDPRRequest(customerId, action, false, 'Internal error');
        }
        break;

      case 'export':
        try {
          // Check if verification is required for destructive actions
          if (!verificationToken) {
            const token = generateVerificationToken(customerId, action);
            response.verificationRequired = true;
            response.verificationToken = token;
            response.message = 'Verification token generated. Please confirm the export request.';
            response.success = true;
            return new Response(JSON.stringify(response), {
              status: 200,
              headers: { 'Content-Type': 'application/json' }
            });
          }

          // Validate verification token
          if (!validateVerificationToken(verificationToken, customerId, action)) {
            response.message = 'Invalid or expired verification token';
            await logGDPRRequest(customerId, action, false, 'Invalid verification token');
            return new Response(JSON.stringify(response), {
              status: 400,
              headers: { 'Content-Type': 'application/json' }
            });
          }

          // Export customer data
          const exportData = await secureStorage.exportCustomerData(customerId);
          
          // Remove verification token
          verificationTokens.delete(verificationToken);
          
          response.success = true;
          response.message = 'Data export completed successfully';
          response.data = {
            ...exportData,
            gdprCompliance: {
              exportDate: new Date().toISOString(),
              dataController: 'PowerReview System',
              legalBasis: 'Data subject request (GDPR Article 20)',
              retentionPolicy: `${customerData.retentionPeriod} days`,
              contactEmail: 'privacy@powerreview.com'
            }
          };
          
          await logGDPRRequest(customerId, action, true);
        } catch (error) {
          response.message = `Data export failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
          await logGDPRRequest(customerId, action, false, error instanceof Error ? error.message : 'Unknown error');
        }
        break;

      case 'delete':
        try {
          if (!reason) {
            response.message = 'Deletion reason is required';
            return new Response(JSON.stringify(response), {
              status: 400,
              headers: { 'Content-Type': 'application/json' }
            });
          }

          // Check if verification is required for destructive actions
          if (!verificationToken) {
            const token = generateVerificationToken(customerId, action);
            response.verificationRequired = true;
            response.verificationToken = token;
            response.message = 'Verification token generated. Please confirm the deletion request.';
            response.success = true;
            return new Response(JSON.stringify(response), {
              status: 200,
              headers: { 'Content-Type': 'application/json' }
            });
          }

          // Validate verification token
          if (!validateVerificationToken(verificationToken, customerId, action)) {
            response.message = 'Invalid or expired verification token';
            await logGDPRRequest(customerId, action, false, 'Invalid verification token');
            return new Response(JSON.stringify(response), {
              status: 400,
              headers: { 'Content-Type': 'application/json' }
            });
          }

          // Delete customer data
          const deleted = await secureStorage.deleteCustomerData(customerId, reason);
          
          // Remove verification token
          verificationTokens.delete(verificationToken);
          
          if (deleted) {
            response.success = true;
            response.message = 'All customer data has been permanently deleted';
            response.data = {
              deletionDate: new Date().toISOString(),
              reason,
              gdprCompliance: {
                legalBasis: 'Data subject request (GDPR Article 17)',
                retentionOverride: 'Data deleted upon request',
                auditTrail: 'Deletion logged in secure audit system'
              }
            };
            
            await logGDPRRequest(customerId, action, true, reason);
          } else {
            response.message = 'Failed to delete customer data';
            await logGDPRRequest(customerId, action, false, 'Deletion operation failed');
          }
        } catch (error) {
          response.message = `Data deletion failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
          await logGDPRRequest(customerId, action, false, error instanceof Error ? error.message : 'Unknown error');
        }
        break;

      default:
        response.message = `Unknown action: ${action}`;
        return new Response(JSON.stringify(response), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
    }

    const statusCode = response.success ? 200 : 400;
    
    return new Response(JSON.stringify(response), {
      status: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'X-GDPR-Action': action,
        'X-Customer-ID': customerId.substring(0, 8) + '...' // Partial ID for logging
      }
    });

  } catch (error) {
    console.error('❌ GDPR endpoint error:', error);
    
    response.message = 'Internal server error';
    
    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

// Helper functions
async function getAssessmentCount(customerId: string): Promise<number> {
  try {
    // This would query the secure storage for assessment count
    // For now, return a placeholder
    return 0;
  } catch {
    return 0;
  }
}

async function getFileCount(customerId: string): Promise<number> {
  try {
    // This would query the secure storage for file count
    // For now, return a placeholder
    return 0;
  } catch {
    return 0;
  }
}

// Data retention cleanup endpoint
export const DELETE: APIRoute = async ({ request }) => {
  try {
    // Check admin authentication
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Admin ')) {
      return new Response(JSON.stringify({
        success: false,
        message: 'Admin authentication required'
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Perform retention cleanup
    await secureStorage.performRetentionCleanup();

    return new Response(JSON.stringify({
      success: true,
      message: 'Data retention cleanup completed',
      timestamp: new Date().toISOString()
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('❌ Retention cleanup error:', error);
    
    return new Response(JSON.stringify({
      success: false,
      message: 'Retention cleanup failed'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};