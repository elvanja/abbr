defmodule AbbrWeb.Router do
  use AbbrWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # TODO maybe without protect_from_forgery and fetch_session, also put_secure_browser_headers
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/api", AbbrWeb do
    pipe_through(:api)

    # TODO GET details
    # TODO GET stats
    post("/urls", ShortenController, :given)
  end

  scope "/", AbbrWeb do
    pipe_through(:browser)

    get("/:short", ExpandController, :given)
  end
end
