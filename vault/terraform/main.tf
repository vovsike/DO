resource "vault_mount" "fia_kv2" {
  path    = "fia"
  type    = "kv-v2"
  options = { version = "2" }
}

resource "vault_mount" "fase_kv2" {
  path    = "fase"
  type    = "kv-v2"
  options = { version = "2" }
}

resource "vault_mount" "isis_observability_kv2" {
  path    = "isis_observability"
  type    = "kv-v2"
  options = { version = "2" }
}

resource "vault_mount" "isis_security_kv2" {
  path    = "isis_security"
  type    = "kv-v2"
  options = { version = "2" }
}

resource "vault_mount" "fia_db" {
  path = "fia_db"
  type = "database"
}

resource "vault_mount" "fase_db" {
  path = "fase_db"
  type = "database"
}

resource "vault_mount" "fia_pki" {
  path = "fia_pki"
  type = "pki"
}

resource "vault_mount" "isis_observability_pki" {
  path = "isis_observability_pki"
  type = "pki"
}