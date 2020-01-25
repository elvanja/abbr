defmodule Abbr.DistributedCacheTest do
  use Abbr.DataCase, async: false

  alias Abbr.Cache
  alias Abbr.Url
  alias Ecto.UUID

  setup_all do
    nodes = LocalCluster.start_nodes("abbr_distributed_cache_cluster_", 3)

    on_exit(fn ->
      LocalCluster.stop_nodes(nodes)
    end)

    [nodes: nodes]
  end

  test "syncs cache across stable cluster", %{nodes: [node1, node2, node3]} do
    url = build_url()

    :ok = :rpc.call(node1, Cache, :save, [url])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
    end)
  end

  test "cache remains out of sync while network partition lasts", %{nodes: [node1, node2, node3]} do
    url = build_url()

    Schism.partition([node1, node2])
    Schism.partition([node3])

    :ok = :rpc.call(node1, Cache, :save, [url])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
      refute :rpc.call(node3, Cache, :lookup, [url.short]) == url
    end)

    Schism.heal([node1, node2, node3])
  end

  test "syncs cache after network partition healed", %{nodes: [node1, node2, node3]} do
    url = build_url()

    Schism.partition([node1, node2])
    Schism.partition([node3])

    :ok = :rpc.call(node1, Cache, :save, [url])

    Schism.heal([node1, node2, node3])

    eventually(fn ->
      assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
      assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
    end)
  end

  defp build_url do
    %Url{
      short: UUID.generate(),
      original: "http://www.home_of_long_urls.com?q=some+very+long+param+list"
    }
  end

  def eventually(f, retries \\ 0) do
    f.()
  rescue
    error ->
      if retries >= 10 do
        reraise error, System.stacktrace()
      else
        :timer.sleep(200)
        eventually(f, retries + 1)
      end
  end
end
