defmodule LootifyGatewayWeb.BetController do
  use LootifyGatewayWeb, :controller

  def index(conn, params) do
    user_id = conn.assigns[:current_user].id
    filters = if params["status"], do: %{status: String.to_atom(params["status"])}, else: %{}

    case call_bets_service(:list_user_bets, [user_id, filters]) do
      bets when is_list(bets) ->
        conn
        |> put_status(:ok)
        |> json(%{bets: Enum.map(bets, &serialize_bet/1)})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao buscar apostas"})
    end
  end

  def show(conn, %{"id" => id}) do
    case call_bets_service(:get_bet, [id]) do
      {:ok, bet} ->
        # Verifica se a aposta pertence ao usuário
        if bet.user_id == conn.assigns[:current_user].id do
          conn
          |> put_status(:ok)
          |> json(%{bet: serialize_bet(bet)})
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acesso negado"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Aposta não encontrada"})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao buscar aposta"})
    end
  end

  def create(conn, %{"market_id" => market_id, "amount" => amount, "selection" => selection}) do
    user_id = conn.assigns[:current_user].id

    case call_bets_service(:place_bet, [user_id, market_id, Decimal.new(amount), selection]) do
      {:ok, bet} ->
        conn
        |> put_status(:created)
        |> json(%{bet: serialize_bet(bet)})

      {:error, :insufficient_balance} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Saldo insuficiente"})

      {:error, :market_closed} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Mercado fechado para apostas"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  def cancel(conn, %{"id" => id}) do
    user_id = conn.assigns[:current_user].id

    case call_bets_service(:cancel_bet, [id, user_id]) do
      {:ok, bet} ->
        conn
        |> put_status(:ok)
        |> json(%{bet: serialize_bet(bet)})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acesso negado"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # Helpers

  defp call_bets_service(function, args) do
    try do
      GenServer.call({:global, LootifyBets.Server}, List.to_tuple([function | args]), 10_000)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp serialize_bet(bet) do
    %{
      id: bet.id,
      event_id: bet.event_id,
      market_id: bet.market_id,
      amount: Decimal.to_string(bet.amount),
      odds: Decimal.to_string(bet.odds),
      potential_win: Decimal.to_string(bet.potential_win),
      status: bet.status,
      selection: bet.selection,
      settled_at: bet.settled_at,
      created_at: bet.inserted_at
    }
  end
end
