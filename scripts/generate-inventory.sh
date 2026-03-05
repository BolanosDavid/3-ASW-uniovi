#!/bin/bash
# Generate Ansible inventory from Terraform outputs
# Author: UO302313 - David Fernando Bolaños López

set -e

PROJECT_ROOT="$(dirname "$0")/.."
INVENTORY_DIR="$PROJECT_ROOT/ansible/inventories/generated"
INVENTORY_FILE="$INVENTORY_DIR/inventory.ini"

cd "$PROJECT_ROOT/terraform"

echo "==> Extracting outputs from Terraform..."

# Get outputs from Terraform (singular values now)
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "")
ADMIN_USER=$(terraform output -raw admin_username 2>/dev/null || echo "azureuser")
VM_NAME=$(terraform output -raw vm_name 2>/dev/null || echo "asw-lab3-vm")

if [ -z "$PUBLIC_IP" ]; then
    echo "ERROR: Could not get public IP from Terraform outputs"
    echo "Make sure you have run 'terraform apply' successfully"
    exit 1
fi

if [ -z "$ADMIN_USER" ]; then
    echo "WARNING: Could not get admin username, using default: azureuser"
    ADMIN_USER="azureuser"
fi

mkdir -p "$INVENTORY_DIR"

echo "==> Generating Ansible inventory..."

# Generate inventory file for single VM
cat > "$INVENTORY_FILE" <<EOL
# Auto-generated Ansible inventory
# Generated on: $(date)
# VM: $VM_NAME

[deployment_vm]
$VM_NAME ansible_host=$PUBLIC_IP ansible_user=$ADMIN_USER ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOL

echo ""
echo "✓ Inventory generated successfully at: $INVENTORY_FILE"
echo ""
echo "--- Generated Inventory ---"
cat "$INVENTORY_FILE"
echo "---------------------------"
echo ""
echo "Next step: Run Ansible playbook with:"
echo "  cd ansible && ansible-playbook playbooks/site.yml"
echo ""
