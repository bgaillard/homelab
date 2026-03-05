# Vault

Key shares: 6
Key threshold: 3


## DNS

For now the `vault` DNS entry is manually configured on the [Pi-hole](pi-hole.md) DNS server to point to the IP address of `pi-4` where Vault is installed.


## TLS certificate

For now the TLS certificate used to expose the Vault UI and API is a self-signed certificate which has been manually generated.

### Generate

The generation has been done using the following OpenSSL command:

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
    -keyout vault-pi-4.key \
    -out vault-pi-4.crt \
    -extensions san -config \
  <(echo "[req]"; 
    echo distinguished_name=req; 
    echo "[san]"; 
    echo subjectAltName=DNS:vault
    ) \
    -subj "/CN=vault"
```

The certificate and it's private key are then stored in Bitwarden (note `pi-4`) for future reference and usage in Ansible.

### Update trust stores 

#### Update Linux local trust store

```bash
# Update
scp baptiste@pi-4:/usr/local/share/ca-certificates/vault.crt /tmp
sudo cp /tmp/gitlab.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Check
curl https://vault:8200
```

#### Import in Google Chrome

Go to `Settings -> Privacy and security -> Security -> Manage certificates` and then `Local certificates -> Custom -> Installed by you`.

Click on the `Import` button and import the `/usr/local/share/ca-certificates/vault.crt` certificate.

After import close Google Chrome and open it again. You should now be able to access `https://vault` without any certificate warning.


## Backups

!!! info "Section not documented"

    Document the Gitlab backup strategy and how to restore from backup in case of disaster recovery.

