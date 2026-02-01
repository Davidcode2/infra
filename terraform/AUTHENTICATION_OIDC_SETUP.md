# OIDC + SSM Authentication Setup Guide

This guide shows how to implement GitHub Actions authentication using OIDC (no long-lived AWS credentials) with secrets stored in AWS SSM Parameter Store.

## Benefits

- ✅ **No AWS access keys in GitHub** (temporary credentials via OIDC)
- ✅ **All secrets in AWS SSM** (centralized management)
- ✅ **Better security** (no long-lived credentials)
- ✅ **Easy rotation** (update SSM, no GitHub changes)
- ✅ **Audit trail** (CloudTrail logs all access)
- ✅ **Zero GitHub Secrets** (optional: store Hetzner/DO tokens in SSM too)

## Architecture

```
┌─────────────────┐
│ GitHub Actions  │
│  Workflow Run   │
└────────┬────────┘
         │ 1. Request OIDC token
         ↓
┌─────────────────────┐
│ GitHub OIDC Provider│
│ (token.actions...)  │
└────────┬────────────┘
         │ 2. Provide token
         ↓
┌────────────────────────┐
│ AWS STS AssumeRoleWith │
│ WebIdentity            │
└────────┬───────────────┘
         │ 3. Return temporary credentials
         ↓
┌─────────────────────────┐
│ GitHub Actions Workflow │
│ (with AWS credentials)  │
└────────┬────────────────┘
         │ 4. Fetch secrets
         ↓
┌──────────────────────┐
│ AWS SSM Parameter    │
│ Store                │
└────────┬─────────────┘
         │ 5. Return secret values
         ↓
┌─────────────────────┐
│ Terraform Execution │
│ (with all vars)     │
└─────────────────────┘
```

## Part 1: AWS Infrastructure Setup

### 1.1 Create OIDC Provider (via Terraform)

Create `terraform/bootstrap/oidc.tf`:

```hcl
# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  # GitHub's thumbprint (verified)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # Backup thumbprint
  ]
  
  tags = {
    Name      = "GitHub Actions OIDC Provider"
    ManagedBy = "Terraform"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-infra"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Only allow from Davidcode2/infra repository
          "token.actions.githubusercontent.com:sub" = "repo:Davidcode2/infra:*"
        }
      }
    }]
  })
  
  tags = {
    Name      = "GitHub Actions Role"
    ManagedBy = "Terraform"
  }
}

# Policy for Terraform operations
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-permissions"
  role = aws_iam_role.github_actions.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 state backend access
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::jakob-terraform-state",
          "arn:aws:s3:::jakob-terraform-state/*"
        ]
      },
      # DynamoDB state locking
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:eu-central-1:*:table/terraform-state-lock"
      },
      # SSM Parameter Store access
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:eu-central-1:*:parameter/terraform/infra/*"
      }
    ]
  })
}

# Output the role ARN for use in GitHub Actions
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
```

### 1.2 Apply Bootstrap Configuration

```bash
cd terraform/bootstrap

# Add oidc.tf (shown above)
vim oidc.tf

# Apply to create OIDC provider and role
terraform apply

# Note the output: github_actions_role_arn
# Example: arn:aws:iam::123456789012:role/github-actions-terraform-infra
```

### 1.3 Store Terraform Variables in SSM

```bash
# Helper script to store all variables
#!/bin/bash

# Hetzner
aws ssm put-parameter \
  --name /terraform/infra/hcloud_token \
  --value "$HCLOUD_TOKEN" \
  --type SecureString \
  --description "Hetzner Cloud API token" \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/hcloud_ssh_key \
  --value "$HCLOUD_SSH_KEY" \
  --type SecureString \
  --description "SSH public key for Hetzner servers" \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/hetzner_cloud_server_1_ipv4 \
  --value "$HETZNER_SERVER_IP" \
  --type String \
  --description "IP of ubuntu-4gb-nbg1-1" \
  --region eu-central-1

# DigitalOcean
aws ssm put-parameter \
  --name /terraform/infra/digitalocean_token \
  --value "$DO_TOKEN" \
  --type SecureString \
  --description "DigitalOcean API token" \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/digitalocean_droplet_1_ipv4 \
  --value "$DO_DROPLET_IP" \
  --type String \
  --description "DigitalOcean droplet IP" \
  --region eu-central-1

# DNS/Email configuration
aws ssm put-parameter \
  --name /terraform/infra/schluesselmomente_dkim \
  --value "$DKIM_VALUE" \
  --type SecureString \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/schluesselmomente_zmail_dkim \
  --value "$ZMAIL_DKIM" \
  --type SecureString \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/schluesselmomente_spf \
  --value "$SPF_VALUE" \
  --type SecureString \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/schluesselmomente_zoho_verification \
  --value "$ZOHO_VERIFICATION" \
  --type SecureString \
  --region eu-central-1

aws ssm put-parameter \
  --name /terraform/infra/portfolio_netlify_challenge \
  --value "$NETLIFY_CHALLENGE" \
  --type SecureString \
  --region eu-central-1

# AWS Account ID (can be String type, not secret)
aws ssm put-parameter \
  --name /terraform/infra/aws_account_id \
  --value "$AWS_ACCOUNT_ID" \
  --type String \
  --region eu-central-1

echo "All parameters stored in SSM!"
```

