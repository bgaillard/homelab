resource "incus_profile" "this" {
  project = incus_project.this.name
  name    = "k8s"

  config = {
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.this.name
    }
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.this.name
      size = "6GB"
    }
  }
}
