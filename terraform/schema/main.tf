module "sample" {
  source             = "../modules/droplet"
  environment        = "${var.env}"
  name               = "${var.name}"
  region             = "${var.region}"
  nodes              = "${var.nodes}"
  node_size          = "${var.node_size}"
  priv_key           = "${data.vault_generic_secret.do_priv_key.data["value"]}"
  ssh_fingerprint    = "${data.vault_generic_secret.do_ssh_fingerprint.data["value"]}"
}

