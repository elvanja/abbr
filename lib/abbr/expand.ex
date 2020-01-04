defmodule Abbr.Expand do
  alias Abbr.Url
  alias Abbr.UrlStorage

  def given(short) do
    case UrlStorage.lookup(short) do
      %Url{original: original} -> {:ok, original}
      _ -> {:error, :not_found}
    end
  end
end
