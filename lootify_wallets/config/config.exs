import Config

config :lootify_wallets,
  ecto_repos: [LootifyWallets.Repo]

config :lootify_wallets, LootifyWallets.Repo,
  database: "lootify_wallets_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10

# Configuração de logs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :wallet_id]

# Importa configuração específica do ambiente
import_config "#{config_env()}.exs"
