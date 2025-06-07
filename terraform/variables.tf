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
