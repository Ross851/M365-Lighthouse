# PowerReview API Documentation

## 🚀 API Overview

PowerReview provides a comprehensive REST API for security assessment automation, real-time monitoring, and compliance tracking across Microsoft 365 environments. The API is designed with enterprise security, multi-region compliance, and scalability as core principles.

## 🔐 Authentication & Security

### **Authentication Methods**
```javascript
// JWT Bearer Token Authentication
headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'Content-Type': 'application/json',
    'X-API-Version': 'v1'
}

// API Key Authentication (for server-to-server)
headers: {
    'X-API-Key': 'pr_live_abc123...',
    'Content-Type': 'application/json'
}
```

### **Rate Limiting**
- **Free Tier**: 100 requests/hour
- **Professional**: 1,000 requests/hour  
- **Enterprise**: 10,000 requests/hour
- **Rate Limit Headers**: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### **Regional Endpoints**
```bash
# United States
https://api-us.powerreview.com/v1/

# European Union (GDPR Compliant)
https://api-eu.powerreview.com/v1/

# Asia Pacific
https://api-ap.powerreview.com/v1/

# For complete list of 14 regional endpoints, see GLOBAL-COMPLIANCE-GUIDE.md
```

## 📊 Core API Endpoints

### **1. Authentication Endpoints**

#### **POST /auth/login**
Authenticate user and obtain JWT token.

```javascript
// Request
POST /auth/login
Content-Type: application/json

{
    "email": "user@company.com",
    "password": "secure_password",
    "organization_id": "org_123456",
    "mfa_code": "123456" // Optional, required if MFA enabled
}

// Response
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "refresh_abc123...",
    "expires_in": 3600,
    "user": {
        "id": "user_789",
        "email": "user@company.com",
        "role": "security_analyst",
        "organization": {
            "id": "org_123456",
            "name": "Contoso Corporation",
            "region": "us-east"
        }
    }
}
```

#### **POST /auth/refresh**
Refresh expired JWT token.

```javascript
// Request
POST /auth/refresh
Content-Type: application/json

{
    "refresh_token": "refresh_abc123..."
}

// Response
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
}
```

### **2. Assessment Endpoints**

#### **POST /assessments/start**
Start a new security assessment.

```javascript
// Request
POST /assessments/start
Authorization: Bearer {token}
Content-Type: application/json

{
    "assessment_type": "comprehensive", // 'quick', 'comprehensive', 'compliance'
    "scope": {
        "services": ["azuread", "exchange", "sharepoint", "teams"],
        "include_evidence": true,
        "compliance_frameworks": ["GDPR", "HIPAA", "SOC2"]
    },
    "metadata": {
        "purpose": "quarterly_review",
        "requester": "security_team",
        "priority": "high"
    }
}

// Response
{
    "assessment_id": "assess_abc123",
    "status": "running",
    "estimated_completion": "2024-07-12T13:45:00Z",
    "progress": {
        "current_step": "authenticating",
        "completed_checks": 0,
        "total_checks": 347,
        "percentage": 0
    },
    "websocket_url": "wss://api-us.powerreview.com/ws/assessments/assess_abc123"
}
```

#### **GET /assessments/{assessment_id}**
Get assessment status and results.

```javascript
// Request
GET /assessments/assess_abc123
Authorization: Bearer {token}

// Response
{
    "assessment_id": "assess_abc123",
    "status": "completed", // 'pending', 'running', 'completed', 'failed', 'cancelled'
    "created_at": "2024-07-12T13:00:00Z",
    "completed_at": "2024-07-12T13:42:00Z",
    "duration_seconds": 2520,
    "summary": {
        "overall_score": 78,
        "findings": {
            "critical": 3,
            "high": 12,
            "medium": 28,
            "low": 45
        },
        "compliance_scores": {
            "GDPR": 85,
            "HIPAA": 72,
            "SOC2": 68
        }
    },
    "results_url": "/assessments/assess_abc123/results",
    "report_url": "/assessments/assess_abc123/report"
}
```

#### **GET /assessments/{assessment_id}/results**
Get detailed assessment findings.

