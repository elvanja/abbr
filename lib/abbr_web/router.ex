defmodule AbbrWeb.Router do
  use AbbrWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/api", AbbrWeb do
    pipe_through(:api)

    post("/urls", ShortenController, :given)
    post("/cluster/leave", ClusterController, :leave)
    post("/cluster/join", ClusterController, :join)
  end

  scope "/", AbbrWeb do
    pipe_through(:browser)

    get("/health", HealthController, :check)
    get("/:short", ExpandController, :given)
  end
end
