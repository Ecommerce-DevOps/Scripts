#!/bin/bash

# deploy-apps.sh
# Deploys all microservices and infrastructure components using Helm

# Exit on error
set -e

# Navigate to project root
cd "$(dirname "$0")/../.."

NAMESPACE="staging"
PROJECT_ID="rock-fortress-479417-t5"

echo "🚀 Starting Application Deployment to $NAMESPACE..."

# Ensure namespace exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Helper function to deploy a chart
deploy_chart() {
    local app_name=$1
    local chart_path=$2
    
    echo "📦 Deploying $app_name..."
    
    # Construct helm command
    local helm_cmd="helm upgrade --install $app_name $chart_path --namespace $NAMESPACE --wait --timeout=5m"
    
    # Only override image repository for internal services (including zipkin now)
    helm_cmd="$helm_cmd --set image.repository=us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-microservices/$app_name"
    
    # Execute command
    if ! $helm_cmd; then
        echo "❌ Deployment of $app_name failed!"
        echo "🔍 Debugging info:"
        echo "--- Pod Status ---"
        kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$app_name
        echo "--- Pod Events ---"
        kubectl describe pods -n $NAMESPACE -l app.kubernetes.io/name=$app_name | grep -A 20 "Events:"
        echo "--- Pod Logs ---"
        kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=$app_name --tail=50
        exit 1
    fi
}

# 1. Observability & Infrastructure
echo "--- Infrastructure Components ---"
deploy_chart "zipkin" "Manifests/zipkin"
deploy_chart "discovery" "Manifests/discovery"
# deploy_chart "cloud-config" "Manifests/cloud-config" # Uncomment if you have this manifest

# 2. Core Services (Order matters for dependencies)
echo "--- Core Services ---"
deploy_chart "user-service" "Manifests/user-service"
deploy_chart "product-service" "Manifests/product-service"
deploy_chart "order-service" "Manifests/order-service"
deploy_chart "payment-service" "Manifests/payment-service"
deploy_chart "shipping-service" "Manifests/shipping-service"
deploy_chart "favourite-service" "Manifests/favourite-service"

# 3. Gateway / Proxy
echo "--- Gateway ---"
# Deploy proxy-client with staging values (NoSecurity for tests) or default
deploy_chart "proxy-client" "Manifests/proxy-client"

echo "✅ All applications deployed successfully!"
