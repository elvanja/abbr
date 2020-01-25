defmodule Abbr.Expand do
  @moduledoc """
  Expands the original URL from short one.
  """

  alias Abbr.Cache
  alias Abbr.Url

  @spec given(Url.short()) :: {:ok, Url.original()} | {:error, :not_found}
  def given(short) when is_binary(short) do
    case Cache.lookup(short) do
      %Url{original: original} -> {:ok, original}
      _ -> {:error, :not_found}
    end
  end
end
