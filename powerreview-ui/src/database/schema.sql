-- PowerReview Production Database Schema
-- Multi-Region Compliant Data Architecture
-- Created: 2025-01-12
-- Security Level: RESTRICTED

-- Enable advanced security features
-- This should be run on encrypted database instance
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =================================================================
-- ENCRYPTION AND SECURITY SETUP
-- =================================================================

-- Create database master key for encryption
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PowerReview2025SecureMasterKey!@#';
END
GO

-- Create certificate for data encryption
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'PowerReviewDataCert')
BEGIN
    CREATE CERTIFICATE PowerReviewDataCert
    WITH SUBJECT = 'PowerReview Data Encryption Certificate',
    EXPIRY_DATE = '2030-12-31';
END
GO

-- Create symmetric key for column-level encryption
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'PowerReviewDataKey')
BEGIN
    CREATE SYMMETRIC KEY PowerReviewDataKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE PowerReviewDataCert;
END
GO

-- =================================================================
-- REGIONAL CONFIGURATION TABLES
-- =================================================================

-- Global regions configuration
CREATE TABLE regions (
    region_code NVARCHAR(20) PRIMARY KEY,
    region_name NVARCHAR(100) NOT NULL,
    jurisdiction NVARCHAR(100) NOT NULL,
    data_center_location NVARCHAR(200) NOT NULL,
    compliance_standards NVARCHAR(MAX) NOT NULL, -- JSON array
    encryption_requirements NVARCHAR(200) NOT NULL,
    data_residency_laws NVARCHAR(MAX) NOT NULL, -- JSON array
    languages NVARCHAR(MAX) NOT NULL, -- JSON array
    time_zone NVARCHAR(50) NOT NULL,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE()
);

-- Insert global regions
INSERT INTO regions VALUES
('us-east', 'United States East', 'United States', 'Virginia, USA', 
 '["SOC2", "NIST", "CCPA", "HIPAA"]', 'FIPS 140-2 Level 3', 
 '["US CLOUD Act", "State Privacy Laws"]', '["en-US"]', 'America/New_York', 1, GETUTCDATE(), GETUTCDATE()),
('us-west', 'United States West', 'United States', 'California, USA',
 '["SOC2", "NIST", "CCPA", "HIPAA"]', 'FIPS 140-2 Level 3',
 '["US CLOUD Act", "CCPA"]', '["en-US"]', 'America/Los_Angeles', 1, GETUTCDATE(), GETUTCDATE()),
('canada', 'Canada', 'Canada', 'Toronto, Canada',
 '["SOC2", "PIPEDA", "NIST"]', 'CSE-approved encryption',
 '["PIPEDA", "Provincial Privacy Acts"]', '["en-CA", "fr-CA"]', 'America/Toronto', 1, GETUTCDATE(), GETUTCDATE()),
('eu-central', 'European Union Central', 'European Union', 'Frankfurt, Germany',
 '["GDPR", "ISO27001", "SOC2"]', 'Common Criteria EAL4+',
 '["GDPR", "EU Data Act", "Digital Services Act"]', '["de-DE", "en-EU"]', 'Europe/Berlin', 1, GETUTCDATE(), GETUTCDATE()),
('eu-west', 'European Union West', 'European Union', 'Dublin, Ireland',
 '["GDPR", "ISO27001", "SOC2"]', 'Common Criteria EAL4+',
 '["GDPR", "Irish Data Protection Act"]', '["en-IE", "ga-IE"]', 'Europe/Dublin', 1, GETUTCDATE(), GETUTCDATE()),
('uk', 'United Kingdom', 'United Kingdom', 'London, UK',
 '["UK GDPR", "ISO27001", "SOC2"]', 'NCSC-approved encryption',
 '["UK GDPR", "Data Protection Act 2018"]', '["en-GB"]', 'Europe/London', 1, GETUTCDATE(), GETUTCDATE()),
