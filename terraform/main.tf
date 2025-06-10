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

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
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

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
}
