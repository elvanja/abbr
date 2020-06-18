defmodule Abbr.Mnesia.Sync do
  @moduledoc """
  Ensures cache stays in sync across cluster.

  Flow:
  - monitors the `:inconsistent_database` mnesia system event
  - and merges local cache with (potentially) out of sync node
  """

  alias Abbr.Cache
  alias Abbr.Mnesia.Local
  alias Abbr.Mnesia.Url
  alias Memento.Schema
  alias Memento.Table
  alias Phoenix.PubSub

  use GenServer

  require Logger

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
    :ok = GenServer.cast(__MODULE__, :synchronize_on_startup)
    {:ok, pid}
  end

  @impl GenServer
  def init(:ok) do
    Logger.metadata(node: Node.self())
    :mnesia.subscribe(:system)
    {:ok, nil}
  end

  @doc """
  The node is either the 1st node in the cluster in which case:
  - it needs to create the table

  or, it needs to join the Mnesia cluster, which requires:
  - registering the node via `:mnesia.change_config/2`, which effectively joins the Mnesia cluster
  - waiting for table to become available

  We're using Memento master branch due to usage of:
  - `Memento.wait/1`
  - `Memento.add_nodes/1`
  When [PR 20](https://github.com/sheharyarn/memento/pull/20) is released, we can move to release version.
  """
  @impl GenServer
  def handle_cast(:synchronize_on_startup, state) do
    if Enum.empty?(Node.list()) do
      Schema.set_storage_type(Node.self(), :ram_copies)
      Table.create(Url)
      Memento.wait([Url])
      PubSub.broadcast(Abbr.PubSub, Cache.events_topic(), {:cache_event, :synchronized})
    else
      Memento.add_nodes(Node.list())
      Memento.wait([Url])
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:merge, cached_data}, state) do
    Memento.wait([Url])
    :ok = Local.merge(cached_data)
    PubSub.broadcast(Abbr.PubSub, Cache.events_topic(), {:cache_event, :synchronized})
    {:noreply, state}
  end

  @doc """
  Catches the `:inconsistent_database` Mnesia event.
  It occurs every time a node joins the cluster, for which the schema is not in sync with this node.
  It can even occur if there are no differences in the underlying data,
  e.g. if during network split there were no new data added to respective tables.
  Every time this event occurs, we need to reconcile the data.
  It needs to be done manually, since Mnesia doesn't know which reconciliation method suits our data.
  """
  @impl true
  def handle_info({:mnesia_system_event, {:inconsistent_database, _, node}}, state) do
    :global.trans({__MODULE__, self()}, fn -> join(node) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp join(node) do
    :running_db_nodes
    |> Memento.system()
    |> Enum.member?(node)
    |> case do
      true ->
        Logger.info("Already healed and joined #{node}")
        :ok

      false ->
        Logger.warn("Detected netsplit on #{node}")
        do_join(node)
    end
  end

  defp do_join(node) do
    :mnesia_controller.connect_nodes([node], fn merge_fun ->
      case merge_fun.([Url]) do
        {:merged, _, _} = result ->
          :ok = GenServer.cast({__MODULE__, node}, {:merge, Local.export()})
          result

        other ->
          other
      end
    end)
  end
end
