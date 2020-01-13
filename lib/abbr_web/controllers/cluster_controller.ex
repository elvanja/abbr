defmodule AbbrWeb.ClusterController do
  use AbbrWeb, :controller

  alias Abbr.ClusterSupervisor
  alias Cluster.Strategy

  action_fallback AbbrWeb.FallbackController

  def leave(conn, _) do
    with :ok <- Supervisor.terminate_child(ClusterSupervisor, :local),
         :ok <-
           Strategy.disconnect_nodes(
             :local,
             {:erlang, :disconnect_node, []},
             {:erlang, :nodes, [:connected]},
             Node.list()
           ) do
      send_resp(conn, 200, "")
    else
      _ -> send_resp(conn, 500, "")
    end
  end

  def join(conn, _) do
    case Supervisor.restart_child(ClusterSupervisor, :local) do
      {:ok, _} -> send_resp(conn, 200, "")
      {:error, :running} -> send_resp(conn, 200, "")
      _ -> send_resp(conn, 500, "")
    end
  end
end
