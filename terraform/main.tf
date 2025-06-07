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
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

provider "hcloud" {
  token = var.hcloud_token
}

module "dns" {
 source = "./global/dns"
 droplet_ipv4 = digitalocean_droplet.digitalocean-droplet-1.ipv4_address
}

resource "digitalocean_droplet" "digitalocean-droplet-1" {
  name   = "digitalocean-droplet-1"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"
}

resource "hcloud_server" "web" {
  name        = "hetzner-server"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = "nbg1"

  ssh_keys = [hcloud_ssh_key.default.id]
}

resource "hcloud_ssh_key" "default" {
  name       = "main-key"
  public_key = file(var.hcloud_ssh_key_path)
}

