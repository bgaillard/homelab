#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

incus exec --project k8s homelab:control-plane-1 -- systemctl stop kubelet
incus exec --project k8s homelab:control-plane-1 -- kubeadm init --config=/root/kubeadm-config.yaml --upload-certs

# TODO: Manage the join of other nodes automatically
