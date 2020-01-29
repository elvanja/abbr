import Config

config :abbr, AbbrWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
