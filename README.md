Terraform configs and asnible playbooks to deploy k3s clusters
==============================================================

Table of Contents
-----------------
* [Introduction](#introduction)
* [Quick start](#quick-start)
* [Usage](#usage)
    * [Notes on k3s specifics](#notes-on-k3s-specifics)
    * [Playbook defaults](#playbook-defaults)
    * [Creating the infrastructure](#creating-the-infrastructure)
    * [Running the playbook](#running-the-playbook)
* [Batteries included](#batteries-included)

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
1. Create infrastructure with terraform: `cd terraform/sample && terraform init && terraform apply`
1. Run the playbook: `cd ../..; ansible-playbook -i terraform/sample/inventory plays/k3s.yml`
1. You should now have 3 nodes k8s cluster, and `kubeconfig` file locally. Move it to `~/.kube/config` and
use kubectl as you normally would: `mv kubeconfig ~/.kube/config && kubectl get nodes -o wide` 
1. If you need helm, run `ansible-playbook -terraform/sample/inventory plays/helm.yml`, it will install tiller pod in the cluster
and helm client on master node.
1. To "reset" the cluster run `ansible-playbook -terraform/sample/inventory plays/reset-cluster.yml`. Note that last task of the playbook reboots
all the nodes, so expect it to fail in the end. Then run `ansible-playbook -i terraform/sample/inventory plays/k3s.yml -t master,node` to 
create a new cluster.
1. Don't forget to destroy your env when you are done: `cd terraform/sample && terraform destroy`.

### Usage

#### Notes on k3s specifics

k3s uses a single master without HA. It uses sqlite instead of ectd by default for storage.
k3s master node has no taints by default, which means that pods will be scheduled on master node as well.

k3s includes and uses flannel by default for CNI networking. 

k3s uses [containerd](https://containerd.io/) (already integrated into k3s binary) instead of docker, which means that:
1. Applications that rely on docker specific paths/files/sockets/formats probably won't work.
1. To operate running containers on a node you need to use `k3s crictl ...` instead of `docker ...`

k3s has a builtin deploy controller. It scans `/var/lib/rancher/k3s/server/manifests/` directory on master node,
and tries to deploy [manifests](roles/k3s/deploy/files/grafana-datasources.yaml) and [helm charts](roles/k3s/deploy/files/grafana) found
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

The playbook installs a bunch of helpful bash [aliases](roles/aliases/files/kubeadm.sh) on cluster nodes:
```
alias kubectl=`k3s kubectl`
alias ktl=`k3s kubectl`
alias crictl=`k3s crictl`
```

#### Creating new infrastructure

There are [sample](terraform/sample) terraform configs for creating droplets in DO and generating ansible inventory.
When starting new project you can use that as a basis:

1. Copy sample configs: `cp -r terraform/sample terrafom/myNewProject && cd terraform/myNewProject`.
1. Adjust values to your needs. Main candidates: `name`, `nodes`, `region`, `node_size` (default is **s-2vcpu-4gb**).
1. Get your vault token and export it as `TF_VAR_vault_token`.
1. `terraform init && terraform plan && terraform apply`.
1. You are ready to run the playbook. Go back to the root dir: `cd ../..`

#### Running the playbook

* The whole playbook from scratch: `ansible-playbook -i terraform/myNewProject/inventory plays/k3s.yml`
* Only master part: `ansible-playbook -i terraform/myNewProject/inventory plays/k3s.yml -t master`
* Only nodes part: `ansible-playbook -i terraform/myNewProject/inventory plays/k3s.yml -t node`
* Destroying and recreating the cluster:  
```
ansible-playbook -i terraform/myNewProject/inventory plays/reset-cluster.yml
sleep 30
ansible-playbook -i terraform/myNewProject/inventory plays/k3s.yml -t master,node
```

### Batteries included

There are a couple of additional playbooks included:

* [helm](plays/helm.yml)  
Installs helm server part (with RBAC) in the cluster and helm client on the master node.  
`ansible-playbook -i terraform/myNewProject/inventory plays/helm.yml`

* [monitoring](plays/monitoring.yml)  
Installs [loki](https://github.com/grafana/loki), [prometheus-operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator)
and [grafana](https://github.com/helm/charts/tree/master/stable/grafana) into monitoring namespace of your cluster. Grafana comes preconfigured with
loki and prometheus datasources. The playbook uses builtin k3s deploy controller.  
`ansible-playbook -i terraform/myNewProject/inventory plays/monitoring.yml`

#### k3s deploy controller helm tricks

You can't feed a local chart to k3s deploy controller (you can, of course, use `helm template` to generate a bundle of manifests and use that, but it's not always convenient), but you can specify an url of a public helm repo to install a chart from there. So we can do something like this:

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
