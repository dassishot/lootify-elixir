defmodule LootifyWallets.Wallets do
  @moduledoc """
  Contexto de Wallets - contém toda a lógica de negócio.
  Equivalente aos usecases do projeto Go.
  """

  import Ecto.Query
  alias LootifyWallets.Repo
  alias LootifyWallets.Domain.{Wallet, Transaction}

  # ============================================
  # Queries
  # ============================================

  @doc """
  Busca uma wallet pelo ID.
  """
  def get_wallet(id) do
    case Repo.get(Wallet, id) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  @doc """
  Busca uma wallet pelo user_id.
  """
  def get_wallet_by_user_id(user_id) do
    query = from w in Wallet, where: w.user_id == ^user_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  @doc """
  Busca uma wallet pelo user_id com lock para update.
  Deve ser usada dentro de uma transação.
  """
  def get_wallet_for_update(user_id) do
    query =
      from w in Wallet,
        where: w.user_id == ^user_id,
        lock: "FOR UPDATE"

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  @doc """
  Busca uma transação de reserva pelo reference_id.
  """
  def get_reserve_transaction(reference_id) do
    query =
      from t in Transaction,
        where: t.reference_id == ^reference_id and t.transaction_type == :reserve

    case Repo.one(query) do
      nil -> {:error, :reserve_not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Verifica se já existe uma transação (para idempotência).
  """
  def transaction_exists?(wallet_id, reference_id, type) do
    query =
      from t in Transaction,
        where:
          t.wallet_id == ^wallet_id and
            t.reference_id == ^reference_id and
            t.transaction_type == ^type

    Repo.exists?(query)
  end

  # ============================================
  # Commands
  # ============================================

  @doc """
  Cria uma nova wallet para um usuário.
  """
  def create_wallet(user_id) do
    %Wallet{}
    |> Wallet.create_changeset(%{user_id: user_id})
    |> Repo.insert()
  end

  @doc """
  Adiciona crédito à wallet de um usuário.
  Operação idempotente baseada no reference_id.
  """
  def credit(user_id, amount, reference_id, description \\ "Crédito") do
    Repo.transaction(fn ->
      with {:ok, wallet} <- get_wallet_for_update(user_id),
           false <- transaction_exists?(wallet.id, reference_id, :credit),
           {:ok, new_balance} <- Wallet.calculate_credit(wallet, amount) do
        # Atualiza wallet
        {:ok, updated_wallet} =
          wallet
          |> Wallet.update_balance_changeset(%{balance: new_balance})
          |> Repo.update()

        # Cria transação
        {:ok, transaction} =
          Transaction.build_credit(wallet.id, reference_id, amount, description)
          |> Repo.insert()

        %{wallet: updated_wallet, transaction: transaction}
      else
        true ->
          # Transação já existe (idempotente) - retorna wallet atual
          {:ok, wallet} = get_wallet_by_user_id(user_id)
          wallet

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Remove débito da wallet de um usuário.
  Operação idempotente baseada no reference_id.
  """
  def debit(user_id, amount, reference_id, description \\ "Débito") do
    Repo.transaction(fn ->
      with {:ok, wallet} <- get_wallet_for_update(user_id),
           false <- transaction_exists?(wallet.id, reference_id, :debit),
           {:ok, new_balance} <- Wallet.calculate_debit(wallet, amount) do
        # Atualiza wallet
        {:ok, updated_wallet} =
          wallet
          |> Wallet.update_balance_changeset(%{balance: new_balance})
          |> Repo.update()

        # Cria transação
        {:ok, transaction} =
          Transaction.build_debit(wallet.id, reference_id, amount, description)
          |> Repo.insert()

        %{wallet: updated_wallet, transaction: transaction}
      else
        true ->
          {:ok, wallet} = get_wallet_by_user_id(user_id)
          wallet

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Reserva (lock) parte do saldo da wallet.
  Move de balance para locked.
  Operação idempotente baseada no reference_id.
  """
  def reserve(user_id, amount, reference_id, description \\ "Reserva") do
    Repo.transaction(fn ->
      with {:ok, wallet} <- get_wallet_for_update(user_id),
           false <- transaction_exists?(wallet.id, reference_id, :reserve),
           {:ok, new_balance, new_locked} <- Wallet.calculate_lock(wallet, amount) do
        # Atualiza wallet
        {:ok, updated_wallet} =
          wallet
          |> Wallet.update_balance_changeset(%{balance: new_balance, locked: new_locked})
          |> Repo.update()

        # Cria transação
        {:ok, transaction} =
          Transaction.build_reserve(wallet.id, reference_id, amount, description)
          |> Repo.insert()

        %{wallet: updated_wallet, transaction: transaction}
      else
        true ->
          {:ok, wallet} = get_wallet_by_user_id(user_id)
          wallet

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Libera (unlock) parte do saldo reservado.
  Move de locked de volta para balance.
  Usado quando uma aposta é cancelada.
  """
  def release(user_id, reference_id, description \\ "Liberação") do
    Repo.transaction(fn ->
      with {:ok, wallet} <- get_wallet_for_update(user_id),
           {:ok, reserve_tx} <- get_reserve_transaction(reference_id),
           false <- transaction_exists?(wallet.id, reference_id, :release),
           {:ok, new_balance, new_locked} <- Wallet.calculate_unlock(wallet, reserve_tx.amount) do
        # Atualiza wallet
        {:ok, updated_wallet} =
          wallet
          |> Wallet.update_balance_changeset(%{balance: new_balance, locked: new_locked})
          |> Repo.update()

        # Cria transação
        {:ok, transaction} =
          Transaction.build_release(wallet.id, reference_id, reserve_tx.amount, description)
          |> Repo.insert()

        %{wallet: updated_wallet, transaction: transaction}
      else
        true ->
          {:ok, wallet} = get_wallet_by_user_id(user_id)
          wallet

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Confirma uma reserva, removendo o valor do locked.
  Usado quando uma aposta é confirmada/perdida.
  """
  def confirm(user_id, reference_id, description \\ "Confirmação") do
    Repo.transaction(fn ->
      with {:ok, wallet} <- get_wallet_for_update(user_id),
           {:ok, reserve_tx} <- get_reserve_transaction(reference_id),
           false <- transaction_exists?(wallet.id, reference_id, :confirm),
           {:ok, new_locked} <- Wallet.calculate_confirm(wallet, reserve_tx.amount) do
        # Atualiza wallet
        {:ok, updated_wallet} =
          wallet
          |> Wallet.update_balance_changeset(%{locked: new_locked})
          |> Repo.update()

        # Cria transação
        {:ok, transaction} =
          Transaction.build_confirm(wallet.id, reference_id, reserve_tx.amount, description)
          |> Repo.insert()

        %{wallet: updated_wallet, transaction: transaction}
      else
        true ->
          {:ok, wallet} = get_wallet_by_user_id(user_id)
          wallet

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Retorna o saldo de uma wallet.
  """
  def get_balance(user_id) do
    case get_wallet_by_user_id(user_id) do
      {:ok, wallet} ->
        {:ok,
         %{
           balance: wallet.balance,
           locked: wallet.locked,
           available: Wallet.available_balance(wallet),
           total: Wallet.total_balance(wallet)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
