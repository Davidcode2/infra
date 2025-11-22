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
