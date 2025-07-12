-- PowerReview Production Database Schema (PostgreSQL)
-- Multi-Region Compliant Data Architecture
-- Created: 2025-01-12
-- Security Level: RESTRICTED

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =================================================================
-- REGIONAL CONFIGURATION TABLES
-- =================================================================

-- Global regions configuration
DROP TABLE IF EXISTS regions CASCADE;
CREATE TABLE regions (
    region_code VARCHAR(20) PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    data_center_location VARCHAR(200) NOT NULL,
    compliance_standards JSONB NOT NULL DEFAULT '[]'::jsonb,
    encryption_requirements VARCHAR(200) NOT NULL,
    data_residency_laws JSONB NOT NULL DEFAULT '[]'::jsonb,
    languages JSONB NOT NULL DEFAULT '[]'::jsonb,
    time_zone VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert global regions
INSERT INTO regions (region_code, region_name, jurisdiction, data_center_location, compliance_standards, encryption_requirements, data_residency_laws, languages, time_zone) VALUES
('us-east', 'United States East', 'United States', 'Virginia, USA', 
 '["SOC2", "NIST", "CCPA", "HIPAA"]'::jsonb, 'FIPS 140-2 Level 3', 
 '["US CLOUD Act", "State Privacy Laws"]'::jsonb, '["en-US"]'::jsonb, 'America/New_York'),
('us-west', 'United States West', 'United States', 'California, USA',
 '["SOC2", "NIST", "CCPA", "HIPAA"]'::jsonb, 'FIPS 140-2 Level 3',
 '["US CLOUD Act", "CCPA"]'::jsonb, '["en-US"]'::jsonb, 'America/Los_Angeles'),
('canada', 'Canada', 'Canada', 'Toronto, Canada',
 '["SOC2", "PIPEDA", "NIST"]'::jsonb, 'CSE-approved encryption',
 '["PIPEDA", "Provincial Privacy Acts"]'::jsonb, '["en-CA", "fr-CA"]'::jsonb, 'America/Toronto'),
('eu-central', 'European Union Central', 'European Union', 'Frankfurt, Germany',
 '["GDPR", "ISO27001", "SOC2"]'::jsonb, 'Common Criteria EAL4+',
 '["GDPR", "EU Data Act", "Digital Services Act"]'::jsonb, '["de-DE", "en-EU"]'::jsonb, 'Europe/Berlin'),
('eu-west', 'European Union West', 'European Union', 'Dublin, Ireland',
 '["GDPR", "ISO27001", "SOC2"]'::jsonb, 'Common Criteria EAL4+',
 '["GDPR", "Irish Data Protection Act"]'::jsonb, '["en-IE", "ga-IE"]'::jsonb, 'Europe/Dublin'),
('uk', 'United Kingdom', 'United Kingdom', 'London, UK',
 '["UK GDPR", "ISO27001", "SOC2"]'::jsonb, 'NCSC-approved encryption',
 '["UK GDPR", "Data Protection Act 2018"]'::jsonb, '["en-GB"]'::jsonb, 'Europe/London'),
('japan', 'Japan', 'Japan', 'Tokyo, Japan',
 '["APPI", "ISO27001", "ISMS"]'::jsonb, 'CRYPTREC-approved encryption',
 '["Personal Information Protection Act", "Cybersecurity Basic Act"]'::jsonb, '["ja-JP", "en-JP"]'::jsonb, 'Asia/Tokyo'),
('australia', 'Australia', 'Australia', 'Sydney, Australia',
 '["Privacy Act", "ISO27001", "SOC2"]'::jsonb, 'ASD-approved encryption',
 '["Privacy Act 1988", "Telecommunications Act"]'::jsonb, '["en-AU"]'::jsonb, 'Australia/Sydney'),
('singapore', 'Singapore', 'Singapore', 'Singapore',
 '["PDPA", "ISO27001", "MAS Guidelines"]'::jsonb, 'CSA-approved encryption',
 '["Personal Data Protection Act", "Banking Act"]'::jsonb, '["en-SG", "zh-SG", "ms-SG", "ta-SG"]'::jsonb, 'Asia/Singapore'),
('south-korea', 'South Korea', 'South Korea', 'Seoul, South Korea',
 '["PIPA", "K-ISMS", "ISO27001"]'::jsonb, 'KISA-approved encryption',
 '["Personal Information Protection Act", "Information Communications Network Act"]'::jsonb, '["ko-KR", "en-KR"]'::jsonb, 'Asia/Seoul'),
('malaysia', 'Malaysia', 'Malaysia', 'Kuala Lumpur, Malaysia',
 '["PDPA MY", "ISO27001", "MFCA Guidelines"]'::jsonb, 'CyberSecurity Malaysia approved',
 '["Personal Data Protection Act 2010", "Computer Crimes Act"]'::jsonb, '["ms-MY", "en-MY", "zh-MY"]'::jsonb, 'Asia/Kuala_Lumpur'),
('thailand', 'Thailand', 'Thailand', 'Bangkok, Thailand',
 '["PDPA TH", "ISO27001"]'::jsonb, 'ETDA-approved encryption',
 '["Personal Data Protection Act B.E. 2562", "Cybersecurity Act"]'::jsonb, '["th-TH", "en-TH"]'::jsonb, 'Asia/Bangkok'),
('philippines', 'Philippines', 'Philippines', 'Manila, Philippines',
 '["DPA PH", "ISO27001", "BSP Guidelines"]'::jsonb, 'DOST-approved encryption',
 '["Data Privacy Act of 2012", "Central Bank Regulations"]'::jsonb, '["fil-PH", "en-PH"]'::jsonb, 'Asia/Manila'),
('indonesia', 'Indonesia', 'Indonesia', 'Jakarta, Indonesia',
 '["UU PDP", "ISO27001", "OJK Guidelines"]'::jsonb, 'BSN-approved encryption',
 '["Personal Data Protection Law", "Electronic Information Law"]'::jsonb, '["id-ID", "en-ID"]'::jsonb, 'Asia/Jakarta'),
('vietnam', 'Vietnam', 'Vietnam', 'Ho Chi Minh City, Vietnam',
 '["PDPD", "Cybersecurity Law", "ISO27001"]'::jsonb, 'VGCA-approved encryption',
 '["Personal Data Protection Decree", "Cybersecurity Law 2018"]'::jsonb, '["vi-VN", "en-VN"]'::jsonb, 'Asia/Ho_Chi_Minh');

-- =================================================================
-- CLIENT MANAGEMENT TABLES
-- =================================================================

-- Clients table
DROP TABLE IF EXISTS clients CASCADE;
CREATE TABLE clients (
    client_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100) NOT NULL,
    primary_region_code VARCHAR(20) NOT NULL REFERENCES regions(region_code),
    secondary_regions JSONB DEFAULT '[]'::jsonb,
    employee_count INTEGER,
    annual_revenue_usd DECIMAL(15,2),
    contract_type VARCHAR(50) DEFAULT 'Standard',
    compliance_requirements JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    onboarding_date DATE,
    renewal_date DATE,
    account_manager VARCHAR(255),
    technical_contact JSONB,
    billing_contact JSONB,
    security_contact JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255)
);

