#!/bin/bash

# Import existing SSM parameters into Terraform state
# Run this locally before applying via pipeline

set -e

echo "Importing existing SSM parameters into Terraform state..."
echo "This will NOT overwrite values, just register them in state."
echo ""

# Parameters to import (created manually earlier)
declare -a PARAMS=(
  "/infra/terraform/providers/hcloud_token"
  "/infra/terraform/providers/digitalocean_token"
  "/infra/terraform/servers/hetzner_server_1_ipv4"
  "/infra/terraform/servers/digitalocean_droplet_1_ipv4"
  "/infra/terraform/servers/hcloud_ssh_key"
  "/infra/terraform/dns/schluesselmomente_dkim"
  "/infra/terraform/dns/schluesselmomente_zmail_dkim"
  "/infra/terraform/dns/schluesselmomente_spf"
  "/infra/terraform/dns/schluesselmomente_zoho_verification"
  "/infra/terraform/dns/portfolio_netlify_challenge"
  "/infra/terraform/aws/account_id"
  "/infra/terraform/ssh_private_key_path"
)

# Change to terraform directory
cd /home/jakob/documents/code/infra/terraform

for param in "${PARAMS[@]}"; do
  echo "Importing: $param"
  
  # Convert parameter name to resource address
  # e.g., /infra/terraform/providers/hcloud_token -> module.projects.aws_ssm_parameter.terraform_secrets[\"/infra/terraform/providers/hcloud_token\"]
  resource_addr="module.projects.aws_ssm_parameter.terraform_secrets[\"$param\"]"
  
  # Check if already in state
  if terraform state show "$resource_addr" &>/dev/null; then
    echo "  Already imported, skipping."
    continue
  fi
  
  # Import the parameter
  terraform import "$resource_addr" "$param" || echo "  Failed to import (may already exist or not exist in AWS)"
  echo ""
done

echo "Import complete!"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to verify no changes needed"
echo "2. Commit any changes"
echo "3. Push to trigger workflow"
