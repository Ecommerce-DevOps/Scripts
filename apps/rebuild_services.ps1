$ErrorActionPreference = "Stop"

Write-Host "Rebuilding Shipping Service..."
Set-Location "shipping-service"
cmd /c "mvn clean package -DskipTests"
docker build -t us-central1-docker.pkg.dev/rock-fortress-479417-t5/ecommerce-microservices/shipping-service:latest-dev .
docker push us-central1-docker.pkg.dev/rock-fortress-479417-t5/ecommerce-microservices/shipping-service:latest-dev
Set-Location ..

Write-Host "Rebuilding Proxy Client..."
Set-Location "proxy-client"
cmd /c "mvn clean package -DskipTests"
docker build -t us-central1-docker.pkg.dev/rock-fortress-479417-t5/ecommerce-microservices/proxy-client:dev .
docker push us-central1-docker.pkg.dev/rock-fortress-479417-t5/ecommerce-microservices/proxy-client:dev
Set-Location ..

Write-Host "Rebuild Complete!"
