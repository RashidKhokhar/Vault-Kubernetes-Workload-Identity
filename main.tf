terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = "root"
}

resource "vault_mount" "kv2" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "Production KV2 Secrets Storage Engine"
}

# -------------------------------------------------------------
# INFRASTRUCTURE POLICIES FOR ALL 3 PATHS (Zero plaintext secrets)
# -------------------------------------------------------------

# PATH 1: The Old Original Path
resource "vault_policy" "payment_policy" {
  name   = "team-payment-policy"
  policy = <<EOT
path "secret/data/teams/payment/*" {
  capabilities = ["read"]
}
EOT
}

# PATH 2: The Migrated Billing Path
resource "vault_policy" "new_billing_policy" {
  name   = "production-billing-policy"
  policy = <<EOT
path "secret/data/production/billing/*" {
  capabilities = ["read"]
}
EOT
}

# PATH 3: The New Shipping Path
resource "vault_policy" "shipping_policy" {
  name   = "production-shipping-policy"
  policy = <<EOT
path "secret/data/production/shipping/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "payments_policy" {
  name   = "production-payments-policy"
  policy = <<EOT
path "secret/data/production/payments/*" {
  capabilities = ["read"]
}
EOT
}


# -------------------------------------------------------------
# KUBERNETES AUTH CONNECTION BACKEND
# -------------------------------------------------------------
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend              = vault_auth_backend.kubernetes.path
  kubernetes_host      = "https://kubernetes.default.svc:443"
  disable_local_ca_jwt = false
}

# This role binds all 3 path permissions to your application service account
resource "vault_kubernetes_auth_backend_role" "payment_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "payment-app-role"
  bound_service_account_names      = ["payment-sa"]
  bound_service_account_namespaces = ["default"]
  token_policies = [
    vault_policy.payment_policy.name,
    vault_policy.new_billing_policy.name,
    vault_policy.shipping_policy.name,
    vault_policy.payments_policy.name
  ]
  token_ttl = 3600
}

# ====================================================================
# HIGH-SCALE AUTOMATION MODULES (For client multi-tenant scale)
# ====================================================================

module "onboard_analytics_app" {
  source               = "./modules/vault-app-onboarding"
  team_name            = "analytics"
  secret_path          = "production/analytics/metrics-token"
  service_account_name = "analytics-sa"
  k8s_namespace        = "default"

  depends_on = [vault_auth_backend.kubernetes]
}

module "onboard_marketing_app" {
  source               = "./modules/vault-app-onboarding"
  team_name            = "marketing"
  secret_path          = "production/marketing/api-key"
  service_account_name = "marketing-sa"
  k8s_namespace        = "default"

  depends_on = [vault_auth_backend.kubernetes]
}

