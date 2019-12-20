ExUnit.start()

if GenServer.whereis(Abbr.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(Abbr.Repo, :manual)
end