```javascript
// Request
GET /assessments/assess_abc123/results?severity=critical,high&limit=50
Authorization: Bearer {token}

// Response
{
    "assessment_id": "assess_abc123",
    "total_findings": 88,
    "page": 1,
    "per_page": 50,
    "findings": [
        {
            "finding_id": "finding_001",
            "severity": "critical",
            "category": "identity_access",
            "title": "12% of users lack Multi-Factor Authentication",
            "description": "600 user accounts do not have MFA enabled, including 23 administrative accounts.",
            "service": "azuread",
            "evidence": {
                "screenshots": [
                    "https://evidence.powerreview.com/assess_abc123/mfa_gap_001.png"
                ],
                "configuration_export": "https://evidence.powerreview.com/assess_abc123/aad_config.json",
                "affected_users": [
                    "finance@contoso.com",
                    "hr@contoso.com"
                ]
            },
            "business_impact": {
                "financial_exposure": 2100000,
                "compliance_violations": ["GDPR Article 32", "HIPAA 164.312(a)(2)(i)"],
                "affected_data_types": ["PII", "PHI", "Financial"]
            },
            "remediation": {
                "description": "Enable MFA for all user accounts",
                "effort_hours": 2,
                "cost_estimate": 0,
                "scripts": [
                    {
                        "platform": "powershell",
                        "script": "Set-MsolUser -UserPrincipalName $user -StrongAuthenticationRequirements $mfa"
                    }
                ]
            }
        }
    ]
}
```

### **3. Real-time Monitoring Endpoints**

#### **GET /monitoring/compliance/events**
Server-Sent Events stream for real-time compliance monitoring.

```javascript
// Request
GET /monitoring/compliance/events
Authorization: Bearer {token}
Accept: text/event-stream

// Response Stream
data: {"event_type": "compliance_score_change", "region": "us-east", "framework": "HIPAA", "old_score": 72, "new_score": 75, "timestamp": "2024-07-12T14:30:00Z"}

data: {"event_type": "violation_detected", "severity": "high", "service": "sharepoint", "description": "External sharing enabled on sensitive document", "timestamp": "2024-07-12T14:31:00Z"}

data: {"event_type": "remediation_applied", "finding_id": "finding_001", "action": "mfa_enabled", "user": "finance@contoso.com", "timestamp": "2024-07-12T14:32:00Z"}
```

#### **GET /monitoring/threats/live**
Live threat intelligence feed.

```javascript
// Request
GET /monitoring/threats/live
Authorization: Bearer {token}

// Response
{
    "active_threats": [
        {
            "threat_id": "threat_001",
            "type": "brute_force_attack",
            "severity": "high",
            "source_ip": "185.220.100.252",
            "source_country": "Russia",
            "target_service": "azuread",
            "first_detected": "2024-07-12T14:25:00Z",
            "attempts": 47,
            "status": "blocked"
        }
    ],
    "threat_summary": {
        "last_24h": {
            "total_threats": 234,
            "blocked": 231,
            "successful": 0,
            "under_investigation": 3
        }
    }
}
```

### **4. Compliance & Reporting Endpoints**

#### **GET /compliance/frameworks**
Get compliance framework status across regions.

```javascript
// Request
GET /compliance/frameworks?region=all
Authorization: Bearer {token}

// Response
{
    "frameworks": [
        {
            "framework": "GDPR",
            "regions": ["eu-central", "uk-south"],
            "overall_compliance": 85,
            "requirements": {
                "total": 47,
                "met": 40,
                "partial": 5,
                "not_met": 2
            },
            "gaps": [
                {
                    "requirement": "Article 32 - Security of processing",
                    "status": "partial",
                    "remediation_effort": "medium"
                }
            ],
            "next_review": "2024-10-12"
        }
    ]
}
```

#### **POST /reports/generate**
Generate executive or technical reports.

```javascript
// Request
POST /reports/generate
Authorization: Bearer {token}
Content-Type: application/json

{
    "report_type": "executive", // 'executive', 'technical', 'compliance'
    "assessment_id": "assess_abc123",
    "format": "pdf", // 'pdf', 'docx', 'html', 'json'
    "options": {
        "include_evidence": true,
        "include_remediation_scripts": false,
        "executive_summary": true,
        "roi_analysis": true
    },
    "delivery": {
        "method": "email", // 'email', 'webhook', 'download'
        "recipients": ["ciso@company.com", "security-team@company.com"]
    }
}

// Response
{
    "report_id": "report_xyz789",
    "status": "generating",
    "estimated_completion": "2024-07-12T15:05:00Z",
    "download_url": "/reports/report_xyz789/download", // Available when complete
    "webhook_url": "https://your-app.com/webhooks/reports" // If webhook delivery
}
```

