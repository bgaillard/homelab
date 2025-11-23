#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

# The Incus project
project=k8s

# The Incus instance where to copy the CA files
instance=$1

# FIXME: The key file should not be copied, we do it for now just "in case" but it's not good. I suppose the Kubernetes
#         official documentation indicates to keep it on the first etcd host as a backup but it's probably not a good
#         idea. The file should be kept offline in a very secure location instead.
#
#         In any ways we should probably manage this using HashiCorp Vault in the future.
#
ca_crt_path="/etc/kubernetes/pki/etcd/ca.crt"
ca_key_path="/etc/kubernetes/pki/etcd/ca.key"

# Wait for the instance to be fully started
sleep 30

incus file push --project "${project}" --create-dirs "${CURRENT_DIR}${ca_crt_path}" "homelab:${instance}${ca_crt_path}"
incus file push --project "${project}" --create-dirs "${CURRENT_DIR}${ca_key_path}" "homelab:${instance}${ca_key_path}"
