defmodule LootifyWallets.Repo.Migrations.CreateWalletsAndTransactions do
  use Ecto.Migration

  def change do
    # Tabela de wallets
    create table(:wallets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :binary_id, null: false
      add :balance, :decimal, precision: 20, scale: 2, null: false, default: 0
      add :locked, :decimal, precision: 20, scale: 2, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    # Índice único para user_id (cada usuário tem uma wallet)
    create unique_index(:wallets, [:user_id])

    # Tabela de transações
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :wallet_id, references(:wallets, type: :binary_id, on_delete: :restrict), null: false
      add :reference_id, :binary_id, null: false
      add :transaction_type, :string, null: false
      add :description, :string, size: 500, null: false
      add :amount, :decimal, precision: 20, scale: 2, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Índice para busca rápida por wallet_id
    create index(:transactions, [:wallet_id])

    # Índice para busca por reference_id e tipo (idempotência)
    create unique_index(:transactions, [:wallet_id, :reference_id, :transaction_type])

    # Índice para buscar transações de reserva por reference_id
    create index(:transactions, [:reference_id, :transaction_type])
  end
end
