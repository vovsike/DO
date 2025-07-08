resource "vault_policy" "team1_dev_policy" {
    name = "team1_dev"
    policy = file("../policies/team1.hcl")
}