-- Client data residency rules
DROP TABLE IF EXISTS client_data_residency CASCADE;
CREATE TABLE client_data_residency (
    residency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(client_id),
    region_code VARCHAR(20) NOT NULL REFERENCES regions(region_code),
    data_types JSONB NOT NULL DEFAULT '[]'::jsonb,
    must_stay_in_region BOOLEAN DEFAULT true,
    cross_border_transfer_allowed BOOLEAN DEFAULT false,
    allowed_transfer_regions JSONB DEFAULT '[]'::jsonb,
    compliance_standards JSONB NOT NULL DEFAULT '[]'::jsonb,
    encryption_standard VARCHAR(200) NOT NULL,
    retention_period_days INTEGER NOT NULL DEFAULT 2555,
    special_requirements TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, region_code)
);

-- =================================================================
-- USER AND ACCESS MANAGEMENT
-- =================================================================

-- Users table
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    azure_ad_object_id VARCHAR(255) UNIQUE,
    auth_provider VARCHAR(50) DEFAULT 'AzureAD',
    password_hash VARCHAR(255),
    mfa_enabled BOOLEAN DEFAULT false,
    mfa_secret_encrypted TEXT,
    last_login TIMESTAMPTZ,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    allowed_regions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_password_change TIMESTAMPTZ,
    password_expiry_date TIMESTAMPTZ,
    must_change_password BOOLEAN DEFAULT false
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_azure_ad ON users(azure_ad_object_id);

