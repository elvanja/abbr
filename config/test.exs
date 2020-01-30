import Config

config :abbr, AbbrWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

# in tests, cluster is setup manually, via LocalCluster
# hence, no need to declare hosts upfront
# we can also skip gossip protocol entirely
# takes care of sporadic connection warnings
config :abbr,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [:hosts, []],
      connect: {:net_kernel, :connect_node, []},
      disconnect: {:erlang, :disconnect_node, []},
      list_nodes: {:erlang, :nodes, [:connected]}
    ]
  ]
