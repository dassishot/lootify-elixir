defmodule LootifyWallets.Repo do
  use Ecto.Repo,
    otp_app: :lootify_wallets,
    adapter: Ecto.Adapters.Postgres
end
