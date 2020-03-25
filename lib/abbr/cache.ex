defmodule Abbr.Cache do
  @moduledoc """
  Central hub for cache, the only one that knows which caching mechanism is to be used.
  """

  alias Abbr.RpcCache

  @doc """
  Topic to which cache events will be broadcast.
  """
  @spec events_topic :: String.t()
  def events_topic, do: "cache_events"

  defdelegate lookup(short), to: RpcCache
  defdelegate save(url), to: RpcCache
end