### 1.4 Verify Parameters

```bash
# List all parameters
aws ssm get-parameters-by-path \
  --path /terraform/infra \
  --region eu-central-1 \
  --query "Parameters[].Name"

# Test fetching a secret
aws ssm get-parameter \
  --name /terraform/infra/hcloud_token \
  --with-decryption \
  --region eu-central-1 \
  --query "Parameter.Value" \
  --output text
```

## Part 2: GitHub Actions Workflow

### 2.1 Update Workflow to Use OIDC

Replace `.github/workflows/terraform.yml` with:

```yaml
name: Terraform CI/CD (OIDC + SSM)

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform.yml'
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform.yml'

env:
  TF_VERSION: 1.7.0
  AWS_REGION: eu-central-1

jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    
    permissions:
      id-token: write    # Required for OIDC
      contents: read
      pull-requests: write
    
    defaults:
      run:
        working-directory: terraform
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform-infra
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Fetch Terraform Variables from SSM
        id: fetch-vars
        run: |
          # Fetch all variables from SSM Parameter Store
          echo "Fetching Terraform variables from SSM..."
          
          export TF_VAR_hcloud_token=$(aws ssm get-parameter --name /terraform/infra/hcloud_token --with-decryption --query Parameter.Value --output text)
          export TF_VAR_hcloud_ssh_key=$(aws ssm get-parameter --name /terraform/infra/hcloud_ssh_key --with-decryption --query Parameter.Value --output text)
          export TF_VAR_hetzner_cloud_server_1_ipv4=$(aws ssm get-parameter --name /terraform/infra/hetzner_cloud_server_1_ipv4 --query Parameter.Value --output text)
          export TF_VAR_digitalocean_token=$(aws ssm get-parameter --name /terraform/infra/digitalocean_token --with-decryption --query Parameter.Value --output text)
          export TF_VAR_digitalocean_droplet_1_ipv4=$(aws ssm get-parameter --name /terraform/infra/digitalocean_droplet_1_ipv4 --query Parameter.Value --output text)
          export TF_VAR_schluesselmomente_freiburg_de_DKIM_value=$(aws ssm get-parameter --name /terraform/infra/schluesselmomente_dkim --with-decryption --query Parameter.Value --output text)
          export TF_VAR_schluesselmomente_freiburg_de_ZMAIL_DKIM_value=$(aws ssm get-parameter --name /terraform/infra/schluesselmomente_zmail_dkim --with-decryption --query Parameter.Value --output text)
          export TF_VAR_schluesselmomente_freiburg_de_SPF_TXT_value=$(aws ssm get-parameter --name /terraform/infra/schluesselmomente_spf --with-decryption --query Parameter.Value --output text)
          export TF_VAR_schluesselmomente_freiburg_de_zoho_verification_TXT_value=$(aws ssm get-parameter --name /terraform/infra/schluesselmomente_zoho_verification --with-decryption --query Parameter.Value --output text)
          export TF_VAR_portfolio_netlify_challenge_txt=$(aws ssm get-parameter --name /terraform/infra/portfolio_netlify_challenge --with-decryption --query Parameter.Value --output text)
          export TF_VAR_aws_account_id=$(aws ssm get-parameter --name /terraform/infra/aws_account_id --query Parameter.Value --output text)
          export TF_VAR_ssh_private_key_path=/tmp/ssh_key
          
          # Export to GITHUB_ENV for subsequent steps
          echo "TF_VAR_hcloud_token=$TF_VAR_hcloud_token" >> $GITHUB_ENV
          echo "TF_VAR_hcloud_ssh_key=$TF_VAR_hcloud_ssh_key" >> $GITHUB_ENV
          echo "TF_VAR_hetzner_cloud_server_1_ipv4=$TF_VAR_hetzner_cloud_server_1_ipv4" >> $GITHUB_ENV
          echo "TF_VAR_digitalocean_token=$TF_VAR_digitalocean_token" >> $GITHUB_ENV
          echo "TF_VAR_digitalocean_droplet_1_ipv4=$TF_VAR_digitalocean_droplet_1_ipv4" >> $GITHUB_ENV
          echo "TF_VAR_schluesselmomente_freiburg_de_DKIM_value=$TF_VAR_schluesselmomente_freiburg_de_DKIM_value" >> $GITHUB_ENV
          echo "TF_VAR_schluesselmomente_freiburg_de_ZMAIL_DKIM_value=$TF_VAR_schluesselmomente_freiburg_de_ZMAIL_DKIM_value" >> $GITHUB_ENV
          echo "TF_VAR_schluesselmomente_freiburg_de_SPF_TXT_value=$TF_VAR_schluesselmomente_freiburg_de_SPF_TXT_value" >> $GITHUB_ENV
          echo "TF_VAR_schluesselmomente_freiburg_de_zoho_verification_TXT_value=$TF_VAR_schluesselmomente_freiburg_de_zoho_verification_TXT_value" >> $GITHUB_ENV
          echo "TF_VAR_portfolio_netlify_challenge_txt=$TF_VAR_portfolio_netlify_challenge_txt" >> $GITHUB_ENV
          echo "TF_VAR_aws_account_id=$TF_VAR_aws_account_id" >> $GITHUB_ENV
          echo "TF_VAR_ssh_private_key_path=/tmp/ssh_key" >> $GITHUB_ENV
          
          echo "✅ All variables fetched from SSM"
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        continue-on-error: true
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Validate
        run: terraform validate -no-color
      
      - name: Terraform Plan
        run: terraform plan -no-color -input=false -out=tfplan
      
      - name: Comment PR with Plan
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        env:
          PLAN: "${{ steps.plan.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = \`#### Terraform Plan 📖
            <details><summary>Show Plan</summary>

            \`\`\`terraform
            \${process.env.PLAN}
            \`\`\`

            </details>

            *Authentication: OIDC + SSM Parameter Store*
            *Pushed by: @${{ github.actor }}*\`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    permissions:
      id-token: write    # Required for OIDC
      contents: read
    
    defaults:
      run:
        working-directory: terraform
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform-infra
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Fetch Terraform Variables from SSM
        run: |
          # Same as plan job
          # ... (fetch all variables)
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Apply
        run: terraform apply -auto-approve -input=false
```

