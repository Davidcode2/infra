#!/usr/bin/env tsx
/**
 * Environment validation script
 * 
 * Checks that all required environment variables and credentials are set
 * before attempting to create a Resend domain.
 */

import { Resend } from 'resend';
import { loadCredentials, SSM_PATHS } from './ssm.js';

interface CheckResult {
  name: string;
  status: 'ok' | 'warning' | 'error';
  message: string;
}

async function checkEnvironment(): Promise<void> {
  console.log('🔍 Checking environment setup...\n');
  
  const checks: CheckResult[] = [];

  // Check AWS credentials (required to access SSM)
  const awsProfile = process.env.AWS_PROFILE;
  const awsAccessKey = process.env.AWS_ACCESS_KEY_ID;
  const awsSecretKey = process.env.AWS_SECRET_ACCESS_KEY;
  
  if (!awsProfile && !awsAccessKey) {
    checks.push({
      name: 'AWS Credentials',
      status: 'error',
      message: 'Not configured - Set AWS_PROFILE or AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY'
    });
  } else {
    checks.push({
      name: 'AWS Credentials',
      status: 'ok',
      message: awsProfile ? `Using profile: ${awsProfile}` : 'Using access keys'
    });
  }

  // Check SSM parameters
  try {
    const credentials = await loadCredentials();
    
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
        const { error } = await resend.domains.list();
        if (error) {
          checks.push({
            name: `SSM: ${SSM_PATHS.resendApiKey}`,
            status: 'error',
            message: `Invalid API key: ${error.message}`
          });
        } else {
          checks.push({
            name: `SSM: ${SSM_PATHS.resendApiKey}`,
            status: 'ok',
            message: 'Valid and working'
          });
        }
      } catch (err) {
        checks.push({
          name: `SSM: ${SSM_PATHS.resendApiKey}`,
          status: 'error',
          message: `API call failed: ${err}`
        });
      }
    }

    // Check DigitalOcean token
    if (credentials.digitalOceanToken) {
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
  const { existsSync } = await import('fs');
  const { join } = await import('path');
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
    console.log('   1. Ensure AWS credentials are configured (AWS_PROFILE or access keys)');
    console.log('   2. Check SSM parameters exist:');
    console.log(`      - ${SSM_PATHS.resendApiKey}`);
    console.log(`      - ${SSM_PATHS.digitalOceanToken}`);
    console.log('   3. Parameters should be created via Terraform');
    process.exit(1);
  } else if (warnings.length > 0) {
    console.log(`⚠️  Found ${warnings.length} warning(s). You can proceed, but review them.`);
  } else {
    console.log('✅ All checks passed! You can proceed with domain creation.');
    console.log('\nNext step: npm run create-domain');
  }
}

checkEnvironment();
