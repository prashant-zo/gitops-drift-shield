#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
TF_DIR="terraform/environments/${ENVIRONMENT}"
INVENTORY_FILE="ansible/inventories/${ENVIRONMENT}/hosts.ini"

mkdir -p "ansible/inventories/${ENVIRONMENT}"

echo "Fetching IPs from Terraform..."

echo "[app]" > "$INVENTORY_FILE"

terraform -chdir="$TF_DIR" output -json public_ips | jq -r '.[]' >> "$INVENTORY_FILE"

echo "" >> "$INVENTORY_FILE"
echo "[app:vars]" >> "$INVENTORY_FILE"
echo "ansible_user=ubuntu" >> "$INVENTORY_FILE"
echo "ansible_ssh_private_key_file=~/.ssh/gitops-drift-shield-dev.pem" >> "$INVENTORY_FILE"
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> "$INVENTORY_FILE"

echo "✅ Inventory successfully written to $INVENTORY_FILE"
cat "$INVENTORY_FILE"
