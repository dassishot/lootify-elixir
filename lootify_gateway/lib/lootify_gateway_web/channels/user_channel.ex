defmodule LootifyGatewayWeb.UserChannel do
  @moduledoc """
  Channel para comunicação real-time com o usuário.
  Recebe notificações de apostas, saldo, etc.
  """
  use Phoenix.Channel
  require Logger

  @impl true
  def join("user:" <> user_id, _params, socket) do
    if socket.assigns.user_id == user_id do
      # Subscribe no PubSub do serviço de Bets
      Phoenix.PubSub.subscribe(LootifyBets.PubSub, "user:#{user_id}")

      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Envia saldo atual ao conectar
    user_id = socket.assigns.user_id

    case get_balance(user_id) do
      {:ok, balance} ->
        push(socket, "balance", balance)

      _ ->
        :ok
    end

    {:noreply, socket}
  end

  # Recebe eventos do PubSub
  @impl true
  def handle_info({:bet_placed, bet}, socket) do
    push(socket, "bet_placed", %{bet: serialize_bet(bet)})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:bet_settled, bet}, socket) do
    push(socket, "bet_settled", %{bet: serialize_bet(bet)})

    # Atualiza saldo
    case get_balance(socket.assigns.user_id) do
      {:ok, balance} -> push(socket, "balance", balance)
      _ -> :ok
    end

    {:noreply, socket}
  end

  # Ações do usuário
  @impl true
  def handle_in("place_bet", %{"market_id" => market_id, "amount" => amount, "selection" => selection}, socket) do
    user_id = socket.assigns.user_id

    case place_bet(user_id, market_id, Decimal.new(amount), selection) do
      {:ok, bet} ->
        {:reply, {:ok, %{bet_id: bet.id, status: "confirmed"}}, socket}

      {:error, :insufficient_balance} ->
        {:reply, {:error, %{reason: "Saldo insuficiente"}}, socket}

      {:error, :market_closed} ->
        {:reply, {:error, %{reason: "Mercado fechado"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: to_string(reason)}}, socket}
    end
  end

  @impl true
  def handle_in("cancel_bet", %{"bet_id" => bet_id}, socket) do
    user_id = socket.assigns.user_id

    case cancel_bet(bet_id, user_id) do
      {:ok, _} ->
        {:reply, {:ok, %{status: "canceled"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: to_string(reason)}}, socket}
    end
  end

  @impl true
  def handle_in("get_balance", _params, socket) do
    case get_balance(socket.assigns.user_id) do
      {:ok, balance} ->
        {:reply, {:ok, balance}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: to_string(reason)}}, socket}
    end
  end

  # Helpers

  defp get_balance(user_id) do
    try do
      LootifyWallets.Server.get_balance(user_id)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp place_bet(user_id, market_id, amount, selection) do
    try do
      LootifyBets.Server.place_bet(user_id, market_id, amount, selection)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp cancel_bet(bet_id, user_id) do
    try do
      LootifyBets.Server.cancel_bet(bet_id, user_id)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp serialize_bet(bet) do
    %{
      id: bet.id,
      amount: Decimal.to_string(bet.amount),
      odds: Decimal.to_string(bet.odds),
      potential_win: Decimal.to_string(bet.potential_win),
      status: bet.status,
      selection: bet.selection
    }
  end
end
