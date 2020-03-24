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

  test "does not duplicate short url for similar originals" do
    {:ok, short1} =
      Shorten.given("https://www.original.com/very-very-long-slug-to-shorten-in-2020?q=3-263")

    {:ok, short2} =
      Shorten.given("https://www.original.com/very-very-long-slug-to-shorten-in-2020?q=18-961")

    refute short1 == short2
  end
end
