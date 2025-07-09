resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "vault_operator_clsuter" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://9a84c425-8593-4714-9fe5-72b0d28e74c1.k8s.ondigitalocean.com"
  kubernetes_ca_cert = file("../auth/k8s/certs/vault-opperator.crt")
}

resource "vault_kubernetes_auth_backend_role" "vault_operator_cluster" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault_operator_super_admin"
  bound_service_account_names      = ["vault-op"]
  bound_service_account_namespaces = ["vault-op"]
  token_ttl                        = 3600
  token_policies                   = ["default", "super_admin", "fia_admin"]
  audience                         = "vault"
}