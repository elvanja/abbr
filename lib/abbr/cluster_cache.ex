defmodule Abbr.ClusterCache do
  @moduledoc """
  Handles distributing cache save to entire cluster
  """

  alias Abbr.LocalCache
  alias Abbr.Url

  use GenServer

  @spec save(%Url{}) :: :ok
  def save(url) do
    Enum.each(:pg2.get_members(:abbr_cluster_cache), fn pid ->
      :ok = GenServer.call(pid, {:save, url})
    end)

    :ok
  end

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(:ok) do
    state = :pg2.join(:abbr_cluster_cache, self())
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:save, url}, _from, state) do
    {:reply, LocalCache.save(url), state}
  end
end
