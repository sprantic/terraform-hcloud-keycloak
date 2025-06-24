#
# virtual machine
#

# changes 
# replace --proxy=edge with --proxy-headers=xforwarded
# add environment variables to docker


data "hcloud_ssh_key" "me" {
  name = var.hcloud_ssh_key
}

data "cloudinit_config" "idp" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.yml"
    content_type = "text/cloud-config"
    content      = <<-YAML
      #cloud-config
      package_update: true
      package_upgrade: true
      
      # Add package installation with retries and timeout handling
      apt:
        sources:
          docker.list:
            source: deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
            keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
      
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - gnupg
        - lsb-release
        - git
        - docker-ce
        - docker-ce-cli
        - containerd.io
        - docker-buildx-plugin
        - docker-compose-plugin

      users:
        - name: admin
          groups: [docker, sudo]
          shell: /bin/bash
          lock_passwd: true
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${data.hcloud_ssh_key.me.public_key}

      write_files:
        - path: /opt/keycloak/keycloak.env
          content: |
            KEYCLOAK_ADMIN=${var.keycloak_admin_user}
            KEYCLOAK_ADMIN_PASSWORD=${var.keycloak_admin_password}
            KC_HOSTNAME_STRICT=false
            KC_HTTP_ENABLED=true
            KC_PROXY_HEADERS=xforwarded
            KC_HOSTNAME_URL=https://${var.keycloak_subdomain}.${var.domain_name}
            KC_HOSTNAME_ADMIN_URL=https://${var.keycloak_subdomain}.${var.domain_name}
            ${var.use_external_db ? "KC_DB=${var.db_vendor}" : "KC_DB=dev-mem"}
            ${var.use_external_db ? "KC_DB_URL=jdbc:postgresql://${var.db_host}:${var.db_port}/${var.db_name}" : ""}
            ${var.use_external_db ? "KC_DB_USERNAME=${var.db_user}" : ""}
            ${var.use_external_db ? "KC_DB_PASSWORD=${var.keycloak_db_password}" : ""}
        - path: /opt/keycloak/.well-known/webfinger
          content: |
            {
              "subject": "acct:${var.webfinger_email != "" ? var.webfinger_email : "admin@${var.webfinger_domain}"}",
              "links": [
                {
                  "rel": "http://openid.net/specs/connect/1.0/issuer",
                  "href": "${var.oidc_issuer_url != "" ? var.oidc_issuer_url : "https://${var.keycloak_subdomain}.${var.domain_name}/realms/sprantic"}"
                }
              ]
            }
        - path: /opt/keycloak/docker-compose.yml
          content: |
            services:
              keycloak:
                image: quay.io/keycloak/keycloak:${var.keycloak_version}
                command: start --hostname-strict=false --proxy-headers=xforwarded
                env_file:
                  - keycloak.env
                ports:
                  - "8080:8080"
                networks: [web]
                restart: unless-stopped
                healthcheck:
                  test: ["CMD", "/opt/keycloak/bin/kc.sh", "show-config"]
                  interval: 30s
                  timeout: 10s
                  retries: 5
                  start_period: 60s
                environment:
                  KC_HTTP_ENABLED: "true"
                  KC_HOSTNAME_STRICT: "false"
                  KC_PROXY_HEADERS: "xforwarded"
                  KC_HOSTNAME_URL: "https://${var.keycloak_subdomain}.${var.domain_name}"
                  KC_HOSTNAME_ADMIN_URL: "https://${var.keycloak_subdomain}.${var.domain_name}"
                  QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY: "true"
              caddy:
                image: caddy:2-alpine
                volumes:
                  - caddy_data:/data
                  - caddy_config:/config
                  - ./.well-known:/srv/.well-known:ro
                networks: [web]
                ports:
                  - "80:80"
                  - "443:443"
                restart: unless-stopped
                environment:
                  - KEYCLOAK_DOMAIN=${var.keycloak_subdomain}.${var.domain_name}
                  - WEBFINGER_DOMAIN=${var.webfinger_domain}
                  - SSL_EMAIL=${var.ssl_email != "" ? var.ssl_email : "admin@${var.domain_name}"}
                command: >-
                  sh -c "
                  echo '{' > /etc/caddy/Caddyfile &&
                  echo '  acme_ca https://acme.zerossl.com/v2/DV90' >> /etc/caddy/Caddyfile &&
                  echo '  email '$$SSL_EMAIL >> /etc/caddy/Caddyfile &&
                  echo '}' >> /etc/caddy/Caddyfile &&
                  echo '' >> /etc/caddy/Caddyfile &&
                  echo $$KEYCLOAK_DOMAIN' {' >> /etc/caddy/Caddyfile &&
                  echo '  reverse_proxy keycloak:8080' >> /etc/caddy/Caddyfile &&
                  echo '}' >> /etc/caddy/Caddyfile &&
                  echo '' >> /etc/caddy/Caddyfile &&
                  echo $$WEBFINGER_DOMAIN' {' >> /etc/caddy/Caddyfile &&
                  echo '  handle /.well-known/webfinger {' >> /etc/caddy/Caddyfile &&
                  echo '    header Content-Type application/jrd+json' >> /etc/caddy/Caddyfile &&
                  echo '    file_server {' >> /etc/caddy/Caddyfile &&
                  echo '      root /srv' >> /etc/caddy/Caddyfile &&
                  echo '    }' >> /etc/caddy/Caddyfile &&
                  echo '  }' >> /etc/caddy/Caddyfile &&
                  echo '  handle {' >> /etc/caddy/Caddyfile &&
                  echo '    respond \"WebFinger endpoint available at /.well-known/webfinger\" 200' >> /etc/caddy/Caddyfile &&
                  echo '  }' >> /etc/caddy/Caddyfile &&
                  echo '}' >> /etc/caddy/Caddyfile &&
                  caddy run --config /etc/caddy/Caddyfile
                  "
            volumes:
              caddy_data:
              caddy_config:
            networks:
              web:
                driver: bridge
        - path: /opt/keycloak/security-hardening.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            # Security hardening script
            
        - path: /opt/keycloak/start-keycloak.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -euo pipefail
            
            # Logging function
            log() {
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
            }
            
            log "Starting Keycloak deployment script..."
            
            # Wait for Docker to be ready with timeout
            log "Waiting for Docker to be ready..."
            timeout=120
            counter=0
            while ! docker info >/dev/null 2>&1; do
              if [ $counter -ge $timeout ]; then
                log "ERROR: Docker not ready after $timeout seconds"
                exit 1
              fi
              log "Docker not ready, waiting... ($counter/$timeout)"
              sleep 5
              counter=$((counter + 5))
            done
            
            log "Docker is ready!"
            
            # Create directory if it doesn't exist
            mkdir -p /opt/keycloak
            cd /opt/keycloak
            
            # Pull images first to avoid timeout issues
            log "Pulling Docker images..."
            docker compose pull
            
            # Start services with proper error handling and retries
            log "Starting Keycloak services..."
            max_retries=3
            retry_count=0
            
            while [ $retry_count -lt $max_retries ]; do
              if docker compose up -d --wait --timeout 120; then
                log "Keycloak services started successfully!"
                break
              else
                retry_count=$((retry_count + 1))
                log "Attempt $retry_count failed, retrying in 30 seconds..."
                docker compose down || true
                sleep 30
                if [ $retry_count -eq $max_retries ]; then
                  log "ERROR: Failed to start Keycloak after $max_retries attempts"
                  exit 1
                fi
              fi
            done
            
            # Verify services are running
            log "Verifying services..."
            docker compose ps
            
            log "Keycloak deployment completed successfully!"
      runcmd:
        # Memory settings to avoid JGroups Warnings (do this early)
        - [ bash, -c, "sysctl -w net.core.rmem_max=26214400" ]
        - [ bash, -c, "sysctl -w net.core.wmem_max=1048576" ]

        # Update package lists and install Docker GPG key manually
        - [ bash, -c, "apt-get update" ]
        - [ bash, -c, "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" ]
        - [ bash, -c, "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" ]
        - [ bash, -c, "apt-get update" ]
        - [ bash, -c, "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" ]

        # Docker service management with comprehensive error handling
        - [ bash, -c, "systemctl enable docker" ]
        - [ bash, -c, "systemctl start docker" ]
        - [ bash, -c, "usermod -aG docker admin" ]
        
        # Wait for Docker to be fully ready
        - [ bash, -c, "timeout 120 bash -c 'until docker info >/dev/null 2>&1; do echo \"Waiting for Docker daemon...\"; sleep 5; done'" ]
        
        # Start Keycloak with better error handling
        - [ bash, -c, "cd /opt/keycloak && timeout 300 bash -c 'until docker compose up -d --wait; do echo \"Retrying Keycloak startup...\"; sleep 10; done'" ]
        
        # Verify services are running
        - [ bash, -c, "sleep 10 && docker ps" ]
        
        # Security hardening temporarily disabled to ensure Keycloak accessibility
        - [ bash, -c, "echo 'Security hardening skipped to maintain service accessibility'" ]
        # - [ bash, -c, "echo '${var.security_hardening_script != null && var.security_hardening_script != "" ? var.security_hardening_script : base64encode("#!/bin/bash\necho 'No security hardening script provided'")}' | base64 -d | bash" ]
        
    YAML
  }
}

resource "hcloud_server" "idp" {
  name        = var.server_name
  image       = var.server_image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [data.hcloud_ssh_key.me.id]
  user_data   = data.cloudinit_config.idp.rendered
  
  public_net {
    ipv4_enabled = true
    ipv6_enabled = var.enable_ipv6
  }

  # Optional network configuration
  dynamic "network" {
    for_each = var.network_id != null ? [1] : []
    content {
      network_id = var.network_id
      ip         = var.private_ip
    }
  }

  labels = {
    service = "keycloak"
    environment = "production"
  }
}


# DNS
#

resource "hcloud_rdns" "idp_ipv4" {
  server_id  = hcloud_server.idp.id
  ip_address = hcloud_server.idp.ipv4_address
  dns_ptr    = "${var.keycloak_subdomain}.${var.domain_name}"
}

resource "hcloud_rdns" "idp_ipv6" {
  count      = var.enable_ipv6 ? 1 : 0
  server_id  = hcloud_server.idp.id
  ip_address = hcloud_server.idp.ipv6_address
  dns_ptr    = "${var.keycloak_subdomain}.${var.domain_name}"
}

