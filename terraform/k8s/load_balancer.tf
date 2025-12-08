# TODO: It would be much more user friendly to have a DNS name here instead of an IP address for the Load Balancer VIP.

# @see https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#keepalived-and-haproxy
# @see https://itnext.io/create-a-highly-available-kubernetes-cluster-using-keepalived-and-haproxy-37769d0a65ba
resource "incus_instance" "load_balancer" {
  for_each = var.load_balancer_enabled ? local.load_balancers : {}

  project     = incus_project.this.name
  name        = each.value.name
  description = "Load balancer node ${each.value.name}"
  image       = "bgaillard/load-balancer"

  profiles = [
    # Contains a default configuration for the network card and the root disk.
    incus_profile.this.name
  ]

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype        = "bridged"
      parent         = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
    }
  }

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2GB"
  }
}
