import Config

if System.get_env("PHX_SERVER") do
  config :lootify_gateway, LootifyGatewayWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :lootify_gateway, LootifyGatewayWeb.Endpoint,
    url: [host: host, port: port, scheme: "http"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

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