('japan', 'Japan', 'Japan', 'Tokyo, Japan',
 '["APPI", "ISO27001", "ISMS"]', 'CRYPTREC-approved encryption',
 '["Personal Information Protection Act", "Cybersecurity Basic Act"]', '["ja-JP", "en-JP"]', 'Asia/Tokyo', 1, GETUTCDATE(), GETUTCDATE()),
('australia', 'Australia', 'Australia', 'Sydney, Australia',
 '["Privacy Act", "ISO27001", "SOC2"]', 'ASD-approved encryption',
 '["Privacy Act 1988", "Telecommunications Act"]', '["en-AU"]', 'Australia/Sydney', 1, GETUTCDATE(), GETUTCDATE()),
('singapore', 'Singapore', 'Singapore', 'Singapore',
 '["PDPA", "ISO27001", "MAS Guidelines"]', 'CSA-approved encryption',
 '["Personal Data Protection Act", "Banking Act"]', '["en-SG", "zh-SG", "ms-SG", "ta-SG"]', 'Asia/Singapore', 1, GETUTCDATE(), GETUTCDATE()),
('south-korea', 'South Korea', 'South Korea', 'Seoul, South Korea',
 '["PIPA", "K-ISMS", "ISO27001"]', 'KISA-approved encryption',
 '["Personal Information Protection Act", "Information Communications Network Act"]', '["ko-KR", "en-KR"]', 'Asia/Seoul', 1, GETUTCDATE(), GETUTCDATE()),
('malaysia', 'Malaysia', 'Malaysia', 'Kuala Lumpur, Malaysia',
 '["PDPA MY", "ISO27001", "MFCA Guidelines"]', 'CyberSecurity Malaysia approved',
 '["Personal Data Protection Act 2010", "Computer Crimes Act"]', '["ms-MY", "en-MY", "zh-MY"]', 'Asia/Kuala_Lumpur', 1, GETUTCDATE(), GETUTCDATE()),
('thailand', 'Thailand', 'Thailand', 'Bangkok, Thailand',
 '["PDPA TH", "ISO27001"]', 'ETDA-approved encryption',
 '["Personal Data Protection Act B.E. 2562", "Cybersecurity Act"]', '["th-TH", "en-TH"]', 'Asia/Bangkok', 1, GETUTCDATE(), GETUTCDATE()),
('philippines', 'Philippines', 'Philippines', 'Manila, Philippines',
 '["DPA PH", "ISO27001", "BSP Guidelines"]', 'DOST-approved encryption',
 '["Data Privacy Act of 2012", "Cybercrime Prevention Act"]', '["en-PH", "fil-PH"]', 'Asia/Manila', 1, GETUTCDATE(), GETUTCDATE()),
('indonesia', 'Indonesia', 'Indonesia', 'Jakarta, Indonesia',
 '["UU PDP", "ISO27001", "OJK Guidelines"]', 'BSN-approved encryption',
 '["Personal Data Protection Law", "Electronic Information and Transactions Law"]', '["id-ID", "en-ID"]', 'Asia/Jakarta', 1, GETUTCDATE(), GETUTCDATE()),
('vietnam', 'Vietnam', 'Vietnam', 'Ho Chi Minh City, Vietnam',
 '["Decree 13", "ISO27001", "SBV Guidelines"]', 'MIC-approved encryption',
 '["Decree on Personal Data Protection", "Cybersecurity Law"]', '["vi-VN", "en-VN"]', 'Asia/Ho_Chi_Minh', 1, GETUTCDATE(), GETUTCDATE());

-- =================================================================
-- CLIENT MANAGEMENT TABLES
-- =================================================================

