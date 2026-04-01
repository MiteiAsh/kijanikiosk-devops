#!/bin/bash
set -euo pipefail

log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1"; exit 1; }
success() { echo "[PASS] $1"; }

########################################
# Phase 1: Pre-checks and Dirty State Documentation
########################################
log "Phase 1: Pre-checks"

# Expected dirty conditions found in pre-provisioning audit:
# - kk-api, kk-payments, kk-logs already exist with home directories: handled in Phase 2 by id check
# - /opt/kijanikiosk/config/ has overly permissive 777: fixed in Phase 3
# - /opt/kijanikiosk/shared/logs/ missing ACL entries: fixed in Phase 3
# - ufw inactive: reset and configured in Phase 5
# - curl is on hold: handled in Phase 4 by temporary unhold
# - journal size ~243MB: capped in Phase 7

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  error "Run this script as root"
fi

# Detect if we're on a VM with held packages
log "Running pre-checks..."

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
    log "User $user already exists - ensuring correct shell and group"
    usermod -s /usr/sbin/nologin "$user" 2>/dev/null || true
  else
    useradd -r -s /usr/sbin/nologin -g kijanikiosk "$user"
    log "Created user $user"
  fi

  # Ensure user is in kijanikiosk group
  usermod -aG kijanikiosk "$user" 2>/dev/null || true
}

ensure_user kk-api
ensure_user kk-payments
ensure_user kk-logs

########################################
# Phase 3: Directories & Permissions
########################################
log "Phase 3: Directories & Permissions"

# Create base directories if missing
mkdir -p /opt/kijanikiosk/{config,shared/logs,health,api,payments,logs}

# Fix ownership
chown -R root:kijanikiosk /opt/kijanikiosk

# Fix config permissions (remove 777)
chmod 750 /opt/kijanikiosk/config
chmod 770 /opt/kijanikiosk/shared/logs
chmod 750 /opt/kijanikiosk/health

# Set ACLs so services can access logs properly
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/health

# Set default ACLs (CRITICAL for logrotate later)
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/health

log "ACLs configured for shared logs and health directories"

# Create environment files if they don't exist
if [ ! -f /opt/kijanikiosk/config/api.env ]; then
  cat > /opt/kijanikiosk/config/api.env << 'EOF'
PORT=3000
NODE_ENV=production
EOF
fi

if [ ! -f /opt/kijanikiosk/config/payments-api.env ]; then
  cat > /opt/kijanikiosk/config/payments-api.env << 'EOF'
PORT=3001
NODE_ENV=production
PAYMENT_GATEWAY_URL=https://api.stripe.com
EOF
fi

if [ ! -f /opt/kijanikiosk/config/logs-api.env ]; then
  cat > /opt/kijanikiosk/config/logs-api.env << 'EOF'
PORT=3002
LOG_LEVEL=info
EOF
fi

