# PowerReview Database Architecture Guide

## 🗄️ Database Overview

PowerReview uses PostgreSQL as its primary database with enterprise-grade security features including client data isolation, encryption, and multi-region compliance support across 14 global jurisdictions.

## 🏗️ Architecture Principles

### **Multi-Tenant Security**
- **Client Isolation** - Separate schemas per organization
- **Row-Level Security** - Database-enforced access controls
- **Encryption at Rest** - AES-256-GCM for sensitive data
- **Audit Trails** - Comprehensive change tracking

### **Global Compliance**
- **Regional Data Residency** - Data stays within jurisdiction boundaries
- **Retention Policies** - Automated data lifecycle management
- **GDPR Compliance** - Right to erasure and data portability
- **Audit Logging** - Tamper-proof compliance records

## 📊 Database Schema

### **Core Tables Structure**

```sql
-- Primary database schema located in:
-- src/database/schema-postgresql.sql

-- Core organizational structure
├── organizations/          # Client companies
├── users/                 # System users with RBAC
├── assessments/           # Security assessment records
├── assessment_results/    # Detailed findings and evidence
├── compliance_frameworks/ # Regulatory standards tracking
├── audit_logs/           # Security and compliance audit trails
└── regional_data/        # Multi-region data sovereignty
```

### **1. Organizations Table**
```sql
CREATE TABLE organizations (
    organization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    primary_region region_code NOT NULL,
    encryption_key_id VARCHAR(255) NOT NULL,
    compliance_requirements TEXT[],
    data_retention_days INTEGER DEFAULT 2555, -- 7 years
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### **2. Multi-Region Support**
```sql
-- 14 global regions with data sovereignty
CREATE TYPE region_code AS ENUM (
    'us-east',      -- United States (HIPAA, SOC2)
    'eu-central',   -- European Union (GDPR)
    'uk-south',     -- United Kingdom (UK-GDPR)
    'canada-central', -- Canada (PIPEDA)
    'australia-east', -- Australia (Privacy Act)
    'singapore',    -- Singapore (PDPA)
    'japan-east',   -- Japan (APPI)
    'india-central', -- India (DPDP)
    'brazil-south', -- Brazil (LGPD)
    'south-africa', -- South Africa (POPIA)
    'korea-central', -- South Korea (PIPA)
    'hong-kong',    -- Hong Kong (PDPO)
    'new-zealand',  -- New Zealand (Privacy Act)
    'israel'        -- Israel (Privacy Protection Law)
);
```

### **3. Assessment Results with Evidence**
```sql
CREATE TABLE assessment_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID REFERENCES assessments(assessment_id),
    finding_type VARCHAR(50) NOT NULL,
    severity_level VARCHAR(20) CHECK (severity_level IN ('critical', 'high', 'medium', 'low')),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    evidence_data JSONB, -- Screenshots, configurations, etc.
    remediation_script TEXT,
    business_impact TEXT,
    financial_exposure DECIMAL(15,2),
    compliance_violations TEXT[],
    region_code region_code NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### **4. Compliance Framework Tracking**
```sql
CREATE TABLE compliance_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(organization_id),
    framework_name VARCHAR(100) NOT NULL, -- GDPR, HIPAA, SOC2, etc.
    version VARCHAR(50),
    compliance_score INTEGER CHECK (compliance_score >= 0 AND compliance_score <= 100),
    last_assessment TIMESTAMP WITH TIME ZONE,
    next_review_date DATE,
    region_code region_code NOT NULL,
    requirements_met INTEGER DEFAULT 0,
    total_requirements INTEGER,
    gaps_identified TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 🔒 Security Implementation

### **Client Data Isolation**
```sql
-- Row-Level Security (RLS) policies
CREATE POLICY org_isolation ON assessments
    FOR ALL TO authenticated_users
    USING (organization_id = current_setting('app.current_org_id')::UUID);

-- Enable RLS on all sensitive tables
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
```

### **Encryption Functions**
```sql
-- Client-specific encryption using pgcrypto
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
    data TEXT,
    client_key TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN encode(
        pgp_sym_encrypt(data, client_key, 'cipher-algo=aes256'),
        'base64'
    );
END;
$$ LANGUAGE plpgsql;

