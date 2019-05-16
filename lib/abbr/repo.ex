defmodule Abbr.Repo do
  use Ecto.Repo,
    otp_app: :abbr,
    adapter: Ecto.Adapters.Postgres
end
