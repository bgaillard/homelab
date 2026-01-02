#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

# The Incus project
project=k8s

# The Incus instance where to copy the CA files
instance=$1

# FIXME: In the long term we should probably manage backup of the TLS files using HashiCorp Vault.

# Wait for the instance to be fully started
sleep 40

# Copy the etcd CA certificate and API server etcd client certificate
#
# @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#set-up-the-etcd-cluster
incus file push --project "${project}" --create-dirs --uid 0 --gid 0 \
  "${CURRENT_DIR}/../etcd/etcd-1/etc/kubernetes/pki/etcd/ca.crt" \
  "homelab:${instance}/etc/kubernetes/pki/etcd/ca.crt"
incus file push --project "${project}" --create-dirs --uid 0 --gid 0 \
  "${CURRENT_DIR}/../etcd/etcd-1/etc/kubernetes/pki/apiserver-etcd-client.crt" \
  "homelab:${instance}/etc/kubernetes/pki/apiserver-etcd-client.crt"
incus file push --project "${project}" --create-dirs --uid 0 --gid 0 \
  "${CURRENT_DIR}/../etcd/etcd-1/etc/kubernetes/pki/apiserver-etcd-client.key" \
  "homelab:${instance}/etc/kubernetes/pki/apiserver-etcd-client.key"

# Update the CNI configuration to use the correct Pods CIDR
incus exec --project "${project}" "homelab:${instance}" -- bash -c "sed -i 's/10.42.0.0/10.42.${instance##*-}.0/g' /etc/cni/net.d/20-containerd-net.conflist"
incus exec --project "${project}" "homelab:${instance}" -- bash -c "systemctl restart containerd"
