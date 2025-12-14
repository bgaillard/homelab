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

variable "workers_enabled" {
  description = "Enable workers deployment."
  type        = bool
  default     = true
}
