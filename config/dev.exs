import Config

config :abbr, AbbrWeb.Endpoint,
  http: [port: {:system, :integer, "HTTP_PORT", 4000}],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger,
  backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "logs/dev.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:node, :module, :request_id]

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