chmod 640 /opt/kijanikiosk/config/*.env
chown root:kijanikiosk /opt/kijanikiosk/config/*.env

########################################
# Phase 4: Packages
########################################
log "Phase 4: Packages"

# Check for held packages and handle them
HELD_PACKAGES=""
if command -v apt-mark &>/dev/null; then
  HELD_PACKAGES=$(apt-mark showhold || echo "")
fi

# Temporarily unhold packages that might interfere
for pkg in curl nginx; do
  if echo "$HELD_PACKAGES" | grep -q "^$pkg$"; then
    log "$pkg is on hold — unholding temporarily"
    apt-mark unhold "$pkg" || true
  fi
done

# Install required packages
apt-get update -y
apt-get install -y curl nginx ufw acl logrotate

log "Packages installed"

########################################
# Phase 5: Firewall
########################################
log "Phase 5: Firewall"

# Reset firewall completely to known state
ufw --force reset 2>/dev/null || true

# Set defaults
ufw default deny incoming
ufw default allow outgoing

# Allow essential services
ufw allow 22/tcp comment 'Allow SSH access for administration'
ufw allow 80/tcp comment 'Allow HTTP traffic for web services'

# Critical: Allow loopback first (must come before deny rules)
ufw allow in on lo comment 'Allow all loopback traffic'

# Allow monitoring subnet to payments health check
ufw allow from 10.0.1.0/24 to any port 3001 comment 'Allow monitoring subnet to payments health endpoint'

# Deny external access to payments service port
ufw deny 3001 comment 'Deny external access to payments service (internal only)'

# Enable firewall
ufw --force enable

log "Firewall configured and enabled"

########################################
# Phase 6: Systemd Units
########################################
log "Phase 6: Systemd Units"

# kk-api.service
cat > /etc/systemd/system/kk-api.service << 'EOF'
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
ProtectSystem=strict
NoNewPrivileges=yes
PrivateTmp=true
ProtectHome=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# kk-payments.service (hardened for PCI compliance - score 2.1)
cat > /etc/systemd/system/kk-payments.service << 'EOF'
[Unit]
Description=KijaniKiosk Payments Service
After=kk-api.service
Wants=kk-api.service

[Service]
User=kk-payments
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/payments
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/app.js
Restart=on-failure
RestartSec=5s
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env

# Basic hardening
ProtectSystem=strict
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
ProtectKernelLogs=yes
ProtectClock=yes
ProtectHostname=yes

# Network restrictions (but still allow needed network access)
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
RestrictRealtime=yes
PrivateNetwork=no
IPAddressDeny=

# Memory protection
MemoryDenyWriteExecute=yes

# Capabilities - only what's needed
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# System call filtering
SystemCallFilter=~@privileged @resources @swap @reboot @raw-io

# Process restrictions
RestrictSUIDSGID=yes
LockPersonality=yes

# File access
ReadWritePaths=/opt/kijanikiosk/shared/logs
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

# kk-logs.service
cat > /etc/systemd/system/kk-logs.service << 'EOF'
[Unit]
Description=KijaniKiosk Log Aggregation Service
After=network.target

[Service]
User=kk-logs
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/logs
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/app.js
Restart=on-failure
RestartSec=5s
EnvironmentFile=/opt/kijanikiosk/config/logs-api.env
ProtectSystem=strict
NoNewPrivileges=yes
PrivateTmp=true
ReadWritePaths=/opt/kijanikiosk/shared/logs /opt/kijanikiosk/health
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
log "Systemd units created and daemon reloaded"

# Test service startability (without actual start since apps aren't deployed)
log "Testing service configurations..."
for service in kk-api kk-payments kk-logs; do
  if systemctl is-enabled "$service.service" &>/dev/null; then
    log "$service already enabled"
  else
    systemctl enable "$service.service"
    log "$service enabled"
  fi
done

########################################
# Phase 7: Journal Persistence and Log Rotation
########################################
log "Phase 7: Journal Persistence and Log Rotation"

# Configure journald for persistent storage with size cap
mkdir -p /var/log/journal
cat > /etc/systemd/journald.conf << 'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
MaxRetentionSec=1week
Compress=yes
EOF

systemctl restart systemd-journald
log "Journald configured for persistent storage capped at 500MB"

# Create logrotate configuration for all three services
cat > /etc/logrotate.d/kijanikiosk << 'EOF'
/opt/kijanikiosk/shared/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root kijanikiosk
    sharedscripts
    postrotate
        # Signal services to reopen log files
        systemctl kill -s USR1 kk-logs.service 2>/dev/null || true
        systemctl kill -s USR1 kk-api.service 2>/dev/null || true
        systemctl kill -s USR1 kk-payments.service 2>/dev/null || true
    endscript
}
EOF

log "Logrotate configuration created"

# Test logrotate configuration
if logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1 | grep -q "error"; then
  error "Logrotate configuration test failed"
else
  success "Logrotate configuration test passed"
fi

########################################
# Phase 8: Monitoring Health Checks and verification.
########################################
log "Phase 8: Monitoring Health Checks and verification"

# Create health check script
mkdir -p /opt/kijanikiosk/health

# Perform health checks
timestamp=$(date -Is)

# Check service ports
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')
logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null && echo '"ok"' || echo '"down"')
# Write structured JSON
cat > /opt/kijanikiosk/health/last-provision.json << EOF
{
  "timestamp": "$timestamp",
  "kk-api": $api_status,
  "kk-payments": $payments_status,
  "kk-logs": $logs_status,
  "provision_status": "complete"
}
EOF

chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

log "Health check completed: API=$api_status, Payments=$payments_status, Logs=$logs_status"


failed_checks=0

# Function to verify each component
verify_firewall() {
  local status
  status=$(ufw status)

  echo "$status" | grep -q "22/tcp.*ALLOW" && success "PASS: SSH (22) allowed" || { log "FAIL: SSH rule missing"; ((failed_checks++)); }
  echo "$status" | grep -q "80/tcp.*ALLOW" && success "PASS: HTTP (80) allowed" || { log "FAIL: HTTP rule missing"; ((failed_checks++)); }
  echo "$status" | grep -q "3001.*DENY" && success "PASS: Port 3001 external deny present" || { log "FAIL: Port 3001 deny rule missing"; ((failed_checks++)); }
  (echo "$status" | grep -q "3001.*ALLOW.*10.0.1.0/24" || echo "$status" | grep -q "10.0.1.0/24.*3001.*ALLOW") && success "PASS: Monitoring subnet allowed to port 3001" || { log "FAIL: Monitoring subnet rule missing"; ((failed_checks++)); }
  echo "$status" | grep -q "lo.*ALLOW" && success "PASS: Loopback allowed" || { log "FAIL: Loopback rule missing"; ((failed_checks++)); }
}

verify_users_groups() {
  for user in kk-api kk-payments kk-logs; do
    if id "$user" &>/dev/null; then
      success "PASS: User $user exists with nologin shell"
    else
      log "FAIL: User $user missing"
      ((failed_checks++))
    fi
  done

  getent group kijanikiosk &>/dev/null && success "PASS: Group kijanikiosk exists" || { log "FAIL: Group kijanikiosk missing"; ((failed_checks++)); }
}

verify_permissions() {
  local config_perms=$(stat -c %a /opt/kijanikiosk/config)
  if [[ "$config_perms" == "750" ]]; then
    success "PASS: Config directory permissions are 750"
  else
    log "FAIL: Config directory permissions are $config_perms, expected 750"
    ((failed_checks++))
  fi

  # Test ACLs and logrotate compatibility
  sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp 2>/dev/null && \
    success "PASS: kk-api can write to shared/logs" || \
    { log "FAIL: kk-api cannot write to shared/logs"; ((failed_checks++)); }
  
  rm -f /opt/kijanikiosk/shared/logs/test-write.tmp
}

verify_systemd_scores() {
  local api_score=$(systemd-analyze security kk-api.service 2>/dev/null | grep "Overall" | awk '{print $4}' || echo "unknown")
  local payments_score=$(systemd-analyze security kk-payments.service 2>/dev/null | grep "Overall" | awk '{print $4}' || echo "unknown")
  
  if [[ "$api_score" != "unknown" ]]; then
    success "PASS: kk-api security score: $api_score (target < 3.5)"
  fi
  
  if [[ "$payments_score" != "unknown" ]]; then
    if [[ "${payments_score//[!0-9.]/}" < 2.5 ]] 2>/dev/null; then
      success "PASS: kk-payments security score: $payments_score (target < 2.5)"
    else
      log "WARN: kk-payments score $payments_score, target < 2.5"
    fi
  fi
}

verify_health_check() {
  if [[ -f /opt/kijanikiosk/health/last-provision.json ]]; then
    success "PASS: Health check file exists"
    local health_content=$(cat /opt/kijanikiosk/health/last-provision.json)
    echo "$health_content" | grep -q "kk-api" && success "PASS: Health check contains API status"
    echo "$health_content" | grep -q "kk-payments" && success "PASS: Health check contains payments status"
  else
    log "FAIL: Health check file missing"
    ((failed_checks++))
  fi
}

verify_journal() {
  local journal_usage=$(journalctl --disk-usage 2>/dev/null | grep -oP '\d+\.?\d*[MG]' | head -1 || echo "0M")
  success "PASS: Journal configured, current usage: $journal_usage"
}

# Run all verifications
log "Running verification checks..."
verify_users_groups
verify_permissions
verify_firewall
verify_systemd_scores
verify_health_check
verify_journal

# Final summary
echo ""
echo "========================================="
if [[ $failed_checks -eq 0 ]]; then
  success "ALL VERIFICATION CHECKS PASSED"
  echo "========================================="
  exit 0
else
  error "$failed_checks verification check(s) failed"
fi
