# Control plane

## Initialization

After the very first start on the Control Plane nodes (i.e. `control-plane-1`, `control-plane-2`, `control-plane-3`), you need to initialize the cluster on the first control plane node (see [Set up the first control plane node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#set-up-the-first-control-plane-node).

To do it just execute the `init.sh` script on the `control-plane-1` node.

```bash
./init.sh
```

## Create `~/.kube/config` file for users

Execute the `generate-kube-config.sh` script.


## Replace a Control Plane Node

Here is a sample to replace the Control plane node `control-plane-3`.

On the `control-plane-1` node, execute the following commands:

```bash
# Drain and delete the old control plane node
k drain control-plane-3 --ignore-daemonsets
k delete node control-plane-3

# Upload Control Plane certificates to the 'kubeadm-certs' secret
#
# @see https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init-phase/#cmd-phase-upload-certs
kubeadm init phase upload-certs --config=/root/kubeadm-config.yaml --upload-certs
kubeadm token create --print-join-command --certificate-key <certificate-key>
```

On the `control-plane-3` node, execute the join command generated above.

```bash
# Join the control plane node
kubeadm join 10.0.0.40:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --control-plane --certificate-key <certificate-key>

# Configure kubectl
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown 0:0 /root/.kube/config
bash -c "echo 'alias k=kubectl' >> /root/.bashrc"
. .bashrc

# Check the node status
k get nodes
```


## TODO

* [ ] https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
