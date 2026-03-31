#!/bin/bash
set -e

log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

########################################
# Phase 1: Pre-checks
########################################
log "Phase 1: Pre-checks"

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  error "Run this script as root"
fi

########################################
# Phase 2: Users & Groups
########################################
log "Phase 2: Users & Groups"

# Ensure group exists
if getent group kijanikiosk >/dev/null; then
  log "Group kijanikiosk already exists"
else
  groupadd kijanikiosk
  log "Created group kijanikiosk"
fi

# Function to ensure user exists correctly
ensure_user() {
  local user=$1

  if id "$user" &>/dev/null; then
    log "User $user already exists"
  else
    useradd -r -s /usr/sbin/nologin -g kijanikiosk "$user"
    log "Created user $user"
  fi

  # Ensure user is in kijanikiosk group
  usermod -aG kijanikiosk "$user"
}

ensure_user kk-api
ensure_user kk-payments
ensure_user kk-logs

########################################
# Phase 3: Directories & Permissions
########################################
log "Phase 3: Directories & Permissions"

# Create base directories if missing
mkdir -p /opt/kijanikiosk/config
mkdir -p /opt/kijanikiosk/shared/logs

# Fix ownership
chown -R root:kijanikiosk /opt/kijanikiosk

# Fix config permissions (remove 777)
chmod 750 /opt/kijanikiosk/config
log "Fixed permissions for config directory"

# Fix logs directory permissions
chmod 770 /opt/kijanikiosk/shared/logs

# Set ACLs so services can access logs properly
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs

# Set default ACLs (CRITICAL for logrotate later)
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs

log "ACLs configured for shared logs directory"

########################################
# Phase 4: Packages
########################################
log "Phase 4: Packages"

# Check for held packages
held_packages=$(apt-mark showhold)

if echo "$held_packages" | grep -q "curl"; then
  log "curl is on hold — unholding temporarily"
  apt-mark unhold curl
  CURL_WAS_HELD=1
else
  CURL_WAS_HELD=0
fi

# Install required packages
apt-get update -y
apt-get install -y curl nginx ufw acl

log "Packages installed"

# Re-hold curl if it was held before
if [ "$CURL_WAS_HELD" -eq 1 ]; then
  apt-mark hold curl
  log "curl re-held after installation"
fi

########################################
# Phase 5: Firewall
########################################
log "Phase 5: Firewall"

# Reset firewall completely
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp comment 'Allow SSH access'

# Allow HTTP
ufw allow 80/tcp comment 'Allow HTTP traffic'

# Allow monitoring subnet to payments port
ufw allow from 10.0.1.0/24 to any port 3001 comment 'Allow monitoring access to payments'

# Allow loopback FIRST (important)
ufw allow in on lo to any port 3001 comment 'Allow local access to payments'

# Deny external access to payments
ufw deny 3001 comment 'Deny external access to payments service'

# Enable firewall
ufw --force enable

log "Firewall configured"

# Phase 6: Systemd Units
echo "[INFO] Phase 6: Systemd Units"

# kk-api.service
cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
User=kk-api
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/app.js
Restart=on-failure
RestartSec=5s
EnvironmentFile=/opt/kijanikiosk/config/api.env
ProtectSystem=full
NoNewPrivileges=yes
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

log "kk-api service file created"

mkdir -p /opt/kijanikiosk/config

if [ ! -f /opt/kijanikiosk/config/api.env ]; then
  echo "PORT=3000" > /opt/kijanikiosk/config/api.env
  chown root:kijanikiosk /opt/kijanikiosk/config/api.env
  chmod 640 /opt/kijanikiosk/config/api.env
  log "Created api.env"
fi

systemctl daemon-reload
log "systemd daemon reloaded"

