defmodule Abbr.ClusterCache.Monitor do
  @moduledoc """
  Notes:
  - detects when a new node has joined the cluster
  - ensures the node cache process is started and in pg2 group
  - and synchronises data between nodes
  - relies on existing cache implementation, e.g. `Abbr.ClusterCache.SyncOnStartup`
  - uses `GenServer.call` to fetch data to merge locally, ensuring the sync

  Problems:
  - assumes all new nodes are of same application type
    if not, it will wait for cluster cache process on that new node indefinitely
  - it's a little gossipy since all nodes in all parts of the cluster will try to sync
    when in fact, only a single node sync from one part of the split would do just fine
    and, entire cache is synced instead of just differences
  """

  alias Abbr.Constants
  alias Abbr.LocalCache

  use GenServer

  require Logger

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    cache_process_name = Keyword.fetch!(opts, :cache_process_name)
    GenServer.start_link(__MODULE__, cache_process_name, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(cache_process_name) do
    :net_kernel.monitor_nodes(true)
    {:ok, cache_process_name}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, state) do
    Logger.debug("received :nodeup #{node}")
    Process.send(self(), {:wait_for_cluster_cache, node}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:wait_for_cluster_cache, node}, cache_process_name) do
    if source = cluster_cache_process(node, cache_process_name) do
      Logger.debug("merging from #{inspect(source)}")

      source
      |> GenServer.call(:export)
      |> LocalCache.merge()
    else
      Process.send_after(
        self(),
        {:wait_for_cluster_cache, node},
        Constants.cluster_cache_wait_ms()
      )
    end

    {:noreply, cache_process_name}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp cluster_cache_process(node, cache_process_name) do
    case :rpc.call(node, Process, :whereis, [cache_process_name]) do
      pid when is_pid(pid) ->
        members = :pg2.get_members(Constants.cluster_cache_group_name())

        if Enum.member?(members, pid) do
          pid
        end

      _ ->
        nil
    end
  end
end
