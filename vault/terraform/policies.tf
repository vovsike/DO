resource "vault_policy" "isis_admin" {
    name = "isis_admin"
    policy = file("../policies/isis_admin.hcl")
}

resource "vault_policy" "super_admin" {
    name = "super_admin"
    policy = file("../policies/super_admin.hcl")
}

resource "vault_policy" "fia_admin" {
  name = "fia_admin"
  policy = file("../policies/fia_admin.hcl")
}


resource "vault_policy" "fase_admin" {
  name = "fase_admin"
  policy = file("../policies/fase_admin.hcl")
}