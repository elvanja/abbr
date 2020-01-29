import Config

config :abbr, AbbrWeb.Endpoint,
  http: [:inet6, port: {:system, :integer, "HTTP_PORT", 4000}],
  url: [
    host: {:system, :string, "ABBR_HOST", "abbr.io"},
    port: {:system, :integer, "ABBR_PORT", 80}
  ]

config :logger,
  level: :info,
  compile_time_purge_matching: [[level_lower_than: :info]]

import_config "prod.secret.exs"
