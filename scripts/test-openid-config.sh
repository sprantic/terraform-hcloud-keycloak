#!/bin/bash

# OpenID Configuration Test Script
# Tests the Keycloak OpenID configuration endpoint

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
    REALM=$2
fi

OPENID_CONFIG_URL="${KEYCLOAK_URL}/realms/${REALM}/.well-known/openid-configuration"

print_status $YELLOW "Testing OpenID Configuration endpoint..."
print_status $YELLOW "URL: $OPENID_CONFIG_URL"
echo

# Test basic connectivity
print_status $YELLOW "1. Testing basic connectivity..."
if curl -s --connect-timeout 10 --max-time 30 -f "$OPENID_CONFIG_URL" > /dev/null; then
    print_status $GREEN "✓ Endpoint is accessible"
else
    print_status $RED "✗ Endpoint is not accessible"
    echo
    print_status $YELLOW "Debugging information:"
    echo "Trying with verbose output..."
    curl -v --connect-timeout 10 --max-time 30 "$OPENID_CONFIG_URL" 2>&1 | head -20
    exit 1
fi

# Get the response
print_status $YELLOW "2. Fetching OpenID configuration..."
RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 "$OPENID_CONFIG_URL")

if [ -z "$RESPONSE" ]; then
    print_status $RED "✗ Empty response from endpoint"
    exit 1
fi

# Check if it's valid JSON
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    print_status $GREEN "✓ Valid JSON response received"
else
    print_status $RED "✗ Invalid JSON response"
    echo "Response:"
    echo "$RESPONSE"
    exit 1
fi

# Extract key fields
print_status $YELLOW "3. Analyzing configuration..."
ISSUER=$(echo "$RESPONSE" | jq -r '.issuer // empty')
AUTH_ENDPOINT=$(echo "$RESPONSE" | jq -r '.authorization_endpoint // empty')
TOKEN_ENDPOINT=$(echo "$RESPONSE" | jq -r '.token_endpoint // empty')
USERINFO_ENDPOINT=$(echo "$RESPONSE" | jq -r '.userinfo_endpoint // empty')

if [ -n "$ISSUER" ]; then
    print_status $GREEN "✓ Issuer: $ISSUER"
else
    print_status $RED "✗ No issuer found"
fi

if [ -n "$AUTH_ENDPOINT" ]; then
    print_status $GREEN "✓ Authorization endpoint: $AUTH_ENDPOINT"
else
    print_status $RED "✗ No authorization endpoint found"
fi

if [ -n "$TOKEN_ENDPOINT" ]; then
    print_status $GREEN "✓ Token endpoint: $TOKEN_ENDPOINT"
else
    print_status $RED "✗ No token endpoint found"
fi

if [ -n "$USERINFO_ENDPOINT" ]; then
    print_status $GREEN "✓ Userinfo endpoint: $USERINFO_ENDPOINT"
else
    print_status $RED "✗ No userinfo endpoint found"
fi

# Check if issuer matches expected URL
EXPECTED_ISSUER="${KEYCLOAK_URL}/realms/${REALM}"
if [ "$ISSUER" = "$EXPECTED_ISSUER" ]; then
    print_status $GREEN "✓ Issuer URL matches expected value"
else
    print_status $YELLOW "⚠ Issuer URL mismatch:"
    echo "  Expected: $EXPECTED_ISSUER"
    echo "  Actual:   $ISSUER"
fi

echo
print_status $GREEN "OpenID Configuration test complete!"
echo
echo "Full configuration:"
echo "$RESPONSE" | jq .