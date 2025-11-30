defmodule LootifyGatewayWeb.EventChannel do
  @moduledoc """
  Channel para atualizações real-time de eventos e odds.
  Usuários podem se inscrever em eventos específicos para receber updates.
  """
  use Phoenix.Channel

  @impl true
  def join("event:" <> event_id, _params, socket) do
    # Subscribe no PubSub para atualizações deste evento
    Phoenix.PubSub.subscribe(LootifyBets.PubSub, "event:#{event_id}")

    # Envia dados atuais do evento
    send(self(), {:send_event_data, event_id})

    {:ok, assign(socket, :event_id, event_id)}
  end

  @impl true
  def handle_info({:send_event_data, event_id}, socket) do
    case get_event(event_id) do
      {:ok, event} ->
        push(socket, "event_data", serialize_event(event))

      _ ->
        :ok
    end

    {:noreply, socket}
  end

  # Recebe atualizações de odds do PubSub
  @impl true
  def handle_info({:odds_updated, market_id, odds}, socket) do
    push(socket, "odds_updated", %{
      market_id: market_id,
      odds: Decimal.to_string(odds)
    })

    {:noreply, socket}
  end

  @impl true
  def handle_info({:event_status_changed, status}, socket) do
    push(socket, "status_changed", %{status: status})
    {:noreply, socket}
  end

  # Helpers

  defp get_event(event_id) do
    try do
      LootifyBets.Server.get_event(event_id)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp serialize_event(event) do
    %{
      id: event.id,
      name: event.name,
      category: event.category,
      status: event.status,
      starts_at: event.starts_at,
      markets:
        Enum.map(event.markets, fn m ->
          %{
            id: m.id,
            name: m.name,
            type: m.type,
            odds: Decimal.to_string(m.odds),
            status: m.status
          }
        end)
    }
  end
end
