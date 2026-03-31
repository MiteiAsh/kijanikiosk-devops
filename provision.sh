#!/bin/bash

# Expected dirty conditions found in pre-provisioning audit:

# - kk-api, kk-payments, kk-logs users already exist: handled with existence checks before creation
# - kijanikiosk group already exists: handled with group existence check
# - /opt/kijanikiosk directory structure already exists: script ensures correct ownership and permissions
# - /opt/kijanikiosk/config has overly permissive 777 permissions: corrected to secure permissions in provisioning
# - /opt/kijanikiosk/shared/logs missing required ACL entries for service users: fixed during ACL configuration
# - UFW firewall is inactive: will be enabled and configured
# - curl package is on hold: will be unheld before package management steps

echo "Starting provisioning..."
echo "Phase 1: Ensuring users and group exist..."

# Create group if it doesn't exist
if ! getent group kijanikiosk > /dev/null; then
    echo "Creating group kijanikiosk"
    sudo groupadd kijanikiosk
else
    echo "Group kijanikiosk already exists"
fi

# Create users if they don't exist
for user in kk-api kk-payments kk-logs; do
    if ! id "$user" > /dev/null 2>&1; then
        echo "Creating user $user"
        sudo useradd -m -s /bin/bash "$user"
    else
        echo "User $user already exists"
    fi
done
echo "Phase 2: Ensuring directory structure and permissions..."

# Create directory structure if missing
sudo mkdir -p /opt/kijanikiosk/config
sudo mkdir -p /opt/kijanikiosk/shared/logs

# Set ownership
sudo chown -R root:kijanikiosk /opt/kijanikiosk

# Fix permissions
sudo chmod 750 /opt/kijanikiosk
sudo chmod 750 /opt/kijanikiosk/config
sudo chmod 750 /opt/kijanikiosk/shared
sudo chmod 750 /opt/kijanikiosk/shared/logs

echo "Directory structure and permissions configured"
