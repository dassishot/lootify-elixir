defmodule LootifyUsers.MixProject do
  use Mix.Project

  def project do
    [
      app: :lootify_users,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools, :crypto],
      mod: {LootifyUsers.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Banco de dados
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"},

      # Clustering para distributed erlang
      {:libcluster, "~> 3.4"},

      # Criptografia de senhas (pbkdf2 não precisa de compilação nativa)
      {:pbkdf2_elixir, "~> 2.2"},

      # JWT para tokens
      {:guardian, "~> 2.3"},

      # Validações
      {:email_checker, "~> 0.2"},

      # JSON
      {:jason, "~> 1.4"},

      # UUID
      {:elixir_uuid, "~> 1.2"},

      # Telemetria
      {:telemetry, "~> 1.3"},

      # Dev/Test
      {:ex_machina, "~> 2.8", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
