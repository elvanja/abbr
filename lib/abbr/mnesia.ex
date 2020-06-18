defmodule Abbr.Mnesia do
  @moduledoc """
  Entry point to Mnesia cache solution.
  """

  alias Abbr.Mnesia.Local

  @behaviour Abbr.Cache

  @impl true
  defdelegate lookup(short), to: Local

  @impl true
  defdelegate save(url), to: Local
end
