defmodule Abbr.Cache do
  @moduledoc """
  Caches shortened and original URLs
  """

  alias Abbr.ClusterCache
  alias Abbr.LocalCache

  defdelegate save(url), to: ClusterCache
  defdelegate lookup(short), to: LocalCache
end
