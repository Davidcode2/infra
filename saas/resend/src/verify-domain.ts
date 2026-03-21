#!/usr/bin/env tsx
/**
 * Verify Resend domain after DNS records are configured
 * 
 * This script triggers the verification process in Resend
 * after DNS records have been created via Terraform.
 */

import { Resend } from 'resend';
import { existsSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { loadCredentials } from './ssm.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface ResendConfig {
  domainName: string;
  domainId: string;
  region: string;
  createdAt: string;
  records: Array<{
    record: string;
    name: string;
    type: string;
    value: string;
    ttl?: string;
    priority?: number;
    status?: string;
  }>;
  status: string;
}

function loadConfig(): ResendConfig {
  const configPath = join(__dirname, '..', 'resend-config.json');
  
  if (!existsSync(configPath)) {
    console.error('❌ Error: resend-config.json not found');
    console.error('   Run "npm run create-domain" first');
    process.exit(1);
  }

  try {
    const content = readFileSync(configPath, 'utf-8');
    return JSON.parse(content) as ResendConfig;
  } catch (error) {
    console.error('❌ Error reading resend-config.json:', error);
    process.exit(1);
  }
}

async function verifyDomain(): Promise<void> {
  const config = loadConfig();
  
  console.log(`🔍 Verifying Resend domain: ${config.domainName}`);
  console.log(`   Domain ID: ${config.domainId}`);
  console.log(`   Current status: ${config.status}`);
  console.log('   Loading credentials from AWS SSM...\n');
  
  let apiKey: string;
  try {
    const credentials = await loadCredentials();
    apiKey = credentials.resendApiKey;
  } catch (error) {
    console.error('❌ Error loading credentials from SSM:', error);
    console.error('\n   Make sure AWS credentials are configured locally');
    process.exit(1);
  }
  
  const resend = new Resend(apiKey);

  try {
    // First, check current domain status
    const { data: domainDetails, error: detailsError } = await resend.domains.get(config.domainId);
    
    if (detailsError) {
      console.error('❌ Error fetching domain details:', detailsError);
      process.exit(1);
    }

    if (!domainDetails) {
      console.error('❌ Domain not found');
      process.exit(1);
    }

    console.log(`   Latest status: ${domainDetails.status}`);

    // Check if already verified
    if (domainDetails.status === 'verified') {
      console.log('\n✅ Domain is already verified!');
      console.log('   You can now send emails from:', config.domainName);
      return;
    }

    // Trigger verification
    console.log('\n🔄 Triggering verification...');
    const { data: verifyResult, error: verifyError } = await resend.domains.verify(config.domainId);

    if (verifyError) {
      console.error('❌ Error triggering verification:', verifyError);
      console.error('\n💡 Common issues:');
      console.error('   - DNS records haven\'t propagated yet (wait 5-30 minutes)');
      console.error('   - DNS records were configured incorrectly');
      console.error('   - You can check DNS with: nslookup -type=TXT resend._domainkey.' + config.domainName);
      process.exit(1);
    }

    console.log('\n✅ Verification triggered!');
    console.log(`   Status: ${verifyResult?.status || 'pending'}`);
    
    // Show record statuses
    if (domainDetails.records && domainDetails.records.length > 0) {
      console.log('\n📊 DNS Record Statuses:');
      domainDetails.records.forEach((record) => {
        const icon = record.status === 'verified' ? '✅' : record.status === 'pending' ? '⏳' : '❌';
        console.log(`   ${icon} ${record.record} (${record.type}): ${record.status}`);
      });
    }

    console.log('\n📝 Next steps:');
    if (verifyResult?.status !== 'verified') {
      console.log('   - Wait a few more minutes for DNS propagation');
      console.log('   - Run this script again to check status');
      console.log('   - Or check the Resend dashboard: https://resend.com/domains');
    } else {
      console.log('   - Domain is verified! You can send emails now.');
      console.log('   - Create API keys at: https://resend.com/api-keys');
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
    process.exit(1);
  }
}

verifyDomain();
