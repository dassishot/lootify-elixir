import Config

# Disable force SSL for now (enable when you have a proper SSL certificate)
# config :lootify_gateway, LootifyGatewayWeb.Endpoint, force_ssl: [rewrite_on: [:x_forwarded_proto]]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
