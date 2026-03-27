# Homelab k3s Agent Setup Guide

This guide explains how to add Tailscale-connected homelab devices to the k3s cluster as agent (worker) nodes.

## Overview

Homelab devices (like laptops, home servers) connect to the cluster via Tailscale VPN and join as **agent nodes only** (not control plane servers). This is important because:

- **Agent nodes** can go offline without affecting cluster stability
- **Server nodes** participate in etcd consensus - going offline can break the cluster

## Prerequisites

1. Tailscale installed and running on the homelab device
2. Tailscale SSH enabled on the device
3. Device has a Tailscale IP (100.x.x.x range)
4. Kubeconfig file exists at `playbooks/kubeconfig-116.203.111.240.yaml`

## Setup

### 1. Configure Inventory

Edit `ansible/inventory/homelab-inventory.ini`:

```ini
[all:vars]
ansible_user = YOUR_USERNAME  # Your username on the laptop
# If not using Tailscale SSH, uncomment and set your SSH key:
# ansible_ssh_private_key_file = "~/.ssh/your-key"

[k3s_agents]
homelab-laptop ansible_host=100.115.249.19 node_name=homelab-laptop
```

### 2. Run the Playbook

```bash
cd /home/jakob/documents/code/infra/ansible
ansible-playbook -i inventory/homelab-inventory.ini playbooks/homelab-agent-setup.yml
```

### 3. Verify Installation

```bash
kubectl --kubeconfig=playbooks/kubeconfig-116.203.111.240.yaml get nodes
```

You should see `homelab-laptop` in the list with:
- Status: Ready
- Taints: `dedicated=homelab:NoSchedule`
- Labels: `node-type=homelab`

## Scheduling Workloads on Homelab Nodes

Regular pods will NOT schedule on homelab nodes due to the taint. To run pods on homelab:

### Example Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-homelab-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-homelab-app
  template:
    metadata:
      labels:
        app: my-homelab-app
    spec:
      tolerations:
        - key: "dedicated"
          operator: "Equal"
          value: "homelab"
          effect: "NoSchedule"
      nodeSelector:
        node-type: homelab
      containers:
        - name: app
          image: nginx:latest
```

## Adding More Devices

1. Add device to inventory:
   ```ini
   [k3s_agents]
   homelab-laptop ansible_host=100.115.249.19 node_name=homelab-laptop
   homelab-server ansible_host=100.x.x.x node_name=homelab-server
   ```

2. Run playbook again - it will configure the new device while leaving existing ones unchanged

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Hetzner Cloud                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  k8s-node-1  │  │  k8s-node-2  │  │  k8s-node-3  │       │
│  │  (Master)    │  │  (Master)    │  │  (Master)    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                                              │      │
│         │  Private Network: 10.0.1.0/24               │      │
└─────────┼──────────────────────────────────────────────┘      │
          │                                                     │
          │  Public Internet                                    │
          │                                                     │
┌─────────┴──────────────────────────────────────────────┐      │
│                  Tailscale Mesh VPN                      │      │
│                                                          │      │
│  ┌─────────────────┐        ┌──────────────────┐         │      │
│  │ homelab-laptop  │        │ homelab-server   │         │      │
│  │ 100.115.249.19  │        │  100.x.x.x       │         │      │
│  │   (Agent)       │        │   (Agent)        │         │      │
│  └─────────────────┘        └──────────────────┘         │      │
└──────────────────────────────────────────────────────────┘      │
```

- Homelab agents connect to the k3s API server at `116.203.111.240:6443`
- Pod networking uses the overlay network (flannel) via Tailscale

## Troubleshooting

### Node not joining

1. Check Tailscale connectivity:
   ```bash
   ping 100.115.249.19
   ```

2. Verify k3s-agent service:
   ```bash
   ssh YOUR_USERNAME@100.115.249.19
   sudo systemctl status k3s-agent
   sudo journalctl -u k3s-agent -f
   ```

3. Check logs on the agent:
   ```bash
   sudo cat /var/log/syslog | grep k3s
   ```

### Token issues

If the join token retrieval fails:
1. Ensure kubeconfig is correct: `kubectl --kubeconfig=playbooks/kubeconfig-116.203.111.240.yaml get nodes`
2. Check if the secret exists: `kubectl -n kube-system get secret k3s-server-token`

## Security Considerations

- Homelab nodes use the same TLS certificates as cloud nodes
- All communication is encrypted via k3s mTLS
- Tailscale provides an additional encrypted layer
- Homelab nodes cannot access etcd directly (agent-only)

## Cleanup

To remove a homelab node from the cluster:

```bash
# From the homelab device
ssh YOUR_USERNAME@100.115.249.19
sudo /usr/local/bin/k3s-agent-uninstall.sh

# From your workstation (drain and delete node)
kubectl --kubeconfig=playbooks/kubeconfig-116.203.111.240.yaml drain homelab-laptop --ignore-daemonsets --delete-local-data
kubectl --kubeconfig=playbooks/kubeconfig-116.203.111.240.yaml delete node homelab-laptop
```
