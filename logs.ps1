# Script para ver logs de todos os serviços
param(
    [string]$Service = ""
)

if ($Service -eq "") {
    Write-Host "📋 Logs de todos os serviços (Ctrl+C para sair):" -ForegroundColor Cyan
    docker-compose logs -f
} else {
    Write-Host "📋 Logs do serviço $Service (Ctrl+C para sair):" -ForegroundColor Cyan
    docker-compose logs -f $Service
}

