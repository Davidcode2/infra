# SSM Secrets Backup Scripts

## backup-ssm-secrets.sh

Backs up all AWS SSM Parameter Store secrets to a local encrypted JSON file.

### Usage

```bash
# Make sure AWS credentials are configured
aws configure

# Run the backup script
./scripts/backup-ssm-secrets.sh
```

### What it does

1. Fetches ALL SSM parameters recursively from `/` path
2. Decrypts SecureString values
3. Saves to `~/.terraform-backups/ssm_backup_YYYYMMDD_HHMMSS.json`
4. Creates symlink `ssm_backup_latest.json` pointing to most recent backup
5. Sets file permissions to 600 (owner only)

### Security

- Backup files are stored in `~/.terraform-backups/` with 700 permissions
- Each backup file has 600 permissions (owner read/write only)
- Files contain plaintext secrets - keep them secure!
- Never commit backup files to git

### Output Example

```
[INFO] Starting SSM Parameter Store backup...
[INFO] Region: eu-central-1
[INFO] Backup file: /home/jakob/.terraform-backups/ssm_backup_20260315_081106.json
[INFO] Backing up from AWS Account: 787858641164
[INFO] Found 75 parameters
[INFO] Backup completed successfully!
[INFO] File: /home/jakob/.terraform-backups/ssm_backup_20260315_081106.json
[INFO] Size: 45K
[INFO] Parameters backed up: 75

Backed up parameter paths:
   1  /compute/hetzner-cloud-server-1/host
   2  /immoly/db/name
   3  /infra/terraform/aws/account_id
   ...
```

### Restore from Backup

To restore a parameter from backup:

```bash
# Extract a specific parameter value
jq -r '.parameters[] | select(.Name == "/infra/terraform/providers/hcloud_token") | .Value' \
  ~/.terraform-backups/ssm_backup_latest.json

# Restore all parameters (use with caution!)
jq -r '.parameters[] | "aws ssm put-parameter --name '\(.Name)' --type '\(.Type)' --value '\(.Value)' --overwrite"' \
  ~/.terraform-backups/ssm_backup_latest.json | bash
```

### Automated Backups

Add to crontab for daily backups:

```bash
# Edit crontab
crontab -e

# Add line for daily backup at 2 AM
0 2 * * * /home/jakob/documents/code/infra/scripts/backup-ssm-secrets.sh >> /var/log/ssm-backup.log 2>&1
```

### Cleaning Old Backups

Keep only last 30 days of backups:

```bash
find ~/.terraform-backups -name "ssm_backup_*.json" -type f -mtime +30 -delete
```
