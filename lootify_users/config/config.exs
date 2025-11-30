import Config

config :lootify_users,
  ecto_repos: [LootifyUsers.Repo]

config :lootify_users, LootifyUsers.Repo,
  database: "lootify_users_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool_size: 10

# Configuração do Guardian (JWT)
config :lootify_users, LootifyUsers.Guardian,
  issuer: "lootify_users",
  secret_key: "dev_secret_key_change_in_production"

# Configuração de logs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

# Importa configuração específica do ambiente
import_config "#{config_env()}.exs"
