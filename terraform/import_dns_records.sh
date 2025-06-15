#!/usr/bin/env bash

# terraform import "module.dns.digitalocean_record.jakob_lingel_dev_www_A" jakob-lingel.dev,1776336757

DOMAIN="teachly.store"
RESOURCE_PREFIX="teachly_store"

echo "Fetching DNS records for $DOMAIN..."
records=$(doctl compute domain records list "$DOMAIN" --format ID,Type,Name --no-header)

while read -r record; do
  id=$(echo "$record" | awk '{print $1}')
  type=$(echo "$record" | awk '{print $2}')
  name=$(echo "$record" | awk '{print $3}')

  # Sanitize resource name
  safe_name=$(echo "${RESOURCE_PREFIX}_${name}_${type}" | tr '.@-' '_')

  echo "terraform import module.dns.digitalocean_record.${safe_name} ${DOMAIN},${id}"
done <<< "$records"
