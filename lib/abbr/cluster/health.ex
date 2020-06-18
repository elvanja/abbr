defmodule Abbr.Cluster.Health do
  @moduledoc """
  Carries information on whether this instance is in good health or not.

  We don't capture "out of sync" events.
  Once network split occurs, each part thinks it's working correctly.
  So, once a node is reported as in sync, it stays that way.
  """

  alias Abbr.Cache
  alias Phoenix.PubSub

  use GenServer

  @spec healthy? :: boolean()
  def healthy?, do: GenServer.call(__MODULE__, :healthy?)

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(:ok) do
    Logger.metadata(node: Node.self())
    PubSub.subscribe(Abbr.PubSub, Cache.events_topic())
    {:ok, false}
  end

  @impl GenServer
  def handle_call(:healthy?, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info({:cache_event, :synchronized}, _state) do
    {:noreply, true}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
