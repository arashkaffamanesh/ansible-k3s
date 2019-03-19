output "public_ips" {
  value = ["${digitalocean_droplet.node.*.ipv4_address}"]
}

output "node_names" {
  value = ["${digitalocean_droplet.node.*.name}"]
}

