# Hetzner Cloud Configuration
variable "hcloud_ssh_key" {
  description = "Name of the SSH key in Hetzner Cloud"
  type        = string
}

# Server Configuration
variable "server_name" {
  description = "Name of the Keycloak server"
  type        = string
  default     = "keycloak-idp"
}

variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cpx11"
}

variable "server_image" {
  description = "Server image to use"
  type        = string
  default     = "ubuntu-24.04"
}

variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "nbg1"
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the Keycloak instance"
  type        = string
}

variable "keycloak_subdomain" {
  description = "Subdomain for Keycloak"
  type        = string
  default     = "auth"
}

# Keycloak Configuration
variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "keycloak_db_password" {
  description = "Keycloak database password"
  type        = string
  sensitive   = true
  default     = ""
}

# System Configuration
variable "admin_crypted_passwd" {
  description = "Crypted password for the admin user (use mkpasswd -m sha-512)"
  type        = string
  sensitive   = true
}

# Network Configuration
variable "enable_ipv6" {
  description = "Enable IPv6 for the server"
  type        = bool
  default     = false
}

# Keycloak Version
variable "keycloak_version" {
  description = "Keycloak Docker image version"
  type        = string
  default     = "24.0.3"
}

# Database Configuration
variable "use_external_db" {
  description = "Use external database instead of dev-mem"
  type        = bool
  default     = false
}

variable "db_vendor" {
  description = "Database vendor (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "keycloak"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "keycloak"
}

# Security Configuration
variable "security_hardening_script" {
  description = "Security hardening script content"
  type        = string
  default     = ""
}

# Network Configuration
variable "network_id" {
  description = "Hetzner Cloud network ID"
  type        = string
  default     = null
}

variable "private_ip" {
  description = "Private IP address for the server"
  type        = string
  default     = null
}

# WebFinger Configuration for OIDC Discovery
variable "enable_webfinger" {
  description = "Enable WebFinger endpoint for OIDC discovery (required for Tailscale SSO)"
  type        = bool
  default     = false
}

variable "webfinger_domain" {
  description = "Domain to serve WebFinger from (usually the main domain without subdomain)"
  type        = string
  default     = ""
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL for WebFinger response"
  type        = string
  default     = ""
}

variable "webfinger_email" {
  description = "Email address to use in WebFinger subject field"
  type        = string
  default     = ""
}

variable "ssl_email" {
  description = "Email address for SSL certificate registration (ZeroSSL/Let's Encrypt)"
  type        = string
  default     = ""
}
