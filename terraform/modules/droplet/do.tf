resource "digitalocean_droplet" "node" {
  count      = "${var.nodes}"
  image      = "${var.image}"
  name       = "${var.name}-${var.environment}-${var.region}-${count.index+1}"
  region     = "${var.region}"
  size       = "${var.node_size}"
  monitoring = true
  ssh_keys   = ["${var.ssh_fingerprint}"]

  connection {
    user        = "${var.user}"
    type        = "ssh"
    private_key = "${var.priv_key}"
    timeout     = "2m"
    port        = "${var.ssh_port}"
  }

  lifecycle {
    ignore_changes = ["image", "ssh_keys", "private_networking", "resize_disk", "size"]
  }
}

