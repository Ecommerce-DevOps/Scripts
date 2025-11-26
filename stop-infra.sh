#!/bin/bash

# stop-infra.sh
# Stops the infrastructure by scaling node pools to 0 to save costs

# Configuration
CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"
NODE_POOL="general-pool-pool" # Terraform appends -pool to the name defined in variables

echo "Stopping infrastructure (Scaling to 0 nodes)..."

gcloud container clusters resize $CLUSTER_NAME \
    --node-pool $NODE_POOL \
    --num-nodes 0 \
    --region $REGION \
    --quiet

echo "Infrastructure stopped."
