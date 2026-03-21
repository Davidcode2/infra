#!/usr/bin/env tsx
/**
 * AWS SSM Parameter Store utilities
 * 
 * Loads credentials from AWS SSM Parameter Store.
 * Assumes AWS credentials are configured locally (AWS_PROFILE, etc.)
 */

import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';

const ssmClient = new SSMClient({ region: 'eu-central-1' });

// SSM parameter paths
export const SSM_PATHS = {
  resendApiKey: '/saas/resend/api-key',
  digitalOceanToken: '/infra/terraform/digitalocean/api_token',
};

/**
 * Get a parameter value from AWS SSM
 */
export async function getSSMParameter(name: string, withDecryption = true): Promise<string> {
  try {
    const command = new GetParameterCommand({
      Name: name,
      WithDecryption: withDecryption,
    });
    
    const response = await ssmClient.send(command);
    
    if (!response.Parameter?.Value) {
      throw new Error(`Parameter ${name} not found or has no value`);
    }
    
    return response.Parameter.Value;
  } catch (error) {
    throw new Error(`Failed to get SSM parameter ${name}: ${error}`);
  }
}

/**
 * Load all required credentials from SSM
 */
export async function loadCredentials(): Promise<{
  resendApiKey: string;
  digitalOceanToken: string;
}> {
  const [resendApiKey, digitalOceanToken] = await Promise.all([
    getSSMParameter(SSM_PATHS.resendApiKey),
    getSSMParameter(SSM_PATHS.digitalOceanToken),
  ]);

  return {
    resendApiKey,
    digitalOceanToken,
  };
}
