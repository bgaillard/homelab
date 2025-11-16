resource "incus_storage_pool" "control_plane" {
  project = incus_project.this.name
  name    = "control-plane"
  driver  = "dir"
}

resource "incus_instance" "control_plane" {
  count = 0

  project     = incus_project.this.name
  name        = "control-plane-${count.index + 1}"
  description = "Control plane node ${count.index + 1}"

  # Important, use '/cloud' images to be able to use cloud-init.
  #
  # @see https://images.linuxcontainers.org/
  image = "images:debian/trixie/cloud"

  profiles = [
    incus_profile.this.name,
    incus_profile.control_plane_or_worker_node.name,
  ]

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.memory" = "256MB"
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.control_plane.name
      size = "500MB"
    }
  }
}
