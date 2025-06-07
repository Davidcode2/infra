terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

module "dns" {
 source = "./global/dns"
 droplet_ipv4 = digitalocean_droplet.digitalocean_droplet_1.ipv4_address
}

resource "digitalocean_droplet" "digitalocean_droplet_1" {
  name   = "digitalocean_droplet_1"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"
}

