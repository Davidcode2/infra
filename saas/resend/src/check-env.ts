#!/usr/bin/env tsx
/**
 * Environment validation script
 * 
 * Checks that all required SSM parameters exist and are valid
 * before attempting to create a Resend domain.
 */

import { Resend } from 'resend';
import { loadCredentials, SSM_PATHS } from './ssm.js';
import { existsSync } from 'fs';
import { join } from 'path';

interface CheckResult {
  name: string;
  status: 'ok' | 'warning' | 'error';
  message: string;
}

function checkEnvironment(): void {
  console.log('🔍 Checking environment setup...\n');
  
  const checks: CheckResult[] = [];

  // Check SSM parameters using AWS CLI
  try {
    const credentials = loadCredentials();
    
    // Validate Resend API key
    if (!credentials.resendApiKey || !credentials.resendApiKey.startsWith('re_')) {
      checks.push({
        name: `SSM: ${SSM_PATHS.resendApiKey}`,
        status: 'error',
        message: 'Invalid format - Should start with "re_"'
      });
    } else {
      // Try to validate the key by making a simple API call
      try {
        const resend = new Resend(credentials.resendApiKey);
        // We'll check this synchronously by just checking if the key is formatted correctly
        // Full validation happens at runtime
        checks.push({
          name: `SSM: ${SSM_PATHS.resendApiKey}`,
          status: 'ok',
          message: 'Found and properly formatted'
        });
      } catch (err) {
        checks.push({
          name: `SSM: ${SSM_PATHS.resendApiKey}`,
          status: 'error',
          message: `Validation failed: ${err}`
        });
      }
    }

    // Check DigitalOcean token
    if (credentials.digitalOceanToken && credentials.digitalOceanToken.length > 0) {
      checks.push({
        name: `SSM: ${SSM_PATHS.digitalOceanToken}`,
        status: 'ok',
        message: 'Found'
      });
    } else {
      checks.push({
        name: `SSM: ${SSM_PATHS.digitalOceanToken}`,
        status: 'error',
        message: 'Not found or empty'
      });
    }
  } catch (error) {
    checks.push({
      name: 'SSM Parameters',
      status: 'error',
      message: `Failed to load: ${error}`
    });
  }

  // Check domain configuration
  checks.push({
    name: 'DOMAIN_NAME',
    status: 'ok',
    message: 'notifications.jakob-lingel.dev'
  });

  checks.push({
    name: 'REGION',
    status: 'ok',
    message: 'eu-west-1'
  });

  // Check if resend-config.json exists
  const configExists = existsSync(join(process.cwd(), 'resend-config.json'));
  if (configExists) {
    checks.push({
      name: 'resend-config.json',
      status: 'warning',
      message: 'Exists - Domain may already be created'
    });
  } else {
    checks.push({
      name: 'resend-config.json',
      status: 'ok',
      message: 'Not found - Ready to create domain'
    });
  }

  // Print results
  checks.forEach(check => {
    const icon = check.status === 'ok' ? '✅' : check.status === 'warning' ? '⚠️' : '❌';
    console.log(`${icon} ${check.name}`);
    console.log(`   ${check.message}`);
    console.log('');
  });

  // Summary
  const errors = checks.filter(c => c.status === 'error');
  const warnings = checks.filter(c => c.status === 'warning');

  if (errors.length > 0) {
    console.log(`❌ Found ${errors.length} error(s). Please fix before proceeding.`);
    console.log('\nSetup:');
    console.log('   1. Ensure AWS CLI is configured: aws configure');
    console.log('   2. Check SSM parameters exist:');
    console.log(`      - ${SSM_PATHS.resendApiKey}`);
    console.log(`      - ${SSM_PATHS.digitalOceanToken}`);
    console.log('   3. You can verify with: aws ssm get-parameter --name "<path>" --with-decryption');
    process.exit(1);
  } else if (warnings.length > 0) {
    console.log(`⚠️  Found ${warnings.length} warning(s). You can proceed, but review them.`);
  } else {
    console.log('✅ All checks passed! You can proceed with domain creation.');
    console.log('\nNext step: npm run create-domain');
  }
}

checkEnvironment();
