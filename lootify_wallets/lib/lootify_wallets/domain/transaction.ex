defmodule LootifyWallets.Domain.Transaction do
  @moduledoc """
  Schema e lógica de domínio para Transaction.
  Equivalente à entidade Transaction do projeto Go.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LootifyWallets.Domain.Wallet

  @max_description_length 500

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @transaction_types [:credit, :debit, :reserve, :release, :confirm]

  schema "transactions" do
    field :reference_id, :binary_id
    field :transaction_type, Ecto.Enum, values: @transaction_types
    field :description, :string
    field :amount, :decimal

    belongs_to :wallet, Wallet

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Lista de tipos de transação válidos.
  """
  def transaction_types, do: @transaction_types

  @doc """
  Changeset para criação de uma nova transação.
  """
  def create_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:wallet_id, :reference_id, :transaction_type, :description, :amount])
    |> validate_required([:wallet_id, :reference_id, :transaction_type, :description, :amount])
    |> validate_inclusion(:transaction_type, @transaction_types)
    |> validate_length(:description, max: @max_description_length)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:wallet_id)
  end

  @doc """
  Cria uma transação de crédito.
  """
  def build_credit(wallet_id, reference_id, amount, description) do
    %__MODULE__{}
    |> create_changeset(%{
      wallet_id: wallet_id,
      reference_id: reference_id,
      transaction_type: :credit,
      description: description,
      amount: amount
    })
  end

  @doc """
  Cria uma transação de débito.
  """
  def build_debit(wallet_id, reference_id, amount, description) do
    %__MODULE__{}
    |> create_changeset(%{
      wallet_id: wallet_id,
      reference_id: reference_id,
      transaction_type: :debit,
      description: description,
      amount: amount
    })
  end

  @doc """
  Cria uma transação de reserva.
  """
  def build_reserve(wallet_id, reference_id, amount, description) do
    %__MODULE__{}
    |> create_changeset(%{
      wallet_id: wallet_id,
      reference_id: reference_id,
      transaction_type: :reserve,
      description: description,
      amount: amount
    })
  end

  @doc """
  Cria uma transação de liberação.
  """
  def build_release(wallet_id, reference_id, amount, description) do
    %__MODULE__{}
    |> create_changeset(%{
      wallet_id: wallet_id,
      reference_id: reference_id,
      transaction_type: :release,
      description: description,
      amount: amount
    })
  end

  @doc """
  Cria uma transação de confirmação.
  """
  def build_confirm(wallet_id, reference_id, amount, description) do
    %__MODULE__{}
    |> create_changeset(%{
      wallet_id: wallet_id,
      reference_id: reference_id,
      transaction_type: :confirm,
      description: description,
      amount: amount
    })
  end
end
