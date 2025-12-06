resource "incus_profile" "this" {
  project = incus_project.this.name
  name    = "k8s"

  config = {
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.this.name
    }
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.this.name
      size = "5GB"
    }
  }
}

# Profile common to control plane and worker nodes.
resource "incus_profile" "control_plane_or_worker_node" {
  project = incus_project.this.name
  name    = "kubeadm"

  config = {

    # @see https://kubernetes.io/docs/concepts/cluster-administration/swap-memory-management/#swap-and-control-plane-nodes
    "limits.memory.swap" = "false"

    # @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
    "cloud-init.user-data" = <<-EOF
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - apt-transport-https 
        - ca-certificates 
        - curl 
        - gpg
        - containerd
      runcmd:
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
        - apt-get update
        - apt-get install -y kubelet kubeadm kubectl
        - apt-mark hold kubelet kubeadm kubectl
        - systemctl enable --now kubelet
EOF
  }
}
