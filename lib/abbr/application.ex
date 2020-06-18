defmodule Abbr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    Logger.metadata(node: Node.self())
    Confex.resolve_env!(:abbr)
    topologies = Confex.fetch_env!(:libcluster, :topologies)

    children =
      [
        {Cluster.Supervisor, [topologies, [name: Abbr.ClusterSupervisor]]},
        %{
          id: Abbr.PubSub,
          start: {Phoenix.PubSub.Local, :start_link, [:abbr_pubsub, :abbr_pubsub_gc]}
        },
        AbbrWeb.Endpoint,
        Abbr.Cluster.Health
      ] ++ build_cache_children()

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

  if Mix.env() == :test do
    defp build_cache_children do
      Enum.flat_map(
        ~w(rpc mnesia),
        &build_cache_children_for/1
      )
    end
  else
    defp build_cache_children do
      strategy = Application.get_env(:abbr, :cache_strategy)
      children = build_cache_children_for(strategy)
      Logger.info("Starting cache with #{strategy} strategy")
      children
    end
  end

  defp build_cache_children_for("rpc") do
    [
      {Abbr.Util.ETSTableManager, [target_module: Abbr.Rpc.Local]},
      Abbr.Rpc.Local,
      Abbr.Rpc.Sync
    ]
  end

  defp build_cache_children_for("mnesia"), do: [Abbr.Mnesia.Sync]

  defp build_cache_children_for(unknown_strategy) do
    raise ArgumentError, message: "Unrecognised cache strategy: #{unknown_strategy}"
  end
end
