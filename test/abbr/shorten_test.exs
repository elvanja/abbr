defmodule Abbr.ShortenTest do
  use Abbr.DataCase, async: true

  alias Abbr.Shorten
  alias Abbr.UrlStorage

  test "generates same short url given same original" do
    {:ok, short} = Shorten.given("http://original.com")
    assert {:ok, ^short} = Shorten.given("http://original.com")
  end

  test "saves urls in storage" do
    {:ok, short} = Shorten.given("http://original.com")
    url = UrlStorage.lookup(short)
    assert url.original == "http://original.com"
  end
end
