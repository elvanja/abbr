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

  def lookup(short) when is_binary(short) do
    GenServer.call(__MODULE__, {:lookup, short})
  end

  def handle_cast({:save, %Url{short: short, original: original}}, table) do
    true = :ets.insert(table, {short, original})
    {:noreply, table}
  end

  def handle_cast(:get_table, nil) do
    {:noreply, ETSTableManager.give_table()}
  end

  def handle_call({:lookup, short}, _from, table) do
    url =
      case :ets.lookup(table, short) do
        [{^short, original}] -> %Url{short: short, original: original}
        [] -> nil
      end

    {:reply, url, table}
  end

  def handle_info({:"ETS-TRANSFER", table, _manager_pid, _data}, _state) do
    {:noreply, table}
  end
end
