# Control plane

After first start execute the following command on the `control-plane-1` node (see [Set up the first control plane node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#set-up-the-first-control-plane-node).

This command creates a Kubernetes secret named `kubeadm-certs` in the `kube-system` namespace that contains the certificates of the primary control plane node.

```bash
kubeadm init --config /tmp/control-plane-1/kubeadmcfg.yaml --upload-certs
```

To re-upload the certificates and generate a new decryption key, use the following command on a control plane node that is already joined to the cluster.

```bash
kubeadm init phase upload-certs --upload-certs
```

You can also specify a custom --certificate-key during init that can later be used by join. To generate such a key you can use the following command.

```bash
kubeadm certs certificate-key
```
