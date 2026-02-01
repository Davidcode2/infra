# Authentication Approach Comparison

This document compares the GitHub Secrets approach with the OIDC + SSM approach.

## Summary

| Metric | GitHub Secrets (Current) | OIDC + SSM (Proposed) |
|--------|--------------------------|------------------------|
| **GitHub Secrets Count** | 15+ | 1 (AWS Account ID only) |
| **Long-lived Credentials** | Yes (AWS keys, API tokens) | No (temporary OIDC tokens) |
| **Setup Complexity** | Low | Medium |
| **Ongoing Maintenance** | Manual rotation | Update SSM only |
| **Security** | Good | Excellent |
| **Audit Trail** | Limited | Complete (CloudTrail) |
| **Cost** | $0 | $0 |
| **Centralization** | GitHub (per-repo) | AWS (cross-repo) |

## GitHub Secrets Required

### Current Approach
```
AWS_ACCESS_KEY_ID               # Long-lived credential ⚠️
AWS_SECRET_ACCESS_KEY           # Long-lived credential ⚠️
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
**Total: 13 secrets**

### OIDC + SSM Approach
```
AWS_ACCOUNT_ID   # Not sensitive, just needed for role ARN
```
**Total: 1 "secret" (not actually secret)**

**Optional:** You could even eliminate this by hardcoding the account ID in the workflow since it's not sensitive.

## Workflow Comparison

### Current Approach: GitHub Secrets

```yaml
jobs:
  terraform-plan:
    steps:
      - name: Terraform Plan
        env:
          # Long-lived AWS credentials
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          
          # All Terraform variables from GitHub Secrets
          TF_VAR_hcloud_token: ${{ secrets.HCLOUD_TOKEN }}
          TF_VAR_digitalocean_token: ${{ secrets.DIGITALOCEAN_TOKEN }}
          TF_VAR_hcloud_ssh_key: ${{ secrets.HCLOUD_SSH_KEY }}
          TF_VAR_hetzner_cloud_server_1_ipv4: ${{ secrets.HETZNER_CLOUD_SERVER_1_IPV4 }}
          TF_VAR_digitalocean_droplet_1_ipv4: ${{ secrets.DIGITALOCEAN_DROPLET_1_IPV4 }}
          TF_VAR_schluesselmomente_freiburg_de_DKIM_value: ${{ secrets.SCHLUESSELMOMENTE_DKIM }}
          TF_VAR_schluesselmomente_freiburg_de_ZMAIL_DKIM_value: ${{ secrets.SCHLUESSELMOMENTE_ZMAIL_DKIM }}
          TF_VAR_schluesselmomente_freiburg_de_SPF_TXT_value: ${{ secrets.SCHLUESSELMOMENTE_SPF }}
          TF_VAR_schluesselmomente_freiburg_de_zoho_verification_TXT_value: ${{ secrets.SCHLUESSELMOMENTE_ZOHO_VERIFICATION }}
          TF_VAR_portfolio_netlify_challenge_txt: ${{ secrets.PORTFOLIO_NETLIFY_CHALLENGE }}
          TF_VAR_aws_account_id: ${{ secrets.AWS_ACCOUNT_ID }}
        run: terraform plan
```

### OIDC + SSM Approach

```yaml
jobs:
  terraform-plan:
    permissions:
      id-token: write   # Enable OIDC
      contents: read
    
    steps:
      # Authenticate to AWS using OIDC (no credentials!)
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-terraform-infra
          aws-region: eu-central-1
      
      # Fetch all variables from SSM
      - name: Fetch Variables
        run: |
          export TF_VAR_hcloud_token=$(aws ssm get-parameter --name /terraform/infra/hcloud_token --with-decryption --query Parameter.Value --output text)
          export TF_VAR_digitalocean_token=$(aws ssm get-parameter --name /terraform/infra/digitalocean_token --with-decryption --query Parameter.Value --output text)
          # ... (continues for all variables)
      
      - name: Terraform Plan
        run: terraform plan
