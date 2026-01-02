# Worker

## Join a node

See [Adding Linux worker nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/).

```bash
# On `control-plane-1`
kubeadm token create --print-join-command
<join-command-from-control-plane-1>

# On the worker node
<join-command-from-control-plane-1>
```
