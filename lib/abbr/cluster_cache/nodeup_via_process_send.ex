defmodule Abbr.ClusterCache.NodeupViaProcessSend do
  @moduledoc """
  Notes:
  - will handle new nodes correctly
  - also works for network splits

  Problems:
  - uses `Process.send` to send messages between nodes
  - can't use `GenServer.call` or `GenServer.cast` due to deadlock
    one node calls the other one with same message, e.g. the `:export_to`
    resulting in deadlock and timeout of related call/cast call
    thereby failing the synchronization
  """

  alias Abbr.Cache
  alias Abbr.Constants
  alias Abbr.LocalCache
  alias Phoenix.PubSub

  use GenServer

  require Logger

  @pg2_group Constants.cluster_cache_group_name()

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
    Logger.debug("started as #{inspect(pid)}")
    GenServer.cast(pid, :synchronize_on_startup)
    {:ok, pid}
  end

  @impl GenServer
  def init(:ok) do
    :net_kernel.monitor_nodes(true)
    :ok = :pg2.join(@pg2_group, self())
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:save, url}, _from, state) do
    {:reply, LocalCache.save(url), state}
  end

  @impl GenServer
  def handle_call(:export, _from, state) do
    {:reply, LocalCache.export(), state}
  end

  # credo:disable-for-lines:15 Credo.Check.Design.DuplicatedCode
  @impl GenServer
  def handle_cast(:synchronize_on_startup, state) do
    other_members = :pg2.get_members(@pg2_group) -- [self()]
    Logger.debug("synchronizing on startup, from: #{inspect(other_members)}")

    other_members
    |> Enum.flat_map(&GenServer.call(&1, :export))
    |> LocalCache.merge()

    PubSub.broadcast(Abbr.PubSub, Cache.events_topic(), {:cache_event, :synchronized})
    Logger.debug("finished synchronizing on startup")

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, state) do
    Logger.debug("received :nodeup #{node}")
    Process.send(self(), {:wait_for_cluster_cache, node}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:wait_for_cluster_cache, node}, state) do
    if source = cluster_cache_process(node) do
      Logger.debug("triggering export from #{inspect(source)}")
      Process.send(source, {:export_to, self()}, [])
    else
      Process.send_after(
        self(),
        {:wait_for_cluster_cache, node},
        Constants.cluster_cache_wait_ms()
      )
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:export_to, destination}, state) do
    Logger.debug("exporting to #{inspect(destination)}")
    Process.send(destination, {:merge, LocalCache.export(), self()}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:merge, data, from}, state) do
    Logger.debug("merging from #{inspect(from)}")
    LocalCache.merge(data)
    Logger.debug("cache merged")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp cluster_cache_process(node) do
    case :rpc.call(node, Process, :whereis, [__MODULE__]) do
      pid when is_pid(pid) ->
        members = :pg2.get_members(@pg2_group)

        if Enum.member?(members, pid) do
          pid
        end

      _ ->
        nil
    end
  end
end
