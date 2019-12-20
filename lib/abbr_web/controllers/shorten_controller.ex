defmodule AbbrWeb.ShortenController do
  use AbbrWeb, :controller

  alias Abbr.Shorten

  action_fallback AbbrWeb.FallbackController

  def given(conn, %{"url" => original}) do
    with {:ok, short} <- Shorten.given(original) do
      full_short_url = Routes.expand_url(conn, :given, short)

      conn
      |> put_status(:created)
      |> json(%{short_url: full_short_url})
    else
      _ -> send_resp(conn, 500, "")
    end
  end

  def given(_conn, _params), do: {:error, :bad_request}
end
