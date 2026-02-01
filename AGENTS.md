# AGENTS.md - Infrastructure Repository

This repository defines Jakob's cloud infrastructure as code. Everything is automated and repeatable.

## 🎯 Philosophy

**Everything as Code.** All infrastructure is version-controlled and declarative. No manual clicking in cloud consoles.

**GitOps with ArgoCD.** Applications are deployed and managed through ArgoCD, which watches the app-of-apps repository.

**Hybrid Architecture.** K3s cluster for modern workloads + legacy Docker containers on a single VM (being migrated).

## 📦 Repository Structure

```
infra/
├── terraform/          # Infrastructure provisioning (Hetzner, DNS)
│   ├── main.tf        # Provider config, server provisioning
│   ├── global/dns/    # DNS records for all domains
│   └── projects/      # Project-specific infra
├── ansible/           # Server configuration & k3s setup
│   ├── playbooks/     # Orchestration playbooks
│   └── roles/         # Reusable roles (k3s-ha, nginx)
└── reverse_proxy/     # Legacy Docker-based nginx reverse proxy
    ├── nginx.conf
    └── docker-compose.yml
```

## ☁️ Cloud Architecture

### Servers (Hetzner Cloud)

**Production K3s Cluster** (3 nodes):
- `k8s-node-1`, `k8s-node-2`, `k8s-node-3`
- Type: CX23 (4 vCPU, 8GB RAM, 80GB SSD)
- Location: Nuremberg (nbg1)
- Private network: 10.0.1.0/24
- HA k3s control plane across all 3 nodes

**Legacy VM** (1 node):
- `ubuntu-4gb-nbg1-1`
- Type: CX22 (2 vCPU, 4GB RAM, 40GB SSD)
- Runs Docker containers (being migrated to k8s)
- Hosts the reverse proxy for legacy apps
- This is where OpenClaw (me) currently runs

### DNS

Managed via Terraform in `global/dns/`:
- `jakob-lingel.dev` and subdomains
- `schluesselmomente-freiburg.de`
- `immoly.io`
- `mimis-kreativstudio.de`

## 🔧 Terraform Patterns

### Provider Setup
Three cloud providers:
- **Hetzner** (hcloud) - Primary compute
- **DigitalOcean** - DNS management
- **AWS** - Secrets (Parameter Store for External Secrets)

### Modules
- `global/dns` - All DNS records
- `projects` - Project-specific infrastructure

### Main Terraform Files
- `main.tf` - Core infrastructure (servers, networks, backend config)
- `firewall.tf` - Hetzner Cloud Firewalls for all servers
- `iam.tf` - IAM roles and policies
- `outputs.tf` - Terraform outputs
- `variables.tf` - Input variables
- `bootstrap/` - Bootstrap configuration for S3 backend
  - Creates S3 bucket and DynamoDB table
  - Uses local state
  - See `bootstrap/README.md`

### State Management

**Remote State (S3):**
- Stored in: `s3://jakob-terraform-state/infra/terraform.tfstate`
- Region: eu-central-1
- Locking: DynamoDB table `terraform-state-lock`
- Encryption: Enabled (AES256)
- Versioning: Enabled (for rollback)

**Bootstrap Infrastructure:**
The S3 backend itself is managed by Terraform in `terraform/bootstrap/`:
- Uses local state (`terraform/bootstrap/terraform.tfstate`)
- Creates S3 bucket and DynamoDB table
- Separate from main infrastructure
- See `terraform/bootstrap/README.md` for details

**Do not commit local state files** - they're in `.gitignore`.

### CI/CD Workflow

**Automated via GitHub Actions:**

**On Pull Request:**
1. Run `terraform fmt -check`
2. Run `terraform init`
3. Run `terraform validate`
4. Run `terraform plan`
5. Post plan as PR comment

**On Merge to Main:**
1. Run `terraform init`
2. Run `terraform apply -auto-approve`
3. Infrastructure changes applied automatically

**Manual Operations (for urgent changes):**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Common Workflows

**Make Infrastructure Changes (PR-based):**
```bash
# 1. Create branch
git checkout -b feat/add-new-resource

# 2. Edit Terraform files
cd terraform
vim main.tf  # or firewall.tf, etc.

# 3. Commit and push
git add .
git commit -m "feat: Add new resource"
git push -u origin feat/add-new-resource

# 4. Create PR
gh pr create --title "feat: Add new resource"

# 5. Review terraform plan in PR comments
# 6. Merge PR → terraform apply runs automatically
```

**Update DNS records:**
```bash
cd terraform/global/dns
# Edit dns.tf
# Follow PR workflow above
```

**Setup CI/CD (One-Time):**
See `terraform/CICD_SETUP.md` for complete guide

**Migrate Service from Docker to Kubernetes (with DNS update):**
```bash
# 1. Deploy application to k8s (via app-of-apps repo)
# 2. Wait for k8s ingress-nginx LoadBalancer to get IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Example output:
# NAME                       TYPE           EXTERNAL-IP
# ingress-nginx-controller   LoadBalancer   49.13.123.45

# 3. Update terraform variable with the LoadBalancer IP
cd terraform
# Add to terraform.tfvars:
# k8s_load_balancer_ipv4 = "49.13.123.45"

# 4. Update DNS records to point to k8s
cd terraform/global/dns
# Edit relevant domain file (e.g., schluesselmomente-freiburg.de.tf)
# Change: value = var.hetzner_cloud_server_1_ipv4
# To:     value = var.k8s_load_balancer_ipv4

# 5. Apply via PR workflow
git checkout -b feat/dns-migrate-to-k8s
git add .
git commit -m "feat: Migrate DNS to k8s load balancer"
git push
gh pr create

# 6. Merge PR → DNS updates automatically
# 7. Wait for DNS propagation (usually 5-30 minutes)
# 8. Verify new DNS resolves to k8s LB IP:
dig admin.schluesselmomente-freiburg.de +short

# 9. Test service is accessible via k8s
curl -I https://admin.schluesselmomente-freiburg.de

# 10. Once verified, remove old Docker containers (via infra cleanup PR)
```

