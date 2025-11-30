defmodule LootifyGatewayWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "user:*", LootifyGatewayWeb.UserChannel
  channel "event:*", LootifyGatewayWeb.EventChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case validate_token(token) do
      {:ok, user} ->
        {:ok, assign(socket, :user_id, user.id)}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"

  defp validate_token(token) do
    try do
      LootifyUsers.Server.validate_token(token)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end
end
