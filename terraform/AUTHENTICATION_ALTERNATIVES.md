# Authentication & Secrets Management Alternatives

This document explores different approaches to managing credentials and variables for Terraform CI/CD with GitHub Actions.

## Current Approach: GitHub Secrets Only

**What we're doing:**
- Store ~15 secrets in GitHub repository secrets
- Pass each as environment variable to Terraform

**Pros:**
- ✅ Simple, straightforward
- ✅ GitHub manages encryption at rest
- ✅ Easy to understand
- ✅ No additional infrastructure needed
- ✅ Works out of the box

**Cons:**
- ❌ Many secrets to manage (15+)
- ❌ Duplicated across repositories if needed
- ❌ Long-lived credentials (AWS keys, API tokens)
- ❌ Need to rotate in GitHub when changed
- ❌ Limited audit trail
- ❌ No centralized secret management

**Secrets Required:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
HCLOUD_TOKEN
HCLOUD_SSH_KEY
HETZNER_CLOUD_SERVER_1_IPV4
DIGITALOCEAN_TOKEN
DIGITALOCEAN_DROPLET_1_IPV4
SCHLUESSELMOMENTE_DKIM
SCHLUESSELMOMENTE_ZMAIL_DKIM
SCHLUESSELMOMENTE_SPF
SCHLUESSELMOMENTE_ZOHO_VERIFICATION
PORTFOLIO_NETLIFY_CHALLENGE
```

---

## Alternative 1: OIDC + AWS SSM Parameter Store (Recommended)

**What it is:**
- Use GitHub's OIDC provider to authenticate to AWS (no access keys!)
- Store Terraform variables in AWS SSM Parameter Store
- GitHub Actions assumes AWS role via OIDC
- Workflow fetches variables from SSM at runtime

### Architecture

```
GitHub Actions
    ↓ (OIDC token)
AWS STS (assume role)
    ↓ (temporary credentials)
AWS SSM Parameter Store
    ↓ (fetch terraform vars)
Terraform execution
```

### Implementation

**1. AWS IAM OIDC Provider:**
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

**2. IAM Role for GitHub Actions:**
```hcl
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"
  
  assume_role_policy = jsonencode({
    Version = "2012-17-17"
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
          "token.actions.githubusercontent.com:sub" = "repo:Davidcode2/infra:*"
        }
      }
    }]
  })
}
```

**3. Store Terraform Variables in SSM:**
```bash
# Store all terraform variables in SSM
aws ssm put-parameter --name /terraform/infra/hcloud_token --value "$HCLOUD_TOKEN" --type SecureString
aws ssm put-parameter --name /terraform/infra/digitalocean_token --value "$DO_TOKEN" --type SecureString
# ... etc for all variables
```

**4. GitHub Actions Workflow:**
```yaml
jobs:
  terraform-plan:
    permissions:
      id-token: write  # Required for OIDC
      contents: read
    
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
          aws-region: eu-central-1
      
      - name: Fetch Terraform Variables from SSM
        run: |
          export TF_VAR_hcloud_token=$(aws ssm get-parameter --name /terraform/infra/hcloud_token --with-decryption --query Parameter.Value --output text)
          export TF_VAR_digitalocean_token=$(aws ssm get-parameter --name /terraform/infra/digitalocean_token --with-decryption --query Parameter.Value --output text)
          # ... etc
      
      - name: Terraform Plan
        run: terraform plan
