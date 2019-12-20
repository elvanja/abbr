defmodule Abbr.UrlStorage do
  use GenServer

  alias Abbr.ETSTableManager
  alias Abbr.Url

  def start_link(_) do
    {:ok, _} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ok = GenServer.cast(self(), :get_table)
    {:ok, nil}
  end

  def save(%Url{} = url) do
    GenServer.cast(__MODULE__, {:save, url})
  end

  def fetch(short) when is_binary(short) do
    GenServer.call(__MODULE__, {:fetch, short})
  end

  def handle_cast({:save, %Url{short: short} = url}, table) do
    true = :ets.insert(table, {short, url})
    {:noreply, table}
  end

  def handle_cast(:get_table, nil) do
    {:noreply, ETSTableManager.give_table()}
  end

  def handle_call({:fetch, short}, _from, table) do
    url =
      case :ets.lookup(table, short) do
        [{_, url}] -> url
        [] -> nil
      end

    {:reply, url, table}
  end

  def handle_info({:"ETS-TRANSFER", table, _manager_pid, _data}, _state) do
    {:noreply, table}
  end
end
