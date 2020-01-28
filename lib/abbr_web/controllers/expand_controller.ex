defmodule AbbrWeb.ExpandController do
  use AbbrWeb, :controller

  alias Abbr.Expand

  action_fallback AbbrWeb.FallbackController

  def given(conn, %{"short" => short}) do
    case Expand.given(short) do
      {:ok, original} ->
        redirect(conn, external: original)

      {:error, :not_found} ->
        send_resp(conn, 404, "")
    end
  end

  def given(_conn, _params), do: {:error, :bad_request}
end
