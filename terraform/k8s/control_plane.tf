resource "incus_instance" "control_plane" {
  for_each = var.control_plane_enabled ? local.control_planes : {}

  type        = "virtual-machine"
  project     = incus_project.this.name
  name        = each.value.name
  description = "Controle plane node ${each.value.name}"
  image       = "bgaillard/control-plane"

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
    # WARNING: Setting CPU limit to 2 is required otherwise the following error is returned while running 'kubeadm init' 
    #          pre-flight checks.
    #
    #           [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
    #
    "limits.cpu" = "2"

    # WARNING: 1700MB is the minimum otherwise the following error is returned while running 'kubeadm init' pre-flight 
    #          checks.
    #
    #              [ERROR Mem]: the system RAM (899 MB) is less than the minimum 1700 MB
    #
    #          But as we use incus and LXC it appears that configuring 1700MB is not enough, we get the following error
    #          in this case.
    #
    #               [ERROR Mem]: the system RAM (1533 MB) is less than the minimum 1700 MB
    #
    #           So we configure 2GB.
    "limits.memory" = "2GB"
  }

  provisioner "local-exec" {
    command = "${path.module}/control-plane/start.sh ${each.value.name}"
  }
}