```

## Security Comparison

### Attack Vectors

**GitHub Secrets Approach:**
- ❌ Compromised GitHub access = all credentials exposed
- ❌ AWS keys work forever (until manually rotated)
- ❌ No audit log of when secrets were accessed
- ❌ Each repository needs its own copy of secrets

**OIDC + SSM Approach:**
- ✅ Compromised GitHub access ≠ AWS credentials (OIDC validates repository)
- ✅ Temporary credentials (1-hour TTL, auto-expire)
- ✅ CloudTrail logs every SSM access
- ✅ Centralized secrets (one copy in AWS SSM)
- ✅ IAM role limits what can be done even with valid credentials

### Credential Lifespan

**GitHub Secrets:**
```
AWS Access Key → Forever (until rotated)
Hetzner Token → Forever (until regenerated)
DO Token → Forever (until regenerated)
```

**OIDC + SSM:**
```
OIDC Temporary Credentials → 1 hour max (auto-expire)
SSM Parameters → Forever, but only accessible via IAM role
```

### Audit Trail

**GitHub Secrets:**
- GitHub audit log shows when workflow ran
- ❌ No log of which secrets were accessed
- ❌ No log of secret values being read

**OIDC + SSM:**
- GitHub audit log shows when workflow ran
- ✅ CloudTrail logs OIDC role assumption
- ✅ CloudTrail logs every SSM parameter access
- ✅ CloudTrail logs which parameter was accessed and when
- ✅ Can set up CloudWatch alarms on suspicious access patterns

## Maintenance Comparison

### Rotating Credentials

**GitHub Secrets:**
1. Generate new AWS access key in IAM
2. Update `AWS_ACCESS_KEY_ID` in GitHub
3. Update `AWS_SECRET_ACCESS_KEY` in GitHub
4. Delete old AWS access key
5. Repeat for Hetzner token (regenerate in Hetzner, update GitHub)
6. Repeat for DigitalOcean token
7. Update all other secrets when they change

**OIDC + SSM:**
1. Update value in AWS SSM: `aws ssm put-parameter --name /terraform/infra/hcloud_token --value "$NEW_TOKEN" --overwrite`
2. Done! Next workflow run uses new value automatically

### Adding a New Variable

**GitHub Secrets:**
1. Add to GitHub Secrets UI
2. Update workflow YAML to reference it
3. If using multiple repositories, repeat for each

**OIDC + SSM:**
1. Add to SSM: `aws ssm put-parameter --name /terraform/infra/new_var --value "$VALUE" --type SecureString`
2. Update workflow fetch step to include it
3. All repositories using SSM get access automatically (if IAM allows)

## Cost Comparison

### GitHub Secrets
- GitHub Secrets: Free
- **Total: $0/month**

### OIDC + SSM
- OIDC authentication: Free
- SSM Parameter Store: Free tier (10,000 parameters)
- CloudTrail: First trail free
- IAM roles: Free
- **Total: $0/month**

## Implementation Effort

### GitHub Secrets (Current)
- ✅ Already implemented
- ✅ No changes needed
- **Effort: 0 hours**

### OIDC + SSM (Migration)
1. Apply bootstrap OIDC config (15 min)
2. Store parameters in SSM (30 min)
3. Update workflow (30 min)
4. Test (30 min)
5. Delete old GitHub Secrets (5 min)
- **Effort: ~2 hours one-time**

## Recommendations

### Keep GitHub Secrets If:
- ✅ You're the only person working on this
- ✅ You're comfortable with current security posture
- ✅ You don't want to spend 2 hours on migration
- ✅ You don't need audit trails
- ✅ You manually rotate credentials regularly

### Migrate to OIDC + SSM If:
- ✅ You want best-practice security
- ✅ You want audit trails (CloudTrail)
- ✅ You want centralized secret management
- ✅ You want to eliminate long-lived AWS credentials
- ✅ You plan to add more repositories
- ✅ You want easier credential rotation

## My Recommendation

**Migrate to OIDC + SSM** for these reasons:

1. **Security**: Eliminates long-lived AWS credentials (biggest risk)
2. **Future-proof**: Scales to multiple repositories
3. **Industry standard**: This is how most companies do it
4. **Audit trail**: CloudTrail gives you complete visibility
5. **Low effort**: 2-hour one-time investment
6. **Same cost**: $0/month either way

**However**, if you value simplicity over security and don't plan to grow beyond a single repository, GitHub Secrets works fine for personal projects.

## Decision Checklist

Use this to decide:

- [ ] Do I need to pass security audits? → OIDC + SSM
- [ ] Do I have/plan multiple repositories? → OIDC + SSM
- [ ] Do I want detailed audit logs? → OIDC + SSM
- [ ] Am I comfortable managing IAM roles? → OIDC + SSM
- [ ] Is this just a personal project? → GitHub Secrets OK
- [ ] Do I want absolute simplicity? → GitHub Secrets OK
- [ ] Do I rotate credentials regularly? → GitHub Secrets OK

---

**See also:**
- `AUTHENTICATION_ALTERNATIVES.md` - Comparison of all approaches
- `AUTHENTICATION_OIDC_SETUP.md` - Step-by-step OIDC setup guide
