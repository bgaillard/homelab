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


## Runners

For now only one runner has been configured on the Inspiron-3847 machine.

The registration has been manually done (i.e. manually executing commands on the machine) following the [Register with a runner authentication token](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token).

* Use of the _deprecated_ instance runner Registration Token (see [Register with a runner registration token](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-deprecated))
* Executor is `docker`
* Docker image is `python:latest`
* Tags `default`


!!! info "Local runner"

    It is possible to have a local runner on the machine of the user to have more power for CI/CD jobs. This is not yet implemented but it is on the roadmap.


## File `~/.gitconfig`

For now only the `root` user has been created, a PAT named `git` allows to use Git in HTTPs without asking for credentials every time.

The configuration of the `~/.gitconfig` file is like the following:

```ini
[url "https://root:xxxxxxxx@gitlab.homelab.internal"]
  insteadOf = https://gitlab.homelab.internal
```
