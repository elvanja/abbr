defmodule Abbr.Expand do
  @moduledoc """
  Expands the original URL from short one.
  """

  alias Abbr.Cache
  alias Abbr.Url

  def given(short) do
    case Cache.lookup(short) do
      %Url{original: original} -> {:ok, original}
      _ -> {:error, :not_found}
    end
  end
end
