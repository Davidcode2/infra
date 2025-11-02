# This output makes the Load Balancer IP available
output "load_balancer_ip" {
  value = hcloud_load_balancer.k8s_lb.ipv4
}

# This output makes the server private IPs available
output "server_private_ips" {
  value = hcloud_server.k8s_node.*.ipv4_address # Use .ipv4 (public) or .private_net[0].ip (private)
}

# This resource generates the inventory.ini file
resource "local_file" "ansible_inventory" {
  # The content comes from the template file
  content = templatefile("${path.module}/../ansible/inventory/inventory.ini.tfpl", {
    # Pass Terraform data into the template
    lb_ip   = hcloud_load_balancer.k8s_lb.ipv4
    masters = [
      for s in hcloud_server.k8s_node : {
        name = s.name
        ipv4 = s.ipv4_address
      }
    ]
    ssh_key_path = var.ssh_private_key_path # Add a variable for this
  })

  # The path where the inventory file will be created
  filename = "../${path.module}/ansible/inventory/k8s_hosts.ini"
}
