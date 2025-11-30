#!/bin/sh
set -e

# Iniciar EPMD em background
epmd -daemon

# Aguardar EPMD estar pronto
sleep 1

# Iniciar a aplicação
exec bin/lootify_bets start

