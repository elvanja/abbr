defmodule Abbr.Cache do
  @moduledoc """
  Caches shortened and original URLs
  """

  alias Abbr.LocalCache
  alias Abbr.Url

  require Logger

  @events_topic "cache_events"

  defdelegate lookup(short), to: LocalCache

  @spec events_topic :: String.t()
  def events_topic, do: @events_topic

  @spec save(%Url{}) :: :ok | :error
  def save(url) do
    case :rpc.multicall(LocalCache, :save, [url], :timer.seconds(5)) do
      {_, []} ->
        :ok

      {_, failed_nodes} ->
        # successfully saved data can be safely ignored
        # new attempts to save the same URL will overwrite the data
        # the only downside being memory used by unreachable data
        Logger.error("Could not save #{inspect(url)} to: #{inspect(failed_nodes)}")
        :error
    end
  end
end
