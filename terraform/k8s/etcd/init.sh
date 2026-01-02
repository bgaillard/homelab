#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

rm -Rf "${CURRENT_DIR}"/etcd-1
rm -Rf "${CURRENT_DIR}"/etcd-2
rm -Rf "${CURRENT_DIR}"/etcd-3

# Initialize the CA on the first etcd node (the CA is valid for 10 years by default)
incus exec --project k8s homelab:etcd-1 -- kubeadm init phase certs etcd-ca

# Pull the CA and backup it locally
incus file pull --project k8s --recursive --create-dirs homelab:etcd-1/etc/kubernetes/pki/etcd/ "${CURRENT_DIR}"/etcd-1/etc/kubernetes/pki
incus file pull --project k8s --recursive --create-dirs homelab:etcd-1/etc/kubernetes/pki/etcd/ "${CURRENT_DIR}"/etcd-2/etc/kubernetes/pki
incus file pull --project k8s --recursive --create-dirs homelab:etcd-1/etc/kubernetes/pki/etcd/ "${CURRENT_DIR}"/etcd-3/etc/kubernetes/pki

# Push the CA to the other etcd nodes
incus file push --project k8s --recursive --create-dirs "${CURRENT_DIR}"/etcd-1/etc/kubernetes/pki/etcd/ca.* homelab:etcd-2/etc/kubernetes/pki/etcd/
incus file push --project k8s --recursive --create-dirs "${CURRENT_DIR}"/etcd-1/etc/kubernetes/pki/etcd/ca.* homelab:etcd-3/etc/kubernetes/pki/etcd/

for i in 1 2 3; do

  # Execute the init script
  incus exec --project k8s homelab:etcd-${i} -- /root/init.sh

  # Pull the generated certificates to backup them locally
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/apiserver-etcd-client.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/apiserver-etcd-client.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/healthcheck-client.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/healthcheck-client.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/peer.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/peer.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/server.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/server.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd

  # Pull the kubeadm-config.yaml file to backup it locally
  incus file pull --project k8s --create-dirs homelab:etcd-${i}/root/kubeadm-config.yaml "${CURRENT_DIR}"/etcd-${i}/root/kubeadm-config.yaml
done
