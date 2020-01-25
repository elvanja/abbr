defmodule Abbr.CacheMonitor do
  @moduledoc """
  TODO
  """

  alias Abbr.LocalCache

  use GenServer

  require Logger

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(:ok) do
    :net_kernel.monitor_nodes(true)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, state) do
    case :rpc.call(node, LocalCache, :export, []) do
      {:badrpc, {:EXIT, {:undef, _}}} ->
        Logger.info("Node #{node} does not have #{LocalCache}")

      {:badrpc, reason} ->
        Logger.error("Could not collect remote cache from #{node}, reason: #{inspect(reason)}")

      remote_cache ->
        LocalCache.merge(remote_cache)
        combined_cache = LocalCache.export()
        other_nodes = Node.list()

        {_, failed_nodes} =
          :rpc.multicall(other_nodes, LocalCache, :merge, [combined_cache], :timer.seconds(5))

        if !Enum.empty?(failed_nodes) do
          Logger.error("Could not merge cache to: #{inspect(failed_nodes)}")
        end
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
