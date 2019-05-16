defmodule AbbrWeb.Router do
  use AbbrWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AbbrWeb do
    pipe_through :api
  end
end
