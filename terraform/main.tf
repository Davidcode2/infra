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
  source                                                    = "./global/dns"
  digitalocean_droplet_1_ipv4                               = var.digitalocean_droplet_1_ipv4
  schluesselmomente_freiburg_de_DKIM_value                  = var.schluesselmomente_freiburg_de_DKIM_value
  schluesselmomente_freiburg_de_ZMAIL_DKIM_value            = var.schluesselmomente_freiburg_de_ZMAIL_DKIM_value
  hetzner_cloud_server_1_ipv4                               = var.hetzner_cloud_server_1_ipv4
  schluesselmomente_freiburg_de_zoho_verification_TXT_value = var.schluesselmomente_freiburg_de_zoho_verification_TXT_value
  schluesselmomente_freiburg_de_SPF_TXT_value               = var.schluesselmomente_freiburg_de_SPF_TXT_value
  portfolio_netlify_challenge_txt                           = var.portfolio_netlify_challenge_txt
}

#resource "digitalocean_droplet" "digitalocean-droplet-1" {
#  name   = "digitalocean-droplet-1"
#  region = "fra1"
#  size   = "s-1vcpu-1gb"
#  image  = "ubuntu-22-04-x64"
#}
#
#resource "hcloud_server" "web" {
#  name        = "hetzner-server"
#  image       = "ubuntu-22.04"
#  server_type = "cx11"
#  location    = "nbg1"
#
#  ssh_keys = [hcloud_ssh_key.default.id]
#}

#resource "hcloud_ssh_key" "default" {
#  name       = "main-key"
#  public_key = file(var.hcloud_ssh_key_path)
#}

