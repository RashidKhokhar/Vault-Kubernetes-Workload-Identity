# This template loops automatically based on module block declarations
resource "vault_policy" "dynamic_policy" {
  name   = "app-${var.team_name}-policy"
  policy = <<EOT
path "secret/data/${var.secret_path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "dynamic_role" {
  backend                          = "kubernetes"
  role_name                        = "${var.team_name}-app-role"
  bound_service_account_names      = [var.service_account_name]
  bound_service_account_namespaces = [var.k8s_namespace]
  token_policies                   = [vault_policy.dynamic_policy.name]
  token_ttl                        = 3600
}

