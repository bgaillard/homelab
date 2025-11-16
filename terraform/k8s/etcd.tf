resource "incus_storage_pool" "etcd" {
  project = incus_project.this.name
  name    = "etcd"
  driver  = "dir"
}

# TODO: Remove the 'no imagefs label for configured runtime' message in 'systemctl status kubelet'
# 
# @see https://kubernetes.io/blog/2024/01/23/kubernetes-separate-image-filesystem/


# @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology
resource "incus_instance" "etcd" {
  for_each = local.etcds

  type        = "virtual-machine" 
  project     = incus_project.this.name
  name        = each.value.name
  description = "Etcd node ${each.value.name}"

  # Important, use '/cloud' images to be able to use cloud-init.
  #
  # @see https://images.linuxcontainers.org/
  image = "images:debian/trixie/cloud"

  profiles = [incus_profile.this.name]

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
    }
  }

  # @see https://etcd.io/docs/v3.6/faq/#system-requirements
  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.memory" = "1024MB"

    # FIXME: METTRE TOUS LES LIENS QUI VONT BIEN, POUR FAIRE TOURNER KUBERNETES OBLIGE DE LE FAIRE DANS DES VM
    # - https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/#running-kubernetes-inside-unprivileged-containers
    # - https://discuss.linuxcontainers.org/t/cluster-api-and-kubernetes/23084
    # - https://discuss.linuxcontainers.org/t/configure-k3s-in-incus-with-zfs-delegate/19765
    #"security.privileged" = "true"

    # FIXME: Try to put in common Cloud Init common configuration between etcd / control plane / worker nodes. The thing
    #        is that it seems required to have specific configuration for 'etcd'
    #
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

      write_files:
        - path: /etc/kubernetes/kubelet.conf
          content: |
            apiVersion: kubelet.config.k8s.io/v1beta1
            kind: KubeletConfiguration
            authentication:
              anonymous:
                enabled: false
              webhook:
                enabled: false
            authorization:
              mode: AlwaysAllow
            # Important because we are using Debian which uses systemd
            # 
            # @see https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
            cgroupDriver: "systemd"
            address: 127.0.0.1
            containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
            staticPodPath: /etc/kubernetes/manifests

        - path: /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
          content: |
            [Service]
            ExecStart=
            ExecStart=/usr/bin/kubelet --config=/etc/kubernetes/kubelet.conf
            Restart=always

        - path: /root/kubeadmcfg.yaml
          content: |
            ---
            apiVersion: "kubeadm.k8s.io/v1beta4"
            kind: InitConfiguration
            nodeRegistration:
                name: ${each.value.name}
            localAPIEndpoint:
                advertiseAddress: ${each.value.ipv4_address}
            ---
            apiVersion: "kubeadm.k8s.io/v1beta4"
            kind: ClusterConfiguration
            etcd:
                local:
                    serverCertSANs:
                    - "${each.value.ipv4_address}"
                    peerCertSANs:
                    - "${each.value.ipv4_address}"
                    extraArgs:
                    - name: initial-cluster
                      value: ${local.etcds.etcd_1.name}=https://${local.etcds.etcd_1.ipv4_address}:2380,${local.etcds.etcd_2.name}=https://${local.etcds.etcd_2.ipv4_address}:2380,${local.etcds.etcd_3.name}=https://${local.etcds.etcd_3.ipv4_address}:2380
                    - name: initial-cluster-state
                      value: new
                    - name: name
                      value: ${each.value.name}
                    - name: listen-peer-urls
                      value: https://${each.value.ipv4_address}:2380
                    - name: listen-client-urls
                      value: https://${each.value.ipv4_address}:2379
                    - name: advertise-client-urls
                      value: https://${each.value.ipv4_address}:2379
                    - name: initial-advertise-peer-urls
                      value: https://${each.value.ipv4_address}:2380
EOF
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.etcd.name
      size = "5GB"
    }
  }
}
