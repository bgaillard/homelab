packer {
  required_plugins {
    incus = {
      version = ">= 1.0.0"
      #source  = "github.com/bketelsen/incus"
      source  = "github.com/bgaillard/incus"
    }
  }
}

source "incus" "control_plane" {
  image = "images:debian/trixie"
  output_image = "bgaillard/control-plane"

  profile = "k8s"
  project = "k8s"
  container_name = "homelab:control-plane"
  virtual_machine = true
  publish_remote_name = "homelab"
  reuse = true
}

build {
  sources = ["incus.control_plane"]

  # TODO: It would be better to use the Ansible provisioner here

  provisioner "shell" {
    inline = [
      "mkdir -p /etc/cni/net.d",
      "mkdir -p /etc/containerd",
      "mkdir -p /etc/kubernetes",
      # "mkdir -p /etc/systemd/system/kubelet.service.d"
    ]
  }

  provisioner "file" {
    source = "file/etc/cni/net.d/20-containerd-net.conflist"
    destination = "/etc/cni/net.d/20-containerd-net.conflist"
  }
  provisioner "file" {
    source = "file/etc/containerd/config.toml"
    destination = "/etc/containerd/config.toml"
  }
  # provisioner "file" {
  #   source = "file/etc/kubernetes/kubelet.conf"
  #   destination = "/etc/kubernetes/kubelet.conf"
  # }
  provisioner "file" {
    source = "file/etc/sysctl.d/01-ip-forward.conf"
    destination = "/etc/sysctl.d/01-ip-forward.conf"
  }
  # provisioner "file" {
  #   source = "file/etc/systemd/system/kubelet.service.d/20-control-plane-service-manager.conf"
  #   destination = "/etc/systemd/system/kubelet.service.d/20-control-plane-service-manager.conf"
  # }
  provisioner "file" {
    source = "file/root/kubeadm-config.yaml"
    destination = "/root/kubeadm-config.yaml"
  }

  provisioner "shell" {
    inline = [
      "chown root:root /etc/cni/net.d/20-containerd-net.conflist",
      "chown root:root /etc/containerd/config.toml",
      # "chown root:root /etc/kubernetes/kubelet.conf",
      "chown root:root /etc/sysctl.d/01-ip-forward.conf",
      # "chown root:root /etc/systemd/system/kubelet.service.d/20-control-plane-service-manager.conf",
      "chown root:root /root/kubeadm-config.yaml",

      "chmod 400 /etc/cni/net.d/20-containerd-net.conflist",
      "chmod 400 /etc/containerd/config.toml",
      # "chmod 400 /etc/kubernetes/kubelet.conf",
      "chmod 400 /etc/sysctl.d/01-ip-forward.conf",
      # "chmod 400 /etc/systemd/system/kubelet.service.d/20-control-plane-service-manager.conf",
      "chmod 400 /root/kubeadm-config.yaml"
    ]
  }

  provisioner "shell" {
    scripts = [
      "shell/install.sh"
    ]
  }
}
