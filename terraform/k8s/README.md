# k8s

* https://kubernetes.io/docs/reference/setup-tools/kubeadm/
* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
* https://kubernetes.io/docs/reference/networking/ports-and-protocols/
* https://github.com/kelseyhightower/kubernetes-the-hard-way

## SFR Box route table

We have the following IP addresses.

* `192.168.1.43` : Homelab server address
* `10.0.0.40` : Virtual IP address for k8s cluster, this address is part of an Incus network

The following route table entry has been added to the SFR Box route to forward traffic using the Homelab server as a gateway.

* Destination : `10.0.0.40`
* Subnet Mask : `255.255.255.255`
* Gateway : `192.168.1.43`

## TODO

* [ ] Manage authentication using OpenID Connect or something similar
