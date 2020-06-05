defmodule Abbr.RpcCache.LocalCache do
  @moduledoc """
  Caches shortened and original URLs on local node.
  """

  alias Abbr.Util.ETSTableManager
  alias Abbr.Url

  use ETSTableManager
  use GenServer

  @impl ETSTableManager
  def table_definition, do: {__MODULE__, [:set, :public, :named_table]}

  @impl ETSTableManager
  def on_receive_table(table, _state), do: table

  @spec save(%Url{}) :: :ok
  def save(%Url{short: short, original: original}) do
    true = :ets.insert(__MODULE__, {short, original})
    :ok
  end

  @spec lookup(Url.short()) :: %Url{} | nil
  def lookup(short) when is_binary(short) do
    case :ets.lookup(__MODULE__, short) do
      [{^short, original}] -> %Url{short: short, original: original}
      [] -> nil
    end
  end

  @spec export :: list(any())
  def export, do: :ets.tab2list(__MODULE__)

  @spec merge(list(any())) :: :ok
  def merge(list) do
    true = :ets.insert(__MODULE__, list)
    :ok
  end

  @spec start_link([any()]) :: {:ok, pid()}
  def start_link(opts) do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  @impl GenServer
  def init(:ok) do
    {:ok, nil}
  end
end
