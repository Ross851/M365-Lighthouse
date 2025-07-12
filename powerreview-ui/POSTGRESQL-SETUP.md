# PostgreSQL Setup Guide for PowerReview

## Local Development Setup

### 1. Install PostgreSQL

#### Windows (WSL2)
```bash
# Update package list
sudo apt update

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo service postgresql start

# Enable PostgreSQL to start automatically
sudo systemctl enable postgresql
```

#### macOS
```bash
# Using Homebrew
brew install postgresql
brew services start postgresql
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
```

### 2. Initial Database Setup

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE powerreview_dev;
CREATE USER powerreview_user WITH ENCRYPTED PASSWORD 'dev_password_change_in_production';
GRANT ALL PRIVILEGES ON DATABASE powerreview_dev TO powerreview_user;

# Enable required extensions
\c powerreview_dev
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

# Exit psql
\q
```

### 3. Configure PostgreSQL for Development

Edit PostgreSQL configuration:

```bash
# Find config location
sudo -u postgres psql -c "SHOW config_file"

# Edit postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Add/modify these settings:
```conf
# Connection settings
listen_addresses = 'localhost'
port = 5432
max_connections = 100

# Performance settings for development
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Logging for development
log_statement = 'all'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] db=%d,user=%u '
```

Edit pg_hba.conf for authentication:
```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Add:
```conf
# Local development connections
local   all             powerreview_user                md5
host    all             powerreview_user   127.0.0.1/32    md5
host    all             powerreview_user   ::1/128         md5
```

Restart PostgreSQL:
```bash
sudo service postgresql restart
```

### 4. Run Database Schema

```bash
# Navigate to project directory
cd /mnt/c/Users/Ross/M365-Lighthouse/powerreview-ui

# Run schema with psql
psql -U powerreview_user -d powerreview_dev -f src/database/schema.sql

# Or using environment variables
PGPASSWORD=dev_password_change_in_production psql -h localhost -U powerreview_user -d powerreview_dev -f src/database/schema.sql
```

### 5. Verify Installation

```bash
# Test connection
psql -U powerreview_user -d powerreview_dev -c "SELECT version();"

# Check tables
psql -U powerreview_user -d powerreview_dev -c "\dt"

# Test encryption
psql -U powerreview_user -d powerreview_dev -c "SELECT pgp_sym_encrypt('test data', 'encryption_key');"
```

## Production Setup on Azure

### 1. Create Azure Database for PostgreSQL - Flexible Server

```bash
# Create resource group
az group create --name powerreview-prod-rg --location southeastasia

# Create PostgreSQL server
az postgres flexible-server create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-singapore \
  --location southeastasia \
  --admin-user powerreview_admin \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_D4s_v3 \
  --storage-size 512 \
  --version 14 \
  --high-availability Enabled \
  --zone 1 \
  --standby-zone 2 \
  --backup-retention 35 \
  --geo-redundant-backup Enabled \
  --public-access 0.0.0.0

# Configure firewall rules (restrict in production)
az postgres flexible-server firewall-rule create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-singapore \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Enable extensions
az postgres flexible-server parameter set \
  --resource-group powerreview-prod-rg \
  --server-name powerreview-db-singapore \
  --name azure.extensions \
  --value uuid-ossp,pgcrypto,pg_trgm,pgaudit
```

### 2. Configure SSL/TLS

```bash
# Download Azure PostgreSQL SSL certificate
wget https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem

# Configure connection string with SSL
DATABASE_URL="postgresql://powerreview_admin@powerreview-db-singapore:password@powerreview-db-singapore.postgres.database.azure.com:5432/powerreview_production?sslmode=require&sslcert=BaltimoreCyberTrustRoot.crt.pem"
```

### 3. Enable Transparent Data Encryption (TDE)

```bash
# Enable infrastructure encryption
az postgres flexible-server update \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-singapore \
  --data-encryption Enabled
```

### 4. Set Up Read Replicas for Other Regions

```bash
# Create read replica in Japan
az postgres flexible-server replica create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-japan \
  --source-server powerreview-db-singapore \
  --location japaneast

# Create read replica in Australia  
az postgres flexible-server replica create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-australia \
  --source-server powerreview-db-singapore \
  --location australiaeast

# Create read replica in US East
az postgres flexible-server replica create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-us-east \
  --source-server powerreview-db-singapore \
  --location eastus

# Create read replica in EU
az postgres flexible-server replica create \
  --resource-group powerreview-prod-rg \
  --name powerreview-db-eu-central \
  --source-server powerreview-db-singapore \
  --location germanywestcentral
```

### 5. Configure Monitoring

```bash
# Enable diagnostics
az monitor diagnostic-settings create \
  --resource /subscriptions/{subscription-id}/resourceGroups/powerreview-prod-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/powerreview-db-singapore \
  --name powerreview-diagnostics \
  --workspace /subscriptions/{subscription-id}/resourceGroups/powerreview-prod-rg/providers/Microsoft.OperationalInsights/workspaces/powerreview-logs \
  --logs '[{"category":"PostgreSQLLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

## Connection Configuration

