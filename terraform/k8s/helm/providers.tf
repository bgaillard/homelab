provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "homelab"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config" # Configuration options
  config_context = "homelab"
}
