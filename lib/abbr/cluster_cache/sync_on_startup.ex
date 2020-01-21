defmodule Abbr.ClusterCache.SyncOnStartup do
  @moduledoc """
  Notes:
  - works when new node in cluster is started
  - it picks up data from other members
  - and then the node is ready to accept requests

  Problems:
  - doesn't cover net splits
  - data stored on an instance in another part of the network
    will not be propagated to this part of the network
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
end
