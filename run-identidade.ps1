#!/usr/bin/env pwsh
# Script para rodar a API de Identidade

$IdentidadeDir = "F:\MBA\EducaOnline\backend\src\services\EducaOnline.Identidade.API"

Write-Host "Iniciando API de Identidade..." -ForegroundColor Green
Write-Host "Diretório: $IdentidadeDir" -ForegroundColor Yellow

Set-Location $IdentidadeDir
$env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet run
