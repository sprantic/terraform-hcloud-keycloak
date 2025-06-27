# Server Information
output "server_id" {
  description = "ID of the Keycloak server"
  value       = hcloud_server.idp.id
}

output "server_name" {
  description = "Name of the Keycloak server"
  value       = hcloud_server.idp.name
}

output "server_ipv4_address" {
  description = "IPv4 address of the Keycloak server"
  value       = hcloud_server.idp.ipv4_address
}

output "server_ipv6_address" {
  description = "IPv6 address of the Keycloak server"
  value       = var.enable_ipv6 ? hcloud_server.idp.ipv6_address : null
}

# DNS Information
output "keycloak_fqdn" {
  description = "Fully qualified domain name for Keycloak"
  value       = "${var.keycloak_subdomain}.${var.domain_name}"
}

# Keycloak URLs
output "keycloak_url" {
  description = "Keycloak base URL"
  value       = "https://${var.keycloak_subdomain}.${var.domain_name}"
}

output "keycloak_admin_console" {
  description = "Keycloak admin console URL"
  value       = "https://${var.keycloak_subdomain}.${var.domain_name}/admin"
}

output "keycloak_auth_url" {
  description = "Keycloak authentication URL"
  value       = "https://${var.keycloak_subdomain}.${var.domain_name}/realms/master"
}

# Connection Information
output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh admin@${hcloud_server.idp.ipv4_address}"
}

# Service Status Commands
output "service_status_commands" {
  description = "Commands to check service status"
  value = {
    docker_status    = "ssh admin@${hcloud_server.idp.ipv4_address} 'docker ps'"
    keycloak_logs    = "ssh admin@${hcloud_server.idp.ipv4_address} 'docker logs keycloak-keycloak-1'"
    caddy_logs       = "ssh admin@${hcloud_server.idp.ipv4_address} 'docker logs keycloak-caddy-1'"
    service_health   = "curl -f https://${var.keycloak_subdomain}.${var.domain_name}/health"
  }
}

# WebFinger Configuration
output "webfinger_enabled" {
  description = "Whether WebFinger is enabled"
  value       = var.enable_webfinger
}

output "webfinger_url" {
  description = "WebFinger endpoint URL"
  value       = var.enable_webfinger && var.webfinger_domain != "" ? "https://${var.webfinger_domain}/.well-known/webfinger" : null
}

output "webfinger_domain" {
  description = "Domain serving WebFinger endpoint"
  value       = var.enable_webfinger ? var.webfinger_domain : null
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for WebFinger response"
  value       = var.enable_webfinger ? (var.oidc_issuer_url != "" ? var.oidc_issuer_url : "https://${var.keycloak_subdomain}.${var.domain_name}/realms/example") : null
}

# DNS Configuration Requirements
output "dns_records_required" {
  description = "DNS records that need to be configured"
  value = merge(
    {
      keycloak_a_record = {
        name  = "${var.keycloak_subdomain}.${var.domain_name}"
        type  = "A"
        value = hcloud_server.idp.ipv4_address
      }
    },
    var.enable_ipv6 ? {
      keycloak_aaaa_record = {
        name  = "${var.keycloak_subdomain}.${var.domain_name}"
        type  = "AAAA"
        value = hcloud_server.idp.ipv6_address
      }
    } : {},
    var.enable_webfinger && var.webfinger_domain != "" ? {
      webfinger_a_record = {
        name  = var.webfinger_domain
        type  = "A"
        value = hcloud_server.idp.ipv4_address
      }
    } : {},
    var.enable_webfinger && var.webfinger_domain != "" && var.enable_ipv6 ? {
      webfinger_aaaa_record = {
        name  = var.webfinger_domain
        type  = "AAAA"
        value = hcloud_server.idp.ipv6_address
      }
    } : {}
  )
}

# Validation Commands
output "webfinger_validation_command" {
  description = "Command to validate WebFinger configuration"
  value = var.enable_webfinger ? "bash ${path.module}/scripts/validate-webfinger.sh ${var.webfinger_domain} ${var.oidc_issuer_url != "" ? var.oidc_issuer_url : "https://${var.keycloak_subdomain}.${var.domain_name}/realms/example"}" : null
}

output "webfinger_validation_instructions" {
  description = "Instructions for validating WebFinger configuration"
  value = var.enable_webfinger ? {
    step_1 = "Wait for DNS propagation and SSL certificate generation (5-10 minutes)"
    step_2 = "Run the validation command from the webfinger_validation_command output"
    step_3 = "Ensure both issuer URLs match exactly before configuring Tailscale"
    note   = "The issuer URL in WebFinger must exactly match the issuer in /.well-known/openid-configuration"
  } : null
}