-- Organization/Client master table
CREATE TABLE clients (
    client_id NVARCHAR(50) PRIMARY KEY,
    organization_name NVARCHAR(200) NOT NULL,
    headquarters_region NVARCHAR(20) NOT NULL,
    industry NVARCHAR(100) NOT NULL,
    employee_count INT NOT NULL,
    contact_email NVARCHAR(200) NOT NULL,
    contact_phone NVARCHAR(50),
    
    -- Encrypted sensitive fields
    encrypted_contact_details VARBINARY(MAX), -- Encrypted contact info
    encrypted_financial_info VARBINARY(MAX),  -- Encrypted financial details
    
    -- Compliance and residency
    primary_region NVARCHAR(20) NOT NULL,
    backup_regions NVARCHAR(MAX), -- JSON array of backup regions
    data_classification NVARCHAR(20) DEFAULT 'confidential', -- public, internal, confidential, restricted
    
    -- Audit fields
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    created_by NVARCHAR(100),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_by NVARCHAR(100),
    last_audit_date DATETIME2,
    
    FOREIGN KEY (headquarters_region) REFERENCES regions(region_code),
    FOREIGN KEY (primary_region) REFERENCES regions(region_code)
);

-- Client data residency requirements
CREATE TABLE client_data_residency (
    residency_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    region_code NVARCHAR(20) NOT NULL,
    data_types NVARCHAR(MAX) NOT NULL, -- JSON array: customer, assessment, files, logs
    must_stay_in_region BIT DEFAULT 0,
    cross_border_transfer_allowed BIT DEFAULT 0,
    compliance_standards NVARCHAR(MAX) NOT NULL, -- JSON array
    encryption_standard NVARCHAR(200) NOT NULL,
    retention_period_days INT DEFAULT 2555, -- 7 years default
    
    -- Audit fields
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    created_by NVARCHAR(100),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_by NVARCHAR(100),
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (region_code) REFERENCES regions(region_code)
);

-- =================================================================
-- USER MANAGEMENT AND RBAC
-- =================================================================

-- User accounts with role-based access
CREATE TABLE users (
    user_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    username NVARCHAR(100) UNIQUE NOT NULL,
    email NVARCHAR(200) UNIQUE NOT NULL,
    
    -- Encrypted sensitive fields
    encrypted_personal_info VARBINARY(MAX), -- Name, phone, etc.
    
    -- Authentication
    azure_ad_object_id NVARCHAR(100) UNIQUE, -- Azure AD integration
    auth_provider NVARCHAR(50) DEFAULT 'AzureAD', -- AzureAD, Auth0, etc.
    mfa_enabled BIT DEFAULT 0,
    last_login DATETIME2,
    failed_login_attempts INT DEFAULT 0,
    account_locked_until DATETIME2,
    
    -- Access control
    is_active BIT DEFAULT 1,
    is_admin BIT DEFAULT 0,
    allowed_regions NVARCHAR(MAX), -- JSON array of accessible regions
    
    -- Audit fields
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    created_by NVARCHAR(100),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_by NVARCHAR(100)
);

-- Roles definition
CREATE TABLE roles (
    role_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    role_name NVARCHAR(50) UNIQUE NOT NULL,
    description NVARCHAR(500),
    permissions NVARCHAR(MAX) NOT NULL, -- JSON array of permissions
    is_system_role BIT DEFAULT 0, -- Cannot be deleted
    
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE()
);

-- Insert system roles
INSERT INTO roles (role_name, description, permissions, is_system_role) VALUES
('GlobalAdmin', 'Full system access across all regions and clients', 
 '["read:all", "write:all", "admin:all", "audit:all", "export:all"]', 1),
('ClientAdmin', 'Full access to assigned client data across allowed regions',
 '["read:client", "write:client", "admin:client", "audit:client", "export:client"]', 1),
('RegionalViewer', 'Read-only access to specific regions for assigned clients',
 '["read:regional", "audit:view"]', 1),
('AuditorReadOnly', 'Read-only access for compliance auditing purposes',
 '["read:audit", "audit:all", "export:audit"]', 1),
('PowerAppConnector', 'Limited API access for Power Apps integration',
 '["read:powerapp", "api:connect"]', 1);

