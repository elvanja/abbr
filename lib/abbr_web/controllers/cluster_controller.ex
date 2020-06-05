defmodule AbbrWeb.ClusterController do
  use AbbrWeb, :controller

  alias Abbr.Cluster.Membership

  action_fallback AbbrWeb.FallbackController

  def leave(conn, _) do
    case Membership.leave() do
      :ok -> send_resp(conn, 200, "")
      _ -> send_resp(conn, 500, "")
    end
  end

  def join(conn, _) do
    case Membership.join() do
      :ok -> send_resp(conn, 200, "")
      _ -> send_resp(conn, 500, "")
    end
  end
end
