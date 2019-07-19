variable "name" { default = "k3s-sample-cluster" }

variable "region" { default = "nyc1" }

variable "env" {
  default = "dev"
}

variable "node_size" {
  default = "s-2vcpu-4gb"
}


variable "nodes" {
  default = 3
}

