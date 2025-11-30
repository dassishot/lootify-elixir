defmodule LootifyWallets do
  @moduledoc """
  LootifyWallets - Serviço de carteiras para o sistema Lootify.

  Este serviço é responsável por:
  - Gerenciar saldos de usuários
  - Processar créditos e débitos
  - Reservar e liberar valores para apostas
  - Garantir consistência transacional

  ## Uso por outros serviços

  Outros serviços no cluster podem usar as funções através do Server:

      # Criar wallet
      LootifyWallets.Server.create_wallet(user_id)

      # Creditar
      LootifyWallets.Server.credit(user_id, Decimal.new("100.00"), reference_id)

      # Reservar para aposta
      LootifyWallets.Server.reserve(user_id, Decimal.new("50.00"), bet_id)

      # Liberar (aposta cancelada)
      LootifyWallets.Server.release(user_id, bet_id)

      # Confirmar (aposta perdida)
      LootifyWallets.Server.confirm(user_id, bet_id)

      # Ver saldo
      LootifyWallets.Server.get_balance(user_id)
  """

  defdelegate create_wallet(user_id), to: LootifyWallets.Wallets
  defdelegate get_wallet(id), to: LootifyWallets.Wallets
  defdelegate get_wallet_by_user_id(user_id), to: LootifyWallets.Wallets
  defdelegate get_balance(user_id), to: LootifyWallets.Wallets
  defdelegate credit(user_id, amount, reference_id, description \\ "Crédito"), to: LootifyWallets.Wallets
  defdelegate debit(user_id, amount, reference_id, description \\ "Débito"), to: LootifyWallets.Wallets
  defdelegate reserve(user_id, amount, reference_id, description \\ "Reserva"), to: LootifyWallets.Wallets
  defdelegate release(user_id, reference_id, description \\ "Liberação"), to: LootifyWallets.Wallets
  defdelegate confirm(user_id, reference_id, description \\ "Confirmação"), to: LootifyWallets.Wallets
end
