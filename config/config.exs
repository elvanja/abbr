# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :abbr,
  ecto_repos: [Abbr.Repo]

# Configures the endpoint
config :abbr, AbbrWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "8T+abCxwCQqATxjaFRWI2uPwTHJM2QF7J9rbH31rat0C7NWCCZqfHEdzyi+AdLbJ",
  render_errors: [view: AbbrWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Abbr.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :libcluster,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Gossip,
      connect: {:net_kernel, :connect_node, []},
      disconnect: {:erlang, :disconnect_node, []},
      list_nodes: {:erlang, :nodes, [:connected]}
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
