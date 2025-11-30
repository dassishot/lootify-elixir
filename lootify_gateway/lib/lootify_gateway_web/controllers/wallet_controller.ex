defmodule LootifyGatewayWeb.WalletController do
  use LootifyGatewayWeb, :controller

  def balance(conn, _params) do
    user_id = conn.assigns[:current_user].id

    case call_wallet_service(:get_balance, [user_id]) do
      {:ok, balance} ->
        conn
        |> put_status(:ok)
        |> json(%{
          balance: Decimal.to_string(balance.balance),
          locked: Decimal.to_string(balance.locked),
          available: Decimal.to_string(balance.available),
          total: Decimal.to_string(balance.total)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Wallet não encontrada"})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro ao buscar saldo"})
    end
  end

  def deposit(conn, %{"amount" => amount}) do
    user_id = conn.assigns[:current_user].id
    reference_id = UUID.uuid4()

    case call_wallet_service(:credit, [user_id, Decimal.new(amount), reference_id, "Depósito"]) do
      {:ok, result} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Depósito realizado com sucesso",
          balance: Decimal.to_string(result.wallet.balance)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # Helpers

  defp call_wallet_service(function, args) do
    try do
      GenServer.call({:global, LootifyWallets.Server}, List.to_tuple([function | args]), 10_000)
    rescue
      _ -> {:error, :service_unavailable}
    catch
      :exit, _ -> {:error, :service_unavailable}
    end
  end
end
