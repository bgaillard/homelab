resource "incus_network" "this" {
  project = incus_project.this.name
  name    = "private"

  config = {
    "ipv4.address" = "10.0.0.1/28"
    "ipv4.nat"     = "true"
    #"ipv6.address" = "fd42:474b:622d:259d::1/64"
    #"ipv6.nat"     = "true"
  }
}
