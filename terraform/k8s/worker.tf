resource "incus_instance" "worker" {
  for_each = var.workers_enabled ? local.workers : {}

  type        = "virtual-machine"
  project     = incus_project.this.name
  name        = each.value.name
  description = "Worker ${each.value.name}"
  image       = "bgaillard/worker"

  profiles = [
    # Contains a default configuration for the network card and the root disk.
    incus_profile.this.name,
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

  provisioner "local-exec" {
    command = "${path.module}/worker/start.sh ${each.value.name}"
  }
}