### **5. Data Export & Integration Endpoints**

#### **GET /export/powerbi**
Export data in PowerBI-compatible format.

```javascript
// Request
GET /export/powerbi?assessment_id=assess_abc123&date_range=30d
Authorization: Bearer {token}

// Response
{
    "export_id": "export_123",
    "format": "powerbi_dataset",
    "data_url": "https://api-us.powerreview.com/exports/export_123.pbix",
    "connection_string": "powerquery://api-us.powerreview.com/v1/powerbi/dataset/export_123",
    "refresh_token": "refresh_powerbi_abc",
    "expires_at": "2024-07-13T13:00:00Z"
}
```

#### **GET /export/excel**
Export assessment data to Excel format.

```javascript
// Request
GET /export/excel?assessment_id=assess_abc123&include_charts=true
Authorization: Bearer {token}

// Response
{
    "export_id": "export_456",
    "download_url": "https://api-us.powerreview.com/exports/powerreview_assessment_20240712.xlsx",
    "sheets": [
        "Executive Summary",
        "Detailed Findings",
        "Compliance Matrix",
        "Remediation Plan"
    ],
    "expires_at": "2024-07-19T13:00:00Z"
}
```

## 🔌 WebSocket API

### **Real-time Assessment Updates**
```javascript
// Connect to WebSocket
const ws = new WebSocket('wss://api-us.powerreview.com/ws/assessments/assess_abc123');

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch (data.type) {
        case 'progress_update':
            console.log(`Progress: ${data.percentage}% - ${data.current_step}`);
            break;
            
        case 'finding_discovered':
            console.log(`New ${data.severity} finding: ${data.title}`);
            break;
            
        case 'assessment_complete':
            console.log('Assessment completed successfully');
            break;
            
        case 'error':
            console.error('Assessment error:', data.message);
            break;
    }
};

// Send commands
ws.send(JSON.stringify({
    type: 'pause_assessment'
}));

ws.send(JSON.stringify({
    type: 'resume_assessment'
}));
```

## 📊 Data Models

### **Assessment Model**
```typescript
interface Assessment {
    assessment_id: string;
    organization_id: string;
    status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';
    assessment_type: 'quick' | 'comprehensive' | 'compliance';
    created_at: string; // ISO 8601
    completed_at?: string;
    duration_seconds?: number;
    
    scope: {
        services: string[];
        include_evidence: boolean;
        compliance_frameworks: string[];
    };
    
    summary: {
        overall_score: number;
        findings: {
            critical: number;
            high: number;
            medium: number;
            low: number;
        };
        compliance_scores: Record<string, number>;
    };
    
    metadata: {
        purpose: string;
        requester: string;
        priority: 'low' | 'medium' | 'high';
    };
}
```

### **Finding Model**
```typescript
interface Finding {
    finding_id: string;
    assessment_id: string;
    severity: 'critical' | 'high' | 'medium' | 'low';
    category: string;
    title: string;
    description: string;
    service: string;
    
    evidence: {
        screenshots: string[];
        configuration_export?: string;
        affected_users?: string[];
        log_entries?: string[];
    };
    
    business_impact: {
        financial_exposure: number;
        compliance_violations: string[];
        affected_data_types: string[];
    };
    
    remediation: {
        description: string;
        effort_hours: number;
        cost_estimate: number;
        scripts: Array<{
            platform: string;
            script: string;
        }>;
    };
    
    created_at: string;
    updated_at: string;
}
```

## 🚨 Error Handling

### **Standard Error Response**
```javascript
// Error Response Format
{
    "error": {
        "code": "AUTHENTICATION_FAILED",
        "message": "Invalid or expired token",
        "details": {
            "token_status": "expired",
            "expires_at": "2024-07-12T12:00:00Z"
        },
        "request_id": "req_abc123",
        "documentation_url": "https://docs.powerreview.com/errors/authentication-failed"
    }
}
```

### **Common Error Codes**
```javascript
// Authentication Errors
"AUTHENTICATION_FAILED"     // 401 - Invalid credentials
"TOKEN_EXPIRED"              // 401 - JWT token expired
"INSUFFICIENT_PERMISSIONS"   // 403 - Missing required role

// Request Errors
"VALIDATION_ERROR"           // 400 - Invalid request data
"RESOURCE_NOT_FOUND"         // 404 - Assessment/report not found
"RATE_LIMIT_EXCEEDED"        // 429 - Too many requests

// Server Errors
"ASSESSMENT_FAILED"          // 500 - Internal assessment error
"SERVICE_UNAVAILABLE"        // 503 - Temporary service outage
"REGION_UNAVAILABLE"         // 503 - Regional service down
```

