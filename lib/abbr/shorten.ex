defmodule Abbr.Shorten do
  @moduledoc """
  Shortens the original URL.
  Ensures that shortened URL information is distributed throughout the cluster.
  """

  alias Abbr.Cache
  alias Abbr.Url

  @hash_key "9373a09d-62c2-40cf-8049-2fb953008f78-e998bdba-3275-470e-b4fe-10ff3bd3eda3"

  @spec given(Url.original()) :: {:ok, Url.short()} | :error
  def given(original) do
    url = %Url{
      short: hash_original(original),
      original: original
    }

    case Cache.save(url) do
      :ok -> {:ok, url.short}
      :error -> :error
    end
  end

  defp hash_original(original) do
    :hmac
    |> :crypto.mac(:sha256, @hash_key, original)
    |> Base.encode16()
    |> String.slice(0, 8)
  end
end
