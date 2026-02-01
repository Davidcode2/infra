# Terraform CI/CD Setup Guide

This guide walks through setting up automated Terraform workflows with GitHub Actions and S3 remote state.

## Prerequisites

- AWS account with admin access
- GitHub repository admin access
- Hetzner Cloud API token
- DigitalOcean API token

## 1. Create S3 Backend Resources (Infrastructure as Code)

The S3 backend resources are managed by a separate Terraform configuration in `terraform/bootstrap/`.

### 1.1 Apply Bootstrap Configuration

```bash
cd terraform/bootstrap

# Initialize (uses local backend)
terraform init

# Review what will be created
terraform plan

# Create S3 bucket and DynamoDB table
terraform apply
```

This creates:
- **S3 bucket** `jakob-terraform-state`
  - Versioning enabled
  - Encryption enabled (AES256)
  - Public access blocked
  - Lifecycle policy for old versions
- **DynamoDB table** `terraform-state-lock`
  - Pay-per-request billing
  - Point-in-time recovery
  - Encryption at rest

### 1.2 Verify Resources

```bash
# Check bucket exists
aws s3 ls s3://jakob-terraform-state

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock --region eu-central-1
```

**See `terraform/bootstrap/README.md` for detailed documentation.**

## 2. Migrate Local State to S3

### 2.1 Uncomment Backend Configuration

In `terraform/main.tf`, uncomment the backend block:

```hcl
backend "s3" {
  bucket         = "jakob-terraform-state"
  key            = "infra/terraform.tfstate"
  region         = "eu-central-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### 2.2 Initialize Backend Migration

```bash
cd terraform

# This will prompt to migrate existing state to S3
terraform init -migrate-state

# Verify state is in S3
aws s3 ls s3://jakob-terraform-state/infra/
```

### 2.3 Verify State Lock

```bash
# In one terminal, run a long-running command
terraform plan

# In another terminal, try to run terraform (should fail with lock error)
terraform plan
# Expected: Error acquiring the state lock
```

## 3. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### 3.1 AWS Credentials

**AWS_ACCESS_KEY_ID**
- Create IAM user for GitHub Actions with programmatic access
- Attach policies: `AmazonS3FullAccess`, `AmazonDynamoDBFullAccess`
- Copy Access Key ID

**AWS_SECRET_ACCESS_KEY**
- Copy Secret Access Key from the same IAM user

**AWS_ACCOUNT_ID**
- Your AWS account ID (12-digit number)
- Find it: AWS Console → Account dropdown → Account ID

### 3.2 Hetzner Cloud

**HCLOUD_TOKEN**
- Go to: Hetzner Cloud Console → Project → Security → API Tokens
- Create new token with Read & Write permissions
- Copy the token (shown only once)

**HCLOUD_SSH_KEY**
- Your SSH public key content (the one added to Hetzner)
- Format: `ssh-rsa AAAAB3NzaC1yc2E...`

**HETZNER_CLOUD_SERVER_1_IPV4**
- IP address of your ubuntu-4gb-nbg1-1 server
- Find it: Hetzner Cloud Console → Servers → ubuntu-4gb-nbg1-1

### 3.3 DigitalOcean

**DIGITALOCEAN_TOKEN**
- Go to: DigitalOcean Console → API → Generate New Token
- Create token with Read & Write scopes
- Copy the token

**DIGITALOCEAN_DROPLET_1_IPV4**
- IP address of your DigitalOcean droplet (if you have one)

### 3.4 DNS & Domain Secrets

**SCHLUESSELMOMENTE_DKIM**
- DKIM value for schluesselmomente-freiburg.de
- Find in: Your current terraform.tfvars or email provider

**SCHLUESSELMOMENTE_ZMAIL_DKIM**
- Zoho Mail DKIM value

**SCHLUESSELMOMENTE_SPF**
- SPF TXT record value

**SCHLUESSELMOMENTE_ZOHO_VERIFICATION**
- Zoho domain verification TXT value

**PORTFOLIO_NETLIFY_CHALLENGE**
- Netlify DNS challenge TXT value (if using Netlify)

## 4. Test the Workflow

### 4.1 Create a Test PR

```bash
# Make a small change
cd terraform
echo "# Test comment" >> firewall.tf

# Commit and push
git checkout -b test-terraform-cicd
git add firewall.tf
git commit -m "test: Verify Terraform CI/CD workflow"
git push -u origin test-terraform-cicd

# Create PR on GitHub
gh pr create --title "Test: Terraform CI/CD" --body "Testing automated terraform plan"
```

### 4.2 Verify Plan in PR

- GitHub Actions should automatically run
- Check the PR for a comment with the Terraform plan
- Verify: ✅ Format, ✅ Init, ✅ Validate, ✅ Plan

### 4.3 Test Apply (Optional)

**⚠️ Warning:** This will apply changes to real infrastructure!

```bash
# Only if the test change is safe
git checkout main
git merge test-terraform-cicd
git push origin main

