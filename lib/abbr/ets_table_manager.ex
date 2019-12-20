defmodule Abbr.ETSTableManager do
  use GenServer

  @spec start_link(atom, list) :: {:ok, pid}
  def start_link(name, ets_options \\ []) do
    GenServer.start_link(__MODULE__, %{name: name, ets_opts: ets_options}, name: __MODULE__)
  end

  def init(%{name: name, ets_opts: opts}) do
    table = :ets.new(name, [{:heir, self(), {}} | opts])
    {:ok, %{table: table, name: name, pid: nil}}
  end

  def give_table() do
    GenServer.call(__MODULE__, :give_table)
  end

  @doc "Handle the ETS transfer"
  def handle_info({:"ETS-TRANSFER", _table, _pid, _data}, state) do
    {:noreply, %{state | pid: nil}}
  end

  def handle_call(:give_table, {pid, _}, %{table: table, pid: nil} = state) do
    true = :ets.give_away(table, pid, {})
    {:reply, table, %{state | pid: pid}}
  end
end
