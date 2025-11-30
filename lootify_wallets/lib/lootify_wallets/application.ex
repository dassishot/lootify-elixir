defmodule LootifyWallets.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Repositório do banco de dados
      LootifyWallets.Repo,

      # Servidor que expõe APIs para outros serviços
      LootifyWallets.Server,

      # Cluster (para distributed erlang em produção)
      cluster_supervisor()
    ]
    |> List.flatten()

    opts = [strategy: :one_for_one, name: LootifyWallets.Supervisor]

    Logger.info("Starting LootifyWallets Application...")
    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor do
    topologies = Application.get_env(:libcluster, :topologies, [])

    if topologies != [] do
      [{Cluster.Supervisor, [topologies, [name: LootifyWallets.ClusterSupervisor]]}]
    else
      []
    end
  end
end
