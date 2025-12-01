$namespace = "staging"
$projectId = "rock-fortress-479417-t5"
$manifestsDir = "c:\Users\geoff\Documents\Projects\Ingesoft V\Proyecto Final\Manifests-kubernetes-helms"

# List of apps to deploy
$apps = @(
    "zipkin",
    "discovery",
    "cloud-config",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service",
    "proxy-client",
    "api-gateway"
)

Write-Host "Starting Application Redeployment to $namespace..."

# Uninstall existing releases
Write-Host "Uninstalling existing releases..."
foreach ($app in $apps) {
    Write-Host "Uninstalling $app..."
    helm uninstall $app -n $namespace
}
# Also uninstall mysql if it was a helm release (ignore error)
helm uninstall mysql -n $namespace

# Wait a bit for cleanup
Start-Sleep -Seconds 10

# Deploy MySQL first (using manifest)
Write-Host "Deploying MySQL..."
kubectl apply -f (Join-Path $manifestsDir "mysql-staging.yaml")
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment of MySQL failed!"
    exit 1
}

# Install releases
Write-Host "Installing releases..."
foreach ($app in $apps) {
    $chartPath = Join-Path $manifestsDir $app
    Write-Host "Deploying $app from $chartPath..."
    
    $imageRepo = "us-central1-docker.pkg.dev/$projectId/ecommerce-microservices/$app"
    
    $cmd = "helm upgrade --install $app `"$chartPath`" --namespace $namespace --timeout=10m"
    
    # Add image repository override for services
    $cmd += " --set image.repository=$imageRepo"
    
    # Add spring profile
    $cmd += " --set spring.profiles.active=stage"

    Write-Host "Executing: $cmd"
    Invoke-Expression $cmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Deployment of $app failed!"
        exit 1
    }
}

Write-Host "All applications redeployed successfully!"
