# Script para iniciar todos os serviços Lootify
Write-Host "🚀 Iniciando Lootify..." -ForegroundColor Cyan

# Parar containers existentes
Write-Host "`n📦 Parando containers existentes..." -ForegroundColor Yellow
docker-compose down

# Buildar e iniciar
Write-Host "`n🔨 Construindo e iniciando serviços..." -ForegroundColor Yellow
docker-compose up --build -d

# Aguardar serviços iniciarem
Write-Host "`n⏳ Aguardando serviços iniciarem..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar status
Write-Host "`n📊 Status dos serviços:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n✅ Lootify iniciado!" -ForegroundColor Green
Write-Host "`n📡 API disponível em: http://localhost:4000" -ForegroundColor Cyan
Write-Host "🔌 WebSocket em: ws://localhost:4000/socket" -ForegroundColor Cyan
Write-Host "`n📋 Logs: docker-compose logs -f" -ForegroundColor Gray