### Development (.env.development)
```env
# PostgreSQL connection
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=powerreview_dev
DB_USERNAME=powerreview_user
DB_PASSWORD=dev_password_change_in_production
DB_SSL_ENABLED=false
```

### Production (.env.production)
```env
# Primary PostgreSQL (Singapore)
DB_TYPE=postgresql
DB_HOST=powerreview-db-singapore.postgres.database.azure.com
DB_PORT=5432
DB_NAME=powerreview_production
DB_USERNAME=powerreview_admin
DB_PASSWORD=@vault:database-password
DB_SSL_ENABLED=true
DB_SSL_CA=/app/certs/BaltimoreCyberTrustRoot.crt.pem

# Regional endpoints
DB_SINGAPORE_HOST=powerreview-db-singapore.postgres.database.azure.com
DB_JAPAN_HOST=powerreview-db-japan.postgres.database.azure.com
DB_AUSTRALIA_HOST=powerreview-db-australia.postgres.database.azure.com
DB_US_EAST_HOST=powerreview-db-us-east.postgres.database.azure.com
DB_EU_CENTRAL_HOST=powerreview-db-eu-central.postgres.database.azure.com
```

## Performance Tuning

### Development Settings
```sql
-- Show current settings
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW work_mem;

-- Monitor slow queries
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries slower than 1 second
SELECT pg_reload_conf();
```

### Production Settings
```sql
-- Recommended for 32GB RAM server
ALTER SYSTEM SET shared_buffers = '8GB';
ALTER SYSTEM SET effective_cache_size = '24GB';
ALTER SYSTEM SET maintenance_work_mem = '2GB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '32MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- Apply settings
SELECT pg_reload_conf();
```

## Backup and Recovery

### Automated Backups
```bash
# Create backup script
cat > /home/powerreview/backup-database.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgresql"
mkdir -p $BACKUP_DIR

# Backup with compression
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USERNAME -d $DB_NAME -Fc -f $BACKUP_DIR/powerreview_$DATE.dump

# Encrypt backup
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR/powerreview_$DATE.dump -out $BACKUP_DIR/powerreview_$DATE.dump.enc -k $BACKUP_ENCRYPTION_KEY

# Remove unencrypted backup
rm $BACKUP_DIR/powerreview_$DATE.dump

# Upload to Azure Blob Storage
az storage blob upload \
  --account-name powerreviewbackups \
  --container-name database-backups \
  --name powerreview_$DATE.dump.enc \
  --file $BACKUP_DIR/powerreview_$DATE.dump.enc

# Keep local backups for 7 days
find $BACKUP_DIR -name "*.dump.enc" -mtime +7 -delete
EOF

chmod +x /home/powerreview/backup-database.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /home/powerreview/backup-database.sh
```

### Restore Process
```bash
# Download and decrypt backup
az storage blob download \
  --account-name powerreviewbackups \
  --container-name database-backups \
  --name powerreview_20240101_020000.dump.enc \
  --file restore.dump.enc

openssl enc -d -aes-256-cbc -in restore.dump.enc -out restore.dump -k $BACKUP_ENCRYPTION_KEY

# Restore database
pg_restore -h localhost -U powerreview_user -d powerreview_restore -v restore.dump
```

## Monitoring Queries

### Connection Monitoring
```sql
-- Active connections
SELECT pid, usename, application_name, client_addr, state, query_start, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Connection count by database
SELECT datname, count(*)
FROM pg_stat_activity
GROUP BY datname;
```

### Performance Monitoring
```sql
-- Slow queries
SELECT query, calls, total_time, mean_time, min_time, max_time
FROM pg_stat_statements
WHERE mean_time > 1000 -- queries averaging over 1 second
ORDER BY mean_time DESC
LIMIT 20;

-- Table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan;
```

## Security Best Practices

1. **Encryption at Rest**: Enable TDE on Azure PostgreSQL
2. **Encryption in Transit**: Always use SSL/TLS connections
3. **Access Control**: Use least privilege principle
4. **Audit Logging**: Enable pgAudit extension
5. **Regular Updates**: Keep PostgreSQL version current
6. **Connection Limits**: Set appropriate connection limits
7. **Password Policies**: Enforce strong passwords
8. **Network Security**: Restrict IP access via firewall rules

## Troubleshooting

### Common Issues

1. **Connection Refused**
```bash
# Check if PostgreSQL is running
sudo service postgresql status

# Check listening ports
sudo netstat -plnt | grep postgres

# Check logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

2. **Authentication Failed**
```bash
# Check pg_hba.conf
sudo cat /etc/postgresql/14/main/pg_hba.conf

# Test with psql
psql -h localhost -U powerreview_user -d powerreview_dev
```

3. **Performance Issues**
```sql
-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
AND n_distinct > 100
AND correlation < 0.1
ORDER BY n_distinct DESC;

-- Vacuum and analyze
VACUUM ANALYZE;
```

## Next Steps

1. Run the schema creation script
2. Set up development environment variables
3. Test database connectivity
4. Configure connection pooling
5. Set up monitoring and alerting
6. Plan production deployment