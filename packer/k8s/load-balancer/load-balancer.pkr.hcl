packer {
  required_plugins {
    incus = {
      version = ">= 1.0.0"
      #source  = "github.com/bketelsen/incus"
      source  = "github.com/bgaillard/incus"
    }
  }
}

source "incus" "load_balancer" {
  image = "images:debian/trixie"
  output_image = "bgaillard/load-balancer"

  profile = "k8s"
  project = "k8s"
  container_name = "homelab:load-balancer"
  virtual_machine = false
  publish_remote_name = "homelab"
  reuse = true
}

build {
  sources = ["incus.load_balancer"]

  # TODO: It would be better to use the Ansible provisioner here

  provisioner "shell" {
    inline = [
      "mkdir -p /etc/haproxy",
      "mkdir -p /etc/keepalived"
    ]
  }

  provisioner "file" {
    source = "file/etc/haproxy/haproxy.cfg"
    destination = "/etc/haproxy/haproxy.cfg"
  }
  provisioner "file" {
    source = "file/etc/keepalived/check_api_server.sh"
    destination = "/etc/keepalived/check_api_server.sh"
  }
  provisioner "file" {
    source = "file/etc/keepalived/keepalived.conf"
    destination = "/etc/keepalived/keepalived.conf"
  }
  provisioner "shell" {
    inline = [
      "chown root:root /etc/haproxy/haproxy.cfg",
      "chown root:root /etc/keepalived/check_api_server.sh",
      "chown root:root /etc/keepalived/keepalived.conf",

      "chmod 500 /etc/keepalived/check_api_server.sh"
    ]
  }

  provisioner "shell" {
    scripts = [
      "shell/install.sh"
    ]
  }
}
