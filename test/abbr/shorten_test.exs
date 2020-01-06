defmodule Abbr.ShortenTest do
  use Abbr.DataCase, async: true

  alias Abbr.Cache
  alias Abbr.Shorten

  test "generates same short url given same original" do
    {:ok, short} = Shorten.given("http://original.com")
    assert {:ok, ^short} = Shorten.given("http://original.com")
  end

  test "saves urls in cache" do
    {:ok, short} = Shorten.given("http://original.com")
    url = Cache.lookup(short)
    assert url.original == "http://original.com"
  end
end
