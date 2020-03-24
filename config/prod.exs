import Config

config :abbr, AbbrWeb.Endpoint,
  http: [:inet6, port: {:system, :integer, "HTTP_PORT", 4000}],
  url: [
    host: {:system, :string, "ABBR_HOST", "abbr.io"},
    port: {:system, :integer, "ABBR_PORT", 80}
  ]

config :logger,
  backends: [{LoggerFileBackend, :error_log}]

config :logger,
  level: :info,
  compile_time_purge_matching: [[level_lower_than: :info]]

config :logger, :error_log,
  path: "logs/error.log",
  level: :error

import_config "prod.secret.exs"