-- Roles table
DROP TABLE IF EXISTS roles CASCADE;
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert default roles
INSERT INTO roles (role_name, description, is_system_role) VALUES
('System Administrator', 'Full system access', true),
('Client Administrator', 'Full access to assigned clients', true),
('Compliance Officer', 'Read access to compliance data, write access to assessments', true),
('Auditor', 'Read-only access to all audit logs and compliance data', true),
('Viewer', 'Read-only access to assigned clients', true);

-- Permissions table
DROP TABLE IF EXISTS permissions CASCADE;
CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(100) UNIQUE NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert default permissions
INSERT INTO permissions (permission_name, resource_type, action, description) VALUES
('admin:all', '*', 'admin', 'Full administrative access'),
('read:all', '*', 'read', 'Read access to all resources'),
('write:all', '*', 'write', 'Write access to all resources'),
('read:client', 'client', 'read', 'Read client data'),
('write:client', 'client', 'write', 'Modify client data'),
('read:assessment', 'assessment', 'read', 'Read assessments'),
('write:assessment', 'assessment', 'write', 'Create/modify assessments'),
('read:compliance', 'compliance', 'read', 'Read compliance data'),
('audit:view', 'audit', 'read', 'View audit logs'),
('export:data', '*', 'export', 'Export data');

-- Role permissions mapping
DROP TABLE IF EXISTS role_permissions CASCADE;
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(role_id),
    permission_id UUID NOT NULL REFERENCES permissions(permission_id),
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    granted_by VARCHAR(255),
    PRIMARY KEY (role_id, permission_id)
);

-- User roles mapping
DROP TABLE IF EXISTS user_roles CASCADE;
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(user_id),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    client_id UUID REFERENCES clients(client_id),
    allowed_regions JSONB DEFAULT '[]'::jsonb,
    valid_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMPTZ,
    granted_by VARCHAR(255),
    PRIMARY KEY (user_id, role_id, COALESCE(client_id, '00000000-0000-0000-0000-000000000000'::uuid))
);

-- =================================================================
-- SECURE DATA STORAGE
-- =================================================================

-- Secure data storage with encryption
DROP TABLE IF EXISTS secure_data_storage CASCADE;
CREATE TABLE secure_data_storage (
    record_id VARCHAR(32) PRIMARY KEY,
    client_id UUID NOT NULL REFERENCES clients(client_id),
    data_type VARCHAR(50) NOT NULL,
    region_code VARCHAR(20) NOT NULL REFERENCES regions(region_code),
    encrypted_data TEXT NOT NULL,
    data_classification VARCHAR(20) DEFAULT 'confidential',
    data_size_bytes BIGINT,
    encryption_version INTEGER DEFAULT 1,
    checksum VARCHAR(64),
    is_compressed BOOLEAN DEFAULT false,
    retention_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) NOT NULL,
    last_accessed TIMESTAMPTZ,
    last_accessed_by VARCHAR(255),
    access_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT false,
    archived_at TIMESTAMPTZ,
    archived_by VARCHAR(255)
);

-- Create indexes
CREATE INDEX idx_secure_data_client ON secure_data_storage(client_id);
CREATE INDEX idx_secure_data_type ON secure_data_storage(data_type);
CREATE INDEX idx_secure_data_region ON secure_data_storage(region_code);
CREATE INDEX idx_secure_data_retention ON secure_data_storage(retention_until);

-- =================================================================
-- ASSESSMENT MANAGEMENT
-- =================================================================

-- Assessment types
DROP TABLE IF EXISTS assessment_types CASCADE;
CREATE TABLE assessment_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    base_score INTEGER DEFAULT 100,
    weight_factor DECIMAL(3,2) DEFAULT 1.0,
    required_evidence JSONB DEFAULT '[]'::jsonb,
    questionnaire_template JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Assessments
DROP TABLE IF EXISTS assessments CASCADE;
CREATE TABLE assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(client_id),
    assessment_type_id UUID NOT NULL REFERENCES assessment_types(type_id),
    assessment_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'planned',
    scheduled_date DATE,
    start_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    lead_assessor VARCHAR(255),
    assessment_team JSONB DEFAULT '[]'::jsonb,
    scope JSONB,
    objectives TEXT,
    methodology VARCHAR(100),
    risk_rating VARCHAR(20),
    overall_score DECIMAL(5,2),
    findings_summary TEXT,
    recommendations JSONB,
    evidence_collected JSONB,
    client_stakeholders JSONB,
    is_remote BOOLEAN DEFAULT false,
    region_code VARCHAR(20) REFERENCES regions(region_code),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(255),
    signed_off_by VARCHAR(255),
    signed_off_at TIMESTAMPTZ
);

