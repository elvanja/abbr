defmodule Abbr.Expand do
  alias Abbr.Url
  alias Abbr.Cache

  def given(short) do
    case Cache.lookup(short) do
      %Url{original: original} -> {:ok, original}
      _ -> {:error, :not_found}
    end
  end
end
