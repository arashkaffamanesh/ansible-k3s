variable "name" {}

variable "user" {
  default = "root"
}

variable "ssh_port" {
  default = "22"
}

variable "environment" {
  default = "dev"
}

variable "image" {
  default = "ubuntu-18-04-x64"
}

# To see all available sizes, use the url:
# https://developers.digitalocean.com/documentation/v2/#list-all-sizes
variable "node_size" {
  default = "s-2vcpu-4gb"
}

variable "nodes" {
  default = "1"
}

variable "region" {
  default = "nyc1"
}

variable "priv_key" {}
variable "ssh_fingerprint" {}

