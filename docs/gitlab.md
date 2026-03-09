# Gitlab


## DNS & TLS

The Vault server is accessible at `https://vault.homelab.internal:8200`.

!!! info "DNS & TLS management"

    See [DNS & TLS](dns-and-tls.md) for more details on the TLS certificate management strategy.


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
