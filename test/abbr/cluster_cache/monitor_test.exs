defmodule Abbr.ClusterCache.MonitorTest do
  use Abbr.DataCase, async: false

  alias Abbr.Cache
  alias Abbr.Url

  setup_all do
    Application.put_env(:abbr, :cluster_strategy, "monitor")
    nodes = LocalCluster.start_nodes("abbr", 2)
    [nodes: nodes]
  end

  test "syncs cache across live cluster", %{nodes: [node1, node2]} do
    url = build_url()

    :ok = :rpc.call(node1, Cache, :save, [url])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
    end)
  end

  test "can't sync cache during network partition", %{nodes: [node1, node2]} do
    url = build_url()

    Schism.partition([node1])
    Schism.partition([node2])

    :ok = :rpc.call(node1, Cache, :save, [url])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      refute :rpc.call(node2, Cache, :lookup, [url.short]) == url
    end)

    Schism.heal([node1, node2])
  end

  test "syncs cache after network partition", %{nodes: [node1, node2]} do
    url = build_url()

    Schism.partition([node1])
    Schism.partition([node2])

    :ok = :rpc.call(node1, Cache, :save, [url])

    Schism.heal([node1, node2])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
    end)
  end

  defp build_url do
    %Url{
      short: Ecto.UUID.generate(),
      original: "http://www.home_of_long_urls.com?q=some+very+long+param+list"
    }
  end

  def eventually(f, retries \\ 0) do
    f.()
  rescue
    err ->
      if retries >= 10 do
        raise err
      else
        :timer.sleep(200)
        eventually(f, retries + 1)
      end
  end
end
