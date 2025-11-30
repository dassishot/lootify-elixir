import Config

config :lootify_users, LootifyUsers.Repo,
  database: "lootify_users_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :pbkdf2_elixir, rounds: 1

config :logger, level: :debug
