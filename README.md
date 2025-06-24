# Terraform Hetzner Cloud Keycloak Module

This Terraform module deploys a production-ready Keycloak identity provider on Hetzner Cloud with automatic SSL certificates via Caddy reverse proxy.

## Features

- 🔐 **Keycloak Identity Provider**: Latest Keycloak version with configurable settings
- 🌐 **Automatic SSL**: Caddy reverse proxy with automatic Let's Encrypt certificates
- 🏗️ **Infrastructure as Code**: Complete Hetzner Cloud infrastructure provisioning
- 📡 **DNS Management**: Reverse DNS (PTR) record configuration
- 🐳 **Containerized**: Docker Compose setup for easy management
- 🔧 **Configurable**: Support for external databases and custom configurations
- 📊 **Health Checks**: Built-in health monitoring for services

## Architecture

```
Internet → Caddy (SSL Termination) → Keycloak → Database
                ↓
        Hetzner Cloud Server
        (with reverse DNS)
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Hetzner Cloud Account](https://console.hetzner.cloud/)
- Domain name with external DNS management (Cloudflare, Route53, etc.)
- SSH key uploaded to Hetzner Cloud

## Quick Start

1. **Configure Provider and Module**
   ```hcl
   # main.tf
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

   # Use the module
   module "keycloak" {
     source = "path/to/terraform-hcloud-keycloak"
     
     # Required variables
     hcloud_ssh_key           = var.hcloud_ssh_key
     domain_name              = var.domain_name
     keycloak_admin_password  = var.keycloak_admin_password
     admin_crypted_passwd     = var.admin_crypted_passwd
     
     # Optional variables
     server_name             = "my-keycloak"
     keycloak_subdomain      = "auth"
     # ... other variables as needed
   }
   ```

2. **Create Variables File**
   ```hcl
   # variables.tf
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
     description = "Crypted password for the admin user"
     type        = string
     sensitive   = true
   }
   ```

3. **Configure Values**
   ```hcl
   # terraform.tfvars
   hcloud_token            = "your-hetzner-api-token"
   hcloud_ssh_key          = "your-ssh-key-name"
   domain_name             = "example.com"
   keycloak_admin_user     = "admin"
   keycloak_admin_password = "secure-password"
   admin_crypted_passwd    = "$6$..." # Generate with: mkpasswd -m sha-512
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Configure DNS**
   
   ***After deployment, you'll need to manually create DNS records:***
   ```
   A    auth.yourdomain.com    <server-ip-from-output>
   AAAA auth.yourdomain.com    <server-ipv6-from-output>  # if IPv6 enabled
   ```

6. **Access Keycloak**
   - URL: `https://auth.yourdomain.com` (or your configured subdomain)
   - Admin Console: `https://auth.yourdomain.com/admin`
   - Username: `admin` (or your configured admin user)
   - Password: Your configured admin password

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `hcloud_ssh_key` | SSH key name in Hetzner Cloud | `"my-ssh-key"` |
| `domain_name` | Your domain name | `"example.com"` |
| `keycloak_admin_password` | Keycloak admin password | `"secure-password"` |
| `admin_crypted_passwd` | Crypted system password | `"$6$..."` |

**Note**: Provider configuration variables like `hcloud_token` are now configured at the caller level, not as module variables.

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `server_name` | Server name | `"keycloak-idp"` |
| `server_type` | Hetzner server type | `"cpx11"` |
| `location` | Hetzner location | `"nbg1"` |
| `keycloak_subdomain` | Keycloak subdomain | `"auth"` |
| `keycloak_version` | Keycloak Docker version | `"24"` |
| `enable_ipv6` | Enable IPv6 support | `false` |
| `use_external_db` | Use external database | `false` |
| `enable_webfinger` | Enable WebFinger for OIDC discovery | `false` |
| `webfinger_domain` | Domain to serve WebFinger from | `""` |
| `oidc_issuer_url` | Custom OIDC issuer URL | `""` |
| `webfinger_email` | Email address for WebFinger subject | `""` |

### External Database Configuration

For production deployments, configure an external PostgreSQL database:

```hcl
use_external_db = true
db_vendor = "postgres"
db_host = "your-db-host.com"
db_port = "5432"
db_name = "keycloak"
db_user = "keycloak"
keycloak_db_password = "your-db-password"
```

### WebFinger Configuration for OIDC Discovery

For Tailscale SSO integration, you need to enable WebFinger to provide OIDC discovery:

```hcl
# Enable WebFinger for Tailscale SSO
enable_webfinger = true
webfinger_domain = "sprantic.ai"  # Your main domain (without subdomain)
oidc_issuer_url = "https://auth.sprantic.ai/realms/sprantic"  # Your Keycloak realm URL
webfinger_email = "admin@sprantic.ai"  # Email address for WebFinger subject
```

This configuration:
- Creates a WebFinger endpoint at `https://sprantic.ai/.well-known/webfinger`
- Serves the OIDC issuer URL for domain discovery
- Required for Tailscale custom OIDC provider setup

**Important**:
- The WebFinger endpoint must be served from your main domain (e.g., `sprantic.ai`), not the Keycloak subdomain (`auth.sprantic.ai`).
- The `oidc_issuer_url` must exactly match the `issuer` field in your Keycloak's `/.well-known/openid-configuration` endpoint.
- Use the provided validation script to verify the configuration before configuring Tailscale.

**Validation**:
After deployment, validate your configuration:
```bash
# Get validation command from Terraform output
terraform output webfinger_validation_command

# Run validation to ensure issuer URLs match
bash path/to/validate-webfinger.sh your-domain.com https://auth.your-domain.com/realms/your-realm
```

