defmodule LootifyBets.Repo do
  use Ecto.Repo,
    otp_app: :lootify_bets,
    adapter: Ecto.Adapters.Postgres
end
