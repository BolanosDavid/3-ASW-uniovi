#!/bin/bash
# Apply Terraform configuration and display outputs
# Author: UO302313 - David Fernando Bolaños López

set -e

cd "$(dirname "$0")/../terraform"

echo "==> Applying Terraform configuration..."
echo ""

terraform apply -auto-approve

echo ""
echo "==> Deployment completed successfully!"
echo ""
echo "--- Infrastructure Outputs ---"
terraform output
echo "------------------------------"
echo ""
echo "Next steps:"
echo "  1. Generate Ansible inventory: ./scripts/generate-inventory.sh"
echo "  2. Configure VM: ./scripts/ansible-run.sh"
echo "  3. Verify deployment: ./scripts/verify-deployment.sh"
echo ""
