defmodule Abbr.ClusterCache.Basic do
  @moduledoc """
  Notes:
  - shares data between nodes, as it comes in

  Problems:
  - doesn't handle new nodes or network splits
  """

  alias Abbr.Constants
  alias Abbr.LocalCache

  use GenServer

  @pg2_group Constants.cluster_cache_group_name()

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
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
end
