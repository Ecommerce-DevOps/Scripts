# Script para actualizar todos los microservicios en staging con Helm
# Este script hace upgrade de todos los servicios para que usen el perfil 'stage'

$ErrorActionPreference = "Continue"

# Configuración
$NAMESPACE = "staging"
$HELM_DIR = "c:\Users\geoff\Documents\Projects\Ingesoft V\Proyecto Final\Manifests-kubernetes-helms"

# Lista de servicios a actualizar
$SERVICES = @(
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Actualizando microservicios en staging" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio de Helm
Set-Location $HELM_DIR

foreach ($service in $SERVICES) {
    Write-Host ">>> Actualizando $service..." -ForegroundColor Yellow
    
    # Hacer helm upgrade
    helm upgrade $service ./$service -n $NAMESPACE
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $service actualizado correctamente" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Error actualizando $service" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Esperando que los pods se reinicien..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Esperar a que todos los deployments estén listos
foreach ($service in $SERVICES) {
    Write-Host ">>> Esperando $service..." -ForegroundColor Yellow
    kubectl rollout status deployment/$service -n $NAMESPACE --timeout=180s
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $service está listo" -ForegroundColor Green
    }
    else {
        Write-Host "✗ $service no está listo" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificando perfiles de Spring..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que todos usen el perfil 'stage'
foreach ($service in $SERVICES) {
    Write-Host ">>> Verificando $service..." -ForegroundColor Yellow
    
    $profile = kubectl exec -n $NAMESPACE deployment/$service -- env | Select-String "SPRING_PROFILES_ACTIVE"
    
    if ($profile -match "stage") {
        Write-Host "✓ $service usando perfil: $profile" -ForegroundColor Green
    }
    else {
        Write-Host "✗ $service usando perfil incorrecto: $profile" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Probando endpoints..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Probar algunos endpoints
Write-Host ">>> Probando product-service..." -ForegroundColor Yellow
kubectl run test-product --image=curlimages/curl:latest -n $NAMESPACE --rm -i --restart=Never -- `
    curl -s -w "\nStatus: %{http_code}\n" http://api-gateway:8080/product-service/api/products

Write-Host ""
Write-Host ">>> Probando user-service..." -ForegroundColor Yellow
kubectl run test-user --image=curlimages/curl:latest -n $NAMESPACE --rm -i --restart=Never -- `
    curl -s -w "\nStatus: %{http_code}\n" http://api-gateway:8080/user-service/api/users

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "¡Actualización completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
