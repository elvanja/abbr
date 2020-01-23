defmodule AbbrWeb.ClusterController do
  use AbbrWeb, :controller

  alias Abbr.Cluster

  action_fallback AbbrWeb.FallbackController

  def leave(conn, _) do
    case Cluster.leave() do
      :ok -> send_resp(conn, 200, "")
      _ -> send_resp(conn, 500, "")
    end
  end

  def join(conn, _) do
    case Cluster.join() do
      :ok -> send_resp(conn, 200, "")
      _ -> send_resp(conn, 500, "")
    end
  end
end
