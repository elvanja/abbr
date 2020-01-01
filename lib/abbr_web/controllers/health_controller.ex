defmodule AbbrWeb.HealthController do
  use AbbrWeb, :controller

  action_fallback AbbrWeb.FallbackController

  def check(conn, _) do
    send_resp(conn, 200, "")
  end
end
