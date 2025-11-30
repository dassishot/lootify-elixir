defmodule LootifyGatewayWeb.AuthController do
  use LootifyGatewayWeb, :controller

  def register(conn, params) do
    case call_users_service(:register, [params]) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          user: %{
            id: user.id,
            email: user.email,
            username: user.username
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def login(conn, %{"identifier" => identifier, "password" => password}) do
    case call_users_service(:authenticate, [identifier, password]) do
      {:ok, user, token} ->
        # Cria wallet se não existir
        ensure_wallet_exists(user.id)

        conn
        |> put_status(:ok)
        |> json(%{
          token: token,
          user: %{
            id: user.id,
            email: user.email,
            username: user.username
          }
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Credenciais inválidas"})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao autenticar"})
    end
  end

  def me(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> put_status(:ok)
    |> json(%{
      user: %{
        id: user.id,
        email: user.email,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name
      }
    })
  end

  def logout(conn, _params) do
    token = get_token_from_header(conn)

    case call_users_service(:logout, [token]) do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Logout realizado com sucesso"})

      _ ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Logout realizado"})
    end
  end

  # Helpers

  defp call_users_service(function, args) do
    try do
      GenServer.call({:global, LootifyUsers.Server}, List.to_tuple([function | args]), 10_000)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end

  defp ensure_wallet_exists(user_id) do
    try do
      case GenServer.call({:global, LootifyWallets.Server}, {:get_wallet_by_user_id, user_id}, 10_000) do
        {:error, :not_found} ->
          GenServer.call({:global, LootifyWallets.Server}, {:create_wallet, user_id}, 10_000)

        _ ->
          :ok
      end
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  defp get_token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp format_errors(error) when is_map(error), do: error
  defp format_errors(error) when is_atom(error), do: %{error: to_string(error)}
  defp format_errors(error), do: %{error: inspect(error)}
end
