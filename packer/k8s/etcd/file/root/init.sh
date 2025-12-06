#!/bin/bash

# Update HOST0, HOST1 and HOST2 with the IPs of your hosts
export HOST0=10.0.0.11
export HOST1=10.0.0.12
export HOST2=10.0.0.13

# Update NAME0, NAME1 and NAME2 with the hostnames of your hosts
export NAME0="etcd-1"
export NAME1="etcd-2"
export NAME2="etcd-3"

HOSTS=("${HOST0}" "${HOST1}" "${HOST2}")
NAMES=("${NAME0}" "${NAME1}" "${NAME2}")

HOST=
NAME=$(hostname)

if [[ "${NAME}" -eq "${NAME0}" ]]; then
    HOST=${HOST0}
elif [[ "${NAME}" -eq "${NAME1}" ]]; then
    HOST=${HOST1}
elif [[ "${NAME}" -eq "${NAME2}" ]]; then
    HOST=${HOST2}
else
    echo "Hostname not recognized. Exiting."
    exit 1
fi

cat << EOF > /root/kubeadmcfg.yaml
---
apiVersion: "kubeadm.k8s.io/v1beta4"
kind: InitConfiguration
nodeRegistration:
    name: ${NAME}
localAPIEndpoint:
    advertiseAddress: ${HOST}
---
apiVersion: "kubeadm.k8s.io/v1beta4"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
        - name: heartbeat-interval
          value: "500"
        - name: election-timeout
          value: "10000"
        - name: initial-cluster
          value: ${NAMES[0]}=https://${HOSTS[0]}:2380,${NAMES[1]}=https://${HOSTS[1]}:2380,${NAMES[2]}=https://${HOSTS[2]}:2380
        - name: initial-cluster-state
          value: new
        - name: name
          value: ${NAME}
        - name: listen-peer-urls
          value: https://${HOST}:2380
        - name: listen-client-urls
          value: https://${HOST}:2379
        - name: advertise-client-urls
          value: https://${HOST}:2379
        - name: initial-advertise-peer-urls
          value: https://${HOST}:2380
EOF

kubeadm init phase certs etcd-server --config=/root/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/root/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/root/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/root/kubeadmcfg.yaml
