#!/bin/bash

# start-infra.sh
# Starts the infrastructure by scaling node pools back to original size

# Configuration
CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"
NODE_POOL="general-pool-pool" # Terraform appends -pool to the name defined in variables
TARGET_NODES=8

echo "Starting infrastructure (Scaling to $TARGET_NODES nodes)..."

gcloud container clusters resize $CLUSTER_NAME \
    --node-pool $NODE_POOL \
    --num-nodes $TARGET_NODES \
    --region $REGION \
    --quiet

echo "Infrastructure started."
