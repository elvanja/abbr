use Mix.Config

config :abbr, AbbrWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "8T+abCxwCQqATxjaFRWI2uPwTHJM2QF7J9rbH31rat0C7NWCCZqfHEdzyi+AdLbJ",
  render_errors: [view: AbbrWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Abbr.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:node, :module, :request_id]

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

config :abbr, :cache_strategy, {:system, "CACHE_STRATEGY", "rpc"}

config :mnesia,
  dir: '.mnesia/#{Mix.env()}/#{node()}'

import_config "#{Mix.env()}.exs"
