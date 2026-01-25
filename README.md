# Home lab


## Ansible

```bash
# Install required Python packages
python -m pip install --user ansible
python -m pip install --user hvac

# If Ansible is already installed but python has been updated, you may need to reinstall Ansible
python -m pip install --user --upgrade ansible

# Install required Ansible collections
ansible-galaxy collection install community.general
```


## SSH configuration

The Ansible playbook suppose the Home lab is accessible using the `homelab` host name / domain name.

If this is not the case just add an alias to your SSH configuration file (`~/.ssh/config`):

```ssh
Host homelab
    HostName <YOUR_HOME_LAB_SERVER_IP_OR_HOSTNAME>
    User <USERNAME>
```

This allows to not reveal the IP address or hostname of your home lab if you commit your configuration to a public Git repository.


## Backups

Backups are managed with [Restic](https://restic.net/). 

### Shortcuts

Several shortcut commands are available for each type of backup:

* `restic-k8s-etcd` : Backup of the Kubernetes etcd database

### Cron jobs

The shortcut commands are scheduled to run automatically using cron jobs each day at midnight.

### Strategy

Backups are done following the 3-2-1-0 rule:

* 3 copies of the data
  * 1 original copy
  * 1 additional copy locally
  * 1 additional offsite copy
* 2 different media types
  * Local disk
  * [Openstack Swift](https://docs.openstack.org/swift/latest/)
* 1 offsite copy on [Swiss Backup](https://www.infomaniak.com/swiss-backup)
* 0 errors during backup
