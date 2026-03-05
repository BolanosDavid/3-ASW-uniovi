#!/bin/bash
# Verify deployment of VM and Docker installation
# Author: UO302313 - David Fernando Bolaños López

set -e

PROJECT_ROOT="$(dirname "$0")/.."
cd "$PROJECT_ROOT/terraform"

echo "==> Verifying deployment..."
echo ""

# Get outputs from Terraform
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "")
ADMIN_USER=$(terraform output -raw admin_username 2>/dev/null || echo "azureuser")
VM_NAME=$(terraform output -raw vm_name 2>/dev/null || echo "unknown")

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ ERROR: Cannot retrieve public IP from Terraform outputs"
    echo "   Make sure you have run 'terraform apply' successfully"
    exit 1
fi

echo "✓ VM Name: $VM_NAME"
echo "✓ Public IP: $PUBLIC_IP"
echo "✓ Admin User: $ADMIN_USER"
echo ""

# Test SSH connectivity
echo "==> Testing SSH connectivity..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes "$ADMIN_USER@$PUBLIC_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✓ SSH connectivity: OK"
else
    echo "⚠️  SSH connectivity: FAILED"
    echo "   The VM might still be booting. Wait 1-2 minutes and try again."
    echo "   Or check if your SSH key is configured correctly."
    exit 1
fi

echo ""
echo "==> Checking installed software..."

# Check Docker
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ADMIN_USER@$PUBLIC_IP" "docker --version" 2>/dev/null; then
    echo "✓ Docker: Installed"
    DOCKER_INSTALLED=true
else
    echo "⚠️  Docker: Not installed"
    echo "   Run Ansible playbook to install Docker: ./scripts/ansible-run.sh"
    DOCKER_INSTALLED=false
fi

# Check Docker Compose if Docker is installed
if [ "$DOCKER_INSTALLED" = true ]; then
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ADMIN_USER@$PUBLIC_IP" "docker compose version" 2>/dev/null; then
        echo "✓ Docker Compose: Installed"
    else
        echo "⚠️  Docker Compose: Not installed"
    fi
fi

# Check firewall
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ADMIN_USER@$PUBLIC_IP" "sudo ufw status | grep -q 'Status: active'" 2>/dev/null; then
    echo "✓ Firewall (UFW): Active"
else
    echo "⚠️  Firewall (UFW): Not active or not configured"
    echo "   Run Ansible playbook to configure firewall: ./scripts/ansible-run.sh"
fi

echo ""
echo "==> Verification completed"
echo ""

if [ "$DOCKER_INSTALLED" = true ]; then
    echo "✓ VM is ready for Docker deployments!"
    echo ""
    echo "Connect with:"
    echo "  ssh $ADMIN_USER@$PUBLIC_IP"
    echo ""
    echo "Deploy an application:"
    echo "  1. SSH to the VM"
    echo "  2. Create a docker-compose.yml file"
    echo "  3. Run: docker compose up -d"
else
    echo "⚠️  VM needs configuration. Run:"
    echo "  ./scripts/generate-inventory.sh"
    echo "  ./scripts/ansible-run.sh"
fi

echo ""
