defmodule LootifyBets.Bets do
  @moduledoc """
  Contexto de Bets - contém toda a lógica de negócio.
  """

  import Ecto.Query
  require Logger

  alias LootifyBets.Repo
  alias LootifyBets.Domain.{Event, Market, Bet}
  alias LootifyBets.OddsCache

  # ============================================
  # Events
  # ============================================

  def list_events(filters \\ %{}) do
    query =
      from e in Event,
        order_by: [asc: e.starts_at],
        preload: [:markets]

    query =
      case Map.get(filters, :status) do
        nil -> query
        status -> from e in query, where: e.status == ^status
      end

    query =
      case Map.get(filters, :category) do
        nil -> query
        category -> from e in query, where: e.category == ^category
      end

    Repo.all(query)
  end

  def get_event(id) do
    case Repo.get(Event, id) |> Repo.preload(:markets) do
      nil -> {:error, :not_found}
      event -> {:ok, event}
    end
  end

  def create_event(attrs) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_event_status(event_id, status) do
    with {:ok, event} <- get_event(event_id) do
      event
      |> Event.update_status_changeset(status)
      |> Repo.update()
    end
  end

  # ============================================
  # Markets
  # ============================================

  def get_market(id) do
    case Repo.get(Market, id) do
      nil -> {:error, :not_found}
      market -> {:ok, market}
    end
  end

  def create_market(attrs) do
    result =
      %Market{}
      |> Market.create_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, market} ->
        OddsCache.put(market.id, market.odds)
        {:ok, market}

      error ->
        error
    end
  end

  def update_odds(market_id, new_odds) do
    with {:ok, market} <- get_market(market_id) do
      result =
        market
        |> Market.update_odds_changeset(new_odds)
        |> Repo.update()

      case result do
        {:ok, updated_market} ->
          OddsCache.put(market_id, new_odds)
          {:ok, updated_market}

        error ->
          error
      end
    end
  end

  def get_current_odds(market_id) do
    OddsCache.get(market_id)
  end

  # ============================================
  # Bets
  # ============================================

  @doc """
  Realiza uma aposta.
  1. Valida se o mercado está aberto
  2. Busca odds atuais do cache
  3. Chama WalletService para reservar o valor
  4. Cria a aposta
  """
  def place_bet(user_id, market_id, amount, selection) do
    Repo.transaction(fn ->
      with {:ok, market} <- get_market(market_id),
           true <- Market.open?(market),
           {:ok, event} <- get_event(market.event_id),
           true <- Event.open_for_betting?(event),
           {:ok, current_odds} <- get_current_odds(market_id),
           :ok <- reserve_wallet(user_id, amount) do
        bet_attrs = %{
          user_id: user_id,
          event_id: event.id,
          market_id: market_id,
          amount: amount,
          odds: current_odds,
          selection: selection
        }

        case create_bet(bet_attrs) do
          {:ok, bet} ->
            # Notifica via PubSub
            Phoenix.PubSub.broadcast(
              LootifyBets.PubSub,
              "user:#{user_id}",
              {:bet_placed, bet}
            )

            bet

          {:error, changeset} ->
            # Libera a reserva se falhar
            release_wallet(user_id, amount)
            Repo.rollback(changeset)
        end
      else
        false -> Repo.rollback(:market_closed)
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Cancela uma aposta pendente.
  """
  def cancel_bet(bet_id, user_id) do
    Repo.transaction(fn ->
      with {:ok, bet} <- get_bet(bet_id),
           true <- bet.user_id == user_id,
           true <- Bet.can_cancel?(bet),
           :ok <- release_wallet(user_id, bet.id) do
        bet
        |> Bet.cancel_changeset()
        |> Repo.update!()
      else
        false -> Repo.rollback(:unauthorized)
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Liquida uma aposta (won/lost).
  """
  def settle_bet(bet_id, result) when result in [:won, :lost] do
    with {:ok, bet} <- get_bet(bet_id),
         true <- Bet.pending?(bet) do
      Repo.transaction(fn ->
        updated_bet =
          bet
          |> Bet.settle_changeset(result)
          |> Repo.update!()

        if result == :won do
          # Credita os ganhos
          credit_wallet(bet.user_id, bet.potential_win, bet.id)
        else
          # Confirma a reserva (remove do locked)
          confirm_wallet(bet.user_id, bet.id)
        end

        # Notifica o usuário
        Phoenix.PubSub.broadcast(
          LootifyBets.PubSub,
          "user:#{bet.user_id}",
          {:bet_settled, updated_bet}
        )

        updated_bet
      end)
    else
      false -> {:error, :already_settled}
      error -> error
    end
  end

  def get_bet(id) do
    case Repo.get(Bet, id) do
      nil -> {:error, :not_found}
      bet -> {:ok, bet}
    end
  end

  def list_user_bets(user_id, filters \\ %{}) do
    query =
      from b in Bet,
        where: b.user_id == ^user_id,
        order_by: [desc: b.inserted_at],
        preload: [:event, :market]

    query =
      case Map.get(filters, :status) do
        nil -> query
        status -> from b in query, where: b.status == ^status
      end

    Repo.all(query)
  end

  defp create_bet(attrs) do
    %Bet{}
    |> Bet.create_changeset(attrs)
    |> Repo.insert()
  end

  # ============================================
  # Wallet Integration (via Distributed Erlang)
  # ============================================

  defp reserve_wallet(user_id, amount) do
    # Gera um reference_id único para esta operação
    reference_id = Ecto.UUID.generate()

    case call_wallet_service(:reserve, [user_id, amount, reference_id, "Reserva para aposta"]) do
      {:ok, _} -> :ok
      {:error, :insufficient_balance} -> {:error, :insufficient_balance}
      error -> error
    end
  end

  defp release_wallet(user_id, reference_id) do
    case call_wallet_service(:release, [user_id, reference_id, "Aposta cancelada"]) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp credit_wallet(user_id, amount, reference_id) do
    call_wallet_service(:credit, [user_id, amount, reference_id, "Ganho de aposta"])
  end

  defp confirm_wallet(user_id, reference_id) do
    call_wallet_service(:confirm, [user_id, reference_id, "Aposta perdida"])
  end

  defp call_wallet_service(function, args) do
    try do
      apply(LootifyWallets.Server, function, args)
    rescue
      _ -> {:error, :wallet_service_unavailable}
    catch
      :exit, _ -> {:error, :wallet_service_unavailable}
    end
  end
end
