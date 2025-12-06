resource "incus_storage_pool" "this" {
  project = incus_project.this.name
  name    = incus_project.this.name
  driver  = "dir"
}