## 🔧 SDK & Libraries

### **JavaScript/TypeScript SDK**
```javascript
// Installation
npm install @powerreview/api-client

// Usage
import { PowerReviewClient } from '@powerreview/api-client';

const client = new PowerReviewClient({
    apiKey: 'pr_live_abc123...',
    region: 'us-east',
    timeout: 30000
});

// Start assessment
const assessment = await client.assessments.start({
    assessment_type: 'comprehensive',
    scope: {
        services: ['azuread', 'exchange'],
        include_evidence: true
    }
});

// Monitor progress
const ws = client.assessments.monitor(assessment.assessment_id);
ws.on('progress', (data) => {
    console.log(`Progress: ${data.percentage}%`);
});

// Get results
const results = await client.assessments.getResults(assessment.assessment_id);
```

### **PowerShell Module**
```powershell
# Installation
Install-Module -Name PowerReview

# Usage
Connect-PowerReview -ApiKey "pr_live_abc123..." -Region "us-east"

# Start assessment
$assessment = Start-PowerReviewAssessment -Type Comprehensive -Services @("AzureAD", "Exchange")

# Get results
$results = Get-PowerReviewResults -AssessmentId $assessment.AssessmentId
```

## 📈 Monitoring & Analytics

### **API Usage Analytics**
```javascript
// Get API usage statistics
GET /analytics/usage?period=30d
Authorization: Bearer {token}

// Response
{
    "period": "30d",
    "requests": {
        "total": 15420,
        "by_endpoint": {
            "/assessments/start": 156,
            "/assessments/{id}": 892,
            "/monitoring/compliance": 2341
        },
        "by_status": {
            "2xx": 14876,
            "4xx": 344,
            "5xx": 200
        }
    },
    "rate_limits": {
        "limit": 10000,
        "used": 8934,
        "remaining": 1066,
        "reset_time": "2024-07-13T00:00:00Z"
    }
}
```

## 🌍 Regional Compliance

### **Data Residency**
```javascript
// Get available regions for your organization
GET /regions/available
Authorization: Bearer {token}

// Response
{
    "available_regions": [
        {
            "region_code": "us-east",
            "name": "United States East",
            "compliance_frameworks": ["HIPAA", "SOC2", "CCPA"],
            "api_endpoint": "https://api-us.powerreview.com"
        },
        {
            "region_code": "eu-central", 
            "name": "European Union Central",
            "compliance_frameworks": ["GDPR"],
            "api_endpoint": "https://api-eu.powerreview.com"
        }
    ],
    "current_region": "us-east",
    "data_residency_policy": "strict" // 'strict', 'flexible'
}
```

## 🔐 Security Best Practices

### **API Security Guidelines**
1. **Use HTTPS Only** - All API calls must use TLS 1.3+
2. **Rotate Tokens** - JWT tokens expire every hour
3. **Store Secrets Securely** - Never hardcode API keys
4. **Validate Webhooks** - Verify webhook signatures
5. **Rate Limit Awareness** - Implement exponential backoff

### **Webhook Security**
```javascript
// Verify webhook signature
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('hex');
    
    return crypto.timingSafeEqual(
        Buffer.from(signature, 'hex'),
        Buffer.from(expectedSignature, 'hex')
    );
}
```

## 📚 Additional Resources

### **API Reference Links**
- **Interactive API Explorer**: https://api.powerreview.com/docs
- **Postman Collection**: https://www.postman.com/powerreview/workspace/powerreview-api
- **OpenAPI Specification**: https://api.powerreview.com/openapi.json
- **Status Page**: https://status.powerreview.com

### **Support & Community**
- **Developer Support**: api-support@powerreview.com
- **Community Forum**: https://community.powerreview.com
- **GitHub Issues**: https://github.com/powerreview/api-issues
- **Changelog**: https://docs.powerreview.com/changelog

---

**Last Updated**: July 2024  
**API Version**: v1  
**Base URL**: https://api-{region}.powerreview.com/v1  
**Support**: api-support@powerreview.com