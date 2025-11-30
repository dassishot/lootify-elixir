# Script para popular o banco com dados iniciais
# Execute com: mix run priv/repo/seeds.exs

alias LootifyWallets.Wallets

# Criar uma wallet de teste (opcional)
# {:ok, _wallet} = Wallets.create_wallet("00000000-0000-0000-0000-000000000001")

IO.puts("Seeds executados com sucesso!")
