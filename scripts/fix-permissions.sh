#!/bin/bash

# Keycloak Directory Permissions Fix Script
# This script fixes common permission issues with the Keycloak installation

set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Keycloak permissions fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Ensure admin user is in docker group
if id "admin" &>/dev/null; then
    usermod -aG docker admin
    log "Admin user is in docker group"
else
    log "Warning: Admin user not found"
fi

# Create keycloak directory if it doesn't exist
if [ ! -d "/opt/keycloak" ]; then
    log "Creating /opt/keycloak directory..."
    mkdir -p /opt/keycloak/.well-known
else
    log "/opt/keycloak directory exists"
fi

# Fix ownership and permissions for admin user
log "Fixing ownership and permissions..."
chown -R admin:admin /opt/keycloak
chmod 755 /opt/keycloak
chmod 755 /opt/keycloak/.well-known

# Set proper permissions for specific files
if [ -f "/opt/keycloak/keycloak.env" ]; then
    chmod 640 /opt/keycloak/keycloak.env
    log "Fixed keycloak.env permissions"
else
    log "Warning: keycloak.env not found"
fi

if [ -f "/opt/keycloak/docker-compose.yml" ]; then
    chmod 644 /opt/keycloak/docker-compose.yml
    log "Fixed docker-compose.yml permissions"
else
    log "Warning: docker-compose.yml not found"
fi

if [ -f "/opt/keycloak/start-keycloak.sh" ]; then
    chmod 755 /opt/keycloak/start-keycloak.sh
    log "Fixed start-keycloak.sh permissions"
else
    log "Warning: start-keycloak.sh not found"
fi

if [ -f "/opt/keycloak/security-hardening.sh" ]; then
    chmod 755 /opt/keycloak/security-hardening.sh
    log "Fixed security-hardening.sh permissions"
else
    log "Warning: security-hardening.sh not found"
fi

if [ -f "/opt/keycloak/.well-known/webfinger" ]; then
    chmod 644 /opt/keycloak/.well-known/webfinger
    log "Fixed webfinger permissions"
else
    log "Warning: webfinger not found"
fi

# Admin user already owns the files, no additional group needed
log "Admin user has full access to keycloak directory"

# Display current ownership and permissions
log "Current /opt/keycloak ownership and permissions:"
ls -la /opt/keycloak/

if [ -d "/opt/keycloak/.well-known" ]; then
    log "Current /opt/keycloak/.well-known ownership and permissions:"
    ls -la /opt/keycloak/.well-known/
fi

# Test Docker access for admin user
log "Testing Docker access for admin user..."
if sudo -u admin docker info >/dev/null 2>&1; then
    log "✓ Admin user can access Docker"
else
    log "✗ Admin user cannot access Docker - this may cause issues"
    log "Attempting to fix Docker group membership..."
    usermod -aG docker admin
    # Docker group changes require a new login session to take effect
    log "Docker group membership updated - may require logout/login to take effect"
fi

# Check if Keycloak services are running
log "Checking Keycloak services status..."
if [ -f "/opt/keycloak/docker-compose.yml" ]; then
    cd /opt/keycloak
    if docker compose ps >/dev/null 2>&1; then
        log "Keycloak services status:"
        docker compose ps
    else
        log "Keycloak services are not running or cannot be accessed"
    fi
fi

log "Permissions fix completed successfully!"
log ""
log "If you're still experiencing issues:"
log "1. Restart the Keycloak services: cd /opt/keycloak && docker compose restart"
log "2. Check logs: cd /opt/keycloak && docker compose logs"
log "3. Verify admin user can access directory: sudo -u admin ls -la /opt/keycloak"
log "4. Check Docker volumes: docker volume ls"
log "5. Verify SSL certificate permissions in Docker volumes"