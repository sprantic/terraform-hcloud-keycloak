#!/bin/bash

# Deployment Validation Script
# Validates that both Keycloak and WebFinger are working correctly

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

# Allow override via arguments
if [ $# -ge 1 ]; then
    KEYCLOAK_URL=$1
fi

if [ $# -ge 2 ]; then
    WEBFINGER_DOMAIN=$2
fi

if [ $# -ge 3 ]; then
    REALM=$3
fi

print_status $YELLOW "=== Keycloak Deployment Validation ==="
print_status $YELLOW "Keycloak URL: $KEYCLOAK_URL"
print_status $YELLOW "WebFinger Domain: $WEBFINGER_DOMAIN"
print_status $YELLOW "Realm: $REALM"
echo

# Test 1: Keycloak Health Check
print_status $YELLOW "1. Testing Keycloak health..."
# Use the master realm as a health indicator since /health endpoints aren't exposed through proxy
if curl -s --connect-timeout 10 --max-time 30 -f "$KEYCLOAK_URL/realms/master" > /dev/null; then
    print_status $GREEN "✓ Keycloak is healthy and ready"
else
    print_status $RED "✗ Keycloak health check failed"
    echo "Trying basic connectivity..."
    curl -v --connect-timeout 10 --max-time 30 "$KEYCLOAK_URL" 2>&1 | head -10
fi

# Test 2: OpenID Configuration
print_status $YELLOW "2. Testing OpenID Configuration..."
OIDC_URL="${KEYCLOAK_URL}/realms/${REALM}/.well-known/openid-configuration"
if curl -s --connect-timeout 10 --max-time 30 -f "$OIDC_URL" > /dev/null; then
    print_status $GREEN "✓ OpenID Configuration accessible"
    
    # Extract issuer
    ISSUER=$(curl -s "$OIDC_URL" | jq -r '.issuer // empty')
    if [ -n "$ISSUER" ]; then
        print_status $GREEN "✓ Issuer: $ISSUER"
    else
        print_status $RED "✗ No issuer found in OpenID configuration"
    fi
else
    print_status $RED "✗ OpenID Configuration not accessible at $OIDC_URL"
fi

# Test 3: WebFinger (if enabled)
print_status $YELLOW "3. Testing WebFinger..."
WEBFINGER_URL="https://${WEBFINGER_DOMAIN}/.well-known/webfinger"
if curl -s --connect-timeout 10 --max-time 30 -f "${WEBFINGER_URL}?resource=acct:admin@${WEBFINGER_DOMAIN}" > /dev/null; then
    print_status $GREEN "✓ WebFinger endpoint accessible"
    
    # Extract WebFinger issuer
    WF_ISSUER=$(curl -s "${WEBFINGER_URL}?resource=acct:admin@${WEBFINGER_DOMAIN}" | \
                jq -r '.links[] | select(.rel=="http://openid.net/specs/connect/1.0/issuer") | .href // empty')
    
    if [ -n "$WF_ISSUER" ]; then
        print_status $GREEN "✓ WebFinger issuer: $WF_ISSUER"
        
        # Compare issuers
        if [ "$ISSUER" = "$WF_ISSUER" ]; then
            print_status $GREEN "✓ Issuer URLs match - Ready for Tailscale SSO!"
        else
            print_status $RED "✗ Issuer URLs do not match"
            echo "  OpenID: $ISSUER"
            echo "  WebFinger: $WF_ISSUER"
        fi
    else
        print_status $RED "✗ No issuer found in WebFinger response"
    fi
else
    print_status $YELLOW "⚠ WebFinger endpoint not accessible (may not be enabled)"
fi

# Test 4: SSL Certificates
print_status $YELLOW "4. Testing SSL certificates..."
for domain in "$(echo $KEYCLOAK_URL | cut -d'/' -f3)" "$WEBFINGER_DOMAIN"; do
    if echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
       openssl x509 -noout -dates 2>/dev/null | grep -q "notAfter"; then
        print_status $GREEN "✓ SSL certificate valid for $domain"
    else
        print_status $YELLOW "⚠ Could not verify SSL certificate for $domain"
    fi
done

echo
print_status $GREEN "=== Validation Complete ==="

# Summary
if [ -n "$ISSUER" ] && [ -n "$WF_ISSUER" ] && [ "$ISSUER" = "$WF_ISSUER" ]; then
    echo
    print_status $GREEN "🎉 Deployment is ready for Tailscale SSO!"
    echo
    echo "Configuration for Tailscale:"
    echo "  OIDC Issuer URL: $ISSUER"
    echo "  WebFinger URL: $WEBFINGER_URL"
elif [ -n "$ISSUER" ]; then
    echo
    print_status $YELLOW "⚠ Keycloak is working but WebFinger may need configuration"
    echo "  OIDC Issuer URL: $ISSUER"
else
    echo
    print_status $RED "❌ Deployment has issues that need to be resolved"
fi