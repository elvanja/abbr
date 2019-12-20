defmodule Abbr.Shorten do
  alias Abbr.Url
  alias Abbr.UrlStorage

  @hash_key "abbr:url"

  def given(original) do
    url = %Url{
      short: hash_original(original),
      original: original
    }

    UrlStorage.save(url)

    {:ok, url.short}
  end

  defp hash_original(original) do
    :sha256
    |> :crypto.hmac(@hash_key, original)
    |> Base.encode16()
    |> String.slice(0, 6)
  end
end
