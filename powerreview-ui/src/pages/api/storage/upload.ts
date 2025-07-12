/**
 * Secure File Upload API Endpoint
 * Handles file uploads with security validation and encryption
 */

import type { APIRoute } from 'astro';
import { secureStorage } from '../../../lib/secure-storage';
import crypto from 'crypto';

interface UploadRequest {
  customerId: string;
  files: File[];
  category: string;
}

interface UploadResponse {
  success: boolean;
  uploadedFiles: Array<{
    id: string;
    originalName: string;
    size: number;
    category: string;
  }>;
  errors: string[];
}

// Allowed file types and their MIME types
const ALLOWED_FILE_TYPES = {
  'application/pdf': ['.pdf'],
  'application/msword': ['.doc'],
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
  'text/plain': ['.txt'],
  'application/vnd.ms-excel': ['.xls'],
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
  'text/csv': ['.csv'],
  'image/png': ['.png'],
  'image/jpeg': ['.jpg', '.jpeg'],
  'application/json': ['.json']
};

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_FILES_PER_REQUEST = 10;

function validateFile(file: File): { valid: boolean; error?: string } {
  // Check file size
  if (file.size > MAX_FILE_SIZE) {
    return {
      valid: false,
      error: `File "${file.name}" exceeds maximum size of 10MB`
    };
  }

  // Check file type
  const allowedExtensions = Object.values(ALLOWED_FILE_TYPES).flat();
  const fileExtension = '.' + file.name.split('.').pop()?.toLowerCase();
  
  if (!allowedExtensions.includes(fileExtension)) {
    return {
      valid: false,
      error: `File type not allowed: ${fileExtension}`
    };
  }

  // Check MIME type matches extension
  const expectedMimeTypes = Object.keys(ALLOWED_FILE_TYPES).filter(mimeType =>
    ALLOWED_FILE_TYPES[mimeType as keyof typeof ALLOWED_FILE_TYPES].includes(fileExtension)
  );

  if (!expectedMimeTypes.includes(file.type)) {
    return {
      valid: false,
      error: `MIME type mismatch for "${file.name}": expected ${expectedMimeTypes.join(' or ')}, got ${file.type}`
    };
  }

  // Check for suspicious file names
  const suspiciousPatterns = [
    /\.(exe|bat|cmd|scr|com|pif|vbs|js|jar)$/i,
    /[<>:"|?*]/,
    /^(con|prn|aux|nul|com[1-9]|lpt[1-9])$/i
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(file.name)) {
      return {
        valid: false,
        error: `Suspicious file name: "${file.name}"`
      };
    }
  }

  return { valid: true };
}

