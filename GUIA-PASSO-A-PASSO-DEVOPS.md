# Guia Passo a Passo: Implementando DevOps em Projetos .NET

## Pré-requisitos
- Projeto .NET funcionando localmente
- Docker Desktop instalado
- Conta no GitHub
- Conta no Docker Hub
- kubectl instalado (para Kubernetes)

---

## FASE 1: Dockerfiles

### Passo 1.1: Entender a estrutura do projeto

```bash
# Verificar onde estão os .csproj
dir -Recurse -Filter "*.csproj" | Select-Object FullName
```

### Passo 1.2: Criar Dockerfile para cada serviço

Para cada API, crie um arquivo `Dockerfile` na pasta do projeto:

```dockerfile
# ============================================
# Dockerfile Multi-Stage para API .NET
# ============================================

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copiar .csproj e restaurar dependências (cache de camadas)
COPY ["src/services/NomeDoProjeto/NomeDoProjeto.csproj", "src/services/NomeDoProjeto/"]
COPY ["src/building_blocks/Shared/Shared.csproj", "src/building_blocks/Shared/"]
RUN dotnet restore "src/services/NomeDoProjeto/NomeDoProjeto.csproj"

# Copiar todo o código e compilar
COPY . .
WORKDIR "/src/src/services/NomeDoProjeto"
RUN dotnet build -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime (imagem final pequena)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "NomeDoProjeto.dll"]
```

### Passo 1.3: Testar o build local

```bash
cd pasta-do-backend
docker build -f src/services/NomeDoProjeto/Dockerfile -t meu-projeto:teste .
docker run -p 5001:8080 meu-projeto:teste
```

### Dicas importantes:
- O `WORKDIR /src` deve corresponder aos caminhos do COPY
- Sempre copie os .csproj primeiro (otimiza cache)
- Use porta 8080 (.NET 9 padrão)

---

## FASE 2: Docker Compose

### Passo 2.1: Criar docker-compose.yml na raiz

```yaml
services:
  # Infraestrutura
  rabbitmq:
    image: rabbitmq:3-management
    container_name: meu-projeto-rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    networks:
      - meu-projeto-network

  # API exemplo
  minha-api:
    image: meuusuario/minha-api:latest
    container_name: meu-projeto-api
    ports:
      - "5001:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:8080
      - ConnectionStrings__DefaultConnection=SUA_CONNECTION_STRING
      - OutrasConfigs__Chave=valor
    depends_on:
      rabbitmq:
        condition: service_healthy
    networks:
      - meu-projeto-network

networks:
  meu-projeto-network:
    driver: bridge
```

### Passo 2.2: Identificar variáveis de ambiente necessárias

Verifique o `appsettings.json` e mapeie cada configuração:

```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "..."
  },
  "JwtSettings": {
    "Segredo": "...",
    "Emissor": "..."
  }
}
```

Vira:
```yaml
environment:
  - ConnectionStrings__DefaultConnection=...
  - JwtSettings__Segredo=...
  - JwtSettings__Emissor=...
```

**IMPORTANTE**: Use `__` (duplo underscore) para representar níveis!

### Passo 2.3: Testar localmente

```bash
docker-compose up -d
docker-compose ps
docker-compose logs -f minha-api
```

---

## FASE 3: Health Checks

### Passo 3.1: Criar arquivo HealthCheckExtensions.cs

Coloque em um projeto compartilhado (ex: WebAPI.Core):

```csharp
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using System.Text.Json;

namespace MeuProjeto.WebAPI.Core.Configuration
{
    public static class HealthCheckExtensions
    {
        public static IServiceCollection AddHealthCheckConfig(
            this IServiceCollection services, 
            IConfiguration configuration)
        {
            services.AddHealthChecks()
                .AddCheck("self", () => HealthCheckResult.Healthy("API is running"), 
                    tags: new[] { "ready", "live" });

            return services;
        }

        public static IApplicationBuilder UseHealthCheckConfig(this IApplicationBuilder app)
        {
            app.UseHealthChecks("/health", new HealthCheckOptions
            {
                Predicate = _ => true,
                ResponseWriter = WriteHealthCheckResponse
            });

            app.UseHealthChecks("/health/ready", new HealthCheckOptions
            {
                Predicate = check => check.Tags.Contains("ready"),
                ResponseWriter = WriteHealthCheckResponse
            });

            app.UseHealthChecks("/health/live", new HealthCheckOptions
            {
                Predicate = check => check.Tags.Contains("live"),
                ResponseWriter = WriteHealthCheckResponse
            });

            return app;
        }

        private static Task WriteHealthCheckResponse(HttpContext context, HealthReport report)
        {
            context.Response.ContentType = "application/json";

            var response = new
            {
                status = report.Status.ToString(),
                timestamp = DateTime.UtcNow,
                checks = report.Entries.Select(e => new
                {
                    name = e.Key,
                    status = e.Value.Status.ToString(),
                    description = e.Value.Description
                })
            };

            return context.Response.WriteAsync(
                JsonSerializer.Serialize(response, new JsonSerializerOptions { WriteIndented = true }));
        }
    }
}
```

### Passo 3.2: Registrar em cada API

No arquivo de configuração de cada API:

```csharp
// Em ConfigureServices ou AddApiConfiguration
services.AddHealthCheckConfig(configuration);

// Em Configure ou UseApiConfiguration
app.UseHealthCheckConfig();
```

### Passo 3.3: Adicionar o using

```csharp
using MeuProjeto.WebAPI.Core.Configuration;
```

### Passo 3.4: Testar

```bash
curl http://localhost:5001/health
```

---

## FASE 4: GitHub Actions CI/CD

### Passo 4.1: Criar estrutura de pastas

```bash
mkdir -p .github/workflows
```