```

### Pros
- ✅ **No long-lived AWS credentials** (OIDC generates temporary credentials)
- ✅ **Centralized secret management** (AWS SSM)
- ✅ **Better audit trail** (CloudTrail logs all SSM access)
- ✅ **Automatic encryption** (SSM SecureString)
- ✅ **Easy secret rotation** (update in SSM, no GitHub changes needed)
- ✅ **Fine-grained IAM permissions**
- ✅ **Works across repositories** (multiple repos can use same SSM params)

### Cons
- ❌ Still need Hetzner/DigitalOcean tokens in SSM
- ❌ More complex setup initially
- ❌ Requires AWS infrastructure (OIDC provider, IAM role)
- ❌ Workflow is slightly longer (fetch from SSM step)

### GitHub Secrets Required
```
# NONE for AWS authentication!
# Still need for non-AWS providers:
HCLOUD_TOKEN (or store in SSM and fetch)
DIGITALOCEAN_TOKEN (or store in SSM and fetch)
```

### Cost
- **SSM Parameter Store:** Free tier covers normal usage
- **OIDC authentication:** Free
- **CloudTrail (for audit):** Included in AWS free tier for first trail

**Recommended:** This is the best approach for production.

---

## Alternative 2: Terraform Cloud

**What it is:**
- Use Terraform Cloud to manage state and variables
- GitHub Actions just triggers Terraform Cloud runs
- Terraform Cloud stores all variables

### Implementation

**1. Terraform Cloud Workspace:**
```hcl
terraform {
  cloud {
    organization = "jakob-lingel"
    
    workspaces {
      name = "infra-production"
    }
  }
}
```

**2. Store Variables in Terraform Cloud:**
Via UI or API:
```bash
tfe-cli variables create \
  --workspace infra-production \
  --key hcloud_token \
  --value "$HCLOUD_TOKEN" \
  --sensitive
```

**3. GitHub Actions:**
```yaml
- name: Terraform Init
  run: terraform init
  env:
    TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}

- name: Terraform Plan
  run: terraform plan
```

### Pros
- ✅ Terraform-native solution
- ✅ UI for managing variables
- ✅ Built-in state management
- ✅ Run history and logs
- ✅ Policy as code (Sentinel)
- ✅ Cost estimation
- ✅ VCS integration

### Cons
- ❌ **Vendor lock-in** to HashiCorp
- ❌ **Cost** (free tier: 500 resources, then $20/month per user)
- ❌ State stored externally (not in your S3)
- ❌ Still need one GitHub Secret (TF_API_TOKEN)
- ❌ Less control over infrastructure

### GitHub Secrets Required
```
TF_API_TOKEN (Terraform Cloud API token)
```

**Verdict:** Good for teams, but adds dependency and cost.

---

## Alternative 3: AWS Secrets Manager

**What it is:**
Similar to SSM, but more feature-rich secrets management service.

### Differences from SSM
- **Rotation:** Automatic secret rotation (Lambda-based)
- **Versioning:** Built-in secret versioning
- **Cross-region:** Replicate secrets across regions
- **Cost:** ~$0.40/month per secret (vs SSM free tier)

### When to Use
- Need automatic rotation (database passwords, API keys)
- Need cross-region replication
- Need fine-grained versioning

### Pros
- ✅ Everything from OIDC + SSM
- ✅ Automatic rotation support
- ✅ Better versioning

### Cons
- ❌ More expensive (~$6/month for 15 secrets)
- ❌ Overkill for static configuration values

**Verdict:** Use only if you need rotation or cross-region replication.

---

## Alternative 4: Encrypted tfvars File in S3

**What it is:**
- Store `terraform.tfvars` in S3 (encrypted)
- GitHub Actions downloads it at runtime
- Terraform uses the file normally

### Implementation

**1. Upload tfvars to S3:**
```bash
aws s3 cp terraform.tfvars s3://jakob-terraform-secrets/terraform.tfvars \
  --sse AES256
```

**2. GitHub Actions:**
```yaml
- name: Download tfvars
  run: |
    aws s3 cp s3://jakob-terraform-secrets/terraform.tfvars terraform/terraform.tfvars
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

- name: Terraform Plan
  run: terraform plan -var-file=terraform.tfvars
