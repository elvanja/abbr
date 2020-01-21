defmodule Abbr.Cache do
  @moduledoc """
  Caches shortened and original URLs
  """

  alias Abbr.Constants
  alias Abbr.LocalCache
  alias Abbr.Url

  @events_topic "cache_events"
  @pg2_group Constants.cluster_cache_group_name()

  defdelegate lookup(short), to: LocalCache

  @spec events_topic :: String.t()
  def events_topic, do: @events_topic

  @spec save(%Url{}) :: :ok
  def save(url) do
    Enum.each(:pg2.get_members(@pg2_group), fn pid ->
      :ok = GenServer.call(pid, {:save, url})
    end)

    :ok
  end
end