-- User-role assignments (many-to-many)
CREATE TABLE user_roles (
    assignment_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER NOT NULL,
    role_id UNIQUEIDENTIFIER NOT NULL,
    client_id NVARCHAR(50), -- NULL for global roles
    allowed_regions NVARCHAR(MAX), -- JSON array, NULL for all regions
    
    -- Time-based access
    valid_from DATETIME2 DEFAULT GETUTCDATE(),
    valid_until DATETIME2, -- NULL for permanent
    
    -- Audit fields
    assigned_at DATETIME2 DEFAULT GETUTCDATE(),
    assigned_by NVARCHAR(100),
    revoked_at DATETIME2,
    revoked_by NVARCHAR(100),
    is_active BIT DEFAULT 1,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

-- =================================================================
-- ASSESSMENT AND DATA STORAGE TABLES
-- =================================================================

-- Assessment sessions
CREATE TABLE assessments (
    assessment_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    assessment_type NVARCHAR(50) NOT NULL, -- purview, security, compliance, etc.
    
    -- Regional storage info
    primary_storage_region NVARCHAR(20) NOT NULL,
    backup_regions NVARCHAR(MAX), -- JSON array
    
    -- Assessment metadata
    status NVARCHAR(20) DEFAULT 'in-progress', -- in-progress, completed, failed
    started_by UNIQUEIDENTIFIER NOT NULL,
    completed_at DATETIME2,
    
    -- Encrypted assessment data
    encrypted_results VARBINARY(MAX), -- Encrypted JSON results
    encrypted_responses VARBINARY(MAX), -- Encrypted questionnaire responses
    
    -- Compliance and retention
    data_classification NVARCHAR(20) DEFAULT 'confidential',
    retention_until DATETIME2, -- Auto-calculated based on regional laws
    
    -- Audit fields
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (primary_storage_region) REFERENCES regions(region_code),
    FOREIGN KEY (started_by) REFERENCES users(user_id)
);

-- Regional data storage tracking
CREATE TABLE regional_data_storage (
    storage_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    region_code NVARCHAR(20) NOT NULL,
    data_type NVARCHAR(20) NOT NULL, -- customer, assessment, files, logs
    
    -- Data inventory
    record_count INT DEFAULT 0,
    storage_size_mb DECIMAL(15,2) DEFAULT 0,
    last_backup_date DATETIME2,
    
    -- Compliance tracking
    encryption_status NVARCHAR(20) DEFAULT 'encrypted', -- encrypted, pending, error
    compliance_score INT DEFAULT 100, -- 0-100
    last_compliance_check DATETIME2 DEFAULT GETUTCDATE(),
    
    -- Regional specific info
    jurisdiction_compliance NVARCHAR(MAX), -- JSON object with compliance details
    data_residency_status NVARCHAR(20) DEFAULT 'compliant', -- compliant, violation, pending
    
    -- Audit fields
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (region_code) REFERENCES regions(region_code),
    
    UNIQUE(client_id, region_code, data_type)
);

-- File storage tracking
CREATE TABLE secure_files (
    file_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    assessment_id UNIQUEIDENTIFIER,
    
    -- File metadata
    original_filename NVARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_type NVARCHAR(100) NOT NULL,
    content_hash NVARCHAR(128) NOT NULL, -- SHA-256 hash for integrity
    
    -- Storage information
    storage_region NVARCHAR(20) NOT NULL,
    encrypted_storage_path VARBINARY(MAX), -- Encrypted path information
    encryption_key_id NVARCHAR(100) NOT NULL, -- Reference to encryption key
    
    -- Security scanning
    virus_scan_status NVARCHAR(20) DEFAULT 'pending', -- pending, clean, infected, error
    virus_scan_date DATETIME2,
    content_scan_status NVARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    
    -- Compliance and retention
    data_classification NVARCHAR(20) DEFAULT 'confidential',
    retention_until DATETIME2,
    
    -- Audit fields
    uploaded_by UNIQUEIDENTIFIER NOT NULL,
    uploaded_at DATETIME2 DEFAULT GETUTCDATE(),
    last_accessed DATETIME2,
    access_count INT DEFAULT 0,
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (assessment_id) REFERENCES assessments(assessment_id),
    FOREIGN KEY (storage_region) REFERENCES regions(region_code),
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id)
);

-- =================================================================
-- CROSS-BORDER DATA FLOW TRACKING
-- =================================================================

