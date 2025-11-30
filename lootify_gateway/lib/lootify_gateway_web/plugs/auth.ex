defmodule LootifyGatewayWeb.Plugs.Auth do
  @moduledoc """
  Plug para autenticação via token JWT.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_token_from_header(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Token não fornecido"})
        |> halt()

      token ->
        case validate_token(token) do
          {:ok, user} ->
            assign(conn, :current_user, user)

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{error: "Token inválido"})
            |> halt()
        end
    end
  end

  defp get_token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp validate_token(token) do
    try do
      GenServer.call({:global, LootifyUsers.Server}, {:validate_token, token}, 10_000)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end
end
