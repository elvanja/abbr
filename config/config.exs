import Config

config :abbr, AbbrWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "8T+abCxwCQqATxjaFRWI2uPwTHJM2QF7J9rbH31rat0C7NWCCZqfHEdzyi+AdLbJ",
  render_errors: [view: AbbrWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Abbr.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# need to place libcluster config under :abbr due to local_cluster issue
# this way the configuration is propagated correctly to test nodes
# see https://github.com/whitfin/local-cluster/issues/13 for details
config :abbr,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Gossip,
      connect: {:net_kernel, :connect_node, []},
      disconnect: {:erlang, :disconnect_node, []},
      list_nodes: {:erlang, :nodes, [:connected]}
    ]
  ]

import_config "#{Mix.env()}.exs"
