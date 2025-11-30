defmodule LootifyGateway.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LootifyGatewayWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:lootify_gateway, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LootifyGateway.PubSub},
      # Cluster para distributed erlang
      cluster_supervisor(),
      # Start to serve requests, typically the last entry
      LootifyGatewayWeb.Endpoint
    ]
    |> List.flatten()

    opts = [strategy: :one_for_one, name: LootifyGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor do
    topologies = Application.get_env(:libcluster, :topologies, [])

    if topologies != [] do
      [{Cluster.Supervisor, [topologies, [name: LootifyGateway.ClusterSupervisor]]}]
    else
      []
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LootifyGatewayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
