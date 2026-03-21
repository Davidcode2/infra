# Resend Domain Setup

Automated setup for Resend email service domain verification with DigitalOcean DNS.

## Overview

This tool creates a Resend domain and automatically configures the required DNS records in DigitalOcean. It uses a Node.js/TypeScript script to interact with the Resend API and Terraform to manage DNS records.

**Important:** The domain `notifications.jakob-lingel.dev` already exists as a CNAME in the main Terraform configuration. This setup creates the domain in Resend and adds the required verification DNS records (DKIM, SPF, MX).

## Prerequisites

- Node.js 18+
- Terraform 1.5+
- Resend account with API key
- DigitalOcean account with DNS configured for `jakob-lingel.dev`
- AWS credentials configured locally (for SSM access)

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure AWS Credentials

Ensure AWS credentials are configured to access SSM Parameter Store:

```bash
# Option 1: Using AWS profile
export AWS_PROFILE=your-profile-name

# Option 2: Using access keys
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

### 3. Verify Environment

Check that all required SSM parameters exist:

```bash
npm run check-env
```

This validates:
- AWS credentials are configured
- Resend API key exists in SSM (`/message-router/resend-api-key`)
- DigitalOcean token exists in SSM (`/infra/terraform/digitalocean/api_token`)

### 4. Create Resend Domain

This creates the domain in Resend and saves the configuration:

```bash
npm run create-domain
```

This will:
- Load credentials from AWS SSM
- Create the domain in Resend
- Save domain ID and DNS records to `resend-config.json`
- Display the records that need to be created

### 5. Create DNS Records

Run Terraform to create the DNS records in DigitalOcean:

```bash
cd terraform
terraform init
terraform apply
```

### 6. Verify Domain

After DNS propagation (5-30 minutes), verify the domain:

```bash
npm run verify-domain
```

## File Structure

```
.
├── src/
│   ├── check-env.ts         # Validates environment and SSM parameters
│   ├── create-domain.ts     # Creates domain in Resend
│   ├── verify-domain.ts     # Triggers domain verification
│   └── ssm.ts               # AWS SSM utilities
├── terraform/
│   ├── main.tf             # Terraform backend + providers + SSM data
│   ├── dns.tf              # Creates DNS records from resend-config.json
│   └── variables.tf        # Input variables
├── resend-config.json      # Generated: Domain config + DNS records
├── package.json
└── tsconfig.json
```

## Important Notes

### Free Tier Limitation

**You can only have ONE domain on the Resend free tier.**

- The `create-domain.ts` script checks for existing `resend-config.json` to prevent accidental duplicate creation
- Keep the `resend-config.json` file safe - it contains your domain ID
- This file is committed to git for backup purposes

### DNS Records Explained

The Resend domain verification requires these DNS records:

1. **DKIM TXT record**: `resend._domainkey.notifications`
   - Validates email authenticity
2. **SPF TXT record**: `send.notifications`
   - Authorizes Resend to send emails
3. **SPF MX record**: `send.notifications`
   - Return path for bounces

These are created by Terraform in the `jakob-lingel.dev` DigitalOcean domain.

### One-Way Operation

- Domain creation is a one-way operation (creates domain in Resend)
- DNS records are managed by Terraform (can be destroyed/recreated)
- Domain verification is a separate step that triggers after DNS propagation

### DNS Propagation

DNS records can take 5-30 minutes to propagate globally. If verification fails:

1. Wait a bit longer
2. Check DNS with:
   ```bash
   npm run check-dns
   ```
3. Run `npm run verify-domain` again

### State Management

- `resend-config.json` - Domain configuration (domain ID, DNS records)
- `terraform/` - Manages DNS records only
- S3 backend - Terraform state stored in `s3://jakob-terraform-state/infra/saas/resend/`

## Troubleshooting

### Domain already exists error

If you get an error that the domain already exists:
1. Check your Resend dashboard: https://resend.com/domains
2. If the domain exists there but `resend-config.json` is missing, manually create the config file:
   ```json
   {
     "domainName": "notifications.jakob-lingel.dev",
     "domainId": "your-domain-id-from-dashboard",
     "region": "eu-west-1",
     "createdAt": "2024-...",
     "records": [
       {
         "record": "DKIM",
         "name": "resend._domainkey.notifications",
         "type": "TXT",
         "value": "...",
         "ttl": "Auto"
       },
       {
         "record": "SPF",
         "name": "send.notifications",
         "type": "MX",
         "value": "feedback-smtp.eu-west-1.amazonses.com",
         "priority": 10,
         "ttl": "Auto"
       },
       {
         "record": "SPF",
         "name": "send.notifications",
         "type": "TXT",
         "value": "\"v=spf1 include:amazonses.com ~all\"",
         "ttl": "Auto"
       }
     ],
     "status": "pending"
   }
   ```
3. Run `cd terraform && terraform apply` to create DNS records
4. Run `npm run verify-domain`

### Verification keeps failing

1. Check DNS records are correct:
   ```bash
   nslookup -type=TXT resend._domainkey.notifications.jakob-lingel.dev
   nslookup -type=TXT send.notifications.jakob-lingel.dev
   nslookup -type=MX send.notifications.jakob-lingel.dev
   ```

2. Check the Resend dashboard for specific error messages

3. DNS propagation can take up to 24 hours in rare cases

## Next Steps After Verification

Once verified:

1. Create API keys at https://resend.com/api-keys
2. Use the API key in your applications
3. Test sending email: https://resend.com/docs/api-reference/emails/send-email

## SSM Parameter Store Paths

Credentials are sourced from AWS SSM Parameter Store:

| Parameter | Description |
|-----------|-------------|
| `/message-router/resend-api-key` | Resend API key for authentication |
| `/infra/terraform/digitalocean/api_token` | DigitalOcean API token for DNS management |

These parameters are created via Terraform in the main infrastructure project.

## Resources

- Resend API Docs: https://resend.com/docs/api-reference/introduction
- Domain Verification: https://resend.com/docs/dashboard/domains/introduction
- AWS SSM Parameter Store: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
