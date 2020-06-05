defmodule Abbr.Cluster.Membership do
  @moduledoc """
  Makes a node leave or join the cluster.
  This is achieved by (ab)using libcluster and it's supervisor a bit.
  That's because we use gossip protocol which would normally just reconnect on next tick.
  """

  alias Abbr.ClusterSupervisor
  alias Cluster.Strategy

  @spec leave :: :ok | {:error, String.t()}
  def leave do
    with :ok <- Supervisor.terminate_child(ClusterSupervisor, :local),
         :ok <-
           Strategy.disconnect_nodes(
             :local,
             {:erlang, :disconnect_node, []},
             {:erlang, :nodes, [:connected]},
             Node.list()
           ) do
      :ok
    else
      _ -> {:error, "could not leave cluster"}
    end
  end

  @spec join :: :ok | {:error, String.t()}
  def join do
    case Supervisor.restart_child(ClusterSupervisor, :local) do
      {:ok, _} -> :ok
      {:error, :running} -> :ok
      _ -> {:error, "could not join cluster"}
    end
  end
end
