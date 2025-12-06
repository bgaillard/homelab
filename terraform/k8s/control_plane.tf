resource "incus_instance" "control_plane" {
  # for_each = local.control_planes
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
      nictype        = "bridged"
      parent         = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
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

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    # WARNING: Setting CPU limit to 2 is required otherwise the following error is returned while running 'kubeadm init' 
    #          pre-flight checks.
    #
    #           [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
    #
    "limits.cpu" = "2"

    # WARNING: 1700MB is the minimum otherwise the following error is returned while running 'kubeadm init' pre-flight 
    #          checks.
    #
    #              [ERROR Mem]: the system RAM (899 MB) is less than the minimum 1700 MB
    #
    #          But as we use incus and LXC it appears that configuring 1700MB is not enough, we get the following error
    #          in this case.
    #
    #               [ERROR Mem]: the system RAM (1533 MB) is less than the minimum 1700 MB
    #
    #           So we configure 2GB.
    "limits.memory" = "2GB"
    "cloud-init.user-data" = join(
      "\n",
      [
        "#cloud-config",
        yamlencode(
          {
            package_update  = true
            package_upgrade = true
            packages = [
              "apt-transport-https",
              "ca-certificates",
              "curl",
              "gpg",
              "containerd"
            ]
            runcmd = [
              "sysctl -w net.ipv4.ip_forward=1",
              "curl -fsSL https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
              "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${var.kubernetes_version}/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
              "apt-get update",
              "apt-get install -y kubelet kubeadm kubectl",
              "apt-mark hold kubelet kubeadm kubectl",
              #"systemctl enable --now kubelet",
            ]
            write_files = [
              # @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#set-up-the-etcd-cluster
              #{
              #  path = "/etc/kubernetes/pki/etcd/ca.crt",
              #  content = file("${path.module}/etcd/etc/kubernetes/pki/etcd/ca.crt")
              #},
              #{
              #  path = "/etc/kubernetes/pki/apiserver-etcd-client.crt",
              #  content = file("${path.module}/etcd/etc/kubernetes/pki/apiserver-etcd-client.crt")
              #},
              #{
              #  path = "/etc/kubernetes/pki/apiserver-etcd-client.key",
              #  content = file("${path.module}/etcd/etc/kubernetes/pki/apiserver-etcd-client.key")
              #},
              {
                path = "/etc/kubernetes/kubelet.conf"
                content = yamlencode(
                  {
                    apiVersion = "kubelet.config.k8s.io/v1beta1"
                    kind       = "KubeletConfiguration"
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
                    cgroupDriver             = "systemd"
                    address                  = "127.0.0.1"
                    containerRuntimeEndpoint = "unix:///var/run/containerd/containerd.sock"
                    staticPodPath            = "/etc/kubernetes/manifests"
                  }
                )
              },
              {
                path    = "/etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf"
                content = <<EOT
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/kubernetes/kubelet.conf
Restart=always
EOT
              },
              {
                path    = "/tmp/${each.value.name}/kubeadmcfg.yaml"
                content = <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "${local.load_balancer_vip}:6443"
etcd:
  external:
    endpoints:
      - https://${local.etcds.etcd_1.ipv4_address}:2379
      - https://${local.etcds.etcd_2.ipv4_address}:2379
      - https://${local.etcds.etcd_3.ipv4_address}:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
EOF
              }
            ]
          }
        )
      ]
    )
  }

}
