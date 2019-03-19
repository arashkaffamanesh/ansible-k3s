[all]
${join("\n", formatlist("%v ansible_ssh_host=%v", split(",",node_names), split(",",node_ips)))}

[master]
${element(split(",",node_names),0)}

[all:vars]
master_public_ip=${element(split(",",node_ips),0)}


