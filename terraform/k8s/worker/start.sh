#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "$0")")

# The Incus project
project=k8s

# The Incus instance where to copy the CA files
instance=$1

# Wait for the instance to be fully started
sleep 40

# FIXME: Using sed here is definitely not great, it would probably be better to use some kind of templating tool 
#        instead and execute it using Cloud-Init on first boot.

# Update the CNI configuration to use the correct Pods CIDR
incus exec --project "${project}" "homelab:${instance}" -- bash -c "sed -i 's/10.42.0.0/10.42.10${instance##*-}.0/g' /etc/cni/net.d/20-containerd-net.conflist"

# Update the routing configuration
incus exec --project "${project}" "homelab:${instance}" -- rm "/etc/systemd/network/enp5s0.network.d/${instance}.conf"
incus exec --project "${project}" "homelab:${instance}" -- systemctl daemon-reload
incus exec --project "${project}" "homelab:${instance}" -- systemctl restart systemd-networkd
