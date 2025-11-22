<#
Deploy script for Minikube (PowerShell)

What it does:
- Starts minikube (driver: docker)
- Builds backend and frontend Docker images locally
- Loads images into minikube
- Applies kustomize manifests in `infra/k8s/`

Requirements:
- Docker Desktop
- Minikube installed and on PATH (`minikube`)
- kubectl installed and on PATH
#>

Write-Host "Starting Minikube (driver=docker) if not running..."
minikube start --driver=docker

Write-Host "Building backend service images and loading into minikube..."

$bffServicesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\backend\src\api_gateways"
Get-ChildItem -Path $bffServicesPath -Directory | ForEach-Object {
    $svc = $_
    $dockerfile = Join-Path $svc.FullName "Dockerfile"
    if (Test-Path $dockerfile) {
        # derive a reliable image name from the folder name
        $name = (Split-Path -Path $svc.FullName -Leaf).ToLower()
        # Use string concatenation to avoid PowerShell interpreting "$name:local" as a scoped variable
        $tag = $name + ":local"
        Write-Host "Computed tag for $name => $tag"
        Write-Host "Building $name with minikube image build..."
        # Build the image inside minikube to avoid runtime differences
        $contextPath = $svc.FullName
        $filePath = $dockerfile
        $buildCmd = "minikube image build --tag `"$tag`" --file `"$filePath`" `"$contextPath`""
        Write-Host "Running: $buildCmd"
        $buildResult = & minikube image build --tag $tag --file "$filePath" "$contextPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "minikube image build failed for $name. Falling back to docker build + minikube image load." -ForegroundColor Yellow
            docker build -t "$tag" -f "$filePath" "$contextPath"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Local docker build failed for $name. See output above." -ForegroundColor Red
            } else {
                Write-Host "Loading $tag into minikube..."
                minikube image load $tag
            }
        }
    }
}


$servicesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\backend\src\services"
Get-ChildItem -Path $servicesPath -Directory | ForEach-Object {
    $svc = $_
    $dockerfile = Join-Path $svc.FullName "Dockerfile"
    if (Test-Path $dockerfile) {
        # derive a reliable image name from the folder name
        $name = (Split-Path -Path $svc.FullName -Leaf).ToLower()
        # Use string concatenation to avoid PowerShell interpreting "$name:local" as a scoped variable
        $tag = $name + ":local"
        Write-Host "Computed tag for $name => $tag"
        Write-Host "Building $name with minikube image build..."
        # Build the image inside minikube to avoid runtime differences
        $contextPath = $svc.FullName
        $filePath = $dockerfile
        $buildCmd = "minikube image build --tag `"$tag`" --file `"$filePath`" `"$contextPath`""
        Write-Host "Running: $buildCmd"
        $buildResult = & minikube image build --tag $tag --file "$filePath" "$contextPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "minikube image build failed for $name. Falling back to docker build + minikube image load." -ForegroundColor Yellow
            docker build -t "$tag" -f "$filePath" "$contextPath"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Local docker build failed for $name. See output above." -ForegroundColor Red
            } else {
                Write-Host "Loading $tag into minikube..."
                minikube image load $tag
            }
        }
    }
}

Write-Host "Building frontend image and loading into minikube..."
$frontendDocker = Join-Path -Path $PSScriptRoot -ChildPath "..\..\frontend\apps\educa-online\Dockerfile"
if (Test-Path $frontendDocker) {
    $tag = "educa-online-frontend:local"
    Write-Host "Building frontend with minikube image build..."
    $frontendContext = (Join-Path $PSScriptRoot "..\..\frontend")
    $buildResult = & minikube image build --tag "$tag" --file "$frontendDocker" "$frontendContext" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "minikube image build failed for frontend. Falling back to docker build + minikube image load." -ForegroundColor Yellow
        docker build -t "$tag" -f "$frontendDocker" "$frontendContext"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Local docker build failed for frontend. See output above." -ForegroundColor Red
        } else {
            Write-Host "Loading $tag into minikube..."
            minikube image load $tag
        }
    }
}

Write-Host "Applying kustomize manifests to Minikube..."
kubectl apply -k (Resolve-Path -Path (Join-Path $PSScriptRoot "./"))

Write-Host "Done. To access the frontend run:"
Write-Host "  minikube service frontend --url -n educaonline"
Write-Host "Or open the NodePort on the minikube VM host (port 30080)."

Write-Host "Restarting deployments to pick up local images..."
kubectl -n educaonline rollout restart deployment --selector=app
Write-Host "Waiting for rollouts to complete..."
kubectl -n educaonline rollout status deployment --timeout=120s --watch
