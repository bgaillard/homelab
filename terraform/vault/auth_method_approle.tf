resource "vault_auth_backend" "approle" {
  type = "approle"

  tune {
    default_lease_ttl = "1h"
    max_lease_ttl     = "4h"
    token_type        = "batch"
  }
}
