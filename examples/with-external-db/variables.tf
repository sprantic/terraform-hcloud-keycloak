variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "hcloud_ssh_key" {
  description = "Name of the SSH key in Hetzner Cloud"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Keycloak instance"
  type        = string
}

variable "keycloak_subdomain" {
  description = "Subdomain for Keycloak"
  type        = string
  default     = "auth"
}

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

variable "admin_crypted_passwd" {
  description = "Crypted password for the admin user (use mkpasswd -m sha-512)"
  type        = string
  sensitive   = true
}

# Database Configuration
variable "db_host" {
  description = "Database host"
  type        = string
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

variable "keycloak_db_password" {
  description = "Keycloak database password"
  type        = string
  sensitive   = true
}