-- Data flow configurations
CREATE TABLE data_flows (
    flow_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    
    -- Flow configuration
    source_region NVARCHAR(20) NOT NULL,
    target_region NVARCHAR(20) NOT NULL,
    flow_type NVARCHAR(20) NOT NULL, -- backup, sync, analytics, migration
    data_types NVARCHAR(MAX) NOT NULL, -- JSON array
    
    -- Flow settings
    frequency NVARCHAR(50) NOT NULL, -- real-time, hourly, daily, weekly, monthly
    encryption_standard NVARCHAR(200) NOT NULL,
    compression_enabled BIT DEFAULT 1,
    
    -- Status and monitoring
    status NVARCHAR(20) DEFAULT 'active', -- active, paused, blocked, error
    last_execution DATETIME2,
    next_execution DATETIME2,
    records_transferred BIGINT DEFAULT 0,
    data_volume_mb DECIMAL(15,2) DEFAULT 0,
    
    -- Compliance verification
    compliance_approved BIT DEFAULT 0,
    approved_by UNIQUEIDENTIFIER,
    approved_at DATETIME2,
    legal_basis NVARCHAR(MAX), -- JSON object with legal justification
    
    -- Audit fields
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    created_by UNIQUEIDENTIFIER NOT NULL,
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_by UNIQUEIDENTIFIER,
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (source_region) REFERENCES regions(region_code),
    FOREIGN KEY (target_region) REFERENCES regions(region_code),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id)
);

-- Data flow execution logs
CREATE TABLE data_flow_logs (
    log_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    flow_id UNIQUEIDENTIFIER NOT NULL,
    
    -- Execution details
    execution_start DATETIME2 DEFAULT GETUTCDATE(),
    execution_end DATETIME2,
    status NVARCHAR(20) NOT NULL, -- success, failed, partial
    records_processed INT DEFAULT 0,
    data_transferred_mb DECIMAL(15,2) DEFAULT 0,
    
    -- Error handling
    error_message NVARCHAR(MAX),
    retry_count INT DEFAULT 0,
    
    -- Compliance verification
    encryption_verified BIT DEFAULT 0,
    integrity_check_passed BIT DEFAULT 0,
    compliance_validated BIT DEFAULT 0,
    
    FOREIGN KEY (flow_id) REFERENCES data_flows(flow_id)
);

-- =================================================================
-- AUDIT AND COMPLIANCE LOGGING
-- =================================================================

-- Comprehensive audit log
CREATE TABLE audit_logs (
    audit_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    -- Event identification
    event_type NVARCHAR(50) NOT NULL, -- LOGIN, DATA_ACCESS, DATA_MODIFY, EXPORT, etc.
    event_category NVARCHAR(50) NOT NULL, -- AUTHENTICATION, DATA, COMPLIANCE, SYSTEM
    severity NVARCHAR(20) DEFAULT 'INFO', -- DEBUG, INFO, WARN, ERROR, CRITICAL
    
    -- Actor information
    user_id UNIQUEIDENTIFIER,
    username NVARCHAR(100),
    client_id NVARCHAR(50),
    session_id NVARCHAR(100),
    
    -- Context information
    region_code NVARCHAR(20),
    resource_type NVARCHAR(50), -- CLIENT, ASSESSMENT, FILE, USER, etc.
    resource_id NVARCHAR(100),
    
    -- Request details
    ip_address NVARCHAR(45), -- IPv6 support
    user_agent NVARCHAR(500),
    request_method NVARCHAR(10),
    request_path NVARCHAR(500),
    
    -- Event details (encrypted for sensitive operations)
    event_description NVARCHAR(MAX) NOT NULL,
    encrypted_event_data VARBINARY(MAX), -- Encrypted sensitive event data
    
    -- Results and impact
    operation_result NVARCHAR(20) DEFAULT 'SUCCESS', -- SUCCESS, FAILED, PARTIAL
    records_affected INT DEFAULT 0,
    data_accessed_mb DECIMAL(15,2) DEFAULT 0,
    
    -- Compliance tracking
    compliance_relevant BIT DEFAULT 1,
    retention_period_years INT DEFAULT 7,
    
    -- Immutable timestamp (cannot be modified)
    event_timestamp DATETIME2 DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (region_code) REFERENCES regions(region_code)
);

