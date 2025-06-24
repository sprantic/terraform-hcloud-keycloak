#!/bin/bash

# WebFinger Validation Script
# Validates that WebFinger and OpenID Configuration issuer URLs match

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if required tools are available
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v $cmd &> /dev/null; then
            print_status $RED "Error: $cmd is required but not installed."
            exit 1
        fi
    done
}

# Validate arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <webfinger_domain> <keycloak_realm_url>"
    echo "Example: $0 example.com https://auth.example.com/realms/example"
    echo ""
    echo "This script validates that:"
    echo "1. WebFinger endpoint is accessible at https://<webfinger_domain>/.well-known/webfinger"
    echo "2. OpenID configuration is accessible at <keycloak_realm_url>/.well-known/openid-configuration"
    echo "3. Both endpoints return matching issuer URLs (required for Tailscale SSO)"
    exit 1
fi

WEBFINGER_DOMAIN=$1
KEYCLOAK_REALM_URL=$2

print_status $YELLOW "Validating WebFinger configuration..."
print_status $YELLOW "WebFinger Domain: $WEBFINGER_DOMAIN"
print_status $YELLOW "Keycloak Realm URL: $KEYCLOAK_REALM_URL"
echo

check_dependencies

# Test WebFinger endpoint
print_status $YELLOW "1. Testing WebFinger endpoint..."
WEBFINGER_URL="https://${WEBFINGER_DOMAIN}/.well-known/webfinger"
WEBFINGER_RESPONSE=$(curl -s -H "Accept: application/jrd+json" \
    "${WEBFINGER_URL}?resource=acct:admin@${WEBFINGER_DOMAIN}" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$WEBFINGER_RESPONSE" ]; then
    print_status $RED "✗ WebFinger endpoint not accessible at $WEBFINGER_URL"
    exit 1
fi

print_status $GREEN "✓ WebFinger endpoint accessible"

# Extract issuer from WebFinger response
WEBFINGER_ISSUER=$(echo "$WEBFINGER_RESPONSE" | jq -r '.links[] | select(.rel=="http://openid.net/specs/connect/1.0/issuer") | .href' 2>/dev/null)

if [ -z "$WEBFINGER_ISSUER" ] || [ "$WEBFINGER_ISSUER" = "null" ]; then
    print_status $RED "✗ No OIDC issuer found in WebFinger response"
    echo "WebFinger response:"
    echo "$WEBFINGER_RESPONSE" | jq .
    exit 1
fi

print_status $GREEN "✓ WebFinger issuer found: $WEBFINGER_ISSUER"

# Test OpenID Configuration endpoint
print_status $YELLOW "2. Testing OpenID Configuration endpoint..."
OIDC_CONFIG_URL="${KEYCLOAK_REALM_URL}/.well-known/openid-configuration"
OIDC_RESPONSE=$(curl -s "$OIDC_CONFIG_URL" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$OIDC_RESPONSE" ]; then
    print_status $RED "✗ OpenID Configuration endpoint not accessible at $OIDC_CONFIG_URL"
    exit 1
fi

print_status $GREEN "✓ OpenID Configuration endpoint accessible"

# Extract issuer from OpenID Configuration
OIDC_ISSUER=$(echo "$OIDC_RESPONSE" | jq -r '.issuer' 2>/dev/null)

if [ -z "$OIDC_ISSUER" ] || [ "$OIDC_ISSUER" = "null" ]; then
    print_status $RED "✗ No issuer found in OpenID Configuration response"
    echo "OpenID Configuration response:"
    echo "$OIDC_RESPONSE" | jq .
    exit 1
fi

print_status $GREEN "✓ OpenID Configuration issuer found: $OIDC_ISSUER"

# Compare issuer URLs
print_status $YELLOW "3. Comparing issuer URLs..."
echo "WebFinger issuer:  $WEBFINGER_ISSUER"
echo "OIDC issuer:       $OIDC_ISSUER"

if [ "$WEBFINGER_ISSUER" = "$OIDC_ISSUER" ]; then
    print_status $GREEN "✓ Issuer URLs match perfectly!"
    echo
    print_status $GREEN "🎉 WebFinger configuration is valid for Tailscale SSO!"
    echo
    echo "You can now configure Tailscale with:"
    echo "  Issuer URL: $OIDC_ISSUER"
    echo "  WebFinger: $WEBFINGER_URL"
else
    print_status $RED "✗ Issuer URLs do not match!"
    echo
    print_status $RED "This will cause Tailscale SSO to fail."
    echo "Please ensure the WebFinger issuer URL exactly matches the OpenID Configuration issuer URL."
    echo
    echo "To fix this, update your Terraform configuration:"
    echo "  oidc_issuer_url = \"$OIDC_ISSUER\""
    exit 1
fi

# Additional validation
print_status $YELLOW "4. Additional validation..."

# Check if WebFinger returns proper content type
CONTENT_TYPE=$(curl -s -I -H "Accept: application/jrd+json" \
    "${WEBFINGER_URL}?resource=acct:test@${WEBFINGER_DOMAIN}" | \
    grep -i "content-type" | cut -d: -f2 | tr -d ' \r\n')

if [[ "$CONTENT_TYPE" == *"application/jrd+json"* ]]; then
    print_status $GREEN "✓ WebFinger returns correct content type"
else
    print_status $YELLOW "⚠ WebFinger content type: $CONTENT_TYPE (should include application/jrd+json)"
fi

# Check SSL certificates
print_status $YELLOW "5. Checking SSL certificates..."
for domain in "$WEBFINGER_DOMAIN" "$(echo $KEYCLOAK_REALM_URL | cut -d'/' -f3)"; do
    if openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | \
       openssl x509 -noout -dates 2>/dev/null | grep -q "notAfter"; then
        print_status $GREEN "✓ SSL certificate valid for $domain"
    else
        print_status $YELLOW "⚠ Could not verify SSL certificate for $domain"
    fi
done

echo
print_status $GREEN "Validation complete! Your WebFinger configuration is ready for Tailscale SSO."