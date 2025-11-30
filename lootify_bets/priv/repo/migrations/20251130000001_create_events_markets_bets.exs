defmodule LootifyBets.Repo.Migrations.CreateEventsMarketsBets do
  use Ecto.Migration

  def change do
    # Tabela de eventos
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, size: 200
      add :description, :text
      add :category, :string, null: false, size: 50
      add :status, :string, null: false, default: "scheduled"
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:status])
    create index(:events, [:category])
    create index(:events, [:starts_at])

    # Tabela de mercados
    create table(:markets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, references(:events, type: :binary_id, on_delete: :restrict), null: false
      add :name, :string, null: false, size: 100
      add :type, :string, null: false, size: 50
      add :status, :string, null: false, default: "open"
      add :odds, :decimal, precision: 10, scale: 2, null: false
      add :result, :string

      timestamps(type: :utc_datetime)
    end

    create index(:markets, [:event_id])
    create index(:markets, [:status])

    # Tabela de apostas
    create table(:bets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :binary_id, null: false
      add :event_id, references(:events, type: :binary_id, on_delete: :restrict), null: false
      add :market_id, references(:markets, type: :binary_id, on_delete: :restrict), null: false
      add :amount, :decimal, precision: 20, scale: 2, null: false
      add :odds, :decimal, precision: 10, scale: 2, null: false
      add :potential_win, :decimal, precision: 20, scale: 2, null: false
      add :status, :string, null: false, default: "pending"
      add :selection, :string, null: false
      add :settled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:bets, [:user_id])
    create index(:bets, [:event_id])
    create index(:bets, [:market_id])
    create index(:bets, [:status])
    create index(:bets, [:user_id, :status])
  end
end
