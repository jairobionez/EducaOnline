# Build and (optionally) load images into Minikube
# Run this from repository root: `powershell -ExecutionPolicy Bypass -File infra\k8s\build-and-load-images.ps1`

$services = @(
    @{ name = 'educaonline.identidade.api'; path = 'backend/src/services/EducaOnline.Identidade.API' },
    @{ name = 'educaonline.conteudo.api'; path = 'backend/src/services/EducaOnline.Conteudo.API' },
    @{ name = 'educaonline.aluno.api'; path = 'backend/src/services/EducaOnline.Aluno.API' },
    @{ name = 'educaonline.financeiro.api'; path = 'backend/src/services/EducaOnline.Financeiro.API' },
    @{ name = 'educaonline.pedidos.api'; path = 'backend/src/services/Educaonline.Pedidos.API' },
    @{ name = 'educa-online-frontend'; path = 'frontend/apps/educa-online' },
    @{ name = 'nginx-custom'; path = 'infra/nginx' }
    @{ name = 'rabbitmq-custom'; path = 'infra/rabbitmq' }
    @{ name = 'educaonline.bff'; path = 'backend/src/api-gateways/EducaOnline.Bff' }
)

function CommandExists($cmd) {
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

$hasMinikube = CommandExists 'minikube'
$hasDocker = CommandExists 'docker'

# repo root (two levels up from infra/k8s)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

if (-not $hasDocker) {
    Write-Error "Docker não foi encontrado no PATH. Instale o Docker Desktop antes de prosseguir."
    exit 1
}

foreach ($s in $services) {
    $imageTag = "$($s.name):local"
    $buildPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\$($s.path)" | Resolve-Path -ErrorAction SilentlyContinue
    if (-not $buildPath) {
        Write-Warning "Caminho não encontrado para $($s.name): $($s.path). Pulando."
        continue
    }
    $buildPath = $buildPath.Path

    # Build with Docker locally (use repo root as context if Dockerfile references repo paths)

    Write-Host "Docker build: $imageTag from $buildPath"
    try {
        $dockerfilePath = Join-Path $buildPath 'Dockerfile'
        if (-not (Test-Path $dockerfilePath)) {
            # fallback: try to find Dockerfile in buildPath
            Write-Warning "Dockerfile não encontrado em $buildPath. Pulando $imageTag."
            continue
        }

        # choose appropriate build context to match Dockerfile COPY paths
        if ($s.path -like 'backend/*') {
            $buildContext = Join-Path $repoRoot 'backend'
        } elseif ($s.path -like 'frontend/*') {
            # Use the frontend folder as build context so Dockerfile COPY paths (package.json, libs, nx.json) resolve
            $buildContext = Join-Path $repoRoot 'frontend'
        } elseif ($s.path -like 'infra/*') {
            $buildContext = $buildPath
        } else {
            $buildContext = $repoRoot
        }

        $relDockerfile = $dockerfilePath.Substring($buildContext.Length + 1) -replace '\\','/'
        Push-Location $buildContext
        & docker build -t $imageTag -f $relDockerfile .
        $dockerExit = $LASTEXITCODE
        Pop-Location

        if ($dockerExit -ne 0) { throw 'docker build falhou' }
        Write-Host "Docker build OK: $imageTag"
    } catch {
        Write-Error ("Falha ao buildar {0}: {1}" -f $imageTag, $_)
        continue
    }

    if ($hasMinikube) {
        Write-Host "Carregando imagem no Minikube: $imageTag"
        & minikube image load $imageTag
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "minikube image load falhou para $imageTag. Verifique o estado do minikube."
        } else {
            Write-Host "Imagem carregada no Minikube: $imageTag"
        }
    } else {
        Write-Host "Minikube não encontrado: imagem construída localmente como $imageTag."
        Write-Host "Se estiver usando Minikube, instale/ative o Minikube e rode: minikube image load $imageTag"
    }
}

Write-Host "Builds finalizados. Para redeploy no cluster execute: kubectl rollout restart deployment --all -n educaonline"
