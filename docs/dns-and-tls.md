# DNS & TLS


## DNS

### Pi-hole

For now all DNS records are manually configured in the [Pi-hole](pi-hole.md) DNS server.

!!! info IaC

    The manuel changes in the DNS records of the [Pi-hole](pi-hole.md) DNS server are picked each night by an utility script called the [Iac Updater](iac-updated.md)). This script pushes the new configuration to the Hashicorp Vault server (see [Vault](vault.md)) for backup.

    In the future this mechanism will be improved through Terraform and the [Pi-hole Provider](https://registry.terraform.io/providers/ryanwholey/pihole/latest/docs) and perhaps a little later using a true dedicated BIND DNS server (see [BIND](https://www.isc.org/bind/)) updated with the Terraform [DNS Provider](https://registry.terraform.io/providers/hashicorp/dns/latest/docs).

    See also [23 Best Free and Open Source DNS Servers](https://www.linuxlinks.com/best-free-open-source-dns-servers/).

### Domains

The top-level domain (TLD) of the internal private network is `.internal` (see also [`.internal`](https://en.wikipedia.org/wiki/.internal)).

Servers of the Homelab are then placed in the `.homelab.internal` sub-domain.

### Hostnames

The [Pi-hole](pi-hole.md) DNS server is mainly used by user devices (laptops, smartphones, tablets, etc.) on the network.

The configuration is done using the DHCP server installed with the Pi-hole server itself (i.e. the DHCP server of the ISP router is disabled).

For now for the DNS resolutions to work from the homelab servers we update the `/etc/hosts` file of each server (so the Pi-hole is currently not used by servers).

For example, the following entry is added to the `/etc/hosts` file of the `pi-4` server:

```bash
127.0.0.1 pi-4.homelab.internal pi-4 gitlab.homelab.internal vault.homelab.internal
```

All machines can be joined using 2 conventions:

* The `{hostname}.homelab.internal` FQDN (e.g. `pi-4.homelab.internal` for the `pi-4` machine).
* `{hostname}` (e.g. `pi-4` for the `pi-4` machine).

Then, if several applications are deployed on the machine additional aliases are added to the `/etc/hosts` file of the machine.

For example the `pi-4` machine deploys `gitlab` and `vault` accessible using 2 different FQDNs and both usable with a wildcard `*.homelab.internal` TLS certificate.

* Gitlab is exposed using `gitlab.homelab.internal`
* Vault is exposed using `vault.homelab.internal`.


## TLS

A unique self-signed TLS certificate for the `*.homelab.internal` wildcard domain has been generated with the following command:

```bash
# Create the self-signed TLS certificate
#
# For SAN and Google Chrome see the below link.
#
# @see https://stackoverflow.com/questions/10175812/how-can-i-generate-a-self-signed-ssl-certificate-using-openssl/41366949#41366949
openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -keyout homelab.internal.key \
    -out homelab.internal.crt \
    -extensions san -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[san]";
    echo subjectAltName=DNS:*.homelab.internal
    ) \
    -subj "/CN=*.homelab.internal"
```

The certificate and it's private key are then stored in Bitwarden (note `pi-4`) for future reference and usage in Ansible.


!!! warning Certificate expiration

    This unique self-signed TLS certificate is valid for 365 days only.

    As it is manually generated there is a risk of forgetting to renew it before the expiration date.

    In the long term we'll deploy a private PKI with Hashicorp Vault (see [Vault](vault.md)) to automate the generation and renewal of TLS certificates for the homelab.
