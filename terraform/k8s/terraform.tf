# FIXME: We should store the Terraform state remotely using a low cost backend like MinIO or similar.
#
#        Before being able to do that, we need to setup a private PKI infrastructure to issue TLS certificates. It could
#        be done using Hashicorp Vault for example.
#
#        This KPI could also be used to issue TLS certificates to Incus and allow secure Incus client connections.
#
#         Once MinIO is setup we should backup it using something like Restic or Rclone to Infomaniak Swiss Backup for
#         example.
#
# @see https://www.digitalocean.com/community/tutorials/how-to-set-up-minio-object-storage-server-in-standalone-mode-on-ubuntu-20-04
terraform {
  required_version = ">= 1.13"

  required_providers {
    # @see https://registry.terraform.io/providers/lxc/incus/latest/docs
    incus = {
      source  = "lxc/incus"
      version = "1.0.0"
    }
  }
}
