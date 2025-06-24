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
  server_name = "keycloak-prod"
  server_type = "cpx21"  # Larger server for production
  location    = "nbg1"

  # Domain Configuration
  domain_name         = var.domain_name
  keycloak_subdomain  = var.keycloak_subdomain

  # Keycloak Configuration
  keycloak_admin_user     = var.keycloak_admin_user
  keycloak_admin_password = var.keycloak_admin_password
  keycloak_version        = "24.0.3"

  # System Configuration
  admin_crypted_passwd = var.admin_crypted_passwd

  # External Database Configuration
  use_external_db      = true
  db_vendor           = "postgres"
  db_host             = var.db_host
  db_port             = var.db_port
  db_name             = var.db_name
  db_user             = var.db_user
  keycloak_db_password = var.keycloak_db_password

  # Enable IPv6
  enable_ipv6 = true
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

output "server_ipv4" {
  description = "Server IPv4 address"
  value       = module.keycloak.server_ipv4_address
}

output "server_ipv6" {
  description = "Server IPv6 address"
  value       = module.keycloak.server_ipv6_address
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = module.keycloak.ssh_connection
}

output "service_commands" {
  description = "Service management commands"
  value       = module.keycloak.service_status_commands
}