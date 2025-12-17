#!/bin/bash

CLUSTER="homelab"
CONTEXT="homelab"
USER="baptiste"

incus exec --project k8s --cwd /tmp homelab:control-plane-1 -- kubectl config set-cluster "${CLUSTER}" \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=https://10.0.0.40:6443 \
  --kubeconfig="${USER}.config"

# FIXME: Add '--user' and '--auth-method' options to choose the authentication method
# Authentication using client certs
#
#openssl genrsa -out baptiste.key 2048
#openssl req -new -key baptiste.key -out baptiste.csr -subj "/CN=baptiste/O=developers"
#openssl x509 -req -in baptiste.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out baptiste.crt -days 365
#incus exec --project k8s --cwd /tmp homelab:control-plane-1 -- kubectl config set-credentials "${USER}" \
#  --client-certificate=./baptiste.crt \
#  --client-key=./baptiste.key \
#  --embed-certs=true \
#  --kubeconfig="${USER}.config"

# Authentication using token
incus exec --project k8s --cwd /tmp homelab:control-plane-1 -- kubectl config set-credentials "${USER}" \
  --token=baptiste \
  --kubeconfig="${USER}.config"

incus exec --project k8s --cwd /tmp homelab:control-plane-1 -- kubectl config set-context "${CONTEXT}" \
  --cluster="${CLUSTER}" \
  --user="${USER}" \
  --kubeconfig="${USER}.config"

incus file pull --project k8s --recursive --create-dirs homelab:control-plane-1/tmp/baptiste.config /tmp/baptiste.config

KUBECONFIG=~/.kube/config:/tmp/${USER}.config kubectl config view --flatten > merged-config
mv merged-config ~/.kube/config