## Server Management

### SSH Access
```bash
ssh admin@<server-ip>
```

### Service Management
```bash
# Check running containers
docker ps

# View Keycloak logs
docker logs keycloak-keycloak-1

# View Caddy logs
docker logs keycloak-caddy-1

# Restart services
cd /opt/keycloak
docker compose restart
```

### Health Checks
```bash
# Check Keycloak health
curl -f https://auth.yourdomain.com/health

# Check service status
curl -f https://auth.yourdomain.com/health/ready
```

## Outputs

After deployment, Terraform provides useful outputs:

- `keycloak_url`: Main Keycloak URL
- `keycloak_admin_console`: Admin console URL
- `server_ipv4_address`: Server IP address
- `ssh_connection`: SSH connection command
- `service_status_commands`: Service management commands

## Security Considerations

- 🔐 **Strong Passwords**: Use strong, unique passwords for all accounts
- 🔑 **SSH Keys**: Use SSH key authentication, disable password auth
- 🌐 **Firewall**: Configure appropriate firewall rules
- 📊 **Monitoring**: Set up monitoring and alerting
- 🔄 **Updates**: Regularly update Keycloak and system packages
- 💾 **Backups**: Implement regular database backups

## DNS Configuration

Since Hetzner Cloud doesn't provide DNS hosting services through their API, you'll need to configure DNS records manually with your DNS provider (Cloudflare, Route53, etc.):

### Required DNS Records

**For Keycloak only:**
```
# A record pointing to your server's IPv4 address
auth.yourdomain.com.    300    IN    A       <server-ipv4>

# AAAA record if IPv6 is enabled
auth.yourdomain.com.    300    IN    AAAA    <server-ipv6>
```

**For Keycloak + WebFinger (Tailscale SSO):**
```
# Keycloak subdomain
auth.yourdomain.com.    300    IN    A       <server-ipv4>
auth.yourdomain.com.    300    IN    AAAA    <server-ipv6>  # if IPv6 enabled

# Main domain for WebFinger endpoint
yourdomain.com.         300    IN    A       <server-ipv4>
yourdomain.com.         300    IN    AAAA    <server-ipv6>  # if IPv6 enabled
```

**Note**: When using WebFinger, both the main domain and the Keycloak subdomain must point to the same server, as Caddy will serve both endpoints.

### DNS Providers
Popular DNS providers that work well with this setup:
- **Cloudflare**: Free tier available, excellent performance
- **AWS Route53**: Reliable, integrates well with AWS services
- **Google Cloud DNS**: Good performance and reliability
- **DigitalOcean DNS**: Simple and free
- **Namecheap DNS**: Basic DNS hosting

## Troubleshooting

### Common Issues

1. **Cloud-init Package Installation Timeouts**
   ```bash
   # Check cloud-init logs
   sudo tail -f /var/log/cloud-init-output.log
   
   # If packages failed to install, manually install Docker
   sudo apt update
   sudo apt install -y docker.io docker-compose-plugin git
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -aG docker admin
   
   # Then run the Keycloak startup script
   sudo bash /opt/keycloak/start-keycloak.sh
   ```

2. **Docker Command Issues**
   ```bash
   # Verify Docker is running
   sudo systemctl status docker
   
   # Check Docker Compose version
   docker compose version
   
   # If using older Docker versions, use docker-compose instead
   docker-compose --version
   ```

3. **DNS Resolution Issues**
   ```bash
   # Verify DNS resolution
   nslookup auth.yourdomain.com
   dig auth.yourdomain.com
   ```

4. **SSL Certificate Issues**
   ```bash
   # Check Caddy logs
   docker logs keycloak-caddy-1
   
   # Verify DNS is pointing to correct IP
   nslookup auth.yourdomain.com
   
   # Ensure port 80/443 are accessible for Let's Encrypt
   sudo ufw status
   ```

5. **Keycloak Startup Issues**
   ```bash
   # Check Keycloak logs
   docker logs keycloak-keycloak-1
   
   # Verify environment variables
   cat /opt/keycloak/keycloak.env
   
   # Check if Keycloak container is healthy
   docker ps --filter "name=keycloak"
   ```

6. **Database Connection Issues**
   ```bash
   # Test database connectivity
   docker exec keycloak-keycloak-1 nc -zv db-host 5432
   
   # Check database credentials in environment file
   grep DB /opt/keycloak/keycloak.env
   ```

### Deployment Timeout Solutions

If you experience timeouts during deployment:

1. **Increase cloud-init timeout** (if using custom images):
   ```yaml
   # Add to cloud-config
   timeout: 3600  # 1 hour timeout
   ```

2. **Manual recovery after timeout**:
   ```bash
   # SSH to the server
   ssh admin@<server-ip>
   
   # Check what failed
   sudo tail -100 /var/log/cloud-init-output.log
   
   # Complete the setup manually
   sudo bash /opt/keycloak/start-keycloak.sh
   ```

3. **Verify services are running**:
   ```bash
   # Check all containers
   docker ps -a
   
   # Restart if needed
   cd /opt/keycloak
   docker compose down
   docker compose up -d
   ```

### Log Locations

- Cloud-init logs: `/var/log/cloud-init-output.log`
- Keycloak logs: `docker logs keycloak-keycloak-1`
- Caddy logs: `docker logs keycloak-caddy-1`
- System logs: `journalctl -u docker`
- Docker Compose logs: `cd /opt/keycloak && docker compose logs`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review [Keycloak documentation](https://www.keycloak.org/documentation)
- Open an issue in this repository

---

**Note**: This module creates real infrastructure that incurs costs. Always review the plan before applying and destroy resources when no longer needed.