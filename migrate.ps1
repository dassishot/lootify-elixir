# Script para rodar todas as migrations
Write-Host "Running migrations..." -ForegroundColor Cyan

Write-Host "`n[Wallets]" -ForegroundColor Yellow
docker-compose exec wallets bin/lootify_wallets eval "LootifyWallets.Release.migrate()"

Write-Host "`n[Users]" -ForegroundColor Yellow
docker-compose exec users bin/lootify_users eval "LootifyUsers.Release.migrate()"

Write-Host "`n[Bets]" -ForegroundColor Yellow
docker-compose exec bets bin/lootify_bets eval "LootifyBets.Release.migrate()"

Write-Host "`nMigrations completed!" -ForegroundColor Green

