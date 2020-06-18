# RPC

Start with `CACHE_STRATEGY=rpc`.
You can also leave it out, since this strategy is the default one.

The RPC term used to describe this cache mechanism is a bit misleading.
The solution actually uses [ETS](https://elixir-lang.org/getting-started/mix-otp/ets.html), [RPC](http://erlang.org/doc/man/rpc.html) and of course [GenServer](https://hexdocs.pm/elixir/GenServer.html).
The moving parts are:
- local cache that stores data in ETS table, see [`Abbr.Rpc.Local`](../lib/abbr/rpc/local.ex)
- cache synchronization service that is triggered on cluster topology changes, see [`Abbr.Rpc.Sync`](../lib/abbr/rpc/sync.ex)
- distributed cache that stores new data to all the nodes in their respective local cache, see [`Abbr.Rpc`](../lib/abbr/rpc.ex)

Each node in the cluster contains a full local copy of all the data.
For every shorten request, data is saved in all connected nodes.
Upon cluster topology changes, nodes send to each other their copy of data, to be merged with local data on other nodes.
Expanding short URL reads only local data. 

Problems:
- it's a little gossipy since all nodes in all parts of the cluster will try to sync, when in fact only a single node sync from one part of the split would do just fine

Here are some results. We have several scenarios:
- `Stable cluster`
  - where there are no network splits
  - and all cluster instances are always in sync
- `With network splits`
  - when cluster is broken apart repeatedly during the stress test

Scenario | Splits | Create errors | Execute errors | Req/s
-------- | -------- | -------- | -------- | -------- 
Stable cluster | No | 0 | 0 | 2238 
With network splits | Yes | 1 | 105 | 2840 