## 🤖 Ansible Patterns

### Inventory
Generated dynamically by Terraform (`inventory.ini.tfpl`).

Groups:
- `k3s_masters` - All 3 k8s nodes (HA setup)
- `k3s_master_init` - First node (bootstrap node)

### Playbooks

**`kube_setup.yml`** - Provision k3s HA cluster
```bash
ansible-playbook -i inventory.ini ansible/playbooks/kube_setup.yml
```

**`argocd_bootstrap.yml`** - Install ArgoCD
```bash
export KUBECONFIG=./kubeconfig-<ip>.yaml
ansible-playbook ansible/playbooks/argocd_bootstrap.yml
```

**`server_setup.yaml`** - Initial server configuration

**`kube-cleanup.yml`** - Teardown cluster

### Roles

**`k3s-ha`** - High-availability k3s cluster setup
- First node: initializes cluster
- Additional nodes: join cluster
- Uses k3s native HA (embedded etcd)

**`nginx`** - Nginx configuration (if needed)

## 🐳 Legacy Docker Reverse Proxy

Located in `reverse_proxy/`. Runs on `ubuntu-4gb-nbg1-1`.

### Current Setup
- nginx reverse proxy (port 443)
- Separate certbot container for Let's Encrypt
- Manual cert renewal via cron

### Managed Services
- Schlüsselmomente (frontend + CMS + backend)
- Mimi's Kreativstudio (Ghost CMS)
- Other legacy apps

### Migration Plan
These services are being migrated to the k8s cluster. Once complete, this reverse proxy will be decommissioned.

## 🚀 Complete Setup Flow

From zero to production:

1. **Provision infrastructure:**
   ```bash
   cd terraform
   terraform apply
   ```

2. **Configure servers:**
   ```bash
   ansible-playbook -i inventory.ini ansible/playbooks/server_setup.yaml
   ```

3. **Install k3s cluster:**
   ```bash
   ansible-playbook -i inventory.ini ansible/playbooks/kube_setup.yml
   ```

4. **Bootstrap ArgoCD:**
   ```bash
   export KUBECONFIG=./kubeconfig-<ip>.yaml
   ansible-playbook ansible/playbooks/argocd_bootstrap.yml
   ```

5. **Deploy app-of-apps:**
   ```bash
   kubectl apply -f <path-to-app-of-apps-repo>/app-of-apps.yml
   ```

6. **Watch the magic:**
   ArgoCD syncs and deploys all applications automatically.

## 🔐 Secrets Management

- **Terraform variables:** Stored in `terraform.tfvars` (not committed)
- **Kubernetes secrets:** Managed via External Secrets Operator (syncs from AWS Parameter Store)
- **Manual secrets:** Created directly in cluster (e.g., AWS credentials for External Secrets)

## ⚙️ Current State & TODOs

### Active Components
- ✅ K3s cluster (3 nodes, HA)
- ✅ ArgoCD GitOps
- ✅ Hetzner Cloud CCM (load balancers)
- ✅ cert-manager (Let's Encrypt)
- ✅ External Secrets Operator
- ✅ nginx ingress controller

### Legacy Components (To Migrate)
- 🔄 Docker reverse proxy on ubuntu-4gb-nbg1-1
- 🔄 Schlüsselmomente containers
- 🔄 Mimi's Kreativstudio Ghost

### Planned Improvements
- [ ] Move Terraform state to remote backend (S3 + DynamoDB)
- [ ] Add monitoring (Prometheus + Grafana)
- [ ] Add backup solution for PVCs
- [ ] Complete migration of legacy Docker containers

## 🛠️ Working with this Repo

### Adding a new server
1. Add resource in `terraform/main.tf`
2. Run `terraform apply`
3. Update ansible inventory
4. Configure with appropriate playbook

### Updating k3s
1. SSH to nodes
2. Update k3s binary
3. Restart service (rolling update across nodes)

### Disaster Recovery
1. Terraform can reprovision servers
2. Ansible can reconfigure them
3. ArgoCD can redeploy all apps
4. **Critical:** Ensure PVC data is backed up separately

## 📚 Related Repositories

- **app-of-apps** - ArgoCD application definitions
- Individual application repos (blog, immoly, etc.)

## 🔍 Debugging

**Check Terraform state:**
```bash
terraform show
```

**Verify ansible connectivity:**
```bash
ansible all -i inventory.ini -m ping
```

**Get k3s cluster info:**
```bash
export KUBECONFIG=./kubeconfig-<ip>.yaml
kubectl cluster-info
kubectl get nodes
```

**Check ArgoCD status:**
```bash
kubectl get applications -n argocd
```

---

**Remember:** This infra repo is the foundation. The app-of-apps repo defines what runs on it.
