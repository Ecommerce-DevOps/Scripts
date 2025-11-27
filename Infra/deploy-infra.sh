#!/bin/bash

# deploy-infra.sh
# Deploys the infrastructure using Terraform

# Exit on error
set -e

echo "Starting infrastructure deployment..."

# Navigate to Infrastructure directory
cd "$(dirname "$0")/../Infrastructure"

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Infrastructure deployment completed successfully."
