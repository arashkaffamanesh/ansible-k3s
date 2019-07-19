Terraform configs and asnible playbooks to deploy k3s clusters
==============================================================

Table of Contents
-----------------
* [Introduction](#introduction)
* [Quick start](#quick-start)
* [Usage](#usage)
    * [Notes on k3s specifics](#notes-on-k3s-specifics)
    * [Playbook defaults](#playbook-defaults)
* [Batteries included](#batteries-included)
    * [Custom helm repo with s3](#custom-helm-repo-with-s3)

### Introduction

[k3s](https://k3s.io/) is a lightweight kubernetes distribution, packed into a single
binary, which already includes all you need to quickly spin up a k8s cluster.

It's a very nice tool for development and playing around with k8s clusters, because with k3s
you can spin up a cluster from scratch in about 5 minutes (droplet creation takes the most time).

It does differ from vanilla kubernetes (particularly, right now there is no HA for masters),
so please see official [docs](https://github.com/rancher/k3s/blob/master/README.md) to better
understand k3s specific details.

### Quick start

1. Clone the repo and go to the root dir: `git clone git@github.com:AnchorFree/ansible-k3s.git k3s && cd k3s`
1. Make sure you have `secret/devops/cloud_providers/do_hss/do_priv_key` ssh private key from vault set as your default ssh key.
1. Get your vault token and export it as `TF_VAR_vault_token`.
1. Create a new infrastructure with terraform: `cd terraform && ./new.bash && cd your-project-name && terraform init && terraform apply`
1. Deploy the cluster: 
```
ansible-playbook -i terraform/your-project-name/inventory plays/init.yml
ansible-playbook -i terraform/your-project-name/inventory plays/k3s.yml
```
If you are in a hurry, you can skip the `init` playbook, it does `apt-get update && apt-get upgrade` which takes a while.
1. You should now have 3 nodes k8s cluster, and `kubeconfig` file locally. Move it to `~/.kube/config` and
use kubectl as you normally would: `mv kubeconfig ~/.kube/config && kubectl get nodes -o wide` 
1. If you need helm, run `ansible-playbook -terraform/sample/inventory plays/helm.yml`, it will install tiller pod in the cluster
and helm client on master node.
1. To "reset" the cluster run `ansible-playbook -i terraform/your-project-name/inventory plays/reset-cluster.yml`. Note that last task of the playbook reboots
all the nodes, so expect it to fail in the end. Then run `ansible-playbook -i terraform/sample/inventory plays/k3s.yml` to 
create a new cluster.
1. Don't forget to destroy your env when you are done: `cd terraform/your-project-name && terraform destroy`.

### Usage

#### Notes on k3s specifics

k3s uses a single master without HA. It uses sqlite instead of ectd by default for storage.
k3s master node has no taints by default, which means that pods will be scheduled on master node as well.

k3s includes and uses flannel by default for CNI networking. 

k3s uses [containerd](https://containerd.io/) (already integrated into k3s binary) instead of docker, which means that:
1. Applications that rely on docker specific paths/files/sockets/formats probably won't work.
1. To operate running containers on a node you need to use `k3s crictl ...` instead of `docker ...`

k3s has a builtin deploy controller. It scans `/var/lib/rancher/k3s/server/manifests/` directory on master node,
and tries to deploy [helm charts](roles/k3s/deploy/files/prometheus-operator.yaml) and manifests found
there. 

#### Playbook defaults

k3s uses 10.42.0.0/16 for cluster CIDR and 10.43.0.0/16 for service CIDR by default.
This playbook uses different default [values](roles/k3s/master/defaults/main.yml):
```
k3s_service_cidr: 192.168.64.0/18
k3s_cluster_cidr: 192.168.0.0/18
```

k3s uses flannel as CNI network plugin by default. If you want to use different CNI network plugin,
you need to turn off flannel, this can be done by overriding `k3s_server_extra_args` and `k3s_agent_args` variables:
```
k3s_server_extra_args: "--no-flannel --no-deploy=traefik"
k3s_agent_args: "--no-flannel"
```

k3s deploys [traefik](https://github.com/containous/traefik) by default as a simple ingress/lb solution.
This playbook disables the default traefik deployment. If you want to use it, override `k3s_server_extra_args` and remove
`--no-deploy=traefik` part.

The playbook installs a bunch of helpful bash [aliases](roles/aliases/files/kubeadm.sh) on cluster nodes.

### Batteries included

There are a couple of additional playbooks included:

* [helm](plays/helm.yml)  
Installs helm server part (with RBAC) in the cluster and helm client on the master node.  
`ansible-playbook -i terraform/myNewProject/inventory plays/helm.yml`

* [monitoring](plays/monitoring.yml)  
Installs [loki](https://github.com/grafana/loki) and [prometheus-operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator)
with [grafana](https://github.com/helm/charts/tree/master/stable/grafana) enabled into monitoring namespace of your cluster. The playbook uses builtin k3s deploy controller.  
`ansible-playbook -i terraform/myNewProject/inventory plays/monitoring.yml`

* [storage](plays/storage.yml) Deploys [rook](https://rook.io) and configures `ceph` cluster. After install you will have a `rook-ceph-block` storage class which
can be used by apps thet require persistent storage.

#### Custom helm repo with s3 

You can't feed a local chart to k3s deploy controller (you can, of course, use `helm template` to generate a bundle of manifests and use that, but it's not always convenient), but you can specify an url of a public helm repo to install a chart from there. And a public helm repo is no more than a bunch of packeged charts plus an `index.yaml` file. To package a chart you can use `helm package` and to create an index you can use `helm repo index`. So we can do something like this:

```
git clone https://github.com/grafana/loki.git
cd loki/production
mv helm loki
cd loki
helm package .
mkdir ~/charts
mv loki*tgz ~/charts
cd ~/charts
helm repo index .
s3cmd put -P index.yaml s3://af-k3s/helm/
s3cmd put -P loki-0.2.0.tgz s3://af-k3s/helm/
```

And use `https://af-k3s.s3.amazonaws.com/helm/` as the public address of your repo. 
