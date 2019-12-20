defmodule AbbrWeb.ExpandController do
  use AbbrWeb, :controller

  alias Abbr.Expand

  action_fallback AbbrWeb.FallbackController

  def given(conn, %{"short" => short}) do
    with {:ok, original} <- Expand.given(short) do
      redirect(conn, external: original)
    else
      _ -> send_resp(conn, 500, "")
    end
  end

  def given(_conn, _params), do: {:error, :bad_request}
end
