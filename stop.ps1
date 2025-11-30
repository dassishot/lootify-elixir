# Script para parar todos os serviços Lootify
Write-Host "🛑 Parando Lootify..." -ForegroundColor Yellow

docker-compose down

Write-Host "`n✅ Lootify parado!" -ForegroundColor Green

