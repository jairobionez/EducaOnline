# Script para testar o projeto localmente

Write-Host "=== EducaOnline - Teste Local ===" -ForegroundColor Green
Write-Host ""

# 1. Verificar RabbitMQ
Write-Host "1. Verificando RabbitMQ..." -ForegroundColor Yellow
$rabbit = docker ps | Select-String educa-rabbit
if ($rabbit) {
    Write-Host "   RabbitMQ esta rodando" -ForegroundColor Green
} else {
    Write-Host "   RabbitMQ nao encontrado" -ForegroundColor Red
    Write-Host "   Iniciando RabbitMQ..." -ForegroundColor Yellow
    docker start educa-rabbit
    Start-Sleep -Seconds 15
    Write-Host "   RabbitMQ iniciado" -ForegroundColor Green
}

Write-Host ""
Write-Host "2. RabbitMQ Management UI: http://localhost:15672" -ForegroundColor Cyan
Write-Host "   Usuário: guest | Senha: guest" -ForegroundColor Cyan
Write-Host ""

# 2. Rodar APIs
Write-Host "3. Iniciando APIs..." -ForegroundColor Yellow
Write-Host "   - Você pode executar cada API em um terminal separado" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Identidade API:" -ForegroundColor Cyan
Write-Host "   cd .\backend\src\services\EducaOnline.Identidade.API" -ForegroundColor White
Write-Host "   dotnet run" -ForegroundColor White
Write-Host ""

Write-Host "   Após Identidade estar rodando, em outro terminal:" -ForegroundColor Cyan
Write-Host "   cd .\backend\src\services\EducaOnline.Conteudo.API" -ForegroundColor White
Write-Host "   dotnet run" -ForegroundColor White
Write-Host ""

Write-Host "   E assim por diante para os demais serviços..." -ForegroundColor Cyan
Write-Host ""

# 3. Testas portas
Write-Host "4. Portas esperadas:" -ForegroundColor Yellow
Write-Host "   - Identidade:  http://localhost:5244 (ou https://localhost:7070)" -ForegroundColor Cyan
Write-Host "   - Conteúdo:    http://localhost:5105 (ou https://localhost:7183)" -ForegroundColor Cyan
Write-Host "   - Aluno:       http://localhost:5152 (ou https://localhost:7094)" -ForegroundColor Cyan
Write-Host "   - Pedidos:     http://localhost:5241 (ou https://localhost:7244)" -ForegroundColor Cyan
Write-Host "   - Financeiro:  http://localhost:5137 (ou https://localhost:7059)" -ForegroundColor Cyan
Write-Host "   - BFF:         http://localhost:5051 (ou https://localhost:7093)" -ForegroundColor Cyan
Write-Host ""

# 4. Teste de health check
Write-Host "5. Testando health check (quando a API estiver rodando):" -ForegroundColor Yellow
Write-Host "   curl http://localhost:7070/health" -ForegroundColor White
Write-Host ""

Write-Host "Pronto para testes!" -ForegroundColor Green
