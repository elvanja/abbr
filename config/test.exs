import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :abbr, AbbrWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :abbr, Abbr.Repo,
  username: "postgres",
  password: "postgres",
  database: "abbr_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
