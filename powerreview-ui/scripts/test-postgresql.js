#!/usr/bin/env node

/**
 * PostgreSQL Connection Test Script
 * Tests database connectivity and basic operations
 */

import pg from 'pg';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { config } from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
config({ path: join(__dirname, '..', '.env.local') });
config({ path: join(__dirname, '..', '.env.development') });

const { Pool } = pg;

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'powerreview_dev',
  user: process.env.DB_USERNAME || 'powerreview_user',
  password: process.env.DB_PASSWORD || 'dev_password_change_in_production',
  ssl: process.env.DB_SSL_ENABLED === 'true' ? { rejectUnauthorized: false } : false
};

console.log('🔧 PowerReview PostgreSQL Connection Test');
console.log('========================================');
console.log(`Host: ${dbConfig.host}:${dbConfig.port}`);
console.log(`Database: ${dbConfig.database}`);
console.log(`User: ${dbConfig.user}`);
console.log('');

async function testConnection() {
  const pool = new Pool(dbConfig);
  
  try {
    // Test 1: Basic connectivity
    console.log('📡 Testing connection...');
    const client = await pool.connect();
    console.log('✅ Connected successfully!');
    
    // Test 2: Check PostgreSQL version
    console.log('\n📊 Database Information:');
    const versionResult = await client.query('SELECT version()');
    console.log(`PostgreSQL Version: ${versionResult.rows[0].version}`);
    
    // Test 3: Check extensions
    console.log('\n🔌 Checking required extensions:');
    const extensions = ['uuid-ossp', 'pgcrypto', 'pg_trgm'];
    for (const ext of extensions) {
      const extResult = await client.query(
        'SELECT * FROM pg_extension WHERE extname = $1',
        [ext]
      );
      if (extResult.rows.length > 0) {
        console.log(`✅ ${ext} is installed`);
      } else {
        console.log(`❌ ${ext} is NOT installed`);
      }
    }
    
    // Test 4: Check tables
    console.log('\n📋 Checking tables:');
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    if (tablesResult.rows.length === 0) {
      console.log('⚠️  No tables found. Run the schema script first.');
    } else {
      console.log(`Found ${tablesResult.rows.length} tables:`);
      tablesResult.rows.forEach(row => {
        console.log(`  - ${row.table_name}`);
      });
    }
    
    // Test 5: Test encryption functions
    console.log('\n🔐 Testing encryption:');
    try {
      const encryptTest = await client.query(
        "SELECT pgp_sym_encrypt('test data', 'test_key') as encrypted"
      );
      console.log('✅ Encryption function works');
      
      const decryptTest = await client.query(
        "SELECT pgp_sym_decrypt($1::bytea, 'test_key') as decrypted",
        [encryptTest.rows[0].encrypted]
      );
      console.log('✅ Decryption function works');
      console.log(`   Original: 'test data'`);
      console.log(`   Decrypted: '${decryptTest.rows[0].decrypted}'`);
    } catch (err) {
      console.log('❌ Encryption functions not available');
      console.log('   Run: CREATE EXTENSION pgcrypto;');
    }
    
    // Test 6: Connection pool stats
    console.log('\n📈 Connection Pool Stats:');
    console.log(`  Total connections: ${pool.totalCount}`);
    console.log(`  Idle connections: ${pool.idleCount}`);
    console.log(`  Waiting requests: ${pool.waitingCount}`);
    
    // Release the client
    client.release();
    console.log('\n✅ All tests completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Connection test failed:');
    console.error(`   ${error.message}`);
    
    if (error.code === 'ECONNREFUSED') {
      console.error('\n💡 PostgreSQL might not be running. Try:');
      console.error('   sudo service postgresql start');
    } else if (error.code === '28P01') {
      console.error('\n💡 Authentication failed. Check your password.');
    } else if (error.code === '3D000') {
      console.error('\n💡 Database does not exist. Run setup script first.');
    }
  } finally {
    await pool.end();
  }
}

// Run the test
testConnection().catch(console.error);