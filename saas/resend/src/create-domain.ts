#!/usr/bin/env tsx
/**
 * Create Resend domain and save DNS records for Terraform
 * 
 * This script:
 * 1. Loads credentials from AWS SSM Parameter Store
 * 2. Creates a domain in Resend
 * 3. Saves domain ID and DNS records to resend-config.json
 * 4. Outputs records that need to be added to DNS
 */

import { Resend } from 'resend';
import { writeFileSync, existsSync } from 'fs';
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

const DOMAIN_NAME = 'notifications.jakob-lingel.dev';
const REGION = 'eu-west-1';

async function createDomain(): Promise<void> {
  console.log(`🔧 Creating Resend domain: ${DOMAIN_NAME}`);
  console.log(`   Region: ${REGION}`);
  console.log('   Loading credentials from AWS SSM...\n');
  
  let apiKey: string;
  try {
    const credentials = await loadCredentials();
    apiKey = credentials.resendApiKey;
  } catch (error) {
    console.error('❌ Error loading credentials from SSM:', error);
    console.error('\n   Make sure AWS credentials are configured locally:');
    console.error('   - export AWS_PROFILE=your-profile');
    console.error('   - Or have ~/.aws/credentials configured');
    process.exit(1);
  }
  
  const resend = new Resend(apiKey);

  try {
    // Check if config already exists
    const configPath = join(__dirname, '..', 'resend-config.json');
    if (existsSync(configPath)) {
      console.log('\n⚠️  Warning: resend-config.json already exists');
      console.log('   This means a domain may have already been created.');
      console.log('   Delete resend-config.json if you want to create a new domain.');
      console.log('\n   Existing config:');
      const existing = await import(configPath, { assert: { type: 'json' } });
      console.log(JSON.stringify(existing.default || existing, null, 2));
      process.exit(1);
    }

    // Create the domain
    const { data, error } = await resend.domains.create({
      name: DOMAIN_NAME,
      region: REGION,
    });

    if (error) {
      console.error('❌ Error creating domain:', error);
      process.exit(1);
    }

    if (!data) {
      console.error('❌ No data returned from Resend API');
      process.exit(1);
    }

    console.log('\n✅ Domain created successfully!');
    console.log(`   Domain ID: ${data.id}`);
    console.log(`   Status: ${data.status}`);

    // Get full domain details with DNS records
    const { data: domainDetails, error: detailsError } = await resend.domains.get(data.id);
    
    if (detailsError || !domainDetails) {
      console.error('❌ Error fetching domain details:', detailsError);
      process.exit(1);
    }

    // Save config
    const config: ResendConfig = {
      domainName: domainDetails.name,
      domainId: domainDetails.id,
      region: domainDetails.region,
      createdAt: domainDetails.created_at,
      records: domainDetails.records || [],
      status: domainDetails.status,
    };

    writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log(`\n💾 Configuration saved to: resend-config.json`);

    // Display DNS records that need to be created
    console.log('\n📋 DNS Records to configure:');
    console.log('   (These will be created automatically by Terraform)');
    console.log('');
    
    if (config.records.length === 0) {
      console.log('   ⚠️  No DNS records returned. Domain may still be initializing.');
      console.log('   Run this script again in a few seconds if needed.');
    } else {
      config.records.forEach((record, i) => {
        console.log(`   ${i + 1}. ${record.record} (${record.type})`);
        console.log(`      Name: ${record.name}`);
        console.log(`      Value: ${record.value}`);
        if (record.priority) console.log(`      Priority: ${record.priority}`);
        console.log('');
      });
    }

    console.log('\n📝 Next steps:');
    console.log('   1. Review resend-config.json');
    console.log('   2. Run: cd terraform && terraform init && terraform apply');
    console.log('   3. Wait for DNS propagation (5-30 minutes)');
    console.log('   4. Run: npm run verify-domain');

  } catch (error) {
    console.error('❌ Unexpected error:', error);
    process.exit(1);
  }
}

createDomain();
