alias ktl='k3s kubectl'
alias kubectl='k3s kubectl'
alias crictl='k3s crictl'

k3a () {
  ktl get --all-namespaces --show-labels "${@}"
}

k3ip () {
  ktl get nodes --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}'
}

