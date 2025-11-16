# Home lab

## SSH configuration

The Ansible playbook suppose the Home lab is accessible using the `homelab` host name / domain name.

If this is not the case just add an alias to your SSH configuration file (`~/.ssh/config`):

```ssh
Host homelab
    HostName <YOUR_HOME_LAB_SERVER_IP_OR_HOSTNAME>
    User <USERNAME>
```

This allows to not reveal the IP address or hostname of your home lab if you commit your configuration to a public Git repository.
