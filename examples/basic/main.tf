terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.4"
    }
  }
}

# Configure providers
provider "hcloud" {
  token = var.hcloud_token
}

provider "keycloak" {
  client_id     = "admin-cli"
  client_secret = ""
  url           = "https://${var.keycloak_subdomain}.${var.domain_name}"
  username      = var.keycloak_admin_user
  password      = var.keycloak_admin_password
  tls_insecure  = true
}

module "keycloak" {
  source = "../../"

  # Hetzner Cloud Configuration
  hcloud_ssh_key = var.hcloud_ssh_key

  # Server Configuration
  server_name = "my-keycloak"
  server_type = "cpx11"
  location    = "nbg1"

  # Domain Configuration
  domain_name         = var.domain_name
  keycloak_subdomain  = var.keycloak_subdomain

  # Keycloak Configuration
  keycloak_admin_user     = var.keycloak_admin_user
  keycloak_admin_password = var.keycloak_admin_password

  # System Configuration
  admin_crypted_passwd = var.admin_crypted_passwd

  # Optional: Enable IPv6
  enable_ipv6 = false
}

# Output important information
output "keycloak_url" {
  description = "Keycloak URL"
  value       = module.keycloak.keycloak_url
}

output "keycloak_admin_console" {
  description = "Keycloak admin console URL"
  value       = module.keycloak.keycloak_admin_console
}

output "server_ip" {
  description = "Server IP address"
  value       = module.keycloak.server_ipv4_address
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = module.keycloak.ssh_connection
}