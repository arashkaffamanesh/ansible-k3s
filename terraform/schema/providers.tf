provider "digitalocean" {
  token = "${data.vault_generic_secret.do_token.data["value"]}"
}

