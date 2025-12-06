#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

# The Incus project
project=k8s

# The Incus instance where to copy the CA files
instance=$1

# FIXME: In the long term we should probably manage backup of the TLS files using HashiCorp Vault.

# Wait for the instance to be fully started
sleep 40

# shellcheck disable=SC2044
for f in $(find "${CURRENT_DIR}/${instance}" -type f); do  
  relative_path=${f#"${CURRENT_DIR}/${instance}"/}

  # The Certificate Authority private key should not be copied and kept secure
  if [[ "${relative_path}" != *ca.key ]]; then
    incus file push --project "${project}" --create-dirs --uid 0 --gid 0 "${f}" "homelab:${instance}/${relative_path}"
  fi
done
