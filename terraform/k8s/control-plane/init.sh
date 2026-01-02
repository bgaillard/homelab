#!/bin/bash

incus exec --project k8s homelab:control-plane-1 -- systemctl stop kubelet
#incus exec --project k8s homelab:control-plane-1 -- kubeadm reset --config=/root/kubeadm-config.yaml
incus exec --project k8s homelab:control-plane-1 -- kubeadm init --config=/root/kubeadm-config.yaml --upload-certs

#for i in 1 2 3; do
#
#  # Manage Control Plane nodes 2 and 3 join
#  #if [ "${i}" -ne 1 ]; then
#  #  # TODO: Manage the join of other nodes automatically
#  #fi
#
#  # Configure kubectl on each control plane node
#  incus exec --project k8s homelab:control-plane-${i} -- mkdir -p /root/.kube
#  incus exec --project k8s homelab:control-plane-${i} -- cp /etc/kubernetes/admin.conf /root/.kube/config
#  incus exec --project k8s homelab:control-plane-${i} -- chown 0:0 /root/.kube/config
#  incus exec --project k8s homelab:control-plane-${i} -- bash -c "echo 'alias k=kubectl' >> /root/.bashrc"
#done