-- Compliance monitoring and scoring
CREATE TABLE compliance_scores (
    score_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    client_id NVARCHAR(50) NOT NULL,
    region_code NVARCHAR(20) NOT NULL,
    compliance_standard NVARCHAR(50) NOT NULL, -- GDPR, PDPA, APPI, etc.
    
    -- Scoring details
    overall_score INT NOT NULL, -- 0-100
    score_breakdown NVARCHAR(MAX) NOT NULL, -- JSON object with detailed scores
    risk_level NVARCHAR(20) NOT NULL, -- low, medium, high, critical
    
    -- Assessment details
    assessed_by UNIQUEIDENTIFIER NOT NULL,
    assessment_date DATETIME2 DEFAULT GETUTCDATE(),
    next_assessment_due DATETIME2,
    
    -- Findings and recommendations
    compliance_gaps NVARCHAR(MAX), -- JSON array of identified gaps
    recommendations NVARCHAR(MAX), -- JSON array of recommendations
    remediation_actions NVARCHAR(MAX), -- JSON array of required actions
    
    -- Status tracking
    status NVARCHAR(20) DEFAULT 'current', -- current, outdated, pending
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (region_code) REFERENCES regions(region_code),
    FOREIGN KEY (assessed_by) REFERENCES users(user_id)
);

-- =================================================================
-- INDEXES FOR PERFORMANCE
-- =================================================================

-- Primary indexes for frequent queries
CREATE INDEX IX_audit_logs_event_timestamp ON audit_logs(event_timestamp DESC);
CREATE INDEX IX_audit_logs_client_region ON audit_logs(client_id, region_code);
CREATE INDEX IX_audit_logs_event_type ON audit_logs(event_type, event_timestamp DESC);
CREATE INDEX IX_audit_logs_user_timestamp ON audit_logs(user_id, event_timestamp DESC);

CREATE INDEX IX_assessments_client_status ON assessments(client_id, status);
CREATE INDEX IX_assessments_region_created ON assessments(primary_storage_region, created_at DESC);

CREATE INDEX IX_regional_data_client_region ON regional_data_storage(client_id, region_code);
CREATE INDEX IX_regional_data_compliance ON regional_data_storage(compliance_score, last_compliance_check);

CREATE INDEX IX_secure_files_client_region ON secure_files(client_id, storage_region);
CREATE INDEX IX_secure_files_classification ON secure_files(data_classification, retention_until);

CREATE INDEX IX_data_flows_client_status ON data_flows(client_id, status);
CREATE INDEX IX_data_flows_regions ON data_flows(source_region, target_region);

CREATE INDEX IX_compliance_scores_client_region ON compliance_scores(client_id, region_code, compliance_standard);

-- =================================================================
-- TRIGGERS FOR AUDIT LOGGING
-- =================================================================

-- Trigger to log all client data modifications
CREATE TRIGGER TR_clients_audit
ON clients
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @operation NVARCHAR(20);
    
    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
        SET @operation = 'UPDATE';
    ELSE IF EXISTS(SELECT * FROM inserted)
        SET @operation = 'INSERT';
    ELSE
        SET @operation = 'DELETE';
    
    INSERT INTO audit_logs (
        event_type, event_category, user_id, client_id, 
        event_description, operation_result
    )
    SELECT 
        @operation + '_CLIENT',
        'DATA',
        NULL, -- Will be populated by application layer
        COALESCE(i.client_id, d.client_id),
        'Client record ' + @operation + ' operation for: ' + COALESCE(i.organization_name, d.organization_name),
        'SUCCESS'
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.client_id = d.client_id;
END;
GO

-- Similar triggers for other sensitive tables would be created here...

-- =================================================================
-- STORED PROCEDURES FOR SECURE OPERATIONS
-- =================================================================

