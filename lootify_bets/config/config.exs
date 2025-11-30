import Config

config :lootify_bets,
  ecto_repos: [LootifyBets.Repo]

config :lootify_bets, LootifyBets.Repo,
  database: "lootify_bets_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5434,
  pool_size: 10

# Configuração de logs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :bet_id]

# Importa configuração específica do ambiente
import_config "#{config_env()}.exs"
