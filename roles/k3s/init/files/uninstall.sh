#!/bin/sh
set -x
SYSTEMD_NAME=${K3S_SERVICE_NAME:-k3s}

systemctl kill ${SYSTEMD_NAME}
systemctl disable ${SYSTEMD_NAME}
systemctl reset-failed ${SYSTEMD_NAME}
systemctl daemon-reload

do_unmount() {
    MOUNTS=$(cat /proc/self/mounts | awk '{print $2}' | grep "^$1")
    if [ -n "${MOUNTS}" ]; then
        umount ${MOUNTS}
    fi
}

do_unmount '/run/k3s'
do_unmount '/var/lib/rancher/k3s'

nets=$(ip link show master cni0 | grep cni0 | awk -F': ' '{print $2}' | sed -e 's|@.*||')
for iface in $nets; do
    ip link delete $iface;
done

ip link delete cni0
ip link delete flannel.1

rm -rf /etc/rancher/k3s
rm -rf /var/lib/rancher/k3s