```

### Pros
- ✅ Simple approach
- ✅ Standard Terraform pattern
- ✅ Easy to edit (just a file)

### Cons
- ❌ Still need AWS credentials in GitHub
- ❌ tfvars file contains all secrets in one place
- ❌ Less granular access control
- ❌ No built-in rotation

**Verdict:** Simpler than SSM but less secure.

---

## Alternative 5: HashiCorp Vault

**What it is:**
- Run Vault server for secret management
- GitHub Actions authenticates to Vault
- Fetches secrets dynamically

### Implementation

```yaml
- name: Import Secrets from Vault
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.yourcompany.com
    method: github
    secrets: |
      secret/data/terraform/hcloud_token token | HCLOUD_TOKEN ;
      secret/data/terraform/do_token token | DIGITALOCEAN_TOKEN
```

### Pros
- ✅ Enterprise-grade secret management
- ✅ Dynamic secrets (generate on-demand)
- ✅ Audit logging
- ✅ Encryption as a service

### Cons
- ❌ **Requires running Vault server** (infrastructure overhead)
- ❌ Complex setup
- ❌ Operational burden
- ❌ Overkill for single person/small team

**Verdict:** Only if you already have Vault infrastructure.

---

## Comparison Matrix

| Approach | Setup Complexity | GitHub Secrets | Cost/Month | Security | Best For |
|----------|-----------------|----------------|------------|----------|----------|
| **GitHub Secrets Only** | ⭐ Low | 15+ | $0 | ⭐⭐⭐ | Small projects, quick setup |
| **OIDC + SSM** | ⭐⭐⭐ Medium | 0 (AWS), 2 (other) | $0 | ⭐⭐⭐⭐⭐ | **Recommended** |
| **Terraform Cloud** | ⭐⭐ Low-Medium | 1 | $0-20 | ⭐⭐⭐⭐ | Teams, multi-repo |
| **Secrets Manager** | ⭐⭐⭐ Medium | 0 (AWS), 2 (other) | $6 | ⭐⭐⭐⭐⭐ | Rotation needed |
| **S3 tfvars** | ⭐⭐ Low-Medium | 2 (AWS) | $0 | ⭐⭐⭐ | Simple setups |
| **Vault** | ⭐⭐⭐⭐⭐ High | 1 | $50+ | ⭐⭐⭐⭐⭐ | Enterprise |

---

## Recommendation: OIDC + SSM

**Why this is best for your setup:**

1. **No AWS access keys** - OIDC provides temporary credentials
2. **Centralized** - All secrets in one place (AWS SSM)
3. **Audit trail** - CloudTrail logs all access
4. **Easy rotation** - Update in SSM, no GitHub changes
5. **Cost-effective** - Free tier covers this usage
6. **Scalable** - Works for multiple repos/projects

**Remaining GitHub Secrets:**
- None for AWS authentication
- Hetzner token (no OIDC support, but could store in SSM)
- DigitalOcean token (no OIDC support, but could store in SSM)

**Further optimization:**
Store Hetzner/DO tokens in SSM too, fetch them in workflow:
```yaml
- name: Fetch Non-AWS Secrets
  run: |
    export HCLOUD_TOKEN=$(aws ssm get-parameter --name /terraform/hcloud_token --with-decryption --query Parameter.Value --output text)
    export DO_TOKEN=$(aws ssm get-parameter --name /terraform/do_token --with-decryption --query Parameter.Value --output text)
```

**Final GitHub Secrets count: 0** (everything in AWS SSM)

---

## Implementation Guide: OIDC + SSM

See `AUTHENTICATION_OIDC_SETUP.md` for step-by-step setup guide.

---

## Decision

**Recommended approach:** OIDC + AWS SSM Parameter Store

**Reasoning:**
- Eliminates long-lived AWS credentials
- Centralizes secret management
- Better security posture
- Same or lower complexity than current approach
- Free (no additional cost)
- Industry best practice

**If you need absolute simplicity:** Stick with GitHub Secrets (current approach)
- Works fine for small teams
- Easy to understand and maintain
- No additional infrastructure

**Choose based on:**
- Security requirements → OIDC + SSM
- Team size → Terraform Cloud
- Simplicity → GitHub Secrets
