import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :lootify_users, LootifyUsers.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key =
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise "environment variable GUARDIAN_SECRET_KEY is missing"

  config :lootify_users, LootifyUsers.Guardian,
    issuer: "lootify_users",
    secret_key: secret_key

  # Configuração de cluster para distributed erlang (Docker)
  config :libcluster,
    topologies: [
      docker: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"wallets@wallets.lootify.local",
            :"users@users.lootify.local",
            :"bets@bets.lootify.local",
            :"gateway@gateway.lootify.local"
          ]
        ]
      ]
    ]
end
