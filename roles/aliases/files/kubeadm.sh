export KTL_LAST_NS="${KTL_LAST_NS:-kube-system}"

if (which k3s &>/dev/null); then
    kubectl="k3s kubectl"
    alias crictl='k3s crictl'
else
    kubectl="kubectl"
fi

ktl () {

    local ns=${KTL_LAST_NS}
    local args=("$@")
    local i=0; local k=0

    for arg in "${args[@]}"; do
        if [[ "${arg}" == "-n" ]]; then
            k=$((i+1))
            ns=${args[${k}]}
            export KTL_LAST_NS=${ns}
        fi
        i=$((i+1))
    done
    echo "NAMESPACE: ${ns}"
    if [[ ${k} -gt 0 ]]; then
        ${kubectl} "${@}"
    else
        ${kubectl} -n ${ns} "${@}"
    fi

}

k3.pf () {
  ktl port-forward "${@}"
}

k3.all () {
  ${kubectl} get --all-namespaces "${@}"
}

k3.ip () {
  ${kubectl} get nodes --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}'
}

k3.ev () {
  ktl get events --sort-by='{.lastTimestamp}' "${@}"
}

k3.scp () {

name=${1}; shift
fromNamespace=${1}; shift
toNamespace=${1}

${kubectl} -n ${fromNamespace} get secret ${name} -o json | jq ".metadata.namespace = \"${toNamespace}\"" | ${kubectl} create -f -

}

