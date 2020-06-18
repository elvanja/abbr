import Config

config :abbr, AbbrWeb.Endpoint,
  http: [:inet6, port: {:system, :integer, "HTTP_PORT", 4000}],
  url: [
    host: {:system, :string, "ABBR_HOST", "abbr.io"},
    port: {:system, :integer, "ABBR_PORT", 80}
  ]

config :logger,
  backends: [{LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "logs/prod.log",
  level: :warn,
  format: "$time $metadata[$level] $message\n",
  metadata: [:node, :module, :request_id]

config :logger,
  level: :info,
  compile_time_purge_matching: [[level_lower_than: :info]]

import_config "prod.secret.exs"
