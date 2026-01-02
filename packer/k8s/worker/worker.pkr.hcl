packer {
  required_plugins {
    incus = {
      version = ">= 1.0.0"
      #source  = "github.com/bketelsen/incus"
      source  = "github.com/bgaillard/incus"
    }
  }
}

source "incus" "worker" {
  image = "images:debian/trixie"
  output_image = "bgaillard/worker"

  profile = "k8s"
  project = "k8s"
  container_name = "homelab:worker"
  virtual_machine = true
  publish_remote_name = "homelab"
  reuse = true
}

build {
  sources = ["incus.worker"]

  # TODO: It would be better to use the Ansible provisioner here

  provisioner "shell" {
    inline = [
      "mkdir -p /etc/cni/net.d",
      "mkdir -p /etc/containerd",
      "mkdir -p /etc/kubernetes",
      "mkdir -p /etc/systemd/network/enp5s0.network.d"
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
  provisioner "file" {
    source = "file/etc/sysctl.d/01-ip-forward.conf"
    destination = "/etc/sysctl.d/01-ip-forward.conf"
  }
  provisioner "file" {
    source = "file/root/kubeadm-config.yaml"
    destination = "/root/kubeadm-config.yaml"
  }

  provisioner "shell" {
    inline = [
      "chown root:root /etc/cni/net.d/20-containerd-net.conflist",
      "chown root:root /etc/containerd/config.toml",
      "chown root:root /etc/sysctl.d/01-ip-forward.conf",
      "chown root:root /root/kubeadm-config.yaml",

      "chmod 400 /etc/cni/net.d/20-containerd-net.conflist",
      "chmod 400 /etc/containerd/config.toml",
      "chmod 400 /etc/sysctl.d/01-ip-forward.conf",
      "chmod 400 /root/kubeadm-config.yaml"
    ]
  }

  provisioner "shell" {
    scripts = [
      "shell/install.sh"
    ]
  }

  # FIXME: We are forced to place those files here otherwise the DNS resolution do not work during the install.sh 
  #        execution
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/control-plane-1.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/control-plane-1.conf"
  }
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/control-plane-2.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/control-plane-2.conf"
  }
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/control-plane-3.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/control-plane-3.conf"
  }
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/worker-1.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/worker-1.conf"
  }
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/worker-2.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/worker-2.conf"
  }
  provisioner "file" {
    source = "file/etc/systemd/network/enp5s0.network.d/worker-3.conf"
    destination = "/etc/systemd/network/enp5s0.network.d/worker-3.conf"
  }
  provisioner "shell" {
    inline = [
      "chown -R root:root /etc/systemd/network",
      "chmod 444 /etc/systemd/network/enp5s0.network.d/*.conf",
    ]
  }
}
