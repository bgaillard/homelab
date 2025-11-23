From the `etcd-1` machine execute the following command. 

```bash
kubeadm init phase certs etcd-ca
```

The execute the following locally to retrieve the CA certificaes.

```bash
incus file pull --project k8s homelab:etcd-1/etc/kubernetes/pki/etcd/ca.crt terraform/k8s/etcd/etc/kubernetes/pki/etcd
incus file pull --project k8s homelab:etcd-1/etc/kubernetes/pki/etcd/ca.key terraform/k8s/etcd/etc/kubernetes/pki/etcd
```
