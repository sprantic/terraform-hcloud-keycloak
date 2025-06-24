#!/bin/bash

# Terraform Keycloak Module Validation Script
# This script validates the configuration before deployment

set -e

echo "🔍 Validating Terraform Keycloak Module Configuration..."
echo

# Check if tofu is installed
if ! command -v tofu &> /dev/null; then
    echo "❌ OpenTofu is not installed. Please install OpenTofu first."
    echo "   Visit: https://opentofu.org/docs/intro/install/"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars file not found."
    echo "   Copy terraform.tfvars.sample to terraform.tfvars and configure it."
    exit 1
fi

# Check for required variables in terraform.tfvars
echo "📋 Checking required variables..."

required_vars=("hcloud_token" "hcloud_ssh_key" "domain_name" "keycloak_admin_password" "admin_crypted_passwd")
missing_vars=()

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}\s*=" terraform.tfvars || grep -q "^${var}\s*=\s*\"\"" terraform.tfvars; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Missing or empty required variables:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo
    echo "   Please configure these variables in terraform.tfvars"
    exit 1
fi

# Validate OpenTofu configuration
echo "🔧 Validating OpenTofu configuration..."
tofu fmt -check=true -diff=true
tofu validate

# Check if mkpasswd is available for password hashing
if ! command -v mkpasswd &> /dev/null; then
    echo "⚠️  mkpasswd is not installed. You may need it to generate crypted passwords."
    echo "   Install with: sudo apt-get install whois (Ubuntu/Debian)"
fi

# Check domain format
domain=$(grep "^domain_name" terraform.tfvars | cut -d'"' -f2)
if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    echo "⚠️  Domain name format may be invalid: $domain"
fi

echo
echo "✅ Configuration validation completed successfully!"
echo
echo "📝 Next steps:"
echo "   1. Review your configuration: tofu plan"
echo "   2. Deploy infrastructure: tofu apply"
echo "   3. Access Keycloak at: https://auth.$domain"
echo
echo "🔐 Security reminders:"
echo "   - Use strong passwords"
echo "   - Keep your terraform.tfvars file secure"
echo "   - Regularly update Keycloak and system packages"