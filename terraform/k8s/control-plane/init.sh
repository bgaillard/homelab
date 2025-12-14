#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

incus exec --project k8s homelab:control-plane-1 -- systemctl stop kubelet
#incus exec --project k8s homelab:control-plane-1 -- kubeadm reset --config=/root/kubeadm-config.yaml
incus exec --project k8s homelab:control-plane-1 -- kubeadm init --config=/root/kubeadm-config.yaml --upload-certs

# TODO: Manage the join of other nodes automatically
# TODO: Configure the ~/.kube/config file automatically using pre-created files in '/etc/kubernetes/admin.conf' or similar

# TODO: Manager the configuration of 'kubectl' on the host machine automatically
#
# To start administering your cluster from this node, you need to run the following as a regular user:
#
#        mkdir -p $HOME/.kube
#        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#        sudo chown $(id -u):$(id -g) $HOME/.kube/config
# 
