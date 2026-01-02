# etcd

The purpose of this setup is to create an external etcd cluster made of 3 nodes. The final goal is to create a Kubernetes cluster with an [External etcd topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology).

The setup mainly follows the steps described in [Set up a High Availability etcd Cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/).

## Design

The setup is for my personal Home Lab, it's designed with the following principles in mind:

* Nodes based on Incus VMs and created with Terraform
* Etcd cluster made of 3 nodes having chosen properties:
  * Hostnames are `etcd-1`, `etcd-2` and `etcd-3`
  * IP addresses are `10.0.0.11`, `10.0.0.12` and `10.0.0.13`
* Etcd Incus VM image built with Packer
* Etcd cluster TLS certificates based on it's own Certificate Authority (CA)


## Initialize

### Principle

The initialization process is used to create the following assets for the etcd nodes named `etcd-1`, `etcd-2` and `etcd-3`:

- A Certificate Authority (CA) certificate used to sign all the TLS certificates.
- All the required TLS certificates for the etcd servers signed by the CA certificate.
- The kubeadm configuration file.

After the initialization process all those assets are pulled locally and backuped in the folders `etcd-1`, `etcd-2` and `etcd-3`.

The backup is then used to be able to recreate the etcd nodes by uploading all the assets to each node at startup.

### Usage

The initialization process should be done only one time at the very beginning of the etcd cluster creation.

First ensure there are no `etcd-1`, `etcd-2` and `etcd-3` folders.

Then start the `etcd-1`, `etcd-2` and `etcd-3` servers with Terraform, wait for them to be up and just execute the `init.sh` locally.


## Start

### Start etcd

The start of the etcd process on each node is done by executing the `start.sh` script.

The script creates a static pod `/etc/kubernetes/manifests/etcd.yaml` manifest file and the restarts the Kubelet to quickly start this pod.

### Check cluster health

:bulb: In the future we'll also setup a monitoring solution to check the etcd cluster health automatically (Prometheus + Grafana + Alertmanager).

Just execute the following command on any etcd node.

```bash
# List the cluster members
etcdctl --write-out=table member list

# Check the status of each endpoint in the cluster
etcdctl --write-out=table endpoint status --cluster
```


## Renew TLS certificates

See [Certificate expiry and management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#check-certificate-expiration).

```bash
# Check expiration
kubeadm certs check-expiration

# Check expiration of the CA with openssl (by default valid for 10 years)
openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -text

# Renew all certificates
./renew-ca.sh
```


## Replace a failed etcd node



## Backup



## TODO

* [ ] Understand an adapt the CNI plugin configuration
* [ ] Manage backups of the etcd data regularly
* [ ] Configure monitoring of the etcd cluster (Prometheus + Grafana + Alertmanager)
* [ ] Pass the Kubernetes Conformance tests (see [Introducing Software Certification for Kubernetes](https://kubernetes.io/blog/2017/10/software-conformance-certification/))
* [ ] Setup a firewall on nodes to only allow necessary ports. See how to harden node in general
* [ ] See if it's possible to use Hashicorp Vault to generate the TLS certificates and the CA
* [ ] Document why we use Incus VMs instead of containers and why containers cannot be used for now. See [Running Kubernetes inside Unprivileged Containers](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/#running-kubernetes-inside-unprivileged-containers), [Cluster-api and kubernetes](https://discuss.linuxcontainers.org/t/cluster-api-and-kubernetes/23084), [Configure k3s in Incus with zfs.delegate](https://discuss.linuxcontainers.org/t/configure-k3s-in-incus-with-zfs-delegate/19765)
* [ ] Setup a CI/CD for the Packer image building
* [ ] See if it's possible to update continuously apt packages, containerd and etcd versions with tools like Renovate for example
* [ ] Improve the certificates renewal to propate the etcd client certificates to control plane nodes automatically
* [ ] Improve the certificates renewal process to avoid downtime
* [ ] Simplify the transmission of the Kubernetes version
* [ ] Version the images with a version of Kubernetes and our own version (i.e. `1.32-1.0.0` for example)
* [ ] Read https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
* [ ] Install an internal Docker image registry with a cache to speedup image pulls. This one could also be used for Python, Debian packages, etc.
