# DNS Migration Guide: Docker VM to Kubernetes Cluster

This guide explains how to update DNS records when migrating services from the legacy Docker VM to the Kubernetes cluster.

## Overview

When migrating a service from Docker to Kubernetes:
1. Service is deployed to k8s cluster
2. k8s ingress-nginx creates a Hetzner Load Balancer
3. DNS must be updated to point to the Load Balancer IP instead of the VM IP
4. Old Docker containers can be removed after DNS propagates

## The Problem

**Before Migration:**
```
DNS: admin.schluesselmomente-freiburg.de → 49.13.45.106 (VM IP)
                                              ↓
                                    ubuntu-4gb-nbg1-1 VM
                                              ↓
                                    Docker nginx reverse proxy
                                              ↓
                                    schluesselmomente-cms container
```

**After Migration (k8s):**
```
DNS: admin.schluesselmomente-freiburg.de → 49.13.123.45 (LB IP)
                                              ↓
                                    Hetzner Cloud Load Balancer
                                              ↓
                                    k8s ingress-nginx controller
                                              ↓
                                    schluesselmomente-cms pod
```

The DNS needs to be updated from VM IP to LB IP.

## Step-by-Step Migration

### 1. Deploy Application to Kubernetes

This is done via the app-of-apps repository (see app-of-apps#2 for schluesselmomente-cms).

**Verify deployment:**
```bash
kubectl get pods -n schluesselmomente-cms
kubectl get ingress -n schluesselmomente-cms
```

### 2. Get Kubernetes Load Balancer IP

The Hetzner CCM automatically creates a Load Balancer when you deploy ingress-nginx.

```bash
# Get the external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Example output:
# NAME                       TYPE           EXTERNAL-IP
# ingress-nginx-controller   LoadBalancer   49.13.123.45

# Save this IP - you'll need it for DNS update
export K8S_LB_IP="49.13.123.45"
```

**Note:** This IP is assigned once and doesn't change unless you delete and recreate the LoadBalancer service.

### 3. Add Load Balancer IP to Terraform Variables

Add the k8s load balancer IP to your `terraform.tfvars`:

```hcl
# terraform/terraform.tfvars
k8s_load_balancer_ipv4 = "49.13.123.45"
```

Or set it as an environment variable:
```bash
export TF_VAR_k8s_load_balancer_ipv4="49.13.123.45"
```

Or store in AWS SSM (if using OIDC approach):
```bash
aws ssm put-parameter \
  --name /terraform/infra/k8s_load_balancer_ipv4 \
  --value "49.13.123.45" \
  --type String \
  --region eu-central-1
```

### 4. Update DNS Records

Edit the relevant DNS file in `terraform/global/dns/`.

**Example: Migrating admin.schluesselmomente-freiburg.de**

Edit `terraform/global/dns/schluesselmomente-freiburg.de.tf`:

**Before:**
```hcl
resource "digitalocean_record" "schluesselmomente_freiburg_de_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "admin"
  value  = var.hetzner_cloud_server_1_ipv4  # Old VM IP
  ttl    = 3600
}
```

**After:**
```hcl
resource "digitalocean_record" "schluesselmomente_freiburg_de_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "admin"
  value  = var.k8s_load_balancer_ipv4  # K8s Load Balancer IP
  ttl    = 3600
}
```

**Best Practice - Fallback Pattern:**
```hcl
resource "digitalocean_record" "schluesselmomente_freiburg_de_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "admin"
  # Use k8s LB if set, otherwise fall back to VM (for gradual migration)
  value  = var.k8s_load_balancer_ipv4 != "" ? var.k8s_load_balancer_ipv4 : var.hetzner_cloud_server_1_ipv4
  ttl    = 3600
}
```

### 5. Apply DNS Changes via Pull Request

```bash
cd terraform
git checkout -b feat/dns-migrate-schluesselmomente-cms

# Edit DNS files
vim terraform/global/dns/schluesselmomente-freiburg.de.tf

# Commit changes
git add .
git commit -m "feat: Migrate admin.schluesselmomente-freiburg.de DNS to k8s load balancer

Migrating schluesselmomente-cms from Docker VM to Kubernetes cluster.
DNS now points to k8s ingress-nginx load balancer.

Load Balancer IP: 49.13.123.45
Previous VM IP: 49.13.45.106"

# Push and create PR
git push -u origin feat/dns-migrate-schluesselmomente-cms
gh pr create --title "DNS: Migrate schluesselmomente-cms to k8s" \
  --body "Updates DNS records to point to k8s load balancer after migration"

# Review terraform plan in PR
# Merge PR → terraform apply runs automatically
```

### 6. Monitor DNS Propagation

After merging the PR, DNS records will update. Monitor propagation:

```bash
# Check current DNS resolution
dig admin.schluesselmomente-freiburg.de +short

# Check from different DNS servers
dig @8.8.8.8 admin.schluesselmomente-freiburg.de +short  # Google DNS
dig @1.1.1.1 admin.schluesselmomente-freiburg.de +short  # Cloudflare DNS

# Monitor until it shows the new k8s LB IP
watch -n 5 'dig admin.schluesselmomente-freiburg.de +short'
```

**Typical propagation time:** 5-30 minutes (TTL is 3600 seconds = 1 hour max)

### 7. Verify Service Accessibility

Once DNS propagates, verify the service works via k8s:

```bash
# Test HTTPS access
curl -I https://admin.schluesselmomente-freiburg.de

# Should show 200 OK and cert from Let's Encrypt (cert-manager)

# Full test
curl https://admin.schluesselmomente-freiburg.de

# Check k8s ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
```

### 8. Cleanup Old Docker Configuration

After DNS is fully migrated and service is working:

**Remove from nginx reverse proxy** (infra repo):
```bash
cd /path/to/infra
git checkout -b chore/cleanup-schluesselmomente-cms-vm

# Edit reverse_proxy/nginx.conf
# Remove admin.schluesselmomente-freiburg.de server block

# Edit reverse_proxy/docker-compose.yml
# Remove domain from certbot list

# Commit and PR
```

**Stop and remove Docker containers:**
```bash
# On the VM (ubuntu-4gb-nbg1-1)
ssh ubuntu-4gb-nbg1-1

cd /opt/deployments/schluesselmomente-cms
docker compose down

# Optional: Remove data (be careful!)
# sudo rm -rf /opt/deployments/schluesselmomente-cms
```

## Common Issues

### Issue: DNS not propagating

**Problem:** DNS still shows old VM IP after 30+ minutes

**Solution:**
```bash
# Check DNS record was actually updated
terraform show | grep admin.schluesselmomente

# Force dig to bypass cache
dig admin.schluesselmomente-freiburg.de @ns1.digitalocean.com +short

# Clear local DNS cache
sudo systemd-resolve --flush-caches  # Linux
```

### Issue: Service not accessible via k8s

**Problem:** DNS points to k8s but service returns error

**Solution:**
```bash
# Check ingress exists
kubectl get ingress -n schluesselmomente-cms

# Check ingress has address
kubectl describe ingress -n schluesselmomente-cms

# Check pod is running
kubectl get pods -n schluesselmomente-cms

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Issue: SSL certificate errors

**Problem:** Browser shows certificate error after migration

**Cause:** cert-manager needs time to provision Let's Encrypt certificate

**Solution:**
```bash
# Check certificate status
kubectl get certificate -n schluesselmomente-cms

# Wait for "Ready: True"
kubectl describe certificate -n schluesselmomente-cms

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## Rollback Procedure

If issues occur, you can quickly rollback DNS to point back to the VM:

```bash
# 1. Revert the DNS PR
git revert <dns-migration-commit>
git push

# 2. Or manually update terraform.tfvars
# Set k8s_load_balancer_ipv4 = ""
# This will fall back to var.hetzner_cloud_server_1_ipv4

# 3. Apply terraform
terraform apply

# 4. DNS will point back to VM (Docker containers should still be running)
```

## Best Practices

### 1. Lower TTL Before Migration

Before starting migration, lower the DNS TTL to speed up rollback if needed:

```hcl
resource "digitalocean_record" "schluesselmomente_freiburg_de_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "admin"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 300  # Lower to 5 minutes before migration
}
```

After migration is stable, raise it back to 3600.

### 2. Test in Non-Production First

If possible, test the migration flow with a non-critical service first.

### 3. Keep Docker Containers Running

Don't stop Docker containers until DNS has fully propagated and you've verified k8s is working.

### 4. Document Load Balancer IP

Keep track of the k8s load balancer IP in a safe place:

```bash
# Store in SSM
aws ssm put-parameter \
  --name /infra/k8s_load_balancer_ip \
  --value "49.13.123.45" \
  --type String

# Or document in AGENTS.md
```

### 5. Use Monitoring

Set up monitoring to alert if the service goes down during migration.

## Migration Checklist

Use this checklist for each service migration:

- [ ] Deploy application to k8s cluster
- [ ] Verify pod is running: `kubectl get pods -n <namespace>`
- [ ] Verify ingress created: `kubectl get ingress -n <namespace>`
- [ ] Get k8s load balancer IP: `kubectl get svc -n ingress-nginx`
- [ ] Add LB IP to terraform variables
- [ ] Update DNS records in terraform
- [ ] Create PR for DNS change
- [ ] Review terraform plan
- [ ] Merge PR (terraform apply automatic)
- [ ] Monitor DNS propagation: `dig <domain> +short`
- [ ] Test service via HTTPS: `curl -I https://<domain>`
- [ ] Check certificate valid: `curl https://<domain>`
- [ ] Monitor for 24 hours
- [ ] Remove old Docker configuration
- [ ] Stop Docker containers
- [ ] Document completion

## Example: schluesselmomente-cms Migration

**Service:** schluesselmomente-cms (Strapi CMS)  
**Domain:** admin.schluesselmomente-freiburg.de  
**Old:** VM IP 49.13.45.106  
**New:** k8s LB IP 49.13.123.45 (example)

**Steps taken:**
1. ✅ Deployed to k8s via app-of-apps#2
2. ✅ Got LB IP: `kubectl get svc -n ingress-nginx`
3. ✅ Added to terraform.tfvars: `k8s_load_balancer_ipv4 = "49.13.123.45"`
4. ✅ Updated schluesselmomente-freiburg.de.tf with fallback pattern
5. ✅ Created PR with DNS changes
6. ✅ Merged PR → DNS updated automatically
7. 🔄 Waiting for DNS propagation
8. ⏳ Test service accessibility
9. ⏳ Remove old Docker config
10. ⏳ Document completion

---

**Related Documentation:**
- Main infrastructure: `AGENTS.md`
- App-of-apps migrations: `../app-of-apps/AGENTS.md`
- Kubernetes ingress: `../app-of-apps/*/ingress-resource.yaml`
