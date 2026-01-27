resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

# @see https://github.com/kubernetes/dashboard
resource "helm_release" "kubernetes_dashboard" {
  name = "kubernetes-dashboard"

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
}