async function sanitizeFileName(fileName: string): Promise<string> {
  // Remove or replace dangerous characters
  let sanitized = fileName
    .replace(/[<>:"|?*]/g, '_')
    .replace(/\.\./g, '_')
    .replace(/^\./, '_')
    .trim();

  // Ensure the filename isn't too long
  if (sanitized.length > 255) {
    const extension = sanitized.split('.').pop();
    const baseName = sanitized.substring(0, 255 - (extension?.length || 0) - 1);
    sanitized = `${baseName}.${extension}`;
  }

  return sanitized;
}

async function processFileUpload(file: File, customerId: string, category: string) {
  // Validate file
  const validation = validateFile(file);
  if (!validation.valid) {
    throw new Error(validation.error);
  }

  // Sanitize filename
  const sanitizedName = await sanitizeFileName(file.name);

  // Convert file to buffer
  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  // Additional security check: scan first few bytes for file signature
  const fileSignature = buffer.slice(0, 8).toString('hex');
  await validateFileSignature(fileSignature, file.type, sanitizedName);

  // Store the file securely
  const fileId = await secureStorage.storeUploadedFile(
    buffer,
    sanitizedName,
    file.type,
    customerId
  );

  return {
    id: fileId,
    originalName: sanitizedName,
    size: file.size,
    category
  };
}

async function validateFileSignature(signature: string, mimeType: string, fileName: string): Promise<void> {
  // Common file signatures (magic numbers)
  const fileSignatures: Record<string, string[]> = {
    'application/pdf': ['25504446'], // %PDF
    'image/jpeg': ['ffd8ffe0', 'ffd8ffe1', 'ffd8ffe2', 'ffd8ffe3', 'ffd8ffe8'],
    'image/png': ['89504e47'],
    'application/zip': ['504b0304'], // Also used by docx, xlsx
    'text/plain': [] // Text files don't have consistent signatures
  };

  const expectedSignatures = fileSignatures[mimeType];
  if (expectedSignatures && expectedSignatures.length > 0) {
    const fileStart = signature.toLowerCase();
    const isValid = expectedSignatures.some(sig => fileStart.startsWith(sig));
    
    if (!isValid) {
      throw new Error(`File signature validation failed for "${fileName}". File may be corrupted or have incorrect extension.`);
    }
  }
}

export const POST: APIRoute = async ({ request }) => {
  const response: UploadResponse = {
    success: false,
    uploadedFiles: [],
    errors: []
  };

  try {
    // Check authentication
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({
        ...response,
        errors: ['Authentication required']
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Parse form data
    const formData = await request.formData();
    const customerId = formData.get('customerId') as string;
    const category = formData.get('category') as string || 'general';

    if (!customerId) {
      response.errors.push('Customer ID is required');
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Validate customer exists
    const customerData = await secureStorage.getCustomerData(customerId);
    if (!customerData) {
      response.errors.push('Invalid customer ID');
      return new Response(JSON.stringify(response), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Get uploaded files
    const files: File[] = [];
    for (const [key, value] of formData.entries()) {
      if (key.startsWith('file') && value instanceof File) {
        files.push(value);
      }
    }

    if (files.length === 0) {
      response.errors.push('No files provided');
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (files.length > MAX_FILES_PER_REQUEST) {
      response.errors.push(`Maximum ${MAX_FILES_PER_REQUEST} files allowed per request`);
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Process each file
    const uploadPromises = files.map(async (file) => {
      try {
        return await processFileUpload(file, customerId, category);
      } catch (error) {
        response.errors.push(`Failed to upload "${file.name}": ${error instanceof Error ? error.message : 'Unknown error'}`);
        return null;
      }
    });

    const uploadResults = await Promise.all(uploadPromises);
    response.uploadedFiles = uploadResults.filter(result => result !== null) as typeof response.uploadedFiles;

    // Log upload activity
    console.log(`📁 File upload completed for customer ${customerId}: ${response.uploadedFiles.length} files uploaded, ${response.errors.length} errors`);

    // Set success if at least one file was uploaded
    response.success = response.uploadedFiles.length > 0;

    const statusCode = response.success ? 200 : (response.errors.length > 0 ? 400 : 500);

    return new Response(JSON.stringify(response), {
      status: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'X-Upload-Count': response.uploadedFiles.length.toString(),
        'X-Error-Count': response.errors.length.toString()
      }
    });

  } catch (error) {
    console.error('❌ File upload endpoint error:', error);
    
    response.errors.push('Internal server error during file upload');
    
    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

// Rate limiting helper (to be implemented with Redis in production)
class RateLimiter {
  private requests = new Map<string, number[]>();
  private readonly maxRequests = 10;
  private readonly windowMs = 60000; // 1 minute

  isAllowed(clientId: string): boolean {
    const now = Date.now();
    const windowStart = now - this.windowMs;
    
    if (!this.requests.has(clientId)) {
      this.requests.set(clientId, []);
    }
    
    const clientRequests = this.requests.get(clientId)!;
    
    // Remove old requests
    const validRequests = clientRequests.filter(time => time > windowStart);
    
    if (validRequests.length >= this.maxRequests) {
      return false;
    }
    
    validRequests.push(now);
    this.requests.set(clientId, validRequests);
    
    return true;
  }
}