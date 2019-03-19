Terraform configs and asnible playbooks to deploy k3s clusters
==============================================================

Table of Contents
-----------------
* [Introduction](#introduction)
* [Quick start](#quick-start)
* [Usage](#usage)

### Introduction

[k3s](https://k3s.io/) is a lightweight kubernetes distribution, packed into a single
binary, which already includes all you need to quickly spin up a k8s cluster.

It's a very nice tool for development and playing around with k8s clusters, because with k3s
you can spin up a cluster from scratch in about 5 minutes (droplet creation takes the most time).

It does differ from vanilla kubernetes (particularly, right now there is no HA for masters),
so please see official [docs](https://github.com/rancher/k3s/blob/master/README.md) to better
understand k3s specific details.

### Quick start

1. Get your vault token and export it as TF_VAR_vault_token
1. `cd terraform/sample && terraform init && terraform apply`
1. `cd ../..; ansible-playbook -i terraform/sample/inventory plays/k3s.yml`
1. You should now have 3 nodes k8s cluster, ssh to the master node (or copy `/etc/rancher/k3s/k3s.yaml` 
from the master node to ~/.kube/config to use kubectl locally) and check it out: `k3s kubectl get nodes -o wide`.
1. If you need helm, run `ansible-playbook -terraform/sample/inventory plays/helm.yml`, it will install tiller pod
and helm client on master node.
1. To "reset" the cluster run `ansible-playbook -terraform/sample/inventory plays/reset-cluster.yml`. Note that this playbook reboots
all the nodes, so expect it to fail in the end. Then run `ansible-playbook -i terraform/sample/inventory plays/k3s.yml -t master,node` to 
create a new cluster.
1. Don't forget to destroy your env when you are done: `cd terraform/sample && terraform destroy`.

### Usage
