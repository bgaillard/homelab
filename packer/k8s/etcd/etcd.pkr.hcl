packer {
  required_plugins {
    incus = {
      version = ">= 1.0.0"
      #source  = "github.com/bketelsen/incus"
      source  = "github.com/bgaillard/incus"
    }
  }
}

source "incus" "etcd" {
  image = "images:debian/trixie"
  output_image = "bgaillard/etcd"

  profile = "k8s"
  project = "k8s"
  container_name = "homelab:etcd"
  virtual_machine = true
  publish_remote_name = "homelab"
  reuse = true
}

build {
  sources = ["incus.etcd"]

  # TODO: It would be better to use the Ansible provisioner here

  provisioner "shell" {
    inline = [
      "mkdir -p /etc/cni/net.d",
      "mkdir -p /etc/containerd",
      "mkdir -p /etc/kubernetes",
      "mkdir -p /etc/systemd/system/kubelet.service.d"
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
    source = "file/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf"
    destination = "/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf"
  }
  provisioner "file" {
    source = "file/etc/kubernetes/kubelet.conf"
    destination = "/etc/kubernetes/kubelet.conf"
  }
  provisioner "file" {
    source = "file/root/init.sh"
    destination = "/root/init.sh"
  }
  provisioner "file" {
    source = "file/usr/local/bin/etcdctl"
    destination = "/usr/local/bin/etcdctl"
  }
  provisioner "shell" {
    inline = [
      "chown root:root /etc/cni/net.d/20-containerd-net.conflist",
      "chown root:root /etc/containerd/config.toml",
      "chown root:root /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf",
      "chown root:root /etc/kubernetes/kubelet.conf",
      "chown root:root /root/init.sh",
      "chown root:root /usr/local/bin/etcdctl",

      "chmod +x /usr/local/bin/etcdctl",
      "chmod +x /root/init.sh",
    ]
  }

  provisioner "shell" {
    scripts = [
      "shell/install.sh"
    ]
  }
}
