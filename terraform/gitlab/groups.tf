resource "gitlab_group" "company" {
  name        = "Company"
  path        = "company"
  description = "Group dedicated to private company projects."
}

resource "gitlab_group" "samples" {
  name        = "Samples"
  path        = "samples"
  description = "Group dedicated to sample projects to be quickly reused as templates."
}
resource "gitlab_group" "samples_docs" {
  name        = "Docs"
  path        = "docs"
  description = "Group dedicated to sample documentation projects."
  parent_id   = gitlab_group.samples.id
}
resource "gitlab_group" "samples_internal_developer_portals" {
  name        = "Internal Developer Portals"
  path        = "internal-developer-portals"
  description = "Group dedicated to sample internal developer portal projects."
  parent_id   = gitlab_group.samples.id
}
