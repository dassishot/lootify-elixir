defmodule LootifyUsers.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false, size: 160
      add :username, :string, null: false, size: 30
      add :password_hash, :string, null: false
      add :first_name, :string, size: 100
      add :last_name, :string, size: 100
      add :status, :string, null: false, default: "active"
      add :email_verified, :boolean, null: false, default: false
      add :last_login_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:status])
  end
end
