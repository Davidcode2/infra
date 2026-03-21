#!/usr/bin/env tsx
/**
 * AWS SSM Parameter Store utilities
 * 
 * Loads credentials from AWS SSM Parameter Store using AWS CLI.
 * Assumes AWS CLI is configured (via `aws configure` or ~/.aws/credentials)
 */

import { execSync } from 'child_process';

// SSM parameter paths
export const SSM_PATHS = {
  resendApiKey: '/resend/api-key-full',
  digitalOceanToken: '/infra/terraform/providers/digitalocean_token',
} as const;

/**
 * Get a parameter value from AWS SSM using AWS CLI
 */
export function getSSMParameter(name: string, withDecryption = true): string {
  try {
    const decryptionFlag = withDecryption ? '--with-decryption' : '';
    const command = `aws ssm get-parameter --name "${name}" ${decryptionFlag} --query 'Parameter.Value' --output text --region eu-central-1`;
    const result = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
    return result.trim();
  } catch (error) {
    throw new Error(`Failed to get SSM parameter ${name}: ${error}`);
  }
}

/**
 * Load all required credentials from SSM
 */
export function loadCredentials(): {
  resendApiKey: string;
  digitalOceanToken: string;
} {
  const resendApiKey = getSSMParameter(SSM_PATHS.resendApiKey);
  const digitalOceanToken = getSSMParameter(SSM_PATHS.digitalOceanToken);

  return {
    resendApiKey,
    digitalOceanToken,
  };
}
