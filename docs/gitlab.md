# Gitlab


## DNS

For now the `gitlab` DNS entry is manually configured on the [Pi-hole](pi-hole.md) DNS server to point to the IP address of `pi-4` where Gitlab is installed.


## TLS certificate

For now the TLS certificate used to expose the Gitlab CE UI is a self-signed certificate which has been manually generated.

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
    -keyout gitlab-ce-pi-4.key \
    -out gitlab-ce-pi-4.crt \
    -extensions san -config \
  <(echo "[req]"; 
    echo distinguished_name=req; 
    echo "[san]"; 
    echo subjectAltName=DNS:gitlab
    ) \
    -subj "/CN=gitlab"
```

The certificate and it's private key are then stored in Bitwarden (note `pi-4`) for future reference and usage in Ansible.

### Update trust stores 

#### Update Linux local trust store

```bash
# Update
scp baptiste@pi-4:/usr/local/share/ca-certificates/gitlab.crt /tmp
sudo cp /tmp/gitlab.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Check
curl https://gitlab
```

#### Import in Google Chrome

Go to `Settings -> Privacy and security -> Security -> Manage certificates` and then `Local certificates -> Custom -> Installed by you`.

Click on the `Import` button and import the `/usr/local/share/ca-certificates/gitlab.crt` certificate.

After import close Google Chrome and open it again. You should now be able to access `https://gitlab` without any certificate warning.


## Monitoring

Because Gitlab is installed on a Raspberry Pi 4 it cannot take too much resources (see [Running on a Raspberry Pi](https://docs.gitlab.com/omnibus/settings/rpi/). 

For this reason the following properties are set in the Gitlab configuration file (`/etc/gitlab/gitlab.rb`):

* `node_exporter['enable'] = false`
* `alertmanager['enable'] = false`
* `prometheus['enable'] = false`


## Backups

!!! info "Section not documented"

    Document the Gitlab backup strategy and how to restore from backup in case of disaster recovery.

```bash
# @see https://docs.gitlab.com/administration/backup_restore/backup_gitlab/?tab=Linux+package+%28Omnibus%29
COMPRESS_CMD="gzip -c --best" sudo gitlab-backup create

# @see https://docs.gitlab.com/administration/backup_restore/backup_gitlab/?tab=Linux+package+%28Omnibus%29#upload-to-locally-mounted-shares
```
