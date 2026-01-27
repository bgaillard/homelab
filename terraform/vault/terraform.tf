terraform {
  required_version = ">= 1.13"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.6.0"
    }
  }
}
