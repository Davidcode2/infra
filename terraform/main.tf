terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.44"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  region  = "eu-central-1"
  profile = "admin"
}

module "dns" {
  source                                                    = "./global/dns"
  digitalocean_droplet_1_ipv4                               = var.digitalocean_droplet_1_ipv4
  schluesselmomente_freiburg_de_DKIM_value                  = var.schluesselmomente_freiburg_de_DKIM_value
  schluesselmomente_freiburg_de_ZMAIL_DKIM_value            = var.schluesselmomente_freiburg_de_ZMAIL_DKIM_value
  hetzner_cloud_server_1_ipv4                               = var.hetzner_cloud_server_1_ipv4
  schluesselmomente_freiburg_de_zoho_verification_TXT_value = var.schluesselmomente_freiburg_de_zoho_verification_TXT_value
  schluesselmomente_freiburg_de_SPF_TXT_value               = var.schluesselmomente_freiburg_de_SPF_TXT_value
  portfolio_netlify_challenge_txt                           = var.portfolio_netlify_challenge_txt
}

module "projects" {
  source                      = "./projects"
  hetzner_cloud_server_1_ipv4 = var.hetzner_cloud_server_1_ipv4
  hetzner_cloud_server_1_deployment_private_ssh_key = tls_private_key.hetzner_private_key.private_key_pem
}

# compute
resource "digitalocean_droplet" "jakobsOceanVM" {
  name       = "jakobsOceanVM"
  region     = "fra1"
  size       = "s-1vcpu-2gb"
  image      = "142476112"
  monitoring = true

  vpc_uuid = "94463b0e-551f-4943-b13d-ef8d1f5fcc27"
}

resource "hcloud_server" "hetzner_ubuntu-4gb-nbg1-1" {
  name        = "ubuntu-4gb-nbg1-1"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  location    = "nbg1"
}

resource "hcloud_ssh_key" "hetzner_ssh_key" {
  name       = "hetzner-1"
  public_key = var.hcloud_ssh_key
}

resource "tls_private_key" "hetzner_private_key" {
  algorithm = "ED25519"
  lifecycle {
    create_before_destroy = true
  }
}

resource "hcloud_ssh_key" "deployment_key" {
  name       = "deployment-key"
  public_key = tls_private_key.hetzner_private_key.public_key_openssh
}


# private network
resource "hcloud_network" "k8s_private_net" {
  name     = "k8s-private-net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k8s_private_subnet" {
  network_id   = hcloud_network.k8s_private_net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "k8s_node" {
  count       = 3 # Create three identical nodes
  name        = "k8s-node-${count.index + 1}"
  image       = "ubuntu-24.04"
  server_type = "cx23" 
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.hetzner_ssh_key.id]

  # Attach each server to the private network
  network {
    network_id = hcloud_network.k8s_private_net.id
  }
}

# costs about 7 €/month
resource "hcloud_load_balancer" "k8s_lb" {
  name               = "k8s-load-balancer"
  load_balancer_type = "lb11"
  location           = "nbg1"
}

# Attach the Load Balancer to private network
resource "hcloud_load_balancer_network" "lb_private_net" {
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  network_id       = hcloud_network.k8s_private_net.id
}

# Tell the Load Balancer to target servers
resource "hcloud_load_balancer_target" "lb_target" {
  count            = 3
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  server_id        = hcloud_server.k8s_node[count.index].id
  use_private_ip   = true
}

# Define the services (e.g., HTTP and HTTPS)
resource "hcloud_load_balancer_service" "lb_http" {
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 30080 # Example port for Kubernetes NodePort
}

resource "hcloud_load_balancer_service" "lb_https" {
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 30443 # Example port for Kubernetes NodePort
}

resource "hcloud_load_balancer_service" "lb_kube_api" {
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  protocol         = "tcp"
  listen_port      = 6443 # External port
  destination_port = 6443 # Internal port on the nodes (K3s default)
}

resource "hcloud_load_balancer_target" "kube_api_target" {
  count            = length(hcloud_server.k8s_node)
  load_balancer_id = hcloud_load_balancer.k8s_lb.id
  type             = "server"
  server_id        = hcloud_server.k8s_node[count.index].id
}
