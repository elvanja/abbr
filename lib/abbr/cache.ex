defmodule Abbr.Cache do
  @moduledoc """
  Caches shortened and original URLs
  """

  alias Abbr.ETSTableManager
  alias Abbr.Url

  use ETSTableManager
  use GenServer

  def table_definition, do: {__MODULE__, [:set, :public, :named_table]}

  def on_receive_table(table, _state), do: table

  def save(%Url{} = url) do
    GenServer.call(__MODULE__, {:save, url})
  end

  def lookup(short) when is_binary(short) do
    case :ets.lookup(__MODULE__, short) do
      [{^short, original}] -> %Url{short: short, original: original}
      [] -> nil
    end
  end

  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def init(:ok) do
    {:ok, nil}
  end

  def handle_call({:save, %Url{short: short, original: original}}, _from, table) do
    true = :ets.insert(table, {short, original})
    {:reply, :ok, table}
  end
end
