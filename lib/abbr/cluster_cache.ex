defmodule Abbr.ClusterCache do
  @moduledoc """
  Handles distributing cache save to entire cluster
  """

  alias Abbr.Constants
  alias Abbr.LocalCache
  alias Abbr.Url
  alias Phoenix.PubSub

  use GenServer

  require Logger

  @events_topic "cache_events"
  @pg2_group Constants.cluster_cache_group_name()

  @spec save(%Url{}) :: :ok
  def save(url) do
    Enum.each(:pg2.get_members(@pg2_group), fn pid ->
      :ok = GenServer.call(pid, {:save, url})
    end)

    :ok
  end

  @spec events_topic :: String.t()
  def events_topic, do: @events_topic

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

  @impl GenServer
  def handle_cast(:synchronize_on_startup, state) do
    other_members = :pg2.get_members(@pg2_group) -- [self()]
    Logger.debug("synchronizing on startup, from: #{inspect(other_members)}")

    other_members
    |> Enum.flat_map(&GenServer.call(&1, :export))
    |> LocalCache.merge()

    PubSub.broadcast(Abbr.PubSub, @events_topic, {:cache_event, :synchronized})
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
