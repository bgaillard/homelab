resource "incus_storage_pool" "control_plane" {
  project = incus_project.this.name
  name    = "control-plane"
  driver  = "dir"
}

resource "incus_instance" "control_plane" {
  #for_each = local.control_planes
  for_each = {}

  type        = "virtual-machine" 
  project     = incus_project.this.name
  name        = each.value.name
  description = "Controle plane node ${each.value.name}"

  # Important, use '/cloud' images to be able to use cloud-init.
  #
  # @see https://images.linuxcontainers.org/
  image = "images:debian/trixie/cloud"

  profiles = [
    incus_profile.this.name,
    incus_profile.control_plane_or_worker_node.name,
  ]

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
    }
  }

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.memory" = "256MB"
    "cloud-init.user-data" = join(
      "\n",
      [
        "#cloud-config", 
        yamlencode(
          {
            package_update = true
            package_upgrade = true
            packages = [
              "apt-transport-https",
              "ca-certificates",
              "curl",
              "gpg",
              "containerd"
            ]
            runcmd = [
              "curl -fsSL https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
              "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
              "apt-get update",
              "apt-get install -y kubelet kubeadm kubectl",
              "apt-mark hold kubelet kubeadm kubectl",
              "systemctl enable --now kubelet",
            ]
            write_files = [
              {
                path = "/etc/kubernetes/kubelet.conf"
                content = yamlencode(
                  {
                    apiVersion = "kubelet.config.k8s.io/v1beta1"
                    kind = "KubeletConfiguration"
                    authentication = {
                      anonymous = {
                        enabled = false
                      }
                      webhook = {
                        enabled = false
                      }
                    }
                    authorization = {
                      mode = "AlwaysAllow"
                    }
                    # Important because we are using Debian which uses systemd
                    # 
                    # @see https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
                    cgroupDriver = "systemd"
                    address = "127.0.0.1"
                    containerRuntimeEndpoint = "unix:///var/run/containerd/containerd.sock"
                    staticPodPath = "/etc/kubernetes/manifests"
                  }
                )
              },
              {
                path = "/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf"
                content = <<EOT
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/kubernetes/kubelet.conf
Restart=always
EOT
              },
            ]
          }
        )
      ]
    )
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.control_plane.name
      size = "5GB"
    }
  }
}
