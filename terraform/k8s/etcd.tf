resource "incus_instance" "etcd" {
  for_each = var.etcd_enabled ? local.etcds : {}

  type        = "virtual-machine"
  project     = incus_project.this.name
  name        = each.value.name
  description = "Etcd node ${each.value.name}"
  image       = "bgaillard/etcd"

  profiles = [
    # Contains a default configuration for the network card and the root disk.
    incus_profile.this.name
  ]

  # Override the default network card configuration to set a static IP address
  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype        = "bridged"
      parent         = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
    }
  }

  # @see https://etcd.io/docs/v3.6/faq/#system-requirements
  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2GB"
  }

  provisioner "local-exec" {
    command = "${path.module}/etcd/copy.sh ${each.value.name}"
  }
}
