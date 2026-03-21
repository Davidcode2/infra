# DNS Records for Resend Domain Verification
# These records are automatically created from resend-config.json

# Get the DigitalOcean domain
# Note: This assumes the domain already exists in DigitalOcean
# (managed by the main terraform/global/dns configuration)

data "digitalocean_domain" "jakob_lingel_dev" {
  name = "jakob-lingel.dev"
}

# Create DNS records from Resend configuration
resource "digitalocean_record" "resend_records" {
  for_each = local.has_config ? {
    for idx, record in local.records : "${record.record}-${idx}" => record
  } : {}

  domain = data.digitalocean_domain.jakob_lingel_dev.name
  type   = each.value.type
  name   = each.value.name
  # DigitalOcean requires MX record values to end with a dot
  value = each.value.type == "MX" && !endswith(each.value.value, ".") ? "${each.value.value}." : each.value.value
  ttl   = 3600

  # Only set priority for MX records
  priority = each.value.type == "MX" ? each.value.priority : null
}

# Output what was created
output "created_records" {
  description = "DNS records created for Resend domain verification"
  value = local.has_config ? [
    for key, record in digitalocean_record.resend_records : {
      name     = record.name
      type     = record.type
      value    = record.value
      priority = record.priority
    }
  ] : []
}

output "resend_domain" {
  description = "The Resend domain name"
  value       = local.domain_name
}

output "next_steps" {
  description = "Instructions for next steps"
  value       = local.has_config ? "Run: npm run verify-domain (after waiting 5-30 minutes for DNS propagation)" : "Run: npm run create-domain first"
}
