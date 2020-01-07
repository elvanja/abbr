defmodule Abbr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Confex.resolve_env!(:abbr)
    :pg2.create(:abbr_cluster_cache)

    topologies = Confex.fetch_env!(:libcluster, :topologies)

    children = [
      {Cluster.Supervisor, [topologies, [name: Abbr.ClusterSupervisor]]},
      %{
        id: Abbr.PubSub,
        start: {Phoenix.PubSub.Local, :start_link, [:abbr_pubsub, :abbr_pubsub_gc]}
      },
      AbbrWeb.Endpoint,
      Abbr.Health,
      Abbr.ClusterCache,
      {Abbr.ETSTableManager, Abbr.LocalCache},
      Abbr.LocalCache
    ]

    opts = [strategy: :one_for_one, name: Abbr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    # credo:disable-for-lines:1 Credo.Check.Design.AliasUsage
    AbbrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
