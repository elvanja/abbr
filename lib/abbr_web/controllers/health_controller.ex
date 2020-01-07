defmodule AbbrWeb.HealthController do
  use AbbrWeb, :controller

  alias Abbr.Health

  action_fallback AbbrWeb.FallbackController

  def check(conn, _) do
    if Health.healthy?() do
      send_resp(conn, 200, "")
    else
      send_resp(conn, 503, "")
    end
  end
end
