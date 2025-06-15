variable "hetzner_cloud_server_1_ipv4" {
  type        = string
  description = "IP address of the first Hetzner cloud server"
  sensitive   = true
}

variable "hetzner_cloud_server_1_deployment_private_ssh_key" {
  type        = string
  description = "Private SSH key for deployment of the first Hetzner cloud server"
  sensitive   = true
}