-- Assessment findings
DROP TABLE IF EXISTS assessment_findings CASCADE;
CREATE TABLE assessment_findings (
    finding_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES assessments(assessment_id),
    finding_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    impact TEXT,
    likelihood VARCHAR(20),
    risk_score INTEGER,
    current_controls TEXT,
    recommendations TEXT,
    evidence_references JSONB DEFAULT '[]'::jsonb,
    affected_systems JSONB DEFAULT '[]'::jsonb,
    compliance_references JSONB DEFAULT '[]'::jsonb,
    remediation_priority VARCHAR(20),
    remediation_timeline VARCHAR(50),
    assigned_to VARCHAR(255),
    status VARCHAR(50) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    resolved_at TIMESTAMPTZ,
    resolved_by VARCHAR(255),
    resolution_notes TEXT
);

-- =================================================================
-- REGIONAL DATA STORAGE TRACKING
-- =================================================================

-- Regional data storage statistics
DROP TABLE IF EXISTS regional_data_storage CASCADE;
CREATE TABLE regional_data_storage (
    client_id UUID NOT NULL REFERENCES clients(client_id),
    region_code VARCHAR(20) NOT NULL REFERENCES regions(region_code),
    data_type VARCHAR(50) NOT NULL,
    record_count INTEGER DEFAULT 0,
    storage_size_mb DECIMAL(15,2) DEFAULT 0,
    compliance_score DECIMAL(5,2) DEFAULT 100,
    data_residency_status VARCHAR(20) DEFAULT 'compliant',
    encryption_status VARCHAR(20) DEFAULT 'encrypted',
    last_compliance_check TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_integrity_check TIMESTAMPTZ,
    integrity_check_result VARCHAR(20),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (client_id, region_code, data_type)
);

-- =================================================================
-- AUDIT AND COMPLIANCE
-- =================================================================

-- Audit logs table
DROP TABLE IF EXISTS audit_logs CASCADE;
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    user_id VARCHAR(255),
    client_id UUID REFERENCES clients(client_id),
    region_code VARCHAR(20) REFERENCES regions(region_code),
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    event_description TEXT NOT NULL,
    operation_result VARCHAR(20) NOT NULL,
    error_details TEXT,
    records_affected INTEGER DEFAULT 0,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(64),
    request_id VARCHAR(64),
    additional_data JSONB,
    is_security_event BOOLEAN DEFAULT false,
    is_compliance_event BOOLEAN DEFAULT false
);

-- Create indexes for audit performance
CREATE INDEX idx_audit_timestamp ON audit_logs(event_timestamp);
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_client ON audit_logs(client_id);
CREATE INDEX idx_audit_type ON audit_logs(event_type);
CREATE INDEX idx_audit_security ON audit_logs(is_security_event) WHERE is_security_event = true;

