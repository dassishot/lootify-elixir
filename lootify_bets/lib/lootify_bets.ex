defmodule LootifyBets do
  @moduledoc """
  LootifyBets - Serviço de apostas para o sistema Lootify.

  Este serviço é responsável por:
  - Gerenciar eventos e mercados
  - Processar apostas
  - Manter cache de odds em tempo real
  - Liquidar apostas

  ## Uso por outros serviços

      # Listar eventos
      LootifyBets.Server.list_events(%{status: :live})

      # Fazer aposta
      LootifyBets.Server.place_bet(user_id, market_id, amount, "home_win")

      # Ver apostas do usuário
      LootifyBets.Server.list_user_bets(user_id)

      # Atualizar odds (real-time)
      LootifyBets.Server.update_odds(market_id, Decimal.new("2.50"))
  """

  defdelegate list_events(filters \\ %{}), to: LootifyBets.Bets
  defdelegate get_event(id), to: LootifyBets.Bets
  defdelegate create_event(attrs), to: LootifyBets.Bets

  defdelegate get_market(id), to: LootifyBets.Bets
  defdelegate create_market(attrs), to: LootifyBets.Bets
  defdelegate update_odds(market_id, odds), to: LootifyBets.Bets
  defdelegate get_current_odds(market_id), to: LootifyBets.Bets

  defdelegate place_bet(user_id, market_id, amount, selection), to: LootifyBets.Bets
  defdelegate cancel_bet(bet_id, user_id), to: LootifyBets.Bets
  defdelegate settle_bet(bet_id, result), to: LootifyBets.Bets
  defdelegate get_bet(id), to: LootifyBets.Bets
  defdelegate list_user_bets(user_id, filters \\ %{}), to: LootifyBets.Bets
end
