import Config

config :lootify_wallets, LootifyWallets.Repo,
  database: "lootify_wallets_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :logger, level: :debug
