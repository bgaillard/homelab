resource "incus_storage_pool" "worker" {
  project = incus_project.this.name
  name    = "worker"
  driver  = "dir"
}

resource "incus_instance" "worker" {
  count = 0

  project     = incus_project.this.name
  name        = "worker-${count.index + 1}"
  description = "Worker node ${count.index + 1}"

  # Important, use '/cloud' images to be able to use cloud-init.
  #
  # @see https://images.linuxcontainers.org/
  image = "images:debian/trixie/cloud"

  profiles = [
    # Contains a default configuration for the network card and the root disk.
    incus_profile.this.name,
  ]

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.memory" = "512MB"
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.worker.name
      size = "500MB"
    }
  }
}
