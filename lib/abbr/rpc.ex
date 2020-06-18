defmodule Abbr.Rpc do
  @moduledoc """
  Entry point to RPC cache solution.
  Orchestrates storing and fetching shortened and original URLs
  in the cluster via [RPC](http://erlang.org/doc/man/rpc.html).
  """

  alias Abbr.Rpc.Local

  require Logger

  @behaviour Abbr.Cache

  @impl true
  defdelegate lookup(short), to: Local

  @impl true
  def save(url) do
    case :rpc.multicall(Local, :save, [url], :timer.seconds(5)) do
      {_, []} ->
        :ok

      {_, failed_nodes} ->
        # some data was probably saved successfully on some nodes
        # but, it can be ignored, new attempts to save the same URL will overwrite that data
        # the only downside being memory used by unreachable shortened URLs
        # e.g. given no new attempts to save the same shortened URL
        Logger.error("Could not save #{inspect(url)} to: #{inspect(failed_nodes)}")
        :error
    end
  end
end
