#!/bin/bash

# build-and-push-all.sh
# Builds Maven projects, creates Docker images, and pushes them to Artifact Registry

set -e

PROJECT_ID="rock-fortress-479417-t5"
REPO_URL="us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-microservices"

# Navigate to project root
cd "$(dirname "$0")/.."

# List of services to build
services=(
    "service-discovery"
    "Proxy-client"
    "api-gateway"
    "cloud-config"
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
)

echo "🚀 Starting Build and Push process for ${#services[@]} services..."

# 0. Build Parent POM (General Config)
echo "--------------------------------------------------"
echo "🔨 Processing general-config (Parent POM)..."
if [ -d "general-config" ]; then
    pushd "general-config" > /dev/null
    echo "📦 Installing Parent POM..."
    mvn clean install -N
    popd > /dev/null
    echo "✅ Parent POM installed!"
else
    echo "⚠️ general-config directory not found! Build might fail if parent POM is missing."
fi

for service in "${services[@]}"; do
    echo "--------------------------------------------------"
    echo "🔨 Processing $service..."
    
    if [ ! -d "$service" ]; then
        echo "⚠️ Directory $service not found! Skipping."
        continue
    fi
    
    pushd "$service" > /dev/null
    
    # 1. Maven Build
    echo "📦 Building JAR with Maven..."
    # Prefer system maven if available, fallback to wrapper, or fail
    if command -v mvn &> /dev/null; then
        mvn clean package -DskipTests
    elif [ -f "mvnw" ]; then
        ./mvnw clean package -DskipTests
    else
        echo "❌ Maven not found (neither 'mvn' nor 'mvnw'). Skipping $service."
        popd > /dev/null
        continue
    fi
    
    # 2. Docker Build
    echo "🐳 Building Docker Image..."
    # Determine tag based on service (some use 'dev', some 'latest', aligning to 'latest' for simplicity or checking values.yaml)
    # For simplicity, we'll push both 'latest' and 'dev' to be safe
    
    # Use lowercase service name for image repo to avoid issues
    image_name=$(echo "$service" | tr '[:upper:]' '[:lower:]')
    
    # Handle special case for service-discovery -> discovery to match helm deployment expectation
    if [ "$image_name" == "service-discovery" ]; then
        image_name="discovery"
    fi
    
    docker build -t "$REPO_URL/$image_name:latest" .
    docker tag "$REPO_URL/$image_name:latest" "$REPO_URL/$image_name:dev"
    docker tag "$REPO_URL/$image_name:latest" "$REPO_URL/$image_name:latest-dev"
    
    # 3. Docker Push
    echo "⬆️ Pushing to Artifact Registry..."
    docker push "$REPO_URL/$image_name:latest"
    docker push "$REPO_URL/$image_name:dev"
    docker push "$REPO_URL/$image_name:latest-dev"
    
    popd > /dev/null
    echo "✅ $service completed!"
done

echo "--------------------------------------------------"
echo "🎉 All services built and pushed successfully!"
