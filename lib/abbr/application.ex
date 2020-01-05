defmodule Abbr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Abbr.Cache
  alias Abbr.ETSTableManager
  alias AbbrWeb.Endpoint

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      # Abbr.Repo,
      # Start the endpoint when the application starts
      Endpoint,
      # Starts a worker by calling: Abbr.Worker.start_link(arg)
      # {Abbr.Worker, arg},
      {ETSTableManager, Cache},
      Cache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Abbr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
