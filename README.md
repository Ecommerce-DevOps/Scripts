# Automation Scripts

This directory contains the automation scripts for the project, organized by their function (Infrastructure vs Applications).

**Strategy: Build Once, Deploy Many**
We separate the build process from the deployment process. Images are built and pushed to the Artifact Registry once, and then the same immutable image is deployed to various environments (Staging, Production) using Helm.

## Directory Structure

### apps/
Contains scripts for application lifecycle management (Build, Deploy, Verify).

- **build-and-push-all.sh**
  - **Purpose**: Compiles all microservices (Maven), builds Docker images, and pushes them to Google Artifact Registry.
  - **Usage**: `./apps/build-and-push-all.sh`
  - **When to run**: When code changes or new dependencies are added.

- **deploy-apps.sh**
  - **Purpose**: Deploys all microservices and infrastructure components (Zipkin, Discovery, etc.) to the Kubernetes cluster using Helm.
  - **Usage**: `./apps/deploy-apps.sh`
  - **When to run**: To deploy the latest images from the registry to the cluster.

- **check-app-health.sh**
  - **Purpose**: Verifies the status of pods, services, and checks for recent errors in logs.
  - **Usage**: `./apps/check-app-health.sh`
  - **When to run**: After deployment to verify system stability.

### Infra/
Contains scripts for underlying infrastructure management (Terraform & GKE).

- **deploy-infra.sh**
  - **Purpose**: Provisions the GKE cluster and networking using Terraform.
  - **Usage**: `./Infra/deploy-infra.sh`

- **monitor-infra.sh**
  - **Purpose**: Checks the health status of Kubernetes nodes and system components.
  - **Usage**: `./Infra/monitor-infra.sh`

- **destroy-infra.sh**
  - **Purpose**: Destroys all infrastructure resources (Use with caution).
  - **Usage**: `./Infra/destroy-infra.sh`

- **stop-infra.sh**
  - **Purpose**: Scales the node pool to 0 to save costs when not in use.
  - **Usage**: `./Infra/stop-infra.sh`

- **start-infra.sh**
  - **Purpose**: Scales the node pool back to 8 nodes to resume operations.
  - **Usage**: `./Infra/start-infra.sh`

- **generate-release-notes.sh**
  - **Purpose**: Generates release notes based on git commits.
  - **Usage**: `./Infra/generate-release-notes.sh`

## Prerequisites
- gcloud CLI installed and authenticated
- kubectl installed
- Terraform installed
- Docker installed
- Maven installed
