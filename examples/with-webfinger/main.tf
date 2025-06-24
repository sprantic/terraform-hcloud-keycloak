# Example: Keycloak with WebFinger for Tailscale SSO
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "keycloak" {
  source = "../../"
  
  # Required variables
  hcloud_ssh_key           = var.hcloud_ssh_key
  domain_name              = var.domain_name
  keycloak_admin_password  = var.keycloak_admin_password
  admin_crypted_passwd     = var.admin_crypted_passwd
  
  # Server configuration
  server_name             = "keycloak-tailscale"
  keycloak_subdomain      = "auth"
  
  # WebFinger configuration for Tailscale SSO
  enable_webfinger        = true
  webfinger_domain        = var.domain_name  # Main domain (e.g., "sprantic.ai")
  oidc_issuer_url         = "https://auth.${var.domain_name}/realms/sprantic"
  webfinger_email         = var.webfinger_email
  
  # Optional: External database
  use_external_db         = var.use_external_db
  db_host                 = var.db_host
  keycloak_db_password    = var.keycloak_db_password
}

# Outputs
output "keycloak_url" {
  description = "Keycloak URL"
  value       = module.keycloak.keycloak_url
}

output "keycloak_admin_console" {
  description = "Keycloak admin console URL"
  value       = module.keycloak.keycloak_admin_console
}

output "webfinger_url" {
  description = "WebFinger endpoint URL for Tailscale configuration"
  value       = module.keycloak.webfinger_url
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Tailscale configuration"
  value       = module.keycloak.oidc_issuer_url
}

output "dns_records_required" {
  description = "DNS records that need to be configured"
  value       = module.keycloak.dns_records_required
}

output "tailscale_configuration" {
  description = "Configuration values for Tailscale custom OIDC"
  value = {
    issuer_url    = module.keycloak.oidc_issuer_url
    webfinger_url = module.keycloak.webfinger_url
    instructions  = "Configure these URLs in Tailscale Admin Console → Settings → SSO → Custom OIDC"
  }
}

output "validation_command" {
  description = "Command to validate WebFinger configuration"
  value       = module.keycloak.webfinger_validation_command
}

output "validation_instructions" {
  description = "Instructions for validating WebFinger configuration"
  value       = module.keycloak.webfinger_validation_instructions
}