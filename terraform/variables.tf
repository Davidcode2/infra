variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "hcloud_ssh_key_path" {
  type        = string
  description = "Path to the SSH key for Hetzner Cloud"
  sensitive   = true
}

variable "digitalocean_droplet_1_ipv4" {
  type        = string
  description = "IP address of the first DigitalOcean droplet"
  sensitive   = true
}

variable "hetzner_cloud_server_1_ipv4" {
  type        = string
  description = "IP address of the first Hetzner cloud server"
  sensitive   = true
}

variable "schluesselmomente_freiburg_de_ZMAIL_DKIM_value" {
  type        = string
  description = "zmail DKIM value for schluesselmomente-freiburg.de domain"
  sensitive   = true
}

variable "schluesselmomente_freiburg_de_DKIM_value" {
  type        = string
  description = "DKIM value for schluesselmomente-freiburg.de domain"
  sensitive   = true
}

variable "schluesselmomente_freiburg_de_SPF_TXT_value" {
  type        = string
  description = "SPF TXT value for schluesselmomente-freiburg.de domain"
  sensitive   = true
}

variable "schluesselmomente_freiburg_de_zoho_verification_TXT_value" {
  type        = string
  description = "SPF TXT value for schluesselmomente-freiburg.de domain"
  sensitive   = true
}
