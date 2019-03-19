module "sample" {
  source             = "../modules/droplet"
  name               = "k3s-sample"
  region             = "nyc1"
  nodes              = "3"
  priv_key           = "${data.vault_generic_secret.do_priv_key.data["value"]}"
  ssh_fingerprint    = "${data.vault_generic_secret.do_ssh_fingerprint.data["value"]}"
}

