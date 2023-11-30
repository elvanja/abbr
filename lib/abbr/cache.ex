defmodule Abbr.Cache do
  @moduledoc """
  Central hub for cache, the only one that knows which caching mechanism is to be used.
  """

  alias Abbr.Mnesia
  alias Abbr.Rpc
  alias Abbr.Url

  require Logger

  @callback lookup(Url.short()) :: Url.t() | nil

  @callback save(Url.t()) :: :ok | :error

  @doc """
  Topic to which cache events will be broadcast.
  """
  @spec events_topic :: String.t()
  def events_topic, do: "cache_events"

  def lookup(short), do: cache_module().lookup(short)

  def save(url), do: cache_module().save(url)

  defp cache_module do
    Logger.metadata(node: Node.self())

    case Application.get_env(:abbr, :cache_strategy) do
      "rpc" -> Rpc
      "mnesia" -> Mnesia
    end
  end
end