### Passo 4.2: Criar arquivo ci-cd.yml

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  DOTNET_VERSION: '9.0.x'

jobs:
  build-and-test:
    name: Build e Testes
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Restore
        run: dotnet restore caminho/para/Solution.sln

      - name: Build
        run: dotnet build caminho/para/Solution.sln -c Release --no-restore

      - name: Test
        run: dotnet test caminho/para/Solution.sln -c Release --no-build
        continue-on-error: true

  docker-build-push:
    name: Build e Push Docker
    runs-on: ubuntu-latest
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    
    strategy:
      matrix:
        include:
          - service: minha-api
            dockerfile: caminho/para/Dockerfile
            context: caminho/contexto

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build e Push
        uses: docker/build-push-action@v5
        with:
          context: ${{ matrix.context }}
          file: ${{ matrix.dockerfile }}
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/meu-projeto-${{ matrix.service }}:latest
```

### Passo 4.3: Criar Token no Docker Hub

1. Acesse https://hub.docker.com/settings/security
2. Clique "New Access Token"
3. Nome: github-actions
4. Permissões: Read, Write, Delete
5. Copie o token!

### Passo 4.4: Configurar Secrets no GitHub

1. Vá no repositório GitHub
2. Settings → Secrets and variables → Actions
3. New repository secret:
   - `DOCKERHUB_USERNAME`: seu-usuario
   - `DOCKERHUB_TOKEN`: token-copiado

### Passo 4.5: Fazer push e verificar

```bash
git add .
git commit -m "ci: adicionar pipeline CI/CD"
git push
```

Acompanhe em: https://github.com/seu-usuario/seu-repo/actions

---

## FASE 5: Kubernetes

### Passo 5.1: Criar estrutura de pastas

```bash
mkdir -p k8s/base k8s/services
```

### Passo 5.2: Criar namespace.yaml

```yaml
# k8s/base/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: meu-projeto
```

### Passo 5.3: Criar configmap.yaml

```yaml
# k8s/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: meu-projeto-config
  namespace: meu-projeto
data:
  ASPNETCORE_ENVIRONMENT: "Development"
  ASPNETCORE_URLS: "http://+:8080"
  OUTRAS_CONFIGS: "valores"
```

### Passo 5.4: Criar secrets.yaml

```yaml
# k8s/base/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: meu-projeto-secrets
  namespace: meu-projeto
type: Opaque
stringData:
  CONNECTION_STRING: "sua-connection-string"
  JWT_SEGREDO: "sua-chave-secreta"
```

### Passo 5.5: Criar deployment para cada serviço

```yaml
# k8s/services/minha-api.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minha-api
  namespace: meu-projeto
spec:
  replicas: 2
  selector:
    matchLabels:
      app: minha-api
  template:
    metadata:
      labels:
        app: minha-api
    spec:
      containers:
        - name: minha-api
          image: meuusuario/meu-projeto-minha-api:latest
          ports:
            - containerPort: 8080
          env:
            - name: ASPNETCORE_ENVIRONMENT
              valueFrom:
                configMapKeyRef:
                  name: meu-projeto-config
                  key: ASPNETCORE_ENVIRONMENT
            - name: ConnectionStrings__DefaultConnection
              valueFrom:
                secretKeyRef:
                  name: meu-projeto-secrets
                  key: CONNECTION_STRING
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: minha-api-service
  namespace: meu-projeto
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    app: minha-api
```

### Passo 5.6: Deploy no Kubernetes

```bash
# Aplicar manifests
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/
kubectl apply -f k8s/services/

# Verificar
kubectl get pods -n meu-projeto
kubectl get svc -n meu-projeto

# Ver logs se tiver problema
kubectl logs -n meu-projeto deployment/minha-api
```

---

## Checklist Final

```
FASE 1 - Dockerfiles
[ ] Dockerfile criado para cada serviço
[ ] Build local funcionando
[ ] Imagem rodando localmente

FASE 2 - Docker Compose
[ ] docker-compose.yml criado
[ ] Variáveis de ambiente mapeadas corretamente
[ ] Todos os serviços subindo com docker-compose up

FASE 3 - Health Checks
[ ] HealthCheckExtensions.cs criado
[ ] Registrado em todas as APIs
[ ] Endpoints /health respondendo

FASE 4 - GitHub Actions
[ ] Pasta .github/workflows criada
[ ] ci-cd.yml configurado
[ ] Secrets configurados no GitHub
[ ] Pipeline executando com sucesso
[ ] Imagens sendo publicadas no Docker Hub

FASE 5 - Kubernetes
[ ] Pasta k8s/ criada
[ ] namespace.yaml
[ ] configmap.yaml
[ ] secrets.yaml
[ ] Deployment para cada serviço
[ ] Pods rodando no cluster
```

---

## Erros Comuns e Soluções

### 1. "File not found" no Dockerfile
- Verifique os caminhos do COPY
- O contexto do build deve ser a pasta pai

### 2. Variáveis de ambiente não funcionando
- Use `__` para separar níveis (ConnectionStrings__DefaultConnection)
- Verifique se o nome corresponde EXATAMENTE ao appsettings.json

### 3. Container reiniciando (CrashLoopBackOff)
- Veja os logs: `kubectl logs` ou `docker logs`
- Geralmente é erro de configuração ou conexão

### 4. Health check retornando 404
- Verifique se AddHealthCheckConfig está sendo chamado
- Verifique se UseHealthCheckConfig está sendo chamado
- Verifique a porta (8080 no .NET 9)

### 5. Git não detectando mudança de case
- Use: `git mv "antigo" "temp" && git mv "temp" "Correto"`

---

**Autor:** Fernando Vinícius Valim Motta  
**Data:** Dezembro/2024
