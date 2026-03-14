# Terraform Bootstrap

This directory contains the Terraform configuration that creates the S3 backend resources for the main infrastructure configuration.

## Purpose

Creates:
- **S3 bucket** (`jakob-terraform-state`) - For storing Terraform state
- **DynamoDB table** (`terraform-state-lock`) - For state locking

## Chicken-and-Egg Problem

The main Terraform config needs an S3 backend to store its state, but we need Terraform to create that S3 backend. This bootstrap config solves that:

1. **Bootstrap** uses local state (stored in this directory)
2. **Bootstrap** creates S3 bucket and DynamoDB table
3. **Main config** uses the S3 backend created by bootstrap

## One-Time Setup

### 1. Initialize and Apply Bootstrap

```bash
cd terraform/bootstrap

# Initialize (uses local backend)
terraform init

# Review what will be created
terraform plan

# Create S3 bucket and DynamoDB table
terraform apply
```

Expected output:
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

backend_config = <<EOT
terraform {
  backend "s3" {
    bucket         = "jakob-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
EOT
```

### 2. Configure Main Terraform to Use S3 Backend

In `terraform/main.tf`, uncomment the backend configuration:

```hcl
backend "s3" {
  bucket         = "jakob-terraform-state"
  key            = "infra/terraform.tfstate"
  region         = "eu-central-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### 3. Migrate Main State to S3

```bash
cd ../  # Back to main terraform directory

# Migrate existing state to S3
terraform init -migrate-state

# Verify state is in S3
aws s3 ls s3://jakob-terraform-state/infra/
```

## Ongoing Management

### Viewing Bootstrap State

The bootstrap state is stored locally in `terraform/bootstrap/terraform.tfstate`.

**Important:** This file is gitignored but should be backed up manually since it manages critical infrastructure.

```bash
# View current state
cd terraform/bootstrap
terraform show

# Verify resources exist
terraform plan  # Should show no changes if everything is synced
```

### Updating Bootstrap Resources

If you need to modify the S3 bucket or DynamoDB table:

```bash
cd terraform/bootstrap

# Edit main.tf, variables.tf, etc.
vim main.tf

# Apply changes
terraform plan
terraform apply
```

### Destroying Bootstrap (⚠️ Dangerous)

**Warning:** This will destroy the S3 bucket and DynamoDB table that store your main Terraform state!

Only do this if:
1. You have backups of all state files
2. You're completely tearing down the infrastructure
3. You've already destroyed all resources managed by the main config

```bash
# DO NOT RUN UNLESS YOU KNOW WHAT YOU'RE DOING
cd terraform/bootstrap
terraform destroy
```

## Security Features

### S3 Bucket
- ✅ Versioning enabled (state recovery)
- ✅ Encryption at rest (AES256)
- ✅ Public access blocked
- ✅ Lifecycle policy (archive old versions after 90 days)
- ✅ Auto-delete old versions after 365 days

### DynamoDB Table
- ✅ Pay-per-request billing (cost-effective)
- ✅ Point-in-time recovery enabled
- ✅ Encryption at rest enabled

## Cost Estimation

### S3
- Storage: ~$0.023/GB/month
- State file size: ~50KB
- With versioning: ~500KB (assuming 10 versions)
- **Cost:** < $0.01/month

### DynamoDB
- Pay-per-request: $1.25 per million write requests
- Typical usage: ~10 operations per terraform run
- **Cost:** < $0.01/month

### Total
**< $0.05/month**

## Backup Strategy

The bootstrap state file (`terraform.tfstate`) should be backed up manually:

```bash
# Backup to AWS S3 (different bucket)
aws s3 cp terraform/bootstrap/terraform.tfstate \
  s3://jakob-backups/terraform-bootstrap-state/terraform.tfstate.$(date +%Y%m%d)

# Or backup locally
cp terraform/bootstrap/terraform.tfstate \
  ~/backups/terraform-bootstrap-state-$(date +%Y%m%d).tfstate
```

## Troubleshooting

### Issue: Bucket already exists

**Problem:** Running `terraform apply` shows "bucket already exists"

**Solution:** 
```bash
# Import existing bucket
terraform import aws_s3_bucket.terraform_state jakob-terraform-state
terraform import aws_dynamodb_table.terraform_locks terraform-state-lock
```

### Issue: Access denied

**Problem:** `terraform apply` fails with access denied

**Solution:** Verify AWS credentials have permissions:
- `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`, etc.
- `dynamodb:CreateTable`, `dynamodb:UpdateTable`, etc.

### Issue: State file missing

**Problem:** Bootstrap state file was deleted

**Solution:**
```bash
# Re-import existing resources
cd terraform/bootstrap
terraform init
terraform import aws_s3_bucket.terraform_state jakob-terraform-state
terraform import aws_s3_bucket_versioning.terraform_state jakob-terraform-state
# ... import other resources
```

## Related Documentation

- Main Terraform config: `../main.tf`
- CI/CD setup guide: `../CICD_SETUP.md`
- AWS S3 backend: https://www.terraform.io/docs/language/settings/backends/s3.html

---

**Remember:** This bootstrap config is foundational infrastructure. Handle it with care!
