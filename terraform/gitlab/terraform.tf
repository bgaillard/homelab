terraform {
  required_version = ">= 1.13"

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "18.9.0"
    }
  }
}
