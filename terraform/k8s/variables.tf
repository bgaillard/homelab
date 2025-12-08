variable "control_plane_enabled" {
  description = "Enable control plane nodes deployment."
  type        = bool
  default     = true
}

variable "etcd_enabled" {
  description = "Enable etcd cluster deployment."
  type        = bool
  default     = true
}

variable "load_balancer_enabled" {
  description = "Enable load balancer deployment."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to install."
  type        = string
  default     = "1.34"
}
