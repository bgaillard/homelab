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

* [ ] General
    * [ ] Create graphical schema to explain the architecture
    * [ ] Setup a DNS name for the cluster API server
    * [ ] Write procedures to upgrade the cluster
* [ ] Monitoring
    * [ ] Setup kubernetes-dashboard
* [ ] Ingresses
    * [ ] Setup a sample NGINX Ingress Controller
    * [ ] Setup a sample Traefik Ingress Controller
    * [ ] Setup a sample HAProxy Ingress Controller
    * [ ] Setup a sample Pomerium Ingress Controller
    * [ ] Setup a sample Envoy Ingress Controller
    * [ ] Setup a sample Istio Ingress Gateway
    * [ ] Setup a sample Kong Ingress Controller
    * [ ] Setup a sample Gravitee Ingress Controller
    * [ ] Setup a sample Contour Ingress Controller
* [ ] Security
    * [ ] Setup Cert-Manager
    * [ ] Setup PSS
    * [ ] Setup OPA Gatekeeper
    * [ ] Setup Kyverno
    * [ ] See how to provide a sample based on Talos
* [ ] Etcd
    * [ ] Setup a sample for etcd without the Kubelet and without static pods
    * [ ] Setup a sample with etcd deployed in the same node as the Control plane nodes
* [ ] Setup a sample for each authentication mechanism
    * [ ] OpenID Connect
* [ ] Setup a sample for each well known CNI (see https://www.devopsschool.com/blog/list-of-cni-plugins-used-in-kubernetes/)
    * [ ] Flannel
    * [ ] Calico
    * [ ] Weave
    * [ ] Cilium
    * [ ] Kube-Router
    * [ ] Romana
    * [ ] Antrea
    * [ ] Multus 
