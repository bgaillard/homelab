resource "vault_mount" "example" {
  path        = "kv"
  type        = "kv-v2"
  description = "KV V2 secret engine"
}
