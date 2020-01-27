defmodule Abbr.LocalCacheSync do
  @moduledoc """
  Ensures cache stays in sync across cluster.

  Flow:
  - detects when a new node has joined the cluster
  - waits until related cache process is started on that node
  - and sends local cache to that node

  Relies on the fact that all newly connected nodes receive `nodeup` event.
  This ensures all nodes in newly formed cluster will exchange their data.
  Inherently covers new nodes being started too.

  Problems:
  - assumes all new nodes are of same application type
    if not, it will indefinitely wait for cache process on that node
  - it's a little gossipy since all nodes in all parts of the cluster will try to sync
    when in fact, only a single node sync from one part of the split would do just fine
  - entire cache is synced instead of just differences

  Related to waiting for __MODULE__ process on new node,
  we can't just cast to new node, since freshly started nodes don't run that process yet.
  Hence, a small loop to wait for that process.
  Another approach was to use :pg2 membership, but `nodeup` comes way before process is started
  and :pg2 doesn't emit any events for new group joins, so we'd have to wait for the process too.
  """

  alias Abbr.Cache
  alias Abbr.LocalCache
  alias Phoenix.PubSub

  use GenServer

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
    :ok = GenServer.cast(__MODULE__, :synchronize_on_startup)
    {:ok, pid}
  end

  @impl GenServer
  def init(:ok) do
    :net_kernel.monitor_nodes(true)
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast(:synchronize_on_startup, state) do
    if Enum.empty?(Node.list()) do
      PubSub.broadcast(Abbr.PubSub, Cache.events_topic(), {:cache_event, :synchronized})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:merge, cached_data}, state) do
    :ok = LocalCache.merge(cached_data)
    PubSub.broadcast(Abbr.PubSub, Cache.events_topic(), {:cache_event, :synchronized})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, state) do
    Process.send(self(), {:sync_with, node}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:sync_with, node}, state) do
    if cache_sync_running?(node) do
      :ok = GenServer.cast({__MODULE__, node}, {:merge, LocalCache.export()})
    else
      Process.send_after(self(), {:sync_with, node}, 10)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp cache_sync_running?(node) do
    case :rpc.call(node, Process, :whereis, [__MODULE__]) do
      pid when is_pid(pid) -> true
      _ -> false
    end
  end
end
