defmodule Abbr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Confex.resolve_env!(:abbr)
    topologies = Confex.fetch_env!(:libcluster, :topologies)

    # credo:disable-for-lines:1 Credo.Check.Design.AliasUsage
    :pg2.create(Abbr.Constants.cluster_cache_group_name())

    usual_children = [
      {Cluster.Supervisor, [topologies, [name: Abbr.ClusterSupervisor]]},
      %{
        id: Abbr.PubSub,
        start: {Phoenix.PubSub.Local, :start_link, [:abbr_pubsub, :abbr_pubsub_gc]}
      },
      AbbrWeb.Endpoint,
      Abbr.Health,
      {Abbr.ETSTableManager, [target_module: Abbr.LocalCache]},
      Abbr.LocalCache
    ]

    cluster_cache_children =
      case Application.get_env(:abbr, :cluster_strategy, "monitor") do
        "basic" ->
          [Abbr.ClusterCache.Basic]

        "sync_on_startup" ->
          [Abbr.ClusterCache.SyncOnStartup]

        "nodeup_via_process_send" ->
          [Abbr.ClusterCache.NodeupViaProcessSend]

        "monitor" ->
          [
            Abbr.ClusterCache.SyncOnStartup,
            {Abbr.ClusterCache.Monitor, [cache_process_name: Abbr.ClusterCache.SyncOnStartup]}
          ]
      end

    opts = [strategy: :one_for_one, name: Abbr.Supervisor]
    Supervisor.start_link(usual_children ++ cluster_cache_children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    # credo:disable-for-lines:1 Credo.Check.Design.AliasUsage
    AbbrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
