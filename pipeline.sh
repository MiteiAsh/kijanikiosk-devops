#!/bin/bash

set -e

echo "==================================="
echo "KijaniKiosk Infrastructure Pipeline"
echo "==================================="

cd form

echo ""
echo "Initializing Terraform..."
terraform init

echo ""
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo ""
echo "Extracting server IPs..."
API_IP=$(terraform output -raw api_server_ip 2>/dev/null)
PAYMENTS_IP=$(terraform output -raw payments_server_ip 2>/dev/null)
LOGS_IP=$(terraform output -raw logs_server_ip 2>/dev/null)

echo "API Server IP: $API_IP"
echo "Payments Server IP: $PAYMENTS_IP"
echo "Logs Server IP: $LOGS_IP"

echo ""
echo "Generating Ansible inventory..."
cat > ../ansible/inventory.ini << INVENTORY
[kijanikiosk]
api-server ansible_host=$API_IP
payments-server ansible_host=$PAYMENTS_IP
logs-server ansible_host=$LOGS_IP

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/kijani-key
ansible_python_interpreter=/usr/bin/python3
INVENTORY

cd ..

echo ""
echo "Waiting for SSH to be available (60 seconds)..."
sleep 60

echo ""
echo "Testing SSH connection..."
for ip in $API_IP $PAYMENTS_IP $LOGS_IP; do
    echo "Checking $ip..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/kijani-key ubuntu@$ip "echo 'SSH works on $ip'" || echo "Warning: SSH not ready on $ip"
done

echo ""
echo "Running Ansible playbook..."
ansible-playbook -i ansible/inventory.ini ansible/kijaniikiosk.yml

echo ""
echo "==================================="
echo "Pipeline completed successfully!"
echo "==================================="