# GitHub Actions will automatically run terraform apply
# Monitor: GitHub → Actions → Terraform CI/CD
```

### 4.4 Verify State in S3

```bash
# Check state file exists
aws s3 ls s3://jakob-terraform-state/infra/

# Download and inspect state (optional)
aws s3 cp s3://jakob-terraform-state/infra/terraform.tfstate /tmp/
cat /tmp/terraform.tfstate | jq '.version'
```

## 5. Security Best Practices

### 5.1 Restrict IAM Permissions

Create a least-privilege IAM policy for GitHub Actions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::jakob-terraform-state",
        "arn:aws:s3:::jakob-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:eu-central-1:*:table/terraform-state-lock"
    }
  ]
}
```

### 5.2 Enable MFA for State Modifications

Add to backend configuration (optional):

```hcl
backend "s3" {
  bucket         = "jakob-terraform-state"
  key            = "infra/terraform.tfstate"
  region         = "eu-central-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
  
  # Require MFA for state modifications
  # mfa_serial = "arn:aws:iam::ACCOUNT_ID:mfa/USERNAME"
}
```

### 5.3 Enable S3 Bucket Lifecycle

Reduce costs by transitioning old state versions:

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket jakob-terraform-state \
  --lifecycle-configuration '{
    "Rules": [{
      "Id": "TransitionOldVersions",
      "Status": "Enabled",
      "NoncurrentVersionTransitions": [{
        "NoncurrentDays": 90,
        "StorageClass": "GLACIER"
      }],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 365
      }
    }]
  }'
```

## 6. Workflow Behavior

### On Pull Request
1. Checkout code
2. Setup Terraform
3. Run `terraform fmt -check`
4. Run `terraform init`
5. Run `terraform validate`
6. Run `terraform plan`
7. Post plan as PR comment
8. Fail if plan fails

### On Merge to Main
1. Checkout code
2. Setup Terraform
3. Run `terraform init`
4. Run `terraform apply -auto-approve`
5. Apply changes to infrastructure

## 7. Troubleshooting

### Issue: State Lock Error

**Problem:** `Error acquiring the state lock`

**Solution:**
```bash
# Check for stale locks
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: S3 Access Denied

**Problem:** `Error: error configuring S3 Backend: AccessDenied`

**Solution:**
- Verify AWS credentials in GitHub Secrets
- Check IAM user has S3 permissions
- Verify bucket name is correct

### Issue: Workflow Fails on Init

**Problem:** Terraform init fails in GitHub Actions

**Solution:**
- Check all required secrets are set in GitHub
- Verify AWS credentials are valid
- Check S3 bucket and DynamoDB table exist

### Issue: Plan Succeeds but Apply Fails

**Problem:** Plan works but apply fails with provider errors

**Solution:**
- Verify provider tokens (Hetzner, DigitalOcean) are valid
- Check token permissions (need Read & Write)
- Review error message in Actions logs

## 8. Rollback Procedure

### 8.1 Revert Infrastructure Changes

```bash
# Find the commit that broke things
git log --oneline

# Revert the commit
git revert <bad-commit-hash>
git push origin main

# GitHub Actions will apply the reverted state
```

### 8.2 Restore Previous State Version

```bash
# List state versions
aws s3api list-object-versions \
  --bucket jakob-terraform-state \
  --prefix infra/terraform.tfstate

# Download a previous version
aws s3api get-object \
  --bucket jakob-terraform-state \
  --key infra/terraform.tfstate \
  --version-id <VERSION_ID> \
  /tmp/terraform.tfstate.backup

# Replace current state (use with extreme caution)
aws s3 cp /tmp/terraform.tfstate.backup \
  s3://jakob-terraform-state/infra/terraform.tfstate
```

## 9. Cost Estimation

### S3 Storage
- State file: ~50KB
- Versions: ~10 versions × 50KB = 500KB
- **Cost:** ~$0.01/month

### DynamoDB
- Pay-per-request pricing
- ~10 operations per workflow run
- **Cost:** Essentially free (< $0.01/month)

### GitHub Actions
- Free tier: 2,000 minutes/month
- Terraform workflow: ~3 minutes per run
- **Cost:** Free for most usage

**Total estimated cost:** < $0.05/month

## 10. Next Steps

After setup is complete:

1. ✅ Remove local `terraform.tfstate` files
2. ✅ Add `terraform.tfstate*` to `.gitignore` (if not already)
3. ✅ Document the new workflow in AGENTS.md
4. ✅ Train team on PR-based Terraform workflow
5. ✅ Set up Terraform Cloud (optional alternative to S3)

---

**Questions?** Check the GitHub Actions logs for detailed error messages.
