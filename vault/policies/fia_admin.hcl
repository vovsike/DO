path "fia/*" {
    capabilities = ["create", "read", "update", "list", "patch", "delete"]
}

path "fia_pki/*" {
    capabilities = ["sudo"]
}

path "fia_db/*" {
    capabilities = ["sudo"]
}