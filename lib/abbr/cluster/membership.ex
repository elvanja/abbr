defmodule Abbr.Cluster.Membership do
  @moduledoc """
  Makes a node leave or join the cluster.
  This is achieved by (ab)using libcluster and it's supervisor a bit.
  That's because we use gossip protocol which would normally just reconnect on next tick.
  """

  alias Abbr.ClusterSupervisor
  alias Cluster.Strategy

  require Logger

  @spec leave :: :ok | {:error, String.t()}
  def leave do
    Logger.metadata(node: Node.self())

    with :ok <- Supervisor.terminate_child(ClusterSupervisor, :local),
         :ok <-
           Strategy.disconnect_nodes(
             :local,
             {:erlang, :disconnect_node, []},
             {:erlang, :nodes, [:connected]},
             Node.list()
           ) do
      Logger.warning("Left the cluster")
      :ok
    else
      reason ->
        Logger.error("Could not leave cluster, reason: #{inspect(reason)}")
        {:error, "could not leave cluster"}
    end
  end

  @spec join :: :ok | {:error, String.t()}
  def join do
    Logger.metadata(node: Node.self())

    case Supervisor.restart_child(ClusterSupervisor, :local) do
      {:ok, _} ->
        Logger.warning("Joined the cluster")
        :ok

      {:error, :running} ->
        Logger.warning("Already member of the cluster")
        :ok

      reason ->
        Logger.error("Could not join cluster, reason: #{inspect(reason)}")
        {:error, "could not join cluster"}
    end
  end
end
