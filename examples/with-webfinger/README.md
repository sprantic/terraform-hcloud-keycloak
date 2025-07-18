# Keycloak with WebFinger for Tailscale SSO

This example demonstrates how to deploy Keycloak with WebFinger configuration for Tailscale custom OIDC integration.

## What This Creates

- **Keycloak Server**: Identity provider at `https://auth.example.com`
- **WebFinger Endpoint**: OIDC discovery at `https://example.com/.well-known/webfinger`
- **Automatic SSL**: Let's Encrypt certificates for both domains
- **Single Server**: Both endpoints served from the same Hetzner Cloud server

## Prerequisites

1. **Domain Control**: You must control the main domain (e.g., `example.com`)
2. **Hetzner Cloud Account**: With API token and SSH key uploaded
3. **DNS Management**: Ability to create A/AAAA records for your domain

## Quick Start

1. **Copy Configuration**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit Variables**
   ```bash
   # Edit terraform.tfvars with your values
   nano terraform.tfvars
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure DNS Records**
   
   After deployment, create these DNS records:
   ```
   # Main domain (for WebFinger)
   example.com.        300    IN    A       <server-ip-from-output>
   
   # Keycloak subdomain
   auth.example.com.   300    IN    A       <server-ip-from-output>
   ```

5. **Verify WebFinger**
   ```bash
   # Test WebFinger endpoint
   curl -H "Accept: application/jrd+json" \
        "https://example.com/.well-known/webfinger?resource=acct:admin@example.com"
   ```

6. **Configure Tailscale**
   
   Use the Terraform outputs to configure Tailscale:
   ```bash
   # Get configuration values
   terraform output tailscale_configuration
   ```

## DNS Configuration

**Critical**: Both domains must point to the same server IP:

```dns
# Required DNS records
example.com.        300    IN    A       <server-ip>
auth.example.com.   300    IN    A       <server-ip>

# If IPv6 is enabled
example.com.        300    IN    AAAA    <server-ipv6>
auth.example.com.   300    IN    AAAA    <server-ipv6>
```

## Tailscale Configuration

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/)
2. Navigate to **Settings** → **SSO**
3. Choose **Custom OIDC**
4. Use these values from Terraform outputs:
   - **Issuer URL**: `https://auth.example.com/realms/example`
   - **Client ID**: (from Keycloak realm configuration)
   - **Client Secret**: (from Keycloak realm configuration)

## WebFinger Response

The WebFinger endpoint returns:
```json
{
  "subject": "acct:${email}",
  "links": [
    {
      "rel": "http://openid.net/specs/connect/1.0/issuer",
      "href": "https://auth.example.com/realms/example"
    }
  ]
}
```

## Verification

Test the setup:

```bash
# 1. Verify Keycloak is accessible
curl -f https://auth.example.com/health

# 2. Verify WebFinger endpoint
curl -H "Accept: application/jrd+json" \
     "https://example.com/.well-known/webfinger?resource=acct:test@example.com"

# 3. Verify OIDC discovery
curl https://auth.example.com/realms/example/.well-known/openid-configuration
```

## Troubleshooting

### DNS Issues
```bash
# Check DNS resolution
nslookup example.com
nslookup auth.example.com

# Both should return the same IP address
```

### SSL Certificate Issues
```bash
# Check Caddy logs
ssh admin@<server-ip> 'docker logs keycloak-caddy-1'

# Verify certificates
openssl s_client -connect example.com:443 -servername example.com
openssl s_client -connect auth.example.com:443 -servername auth.example.com
```

### WebFinger Issues
```bash
# Check if WebFinger file exists
ssh admin@<server-ip> 'ls -la /opt/keycloak/.well-known/'

# Check Caddy configuration
ssh admin@<server-ip> 'docker exec keycloak-caddy-1 cat /etc/caddy/Caddyfile'
```

## Security Notes

- Use strong passwords for all accounts
- Restrict SSH access to your IP addresses
- Regularly update Keycloak and system packages
- Monitor access logs for suspicious activity
- Consider using external database for production

## Clean Up

```bash
terraform destroy
```

**Note**: This will delete all infrastructure and data. Ensure you have backups if needed.