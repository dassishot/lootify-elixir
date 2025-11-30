defmodule LootifyBets.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Repositório do banco de dados
      LootifyBets.Repo,

      # PubSub para eventos real-time
      {Phoenix.PubSub, name: LootifyBets.PubSub},

      # Cache de odds em ETS
      LootifyBets.OddsCache,

      # Servidor que expõe APIs para outros serviços
      LootifyBets.Server,

      # Cluster (para distributed erlang em produção)
      cluster_supervisor()
    ]
    |> List.flatten()

    opts = [strategy: :one_for_one, name: LootifyBets.Supervisor]

    Logger.info("Starting LootifyBets Application...")
    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor do
    topologies = Application.get_env(:libcluster, :topologies, [])

    if topologies != [] do
      [{Cluster.Supervisor, [topologies, [name: LootifyBets.ClusterSupervisor]]}]
    else
      []
    end
  end
end
