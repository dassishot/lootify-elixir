import Config

config :lootify_bets, LootifyBets.Repo,
  database: "lootify_bets_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5434,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :logger, level: :debug
