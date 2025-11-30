import Config

config :lootify_users, LootifyUsers.Repo,
  database: "lootify_users_test#{System.get_env("MIX_TEST_PARTITION")}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :pbkdf2_elixir, rounds: 1

config :logger, level: :warning
