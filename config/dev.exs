import Config

config :abbr, AbbrWeb.Endpoint,
  http: [port: {:system, :integer, "HTTP_PORT", 4000}],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module, :pid]

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
