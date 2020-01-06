defmodule Abbr.ETSTableManager do
  @moduledoc """
  Ensures ETS table survives owner process crashes.

  Inspired by:
  - https://blog.danielberkompas.com/2015/04/17/keep-your-ets-tables-alive
  - http://steve.vinoski.net/blog/2011/03/23/dont-lose-your-ets-tables
  - http://steve.vinoski.net/blog/2013/05/08/implementation-of-dont-lose-your-ets-tables
  """

  use GenServer

  @type table_name :: atom()
  @type ets_options :: list(any())
  @callback table_definition() :: {table_name(), ets_options()}

  @type table :: :ets.tid()
  @type state :: any()
  @callback on_receive_table(table(), state()) :: state()

  defmacro __using__(_) do
    quote do
      @behaviour Abbr.ETSTableManager

      def handle_info({:"ETS-TRANSFER", table, _manager_pid, _data}, state) do
        {:noreply, on_receive_table(table, state)}
      end
    end
  end

  @spec start_link(atom()) :: {:ok, pid()}
  def start_link(target_module) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    GenServer.cast(pid, {:create_table, target_module})
    {:ok, pid}
  end

  @impl GenServer
  def init(:ok) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:create_table, target_module}, _state) do
    {name, ets_options} = target_module.table_definition()
    table = :ets.new(name, [{:heir, self(), {}} | ets_options])
    give_away(table, target_module)
    {:noreply, {table, target_module}}
  end

  @impl GenServer
  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, {_, target_module} = state) do
    give_away(table, target_module)
    {:noreply, state}
  end

  defp give_away(table, target_module) do
    pid = wait_for(target_module)
    :ets.give_away(table, pid, {})
  end

  defp wait_for(module) do
    pid = Process.whereis(module)

    if pid && Process.alive?(pid) do
      pid
    else
      wait_for(module)
    end
  end
end
