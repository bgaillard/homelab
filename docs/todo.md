# Todo

This page is organized through sections of the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html).


## Security

### SEC 2: How do you manage authentication for people and machines?

* [ ] Stop using the Hashicorp Vault root token and revoke it

### SEC 9: How do you protect you data in transit?

* [ ] Stop using a manually generated self-signed certificate for `*.homelab.internal`, use a private PKI using HashiCorp Vault instead.

### SEC 6: How do you protect your compute resources?

* [ ] Extend the Hardening of all the servers.


## Reliability

### Failure Management

#### REL 9: How do you back up your data?

* :orange_circle: Improve the Gitlab backup script to also backup the configuration files
* [ ] Write a backup page referencing all backups
* [ ] Find a way to have an S3-compatible backend for Terraform (for example garage), or use an other non-local backend (for example Gitlab, but it's not great because it prevent execution of Terraform with a Gitlab downtime)
* [ ] See how to not stop the HashiCorp Vault server while performing backups with Vault OSS (probably requires the PostgreSQL storage backend)
* [ ] Restore
    * [ ] Implement, test and document the restore for Pi-Hole
    * [ ] Implement, test and document the restore for HashiCorp Vault
    * [ ] Implement, test and document the restore for Gitlab
    * [ ] Implement, test and document the restore for Harbor

## Others

* [ ] Check the Harbor install with `*.asc` files
* [ ] Improve the Harbor install with Ansible to prevent downtime when re-applying the Playbook
