# on osx you typically need to run iex with distribution and click a prompt to allow epmd to open port connections
# e.g. execute `iex --sname gold`, and thus also make sure you can indeed start nodes with distribution
# see https://github.com/whitfin/local-cluster/issues/7
# related error: `{:failed_to_start_child, :net_kernel, {:EXIT, :nodistribution}}`
:ok = LocalCluster.start()

Application.ensure_all_started(:abbr)
ExUnit.start()
