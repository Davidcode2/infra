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

### Security

**Hetzner Cloud Firewalls:**
- **k8s-cluster-firewall** - Applied to all 3 k8s nodes
  - Allows: SSH (22), HTTP (80), HTTPS (443), K8s API (6443), ICMP
  - Allows: All traffic within private network (10.0.0.0/16)
  - Default: Deny all other inbound traffic
- **legacy-vm-firewall** - Applied to ubuntu-4gb-nbg1-1
  - Allows: SSH (22), HTTP (80), HTTPS (443), ICMP
  - Default: Deny all other inbound traffic

All outbound traffic is allowed by default (servers need to reach external services).

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
- `main.tf` - Core infrastructure (servers, networks)
- `firewall.tf` - Hetzner Cloud Firewalls for all servers
- `iam.tf` - IAM roles and policies
- `outputs.tf` - Terraform outputs
- `variables.tf` - Input variables

### State Management
Terraform state is managed locally. **Do not commit state files.**

### Common Workflows

**Provision new infrastructure:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Update DNS records:**
```bash
cd terraform/global/dns
# Edit dns.tf
terraform plan
terraform apply
```

**Update firewall rules:**
```bash
cd terraform
# Edit firewall.tf
terraform plan
terraform apply
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
