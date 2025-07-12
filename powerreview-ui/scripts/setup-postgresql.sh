#!/bin/bash

# PostgreSQL Setup Script for PowerReview
# This script sets up PostgreSQL for local development

set -e  # Exit on error

echo "🚀 PowerReview PostgreSQL Setup Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="powerreview_dev"
DB_USER="powerreview_user"
DB_PASSWORD="dev_password_change_in_production"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check PostgreSQL connection
check_postgres_connection() {
    PGPASSWORD="$1" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c '\q' 2>/dev/null
    return $?
}

# Check if PostgreSQL is installed
echo "Checking PostgreSQL installation..."
if ! command_exists psql; then
    echo -e "${RED}Error: PostgreSQL is not installed.${NC}"
    echo "Please install PostgreSQL first:"
    echo "  - WSL/Ubuntu: sudo apt install postgresql postgresql-contrib"
    echo "  - macOS: brew install postgresql"
    exit 1
fi

echo -e "${GREEN}✓ PostgreSQL is installed${NC}"

# Check if PostgreSQL service is running
echo "Checking PostgreSQL service..."
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" > /dev/null 2>&1; then
    echo -e "${YELLOW}PostgreSQL service is not running. Starting...${NC}"
    
    # Try to start PostgreSQL based on the system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo service postgresql start || sudo systemctl start postgresql
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start postgresql
    fi
    
    # Wait for PostgreSQL to start
    sleep 3
    
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" > /dev/null 2>&1; then
        echo -e "${RED}Error: Failed to start PostgreSQL service${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ PostgreSQL service is running${NC}"

# Prompt for postgres password
echo ""
echo "Please enter the postgres superuser password:"
echo "(If you haven't set one, try leaving it blank or using 'postgres')"
read -s POSTGRES_PASSWORD

# Create database and user
echo ""
echo "Creating database and user..."

# Create SQL script
cat > /tmp/powerreview_setup.sql << EOF
-- Check if database exists, create if not
SELECT 'CREATE DATABASE ${DB_NAME}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\\gexec

-- Check if user exists, create if not
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
    END IF;
END\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to the database
\\c ${DB_NAME}

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT CREATE ON SCHEMA public TO ${DB_USER};
EOF

# Execute setup script
if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -f /tmp/powerreview_setup.sql; then
    echo -e "${GREEN}✓ Database and user created successfully${NC}"
else
    echo -e "${RED}Error: Failed to create database and user${NC}"
    echo "Please check your postgres password and try again."
    rm -f /tmp/powerreview_setup.sql
    exit 1
fi

# Clean up
rm -f /tmp/powerreview_setup.sql

# Test connection with new user
echo ""
echo "Testing connection with new user..."
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection test successful${NC}"
else
    echo -e "${RED}Error: Failed to connect with new user${NC}"
    exit 1
fi

# Check if schema file exists
SCHEMA_FILE="src/database/schema.sql"
if [ -f "$SCHEMA_FILE" ]; then
    echo ""
    echo "Found schema file. Would you like to run it now? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Running schema..."
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCHEMA_FILE"; then
            echo -e "${GREEN}✓ Schema created successfully${NC}"
        else
            echo -e "${YELLOW}Warning: Some schema commands may have failed (this is normal if tables already exist)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Warning: Schema file not found at $SCHEMA_FILE${NC}"
fi

# Create .env.local if it doesn't exist
if [ ! -f ".env.local" ]; then
    echo ""
    echo "Creating .env.local file..."
    cat > .env.local << EOF
# Local PostgreSQL Configuration
DB_TYPE=postgresql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_SSL_ENABLED=false

# Development encryption key (NOT for production)
ENCRYPTION_MASTER_KEY=dev-master-key-not-for-production-use-32-chars-minimum

# Other development settings
NODE_ENV=development
EOF
    echo -e "${GREEN}✓ Created .env.local file${NC}"
else
    echo -e "${YELLOW}Note: .env.local already exists. Please update it manually if needed.${NC}"
fi

# Show connection information
echo ""
echo "========================================"
echo -e "${GREEN}PostgreSQL setup complete!${NC}"
echo ""
echo "Connection details:"
echo "  Host:     $DB_HOST"
echo "  Port:     $DB_PORT"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo ""
echo "Connection string:"
echo "  postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo ""
echo "To connect manually:"
echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo ""
echo "Next steps:"
echo "  1. Review and update .env.local if needed"
echo "  2. Run 'npm run dev' to start the development server"
echo "  3. The application will connect to PostgreSQL automatically"
echo "========================================"