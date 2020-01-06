defmodule Abbr.Shorten do
  @moduledoc """
  Shortens the original URL.
  Ensures that shortened URL information is distributed throughout the cluster.
  """

  alias Abbr.Cache
  alias Abbr.Url

  @hash_key "abbr:url"

  @spec given(Url.original()) :: {:ok, Url.short()}
  def given(original) do
    url = %Url{
      short: hash_original(original),
      original: original
    }

    Cache.save(url)

    {:ok, url.short}
  end

  defp hash_original(original) do
    :sha256
    |> :crypto.hmac(@hash_key, original)
    |> Base.encode16()
    |> String.slice(0, 6)
  end
end
