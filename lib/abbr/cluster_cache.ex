defmodule Abbr.ClusterCache do
  @moduledoc """
  Handles distributing cache save to entire cluster
  """

  alias Abbr.LocalCache

  use GenServer

  def save(url) do
    Enum.map(:pg2.get_members(:abbr_cluster_cache), fn pid ->
      :ok = GenServer.call(pid, {:save, url})
    end)
  end

  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def init(:ok) do
    state = :pg2.join(:abbr_cluster_cache, self())
    {:ok, state}
  end

  def handle_call({:save, url}, _from, state) do
    {:reply, LocalCache.save(url), state}
  end
end
