#!/bin/bash

# Restarting the Kubelet is not required, it's only useful if we do not wish to wait until 20 seconds for the etcd 
# static pod manifest files to be detected by the Kubelet.
#
# Those 20 seconds are the default defined by the 'fileCheckFrequency' parameter in the Kubelet configuration file.
#
# @see https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/

incus exec --project k8s homelab:etcd-1 -- kubeadm init phase etcd local --config=/root/kubeadm-config.yaml
incus exec --project k8s homelab:etcd-1 -- systemctl restart kubelet

incus exec --project k8s homelab:etcd-2 -- kubeadm init phase etcd local --config=/root/kubeadm-config.yaml
incus exec --project k8s homelab:etcd-2 -- systemctl restart kubelet

incus exec --project k8s homelab:etcd-3 -- kubeadm init phase etcd local --config=/root/kubeadm-config.yaml
incus exec --project k8s homelab:etcd-3 -- systemctl restart kubelet