-- Corresponding decryption function
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(
    encrypted_data TEXT,
    client_key TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(
        decode(encrypted_data, 'base64'),
        client_key
    );
END;
$$ LANGUAGE plpgsql;
```

### **Audit Trail Implementation**
```sql
-- Comprehensive audit logging
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(organization_id),
    user_id UUID REFERENCES users(user_id),
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    region_code region_code NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function for automatic audit logging
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (
        organization_id,
        action_type,
        table_name,
        record_id,
        old_values,
        new_values,
        region_code
    ) VALUES (
        COALESCE(NEW.organization_id, OLD.organization_id),
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.assessment_id, OLD.assessment_id),
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
        COALESCE(NEW.region_code, OLD.region_code)
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

## 🌍 Multi-Region Configuration

### **Regional Database Setup**
```yaml
# Each region maintains its own database instance
# Configuration in production/database-regions.yml

regions:
  us-east:
    host: powerreview-us-east.postgres.database.azure.com
    compliance: ["HIPAA", "SOC2", "CCPA"]
    retention_days: 2555  # 7 years for HIPAA
    
  eu-central:
    host: powerreview-eu-central.postgres.database.azure.com
    compliance: ["GDPR"]
    retention_days: 1095  # 3 years for GDPR
    
  singapore:
    host: powerreview-singapore.postgres.database.azure.com
    compliance: ["PDPA"]
    retention_days: 1825  # 5 years for PDPA
```

### **Cross-Region Data Synchronization**
```sql
-- Metadata replication for global insights
CREATE TABLE cross_region_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL,
    source_region region_code NOT NULL,
    data_type VARCHAR(100) NOT NULL,
    aggregated_data JSONB NOT NULL, -- Anonymized/aggregated only
    last_sync TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 📈 Performance Optimization

### **Indexing Strategy**
```sql
-- Performance indexes for common queries
CREATE INDEX idx_assessments_org_created ON assessments(organization_id, created_at DESC);
CREATE INDEX idx_results_assessment_severity ON assessment_results(assessment_id, severity_level);
CREATE INDEX idx_compliance_org_framework ON compliance_frameworks(organization_id, framework_name);
CREATE INDEX idx_audit_logs_org_timestamp ON audit_logs(organization_id, timestamp DESC);

-- Regional data distribution
CREATE INDEX idx_regional_data ON assessments(region_code, created_at);
CREATE INDEX idx_compliance_region ON compliance_frameworks(region_code, last_assessment);
```

### **Connection Pooling Configuration**
```javascript
// Database connection pool settings
// Located in: src/lib/database-service.ts

const poolConfig = {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: 5432,
    max: 20,                    // Maximum connections
    idleTimeoutMillis: 30000,   // Close idle connections after 30s
    connectionTimeoutMillis: 2000, // Timeout connection attempts after 2s
    ssl: {
        rejectUnauthorized: false,
        ca: process.env.DB_SSL_CERT
    }
};
```

## 🔧 Database Operations

### **Setup and Initialization**
```bash
# Initialize new regional database
./scripts/setup-postgresql.sh --region us-east --compliance HIPAA,SOC2

# Run migrations
npm run db:migrate

# Seed test data
npm run db:seed --environment development
```

### **Backup and Recovery**
```bash
# Automated daily backups
pg_dump -h $DB_HOST -U $DB_USER -d powerreview_production \
  --no-password --format=custom --compress=9 \
  --file=backup_$(date +%Y%m%d_%H%M%S).dump

# Point-in-time recovery
pg_restore -h $DB_HOST -U $DB_USER -d powerreview_production \
  --clean --if-exists backup_20240712_120000.dump
```

### **Data Retention and Cleanup**
```sql
-- Automated data lifecycle management
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    org_record RECORD;
BEGIN
    -- Process each organization's retention policy
    FOR org_record IN 
        SELECT organization_id, data_retention_days 
        FROM organizations 
    LOOP
        -- Delete expired assessments
        DELETE FROM assessments 
        WHERE organization_id = org_record.organization_id 
        AND created_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * org_record.data_retention_days;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
    END LOOP;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily cleanup
SELECT cron.schedule('cleanup-expired-data', '0 2 * * *', 'SELECT cleanup_expired_data();');
```

## 🛡️ Security Best Practices

### **Database Hardening**
```sql
-- Create dedicated application user with minimal privileges
CREATE USER powerreview_app WITH PASSWORD 'secure_random_password';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE powerreview TO powerreview_app;
GRANT USAGE ON SCHEMA public TO powerreview_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO powerreview_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO powerreview_app;

-- Revoke dangerous permissions
REVOKE CREATE ON SCHEMA public FROM powerreview_app;
REVOKE DROP ON ALL TABLES IN SCHEMA public FROM powerreview_app;
```

### **Encryption Key Management**
```javascript
// Key rotation strategy
// Located in: src/lib/encryption-manager.ts

class EncryptionKeyManager {
    async rotateClientKeys(organizationId: string) {
        // Generate new encryption key
        const newKey = await crypto.randomBytes(32).toString('hex');
        
        // Re-encrypt all data with new key
        await this.reencryptClientData(organizationId, newKey);
        
        // Update key in secure vault
        await this.updateKeyInVault(organizationId, newKey);
        
        // Audit the key rotation
        await this.auditKeyRotation(organizationId);
    }
}
```

## 📊 Monitoring and Alerting

### **Database Health Monitoring**
```sql
-- Query performance monitoring
CREATE VIEW slow_queries AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE mean_time > 1000  -- Queries slower than 1 second
ORDER BY mean_time DESC;

-- Connection monitoring
CREATE VIEW connection_stats AS
SELECT 
    datname,
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    tup_returned,
    tup_fetched
FROM pg_stat_database
WHERE datname = 'powerreview_production';
```

### **Automated Alerts**
```javascript
// Database monitoring alerts
// Located in: src/lib/monitoring/database-alerts.ts

const monitoringChecks = {
    connectionCount: {
        threshold: 80,  // Alert at 80% of max connections
        query: "SELECT count(*) FROM pg_stat_activity WHERE state = 'active'"
    },
    
    slowQueries: {
        threshold: 5,   // Alert if >5 queries taking >1s
        query: "SELECT count(*) FROM pg_stat_statements WHERE mean_time > 1000"
    },
    
    diskSpace: {
        threshold: 85,  // Alert at 85% disk usage
        query: "SELECT (used/total)*100 FROM pg_stat_database_disk_usage"
    }
};
```

## 🔄 Migration and Versioning

### **Database Migrations**
```sql
-- Migration versioning table
CREATE TABLE schema_migrations (
    version VARCHAR(20) PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Example migration: v2.1.0 - Add threat intelligence tables
-- migrations/v2.1.0_add_threat_intelligence.sql
CREATE TABLE threat_indicators (
    indicator_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(organization_id),
    indicator_type VARCHAR(50) NOT NULL,
    indicator_value TEXT NOT NULL,
    threat_level VARCHAR(20) CHECK (threat_level IN ('critical', 'high', 'medium', 'low')),
    source VARCHAR(100),
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    region_code region_code NOT NULL
);

INSERT INTO schema_migrations (version, description) 
VALUES ('v2.1.0', 'Add threat intelligence tables');
```

## 📁 File Structure

```
database/
├── schema-postgresql.sql           # Complete database schema
├── migrations/                     # Version-controlled schema changes
│   ├── v2.0.0_initial_schema.sql
│   ├── v2.1.0_add_threat_intelligence.sql
│   └── v2.2.0_enhance_compliance.sql
├── functions/                      # Stored procedures
│   ├── encryption_functions.sql
│   ├── audit_triggers.sql
│   └── cleanup_procedures.sql
├── indexes/                        # Performance optimization
│   ├── core_indexes.sql
│   └── regional_indexes.sql
└── seeds/                         # Test data
    ├── development_seed.sql
    └── production_minimal_seed.sql
```

## 🚀 Production Deployment

### **Azure PostgreSQL Configuration**
```yaml
# Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "powerreview" {
  name                = "powerreview-${var.region}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  sku_name   = "GP_Standard_D4s_v3"  # 4 vCPU, 16GB RAM
  storage_mb = 1048576                # 1TB storage
  version    = "13"
  
  backup_retention_days        = 35
  geo_redundant_backup_enabled = true
  
  # High availability for production
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  
  # Security configuration
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled          = true
    tenant_id                     = var.tenant_id
  }
}
```

### **Connection String Examples**
```bash
# Production connection string
DATABASE_URL="postgresql://powerreview_app:${DB_PASSWORD}@powerreview-${REGION}.postgres.database.azure.com:5432/powerreview_production?sslmode=require"

# Development connection string
DATABASE_URL="postgresql://powerreview_dev:${DB_PASSWORD}@localhost:5432/powerreview_development"
```

---

**Last Updated**: July 2024  
**Database Version**: PostgreSQL 13+  
**Schema Version**: v2.1.0  
**Supported Regions**: 14 Global Jurisdictions