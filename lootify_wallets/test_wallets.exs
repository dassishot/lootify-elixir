user_id = Ecto.UUID.generate()
IO.puts("Criando wallet para user: #{user_id}")

{:ok, wallet} = LootifyWallets.create_wallet(user_id)
IO.puts("Wallet criada: #{wallet.id}")

{:ok, result} = LootifyWallets.credit(user_id, Decimal.new("100.00"), Ecto.UUID.generate(), "Deposito inicial")
IO.puts("Credito realizado. Novo saldo: #{result.wallet.balance}")

{:ok, balance} = LootifyWallets.get_balance(user_id)
IO.puts("Saldo disponivel: #{balance.available}")
IO.puts("Saldo bloqueado: #{balance.locked}")

bet_id = Ecto.UUID.generate()
{:ok, result} = LootifyWallets.reserve(user_id, Decimal.new("50.00"), bet_id, "Reserva para aposta")
IO.puts("Reserva realizada. Balance: #{result.wallet.balance}, Locked: #{result.wallet.locked}")

{:ok, balance} = LootifyWallets.get_balance(user_id)
IO.puts("Apos reserva - Disponivel: #{balance.available}, Bloqueado: #{balance.locked}")

# Testa liberação
{:ok, result} = LootifyWallets.release(user_id, bet_id, "Aposta cancelada")
IO.puts("Liberacao realizada. Balance: #{result.wallet.balance}, Locked: #{result.wallet.locked}")

IO.puts("\n✅ Serviço de Wallets funcionando corretamente!")
