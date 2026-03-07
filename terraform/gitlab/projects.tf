resource "gitlab_project" "material_for_mkdocs" {
  namespace_id = gitlab_group.samples_docs.id
  name         = "Material for mkdocs"
  path         = "material-for-mkdocs"
  description  = "Sample documentation project using Material for mkdocs."
}
