defmodule LootifyGatewayWeb.HealthController do
  use LootifyGatewayWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "ok",
      service: "lootify_gateway",
      timestamp: DateTime.utc_now()
    })
  end
end
