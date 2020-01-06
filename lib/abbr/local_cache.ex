defmodule Abbr.LocalCache do
  @moduledoc """
  Caches shortened and original URLs on local node
  """

  alias Abbr.ETSTableManager
  alias Abbr.Url

  use ETSTableManager
  use GenServer

  @impl ETSTableManager
  def table_definition, do: {__MODULE__, [:set, :public, :named_table]}

  @impl ETSTableManager
  def on_receive_table(table, _state), do: table

  @spec save(%Url{}) :: :ok
  def save(%Url{} = url) do
    GenServer.call(__MODULE__, {:save, url})
  end

  @spec lookup(Url.short()) :: %Url{} | nil
  def lookup(short) when is_binary(short) do
    case :ets.lookup(__MODULE__, short) do
      [{^short, original}] -> %Url{short: short, original: original}
      [] -> nil
    end
  end

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(:ok) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:save, %Url{short: short, original: original}}, _from, table) do
    true = :ets.insert(table, {short, original})
    {:reply, :ok, table}
  end
end
