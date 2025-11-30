defmodule LootifyWallets.Domain.Wallet do
  @moduledoc """
  Schema e lógica de domínio para Wallet.
  Equivalente à entidade Wallet do projeto Go.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LootifyWallets.Domain.Transaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "wallets" do
    field :user_id, :binary_id
    field :balance, :decimal, default: Decimal.new(0)
    field :locked, :decimal, default: Decimal.new(0)

    has_many :transactions, Transaction

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset para criação de uma nova wallet.
  """
  def create_changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
    |> put_change(:balance, Decimal.new(0))
    |> put_change(:locked, Decimal.new(0))
  end

  @doc """
  Changeset para atualização de saldos.
  """
  def update_balance_changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:balance, :locked])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> validate_number(:locked, greater_than_or_equal_to: 0)
  end

  # ============================================
  # Lógica de Domínio (equivalente ao Go)
  # ============================================

  @doc """
  Retorna o saldo disponível (balance).
  """
  def available_balance(%__MODULE__{balance: balance}), do: balance

  @doc """
  Retorna o saldo total (balance + locked).
  """
  def total_balance(%__MODULE__{balance: balance, locked: locked}) do
    Decimal.add(balance, locked)
  end

  @doc """
  Retorna o saldo bloqueado (locked).
  """
  def locked_balance(%__MODULE__{locked: locked}), do: locked

  @doc """
  Verifica se a wallet tem saldo suficiente para uma operação.
  """
  def has_sufficient_balance?(%__MODULE__{balance: balance}, amount) do
    Decimal.compare(balance, amount) != :lt
  end

  @doc """
  Calcula novo estado após reserva (lock).
  Retorna {:ok, new_balance, new_locked} ou {:error, reason}.
  """
  def calculate_lock(%__MODULE__{balance: balance, locked: locked}, amount) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :invalid_amount}

      Decimal.compare(balance, amount) == :lt ->
        {:error, :insufficient_balance}

      true ->
        {:ok, Decimal.sub(balance, amount), Decimal.add(locked, amount)}
    end
  end

  @doc """
  Calcula novo estado após liberação (unlock).
  Retorna {:ok, new_balance, new_locked} ou {:error, reason}.
  """
  def calculate_unlock(%__MODULE__{balance: balance, locked: locked}, amount) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :invalid_amount}

      Decimal.compare(locked, amount) == :lt ->
        {:error, :insufficient_locked}

      true ->
        {:ok, Decimal.add(balance, amount), Decimal.sub(locked, amount)}
    end
  end

  @doc """
  Calcula novo estado após confirmação de reserva (remove do locked).
  Retorna {:ok, new_locked} ou {:error, reason}.
  """
  def calculate_confirm(%__MODULE__{locked: locked}, amount) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :invalid_amount}

      Decimal.compare(locked, amount) == :lt ->
        {:error, :insufficient_locked}

      true ->
        {:ok, Decimal.sub(locked, amount)}
    end
  end

  @doc """
  Calcula novo estado após crédito.
  Retorna {:ok, new_balance} ou {:error, reason}.
  """
  def calculate_credit(%__MODULE__{balance: balance}, amount) do
    if Decimal.compare(amount, Decimal.new(0)) != :gt do
      {:error, :invalid_amount}
    else
      {:ok, Decimal.add(balance, amount)}
    end
  end

  @doc """
  Calcula novo estado após débito.
  Retorna {:ok, new_balance} ou {:error, reason}.
  """
  def calculate_debit(%__MODULE__{balance: balance}, amount) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :invalid_amount}

      Decimal.compare(balance, amount) == :lt ->
        {:error, :insufficient_balance}

      true ->
        {:ok, Decimal.sub(balance, amount)}
    end
  end
end
