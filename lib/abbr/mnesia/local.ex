defmodule Abbr.Mnesia.Local do
  @moduledoc """
  Access to underlying Mnesia stored data.
  """

  alias Abbr.Mnesia.Url, as: Table
  alias Abbr.Url
  alias Memento.Query

  require Logger

  @behaviour Abbr.Cache

  @doc """
  Retrieves stored shortened URL.

  There are a few way to do this.
  The usual would be to just `Query.read(Table, short)`.
  But, that doesn't work in face of network splits since table might not be accessible during cluster healing.
  So, we need to wait for the table.

  One option, the simplest one is just to wait for it every time:
  ```
  defp lookup(short) do
    lookup = fn -> Query.read(Table, short) end

    case execute(lookup, true) do
      {:ok, nil} -> nil
      {:ok, data} -> struct(Url, Map.from_struct(data))
      {:error, _reason} -> nil
    end
  end
  ```
  But, that does degrade the performance a bit.

  Another idea is to use dirty reading:
  ```
  def lookup(short) do
    fun = fn -> :mnesia.dirty_read(Table, short) end

    case execute_dirty_with_table(fun) do
      [{Table, short, original}] -> %Url{short: short, original: original}
      [] -> nil
    end
  catch
    reason ->
      Logger.error("Could not read data for \#{short}, reason: \#{inspect(reason)}")
      nil
  end
  ```
  This of course works, but I couldn't measure any meaningful performance gain.
  It introduces the "dirty" usage of Mnesia, with no apparent gain.
  Hence, decided to stay with transaction approach.
  """
  @spec lookup(Url.short()) :: Url.t() | nil
  def lookup(short) do
    lookup = fn -> Query.read(Table, short) end

    case execute_with_table(lookup) do
      {:ok, nil} ->
        nil

      {:ok, data} ->
        struct(Url, Map.from_struct(data))

      {:error, reason} ->
        Logger.error("Could not read data for #{short}, reason: #{inspect(reason)}")
        nil
    end
  end

  @spec save(Url.t()) :: :ok | :error
  def save(url) do
    save = fn ->
      Table
      |> struct(Map.from_struct(url))
      |> Query.write()
    end

    case execute_with_table(save) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to save #{inspect(url)}, reason: #{inspect(reason)}")
        :error
    end
  end

  defp execute_with_table(fun) do
    case execute(fun) do
      {:error, {:no_exists, Table}} -> execute(fun, true)
      result -> result
    end
  end

  defp execute(fun, wait_for_table \\ false) do
    Memento.transaction(fn ->
      if wait_for_table, do: Memento.wait([Table])
      fun.()
    end)
  end

  @doc """
  Exports the entire locally stored data.

  There are a few "in transaction" ways to achieve the same.
  Simplest being just `&Memento.Query.all/1` or something like:
  ```
  {:ok, data} = Memento.transaction(fn ->
    :mnesia.foldl(fn record, acc -> [record | acc] end, [], Table)
  end)
  ```
  But, both export and merge need to be fast, to sync the nodes as soon as possible.
  Hence, decided to use the dirty variant of match idea.
  """
  @spec export :: list(any())
  def export do
    Table
    |> :mnesia.dirty_match_object({:_, :_, :_})
    |> Enum.map(fn {_, key, value} ->
      %Url{short: key, original: value}
    end)
  end

  @doc """
  Merges the supplied URL list to existing local data.

  As with `&export/0`, there was a few "in transaction" ways to do this, e.g.
  ```
  Memento.transaction(fn ->
    for url <- list do
      :ok = save(url)
    end
  end)
  ```
  But, again, for performance reasons, decided to go with dirty variant.
  """
  @spec merge(list(any())) :: :ok
  def merge(list) do
    :mnesia.ets(fn -> Enum.each(list, &save_dirty/1) end)
    :ok
  end

  defp save_dirty(%{short: short, original: original}) do
    execute_dirty_with_table(fn ->
      :ok = :mnesia.dirty_write({Table, short, original})
    end)
  end

  defp execute_dirty_with_table(fun) do
    execute_dirty(fun)
  rescue
    e in MatchError ->
      case e.term do
        {:EXIT, {:aborted, {:node_not_running, _}}} -> execute_dirty(fun, true)
        _ -> raise(e)
      end
  catch
    :exit, {:aborted, {:no_exists, Table}} -> execute_dirty(fun, true)
  end

  defp execute_dirty(fun, wait_for_table \\ false) do
    if wait_for_table, do: Memento.wait([Table])
    fun.()
  end
end
