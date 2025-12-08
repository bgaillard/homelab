#!/bin/bash

KUBERNETES_VERSION=${1:-"1.34"}

# TODO: Check if required by kubelet
swapoff -a

# TODO: Find the link explaining this requirement
sysctl -w net.ipv4.ip_forward=1

apt-get update -y
apt-get upgrade -y

apt-get install -y apt-transport-https \
  ca-certificates \
  curl \
  gpg

curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y

# Warning: Installing the 'containerd' package from Debian repositories did not worked well. So we install
#          a more recent version.
#
# @see https://github.com/containerd/containerd/blob/main/docs/getting-started.md#option-2-from-apt-get-or-dnf
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update -y
apt-get install -y containerd.io


# WARNING: Without 'systemd-timesyncd' installed the following warning can be encountered while running 
#          etcd.
#
#           prober found high clock drift
#
apt-get install -y kubelet kubeadm kubectl systemd-timesyncd
apt-mark hold kubelet kubeadm kubectl

cd  /tmp && \
  curl -sLo nerdctl.tar.gz https://github.com/containerd/nerdctl/releases/download/v2.2.0/nerdctl-2.2.0-linux-amd64.tar.gz && \
  tar -xf nerdctl.tar.gz && \
  mv nerdctl /usr/bin/nerdctl && \
  rm -rf nerdctl.tar.gz

# Enable services at boot time
systemctl enable systemd-timesyncd
systemctl enable containerd
systemctl enable kubelet
