defmodule LootifyGatewayWeb.EventController do
  use LootifyGatewayWeb, :controller

  def index(conn, params) do
    filters = %{}
    filters = if params["status"], do: Map.put(filters, :status, String.to_atom(params["status"])), else: filters
    filters = if params["category"], do: Map.put(filters, :category, params["category"]), else: filters

    case call_bets_service(:list_events, [filters]) do
      events when is_list(events) ->
        conn
        |> put_status(:ok)
        |> json(%{events: Enum.map(events, &serialize_event/1)})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao buscar eventos"})
    end
  end

  def show(conn, %{"id" => id}) do
    case call_bets_service(:get_event, [id]) do
      {:ok, event} ->
        conn
        |> put_status(:ok)
        |> json(%{event: serialize_event(event)})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Evento não encontrado"})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao buscar evento"})
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

  defp serialize_event(event) do
    %{
      id: event.id,
      name: event.name,
      description: event.description,
      category: event.category,
      status: event.status,
      starts_at: event.starts_at,
      markets: Enum.map(event.markets || [], &serialize_market/1)
    }
  end

  defp serialize_market(market) do
    %{
      id: market.id,
      name: market.name,
      type: market.type,
      odds: Decimal.to_string(market.odds),
      status: market.status
    }
  end
end
