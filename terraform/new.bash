#!/bin/bash

ask () {

    default="${1}"; shift
    read userInput
    [[ "${userInput}" == "" ]] && echo "${default}" || echo "${userInput}"

}

echo -n "Environment (default: dev): "
env=$(ask "dev")

echo -n "Region (default: nyc1): "
region=$(ask "nyc1")

echo -n "Nodes (default: 3): "
nodes=$(ask 3)

echo -n "Name (default: k3s-sample-cluster): "
name=$(ask "k3s-sample-cluster")

mkdir "${name}-${env}-${region}"; cd "${name}-${env}-${region}"

for f in ../schema/*.tf; do
    ln -s ${f} ${f##*/}
done

ln -s ../schema/tmpl .

cat <<EOF > terraform.tfvars
nodes = ${nodes}
name = "${name}"
region = "${region}"
env = "${env}"
EOF

