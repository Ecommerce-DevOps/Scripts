$services = @(
    "api-gateway",
    "cloud-config",
    "favourite-service",
    "order-service",
    "payment-service",
    "product-service",
    "service-discovery",
    "shipping-service",
    "user-service"
)

$commitMessage = $args[0]
if (-not $commitMessage) {
    $commitMessage = "fix: pom.xml"
}

$projectRoot = "c:\Users\geoff\Documents\Projects\Ingesoft V\Proyecto Final"

Write-Host "=================================================="
Write-Host "Bulk Commit Tool (PowerShell)"
Write-Host "Project Root: $projectRoot"
Write-Host "Commit Message: $commitMessage"
Write-Host "=================================================="

foreach ($service in $services) {
    $servicePath = Join-Path $projectRoot $service
    
    if (Test-Path $servicePath) {
        Write-Host "Processing $service..."
        
        if (Test-Path (Join-Path $servicePath ".git")) {
            Push-Location $servicePath
            
            if (git status --porcelain) {
                Write-Host "  -> Changes detected. Committing..."
                git add .
                git commit -m "$commitMessage"
                Write-Host "  -> Changes committed."
            }
            else {
                Write-Host "  -> No new changes to commit."
            }
            
            Write-Host "  -> Checking for pending commits to push..."
            git push
            
            Pop-Location
        }
        else {
            Write-Host "  -> Warning: $service is not a git repository."
        }
    }
    else {
        Write-Host "  -> Error: Directory $service not found."
    }
    Write-Host "--------------------------------------------------"
}

Write-Host "Bulk commit process completed."
