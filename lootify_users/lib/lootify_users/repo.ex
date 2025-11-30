defmodule LootifyUsers.Repo do
  use Ecto.Repo,
    otp_app: :lootify_users,
    adapter: Ecto.Adapters.Postgres
end