### 2.2 Configure GitHub Secrets (Minimal)

Now you only need **ONE** secret:

```
AWS_ACCOUNT_ID - Your 12-digit AWS account ID
```

That's it! No AWS access keys, no provider tokens.

## Part 3: Testing

### 3.1 Test OIDC Authentication

Create a test workflow:

```yaml
name: Test OIDC
on: workflow_dispatch

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform-infra
          aws-region: eu-central-1
      
      - name: Test SSM Access
        run: |
          echo "Testing SSM access..."
          aws ssm get-parameter --name /terraform/infra/hcloud_token --with-decryption
          echo "✅ OIDC authentication working!"
```

### 3.2 Verify No Secrets in Logs

Check GitHub Actions logs - you should NOT see any credential values (GitHub masks them automatically).

## Security Benefits

### Before (GitHub Secrets)
- ❌ Long-lived AWS access keys
- ❌ 15+ secrets in GitHub
- ❌ Manual rotation required
- ❌ Limited audit trail

### After (OIDC + SSM)
- ✅ Temporary AWS credentials (1-hour TTL)
- ✅ 1 secret in GitHub (account ID, not sensitive)
- ✅ Centralized secret management
- ✅ Complete CloudTrail audit log
- ✅ Easy rotation (update SSM only)
- ✅ Fine-grained IAM permissions

## Cost

- **OIDC:** Free
- **SSM Parameter Store:** Free tier (10,000 parameters)
- **CloudTrail:** First trail free
- **IAM:** Free

**Total: $0/month**

## Troubleshooting

### Error: "AssumeRoleWithWebIdentity failed"

**Cause:** OIDC trust relationship not configured correctly

**Fix:**
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name github-actions-terraform-infra
```

### Error: "Parameter not found"

**Cause:** Parameter doesn't exist in SSM

**Fix:**
```bash
# List all parameters
aws ssm get-parameters-by-path --path /terraform/infra

# Add missing parameter
aws ssm put-parameter --name /terraform/infra/PARAM_NAME --value VALUE --type SecureString
```

### Error: "Access Denied" fetching from SSM

**Cause:** IAM role doesn't have SSM permissions

**Fix:**
Update role policy in `terraform/bootstrap/oidc.tf` to include:
```hcl
{
  Effect = "Allow"
  Action = ["ssm:GetParameter", "ssm:GetParameters"]
  Resource = "arn:aws:ssm:eu-central-1:*:parameter/terraform/infra/*"
}
```

## Migration from Current Approach

If you already have GitHub Secrets configured:

1. ✅ Apply bootstrap OIDC configuration
2. ✅ Store all variables in SSM
3. ✅ Update workflow to use OIDC
4. ✅ Test with a PR
5. ✅ Delete GitHub Secrets (except AWS_ACCOUNT_ID)

**No downtime** - you can test OIDC in a separate workflow first.

---

**Questions?** See `AUTHENTICATION_ALTERNATIVES.md` for comparison with other approaches.
