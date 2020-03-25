defmodule Abbr.RpcCache do
  @moduledoc """
  Orchestrates storing and fetching shortened and original URLs
  in the cluster via [RPC](http://erlang.org/doc/man/rpc.html).
  """

  alias Abbr.LocalCache
  alias Abbr.Url

  require Logger

  defdelegate lookup(short), to: LocalCache

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
