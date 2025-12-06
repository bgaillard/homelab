#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

for i in 1 2 3; do
  echo "Renewing certificates on etcd-${i}..."

  # Rename the old local etcd directory
  mv "${CURRENT_DIR}"/etcd-${i} "${CURRENT_DIR}"/etcd-${i}.old
  mkdir -p "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  mkdir -p "${CURRENT_DIR}"/etcd-${i}/root
  
  # Copy the CA key to the node
  incus file push --project k8s --create-dirs "${CURRENT_DIR}"/etcd-${i}.old/etc/kubernetes/pki/etcd/ca.key homelab:etcd-${i}/etc/kubernetes/pki/etcd/ca.key 
  
  # Renew the certificates on the node
  incus exec --project k8s homelab:etcd-${i} -- kubeadm certs renew apiserver-etcd-client --config=/root/kubeadmcfg.yaml
  incus exec --project k8s homelab:etcd-${i} -- kubeadm certs renew etcd-healthcheck-client --config=/root/kubeadmcfg.yaml
  incus exec --project k8s homelab:etcd-${i} -- kubeadm certs renew etcd-peer --config=/root/kubeadmcfg.yaml
  incus exec --project k8s homelab:etcd-${i} -- kubeadm certs renew etcd-server --config=/root/kubeadmcfg.yaml

  # Pull the renewed certificates to backup them locally
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/apiserver-etcd-client.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/apiserver-etcd-client.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/healthcheck-client.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/healthcheck-client.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/peer.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/peer.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/server.crt "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd
  incus file pull --project k8s homelab:etcd-${i}/etc/kubernetes/pki/etcd/server.key "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd

  # Remove the CA key from the node for security reasons
  incus exec --project k8s homelab:etcd-${i} -- rm -f /etc/kubernetes/pki/etcd/ca.key

  # Backup the CA and kubeadmcfg.yaml files to the new local etcd directory
  cp "${CURRENT_DIR}"/etcd-${i}.old/etc/kubernetes/pki/etcd/ca.* "${CURRENT_DIR}"/etcd-${i}/etc/kubernetes/pki/etcd/
  cp "${CURRENT_DIR}"/etcd-${i}.old/root/kubeadmcfg.yaml "${CURRENT_DIR}"/etcd-${i}/root/kubeadmcfg.yaml
done

for i in 1 2 3; do
  echo "Applying renewed certificates on etcd-${i}..."

  # Remove the old etcd static pod manifest
  incus exec --project k8s homelab:etcd-${i} -- rm -f /etc/kubernetes/manifests/etcd.yaml

  # Wait 20 seconds to ensure the Kubelet has detected the removal of the static pod manifest
  sleep 20

  # Regenerate the etcd static pod
  incus exec --project k8s homelab:etcd-${i} -- kubeadm init phase etcd local --config=/root/kubeadmcfg.yaml
done
