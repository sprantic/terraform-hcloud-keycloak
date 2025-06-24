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
  description = "Domain name for the Keycloak instance (e.g., 'sprantic.ai')"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "admin_crypted_passwd" {
  description = "Crypted password for the admin user (generate with: mkpasswd -m sha-512)"
  type        = string
  sensitive   = true
}

# Optional database configuration
variable "use_external_db" {
  description = "Use external database instead of dev-mem"
  type        = bool
  default     = false
}

variable "db_host" {
  description = "Database host (if using external database)"
  type        = string
  default     = ""
}

variable "keycloak_db_password" {
  description = "Keycloak database password (if using external database)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "webfinger_email" {
  description = "Email address to use in WebFinger subject field"
  type        = string
  default     = ""
}