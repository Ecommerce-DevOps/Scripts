# Infrastructure Management Scripts

This directory contains scripts to manage the lifecycle of the infrastructure.

## Available Scripts

### deploy-infra.sh
Provisions the infrastructure using Terraform.
Usage: `./deploy-infra.sh`

### monitor-infra.sh
Checks the health status of nodes, pods, and services.
Usage: `./monitor-infra.sh`

### destroy-infra.sh
Tears down all infrastructure resources.
Usage: `./destroy-infra.sh`

### stop-infra.sh
Scales the node pool to 0 to save costs without destroying the cluster control plane.
Usage: `./stop-infra.sh`

### start-infra.sh
Scales the node pool back to 8 nodes to resume operations.
Usage: `./start-infra.sh`

## Prerequisites
- gcloud CLI installed and authenticated
- kubectl installed
- Terraform installed