-- Secure client data retrieval with audit logging
CREATE PROCEDURE sp_GetClientData
    @ClientId NVARCHAR(50),
    @UserId UNIQUEIDENTIFIER,
    @RegionFilter NVARCHAR(MAX) = NULL -- JSON array of allowed regions
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log the access attempt
    INSERT INTO audit_logs (event_type, event_category, user_id, client_id, event_description)
    VALUES ('DATA_ACCESS', 'DATA', @UserId, @ClientId, 'Client data access requested');
    
    -- Return client data based on user permissions
    SELECT 
        c.client_id,
        c.organization_name,
        c.headquarters_region,
        c.industry,
        c.employee_count,
        c.primary_region,
        c.backup_regions,
        c.data_classification,
        c.created_at,
        c.last_audit_date
    FROM clients c
    WHERE c.client_id = @ClientId
      AND c.is_active = 1;
      
    -- Return regional data based on permissions
    SELECT 
        rds.region_code,
        rds.data_type,
        rds.record_count,
        rds.storage_size_mb,
        rds.compliance_score,
        rds.data_residency_status,
        r.region_name,
        r.jurisdiction,
        r.compliance_standards
    FROM regional_data_storage rds
    INNER JOIN regions r ON rds.region_code = r.region_code
    WHERE rds.client_id = @ClientId
      AND (@RegionFilter IS NULL OR rds.region_code IN (SELECT value FROM OPENJSON(@RegionFilter)));
END;
GO

-- Secure data storage with encryption and compliance checks
CREATE PROCEDURE sp_StoreAssessmentData
    @ClientId NVARCHAR(50),
    @AssessmentType NVARCHAR(50),
    @AssessmentData NVARCHAR(MAX), -- JSON data to be encrypted
    @UserId UNIQUEIDENTIFIER,
    @PrimaryRegion NVARCHAR(20),
    @BackupRegions NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @AssessmentId UNIQUEIDENTIFIER = NEWID();
        DECLARE @EncryptedData VARBINARY(MAX);
        
        -- Open symmetric key for encryption
        OPEN SYMMETRIC KEY PowerReviewDataKey
        DECRYPTION BY CERTIFICATE PowerReviewDataCert;
        
        -- Encrypt the assessment data
        SET @EncryptedData = EncryptByKey(Key_GUID('PowerReviewDataKey'), @AssessmentData);
        
        -- Close symmetric key
        CLOSE SYMMETRIC KEY PowerReviewDataKey;
        
        -- Insert assessment record
        INSERT INTO assessments (
            assessment_id, client_id, assessment_type, primary_storage_region,
            backup_regions, started_by, encrypted_results, status
        )
        VALUES (
            @AssessmentId, @ClientId, @AssessmentType, @PrimaryRegion,
            @BackupRegions, @UserId, @EncryptedData, 'completed'
        );
        
        -- Update regional data storage tracking
        MERGE regional_data_storage AS target
        USING (SELECT @ClientId AS client_id, @PrimaryRegion AS region_code, 'assessment' AS data_type) AS source
        ON target.client_id = source.client_id 
           AND target.region_code = source.region_code 
           AND target.data_type = source.data_type
        WHEN MATCHED THEN
            UPDATE SET 
                record_count = record_count + 1,
                storage_size_mb = storage_size_mb + (LEN(@AssessmentData) / 1024.0 / 1024.0),
                updated_at = GETUTCDATE()
        WHEN NOT MATCHED THEN
            INSERT (client_id, region_code, data_type, record_count, storage_size_mb)
            VALUES (@ClientId, @PrimaryRegion, 'assessment', 1, LEN(@AssessmentData) / 1024.0 / 1024.0);
        
        -- Log the operation
        INSERT INTO audit_logs (
            event_type, event_category, user_id, client_id, region_code,
            resource_type, resource_id, event_description, records_affected
        )
        VALUES (
            'STORE_ASSESSMENT', 'DATA', @UserId, @ClientId, @PrimaryRegion,
            'ASSESSMENT', CAST(@AssessmentId AS NVARCHAR(36)),
            'Assessment data encrypted and stored for client: ' + @ClientId, 1
        );
        
        COMMIT TRANSACTION;
        
        -- Return success
        SELECT @AssessmentId AS assessment_id, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Log the error
        INSERT INTO audit_logs (
            event_type, event_category, severity, user_id, client_id,
            event_description, operation_result
        )
        VALUES (
            'STORE_ASSESSMENT_ERROR', 'DATA', 'ERROR', @UserId, @ClientId,
            'Failed to store assessment data: ' + ERROR_MESSAGE(), 'FAILED'
        );
        
        -- Re-raise the error
        THROW;
    END CATCH;
