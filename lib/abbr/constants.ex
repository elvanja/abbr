defmodule Abbr.Constants do
  @moduledoc """
  Contains various internal Abbr constants.
  """

  def cluster_cache_group_name, do: :abbr_cluster_cache
  def cluster_cache_wait_ms, do: 10
end