-- Compliance tracking
DROP TABLE IF EXISTS compliance_tracking CASCADE;
CREATE TABLE compliance_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(client_id),
    region_code VARCHAR(20) NOT NULL REFERENCES regions(region_code),
    compliance_standard VARCHAR(100) NOT NULL,
    assessment_date DATE NOT NULL,
    compliance_score DECIMAL(5,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    findings JSONB,
    remediation_required BOOLEAN DEFAULT false,
    remediation_deadline DATE,
    next_assessment_date DATE,
    assessor VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =================================================================
-- SESSION MANAGEMENT
-- =================================================================

-- Active sessions
DROP TABLE IF EXISTS active_sessions CASCADE;
CREATE TABLE active_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    access_token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    last_activity TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ip_address INET NOT NULL,
    user_agent TEXT,
    mfa_verified BOOLEAN DEFAULT false,
    permissions JSONB DEFAULT '[]'::jsonb,
    allowed_clients JSONB DEFAULT '[]'::jsonb,
    allowed_regions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create index for session cleanup
CREATE INDEX idx_sessions_expires ON active_sessions(expires_at);
CREATE INDEX idx_sessions_user ON active_sessions(user_id);

-- =================================================================
-- FUNCTIONS AND TRIGGERS
-- =================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to all tables with updated_at
CREATE TRIGGER update_regions_updated_at BEFORE UPDATE ON regions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check data residency compliance
CREATE OR REPLACE FUNCTION check_data_residency_compliance(
    p_client_id UUID,
    p_data_type VARCHAR,
    p_region_code VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_allowed BOOLEAN;
BEGIN
    SELECT 
        CASE 
            WHEN must_stay_in_region = true AND region_code != p_region_code THEN false
            WHEN cross_border_transfer_allowed = false AND region_code != p_region_code THEN false
            ELSE true
        END INTO v_allowed
    FROM client_data_residency
    WHERE client_id = p_client_id
    AND p_data_type = ANY(data_types::text[])
    LIMIT 1;
    
    RETURN COALESCE(v_allowed, true);
END;
$$ LANGUAGE plpgsql;

-- Function to encrypt sensitive data (placeholder - actual encryption in app layer)
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(p_data TEXT, p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    -- In production, this would use pgcrypto
    -- For now, return a placeholder indicating encryption
    RETURN pgp_sym_encrypt(p_data, p_key);
END;
$$ LANGUAGE plpgsql;

-- Function to decrypt sensitive data (placeholder - actual decryption in app layer)
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(p_encrypted_data TEXT, p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    -- In production, this would use pgcrypto
    -- For now, return a placeholder
    RETURN pgp_sym_decrypt(p_encrypted_data::bytea, p_key);
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- VIEWS FOR REPORTING
-- =================================================================

-- Client compliance overview
CREATE OR REPLACE VIEW v_client_compliance_overview AS
SELECT 
    c.client_id,
    c.organization_name,
    c.primary_region_code,
    r.region_name as primary_region_name,
    COUNT(DISTINCT ct.compliance_standard) as total_standards,
    AVG(ct.compliance_score) as average_compliance_score,
    MIN(ct.compliance_score) as lowest_compliance_score,
    MAX(ct.next_assessment_date) as next_assessment_due,
    COUNT(CASE WHEN ct.remediation_required = true THEN 1 END) as remediation_items
FROM clients c
JOIN regions r ON c.primary_region_code = r.region_code
LEFT JOIN compliance_tracking ct ON c.client_id = ct.client_id
WHERE c.is_active = true
GROUP BY c.client_id, c.organization_name, c.primary_region_code, r.region_name;

-- Regional data distribution
CREATE OR REPLACE VIEW v_regional_data_distribution AS
SELECT 
    r.region_code,
    r.region_name,
    r.jurisdiction,
    COUNT(DISTINCT rds.client_id) as client_count,
    SUM(rds.record_count) as total_records,
    SUM(rds.storage_size_mb) as total_storage_mb,
    AVG(rds.compliance_score) as avg_compliance_score,
    COUNT(CASE WHEN rds.data_residency_status != 'compliant' THEN 1 END) as violations
FROM regions r
LEFT JOIN regional_data_storage rds ON r.region_code = rds.region_code
GROUP BY r.region_code, r.region_name, r.jurisdiction;

-- =================================================================
-- GRANTS AND PERMISSIONS
-- =================================================================

-- Create read-only role
CREATE ROLE powerreview_readonly;
GRANT CONNECT ON DATABASE powerreview_dev TO powerreview_readonly;
GRANT USAGE ON SCHEMA public TO powerreview_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO powerreview_readonly;

-- Create application role
CREATE ROLE powerreview_app;
GRANT CONNECT ON DATABASE powerreview_dev TO powerreview_app;
GRANT USAGE ON SCHEMA public TO powerreview_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO powerreview_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO powerreview_app;

-- Grant roles to user
GRANT powerreview_app TO powerreview_user;

-- =================================================================
-- INITIAL DATA AND CONFIGURATION
-- =================================================================

-- Set up initial admin user (password should be changed immediately)
INSERT INTO users (username, email, display_name, is_admin, is_active) 
VALUES ('admin', 'admin@powerreview.local', 'System Administrator', true, true)
ON CONFLICT (username) DO NOTHING;

-- Add success message
DO $$
BEGIN
    RAISE NOTICE 'PowerReview PostgreSQL schema created successfully!';
    RAISE NOTICE 'Database is ready for multi-region compliance management.';
END $$;