import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lootify_gateway, LootifyGatewayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "wTl7qINBkPQ50kKnzlSBvSZnuYdKNRwEsA0jKMfBRaiYixxCXwOMWoLkf+NMCw7F",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
