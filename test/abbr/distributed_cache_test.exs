defmodule Abbr.DistributedCacheTest do
  use Abbr.DataCase, async: false

  alias Abbr.Cache
  alias Abbr.Url
  alias Ecto.UUID

  @node_prefix "abbr_distributed_cache_cluster_"

  setup_all do
    nodes = LocalCluster.start_nodes(@node_prefix, 3)

    on_exit(fn ->
      LocalCluster.stop_nodes(nodes)
    end)

    [nodes: nodes]
  end

  setup(%{nodes: nodes}) do
    on_exit(fn ->
      Schism.heal(nodes)
    end)
  end

  test "syncs cache across stable cluster", %{nodes: [node1, node2, node3]} do
    urls = build_urls(100)

    Enum.each(urls, &(:ok = :rpc.call(node1, Cache, :save, [&1])))

    eventually(fn ->
      Enum.each(urls, fn url ->
        assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
      end)
    end)
  end

  test "cache remains out of sync while network partition lasts", %{nodes: [node1, node2, node3]} do
    [left_partition_urls, right_partition_urls] = Enum.chunk_every(build_urls(100), 50)

    Schism.partition([node1, node2])
    Schism.partition([node3])

    Enum.each(left_partition_urls, &(:ok = :rpc.call(node1, Cache, :save, [&1])))
    Enum.each(right_partition_urls, &(:ok = :rpc.call(node3, Cache, :save, [&1])))

    eventually(fn ->
      Enum.each(left_partition_urls, fn url ->
        assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
        refute :rpc.call(node3, Cache, :lookup, [url.short]) == url
      end)
    end)

    eventually(fn ->
      Enum.each(right_partition_urls, fn url ->
        refute :rpc.call(node1, Cache, :lookup, [url.short]) == url
        refute :rpc.call(node2, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
      end)
    end)
  end

  test "syncs cache after network partition healed", %{nodes: [node1, node2, node3]} do
    [left_partition_urls, right_partition_urls] = Enum.chunk_every(build_urls(100), 50)

    Schism.partition([node1, node2])
    Schism.partition([node3])

    Enum.each(left_partition_urls, &(:ok = :rpc.call(node1, Cache, :save, [&1])))
    Enum.each(right_partition_urls, &(:ok = :rpc.call(node3, Cache, :save, [&1])))

    Schism.heal([node1, node2, node3])

    eventually(fn ->
      Enum.each(left_partition_urls, fn url ->
        assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
      end)
    end)

    eventually(fn ->
      Enum.each(right_partition_urls, fn url ->
        assert :rpc.call(node1, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node2, Cache, :lookup, [url.short]) == url
        assert :rpc.call(node3, Cache, :lookup, [url.short]) == url
      end)
    end)
  end

  test "new node receives the existing cache data", %{nodes: nodes} do
    urls = build_urls(100)

    Enum.each(urls, &(:ok = :rpc.call(hd(nodes), Cache, :save, [&1])))

    new_node = add_node()

    eventually(fn ->
      Enum.each(urls, fn url ->
        assert :rpc.call(new_node, Cache, :lookup, [url.short]) == url
      end)
    end)

    remove_node(new_node)
  end

  defp add_node do
    [new_node] = LocalCluster.start_nodes(@node_prefix <> "new_node_", 1)
    Node.set_cookie(new_node, Node.get_cookie())
    new_node
  end

  defp remove_node(node) do
    LocalCluster.stop_nodes([node])
  end

  defp build_urls(count) do
    Enum.map(1..count, fn _ -> build_url() end)
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
