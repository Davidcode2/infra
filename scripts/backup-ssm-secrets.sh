#!/bin/bash

# AWS SSM Parameter Store Backup Script
# Backs up all SSM parameters to a local JSON file

set -e

# Configuration
BACKUP_DIR="${HOME}/.terraform-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/ssm_backup_${TIMESTAMP}.json"
AWS_REGION="${AWS_REGION:-eu-central-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

log_info "Starting SSM Parameter Store backup..."
log_info "Region: $AWS_REGION"
log_info "Backup file: $BACKUP_FILE"

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Get account ID for logging
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log_info "Backing up from AWS Account: $ACCOUNT_ID"

# Fetch all parameters recursively
log_info "Fetching all SSM parameters (this may take a moment)..."

PARAMETERS=$(aws ssm get-parameters-by-path \
    --path "/" \
    --recursive \
    --with-decryption \
    --region "$AWS_REGION" \
    --query 'Parameters' \
    --output json 2>/dev/null)

if [ $? -ne 0 ]; then
    log_error "Failed to fetch parameters from SSM"
    exit 1
fi

# Check if any parameters were found
PARAM_COUNT=$(echo "$PARAMETERS" | jq 'length')
if [ "$PARAM_COUNT" -eq 0 ]; then
    log_warn "No parameters found in SSM"
    exit 0
fi

log_info "Found $PARAM_COUNT parameters"

# Create backup with metadata
BACKUP_DATA=$(jq -n \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg account_id "$ACCOUNT_ID" \
    --arg region "$AWS_REGION" \
    --argjson params "$PARAMETERS" \
    '{
        metadata: {
            backup_timestamp: $timestamp,
            aws_account_id: $account_id,
            aws_region: $region,
            parameter_count: ($params | length)
        },
        parameters: $params
    }'
)

# Save to file
echo "$BACKUP_DATA" | jq . > "$BACKUP_FILE"

# Set restrictive permissions
chmod 600 "$BACKUP_FILE"

# Verify backup
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log_info "Backup completed successfully!"
log_info "File: $BACKUP_FILE"
log_info "Size: $FILE_SIZE"
log_info "Parameters backed up: $PARAM_COUNT"

# List all backed up parameter names for verification
echo ""
log_info "Backed up parameter paths:"
echo "$PARAMETERS" | jq -r '.[].Name' | sort | nl

# Create a symlink to latest backup
LATEST_LINK="${BACKUP_DIR}/ssm_backup_latest.json"
ln -sf "$BACKUP_FILE" "$LATEST_LINK"

log_info ""
log_info "Latest backup also available at: $LATEST_LINK"
log_info ""
log_warn "IMPORTANT: Keep this backup file secure! It contains sensitive secrets."
log_warn "File permissions: 600 (owner read/write only)"

# Summary by path prefix
echo ""
log_info "Backup summary by path prefix:"
echo "$PARAMETERS" | jq -r '.[].Name' | cut -d'/' -f1-2 | sort | uniq -c | sort -rn