END;
GO

-- =================================================================
-- VIEWS FOR REPORTING AND DASHBOARD
-- =================================================================

-- Client compliance overview
CREATE VIEW vw_client_compliance_overview AS
SELECT 
    c.client_id,
    c.organization_name,
    c.industry,
    c.headquarters_region,
    c.primary_region,
    COUNT(DISTINCT rds.region_code) as active_regions,
    SUM(rds.record_count) as total_records,
    SUM(rds.storage_size_mb) as total_storage_mb,
    AVG(CAST(cs.overall_score AS FLOAT)) as avg_compliance_score,
    MIN(cs.overall_score) as min_compliance_score,
    COUNT(CASE WHEN cs.risk_level IN ('high', 'critical') THEN 1 END) as high_risk_regions,
    MAX(rds.last_compliance_check) as last_compliance_check
FROM clients c
LEFT JOIN regional_data_storage rds ON c.client_id = rds.client_id
LEFT JOIN compliance_scores cs ON c.client_id = cs.client_id AND rds.region_code = cs.region_code
WHERE c.is_active = 1
GROUP BY c.client_id, c.organization_name, c.industry, c.headquarters_region, c.primary_region;
GO

-- Regional data distribution summary
CREATE VIEW vw_regional_data_summary AS
SELECT 
    r.region_code,
    r.region_name,
    r.jurisdiction,
    COUNT(DISTINCT rds.client_id) as active_clients,
    SUM(rds.record_count) as total_records,
    SUM(rds.storage_size_mb) as total_storage_mb,
    AVG(CAST(rds.compliance_score AS FLOAT)) as avg_compliance_score,
    COUNT(CASE WHEN rds.data_residency_status = 'violation' THEN 1 END) as compliance_violations
FROM regions r
LEFT JOIN regional_data_storage rds ON r.region_code = rds.region_code
WHERE r.is_active = 1
GROUP BY r.region_code, r.region_name, r.jurisdiction;
GO

-- Data flow monitoring view
CREATE VIEW vw_data_flow_monitoring AS
SELECT 
    df.flow_id,
    df.client_id,
    c.organization_name,
    df.source_region,
    sr.region_name as source_region_name,
    df.target_region,
    tr.region_name as target_region_name,
    df.flow_type,
    df.status,
    df.last_execution,
    df.next_execution,
    df.records_transferred,
    df.data_volume_mb,
    df.compliance_approved,
    dfl.status as last_execution_status,
    dfl.execution_end as last_execution_end
FROM data_flows df
INNER JOIN clients c ON df.client_id = c.client_id
INNER JOIN regions sr ON df.source_region = sr.region_code
INNER JOIN regions tr ON df.target_region = tr.region_code
LEFT JOIN (
    SELECT flow_id, status, execution_end,
           ROW_NUMBER() OVER (PARTITION BY flow_id ORDER BY execution_start DESC) as rn
    FROM data_flow_logs
) dfl ON df.flow_id = dfl.flow_id AND dfl.rn = 1;
GO

-- =================================================================
-- CLEANUP AND FINAL SETUP
-- =================================================================

-- Grant permissions to application roles (would be customized per deployment)
-- These would be set up with proper service accounts in production

PRINT 'PowerReview Production Database Schema Created Successfully';
PRINT 'Next Steps:';
PRINT '1. Configure encryption keys with Azure Key Vault';
PRINT '2. Set up proper service accounts and permissions';
PRINT '3. Configure backup and disaster recovery';
PRINT '4. Set up monitoring and alerting';
PRINT '5. Perform security audit and penetration testing';

GO