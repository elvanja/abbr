defmodule Abbr.ClusterCache do
  @moduledoc """
  Handles distributing cache save to entire cluster
  """

  alias Abbr.LocalCache
  alias Abbr.Url
  alias Phoenix.PubSub

  use GenServer

  @events_topic "cache_events"
  @pg2_group :abbr_cluster_cache

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
    GenServer.cast(pid, :synchronize)
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

  @impl GenServer
  def handle_cast(:synchronize, state) do
    do_synchronize()
    PubSub.broadcast(Abbr.PubSub, @events_topic, {:cache_event, :synchronized})
    {:noreply, state}
  end

  defp do_synchronize do
    other_members = :pg2.get_members(@pg2_group) -- [self()]

    other_members
    |> Enum.flat_map(& GenServer.call(&1, :export))
    |> LocalCache.merge()
  end
end
