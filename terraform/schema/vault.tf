variable "vault_token" {}

provider "vault" {
  address = "https://vault.afdevops.com"
  token = "${var.vault_token}"
}

data "vault_generic_secret" "do_token" {
  path = "secret/devops/cloud_providers/do_hss/token"
}

data "vault_generic_secret" "do_ssh_fingerprint" {
  path = "secret/devops/cloud_providers/do_hss/do_ssh_fingerprint"
}

data "vault_generic_secret" "do_priv_key" {
  path = "secret/devops/cloud_providers/do_hss/do_priv_key"
}
