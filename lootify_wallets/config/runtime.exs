import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :lootify_wallets, LootifyWallets.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # Cluster com nomes curtos
  config :libcluster,
    topologies: [
      docker: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [:wallets@wallets, :users@users, :bets@bets, :gateway@gateway]
        ]
      ]
    ]
end
