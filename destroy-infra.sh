#!/bin/bash

# destroy-infra.sh
# Destroys the infrastructure using Terraform

# Exit on error
set -e

echo "WARNING: This will destroy all infrastructure!"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

echo "Starting infrastructure destruction..."

# Navigate to Infrastructure directory
cd "$(dirname "$0")/../Infrastructure"

echo "Destroying Terraform resources..."
terraform destroy -auto-approve

echo "Infrastructure destruction completed."
