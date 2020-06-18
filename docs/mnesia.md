# Mnesia

Start with `CACHE_STRATEGY=mnesia`.

Uses Mnesia database to store shortened URL data. The moving parts are:
- local cache that is actually just access to Mnesia stored data, see [`Abbr.Mnesia.Local`](../lib/abbr/mnesia/local.ex)
- cache synchronization service that reacts to Mnesia topology changes, see [`Abbr.Mnesia.Sync`](../lib/abbr/mnesia/sync.ex)
- entry point to cache interface, see [`Abbr.Mnesia`](../lib/abbr/mnesia.ex)

Mnesia automatically replicates the stored data across the cluster.
However, you need to deal manually with network split situations. It offers no out the box solution by itself.
The standard way of healing a Mnesia cluster is usually to restart Mnesia on nodes with obsolete data or just declare a master node.
But, that looses the data on affected nodes, e.g. see how [Pow](https://github.com/danschultzer/pow) does it:
- https://github.com/danschultzer/pow/blob/master/lib/pow/store/backend/mnesia_cache/unsplit.ex
- https://github.com/danschultzer/pow/blob/1e18930edd856c91360cbcd9cd3c8f37ad099e8f/lib/pow/store/backend/mnesia_cache.ex#L314-L330
- https://elixirforum.com/t/help-reviewing-distributed-mnesia-cache-in-pow/24635/3

So, we needed a way to reconcile the data across cluster.
There are a few libraries out there that can help, see:
- [unsplit](https://github.com/uwiger/unsplit)
- [reunion](https://github.com/snar/reunion)

Unfortunately, there were issues preventing their direct usage.
The final solution in [`Abbr.Mnesia.Sync`](../lib/abbr/mnesia/sync.ex) was basically copied from those libraries.
The gist of it is:
- subscribe for `:inconsistent_database` Mnesia event
- merge data between affected nodes

Here we take advantage of data itself, it's easily mergeable, as described in [Working assumptions](../README.md#working-assumptions).
Merging is facilitated by undocumented [`:mnesia_controller.connect_nodes/2`](https://github.com/blackberry/Erlang-OTP/blob/master/lib/mnesia/src/mnesia_controller.erl).
It exposes a hook where reconciliation function can do it's work.

Mnesia also offers replication. You can make use of it e.g. via `Table.create_copy(Url, Node.self(), :ram_copies)` which would result in local replica.
This isn't strictly required, but is supposed to improve performance and availability.
That being said, it was not the focus of this experiment, and so it is not part of the Mnesia solution.

Problems:
- it's a little gossipy since all nodes in all parts of the cluster will try to sync, when in fact only a single node sync from one part of the split would do just fine

Here are some results. We have several scenarios:
- `Save and lookup waiting on table always`
  - due to network splits, there might be a moment where related table isn't available
  - this scenario ensures we wait on the table for every storage access
  - it also degrades performance a bit
- `Save and lookup waiting on table only on retries`
  - this is the current solution
  - it first tries to access the table
  - and only waits for it if not available
- `Lookup dirty reading, save waiting on table only on retries`
  - this introduces dirty reading
  - Mnesia allows for so called "dirty" access, without transaction
  - but there was no noticable performance gain

Check out [`Abbr.Mnesia.Local`](../lib/abbr/mnesia/local.ex) for details, with some code snippets for each of the options described.

Scenario | Splits | Create errors | Execute errors | Req/s
-------- | -------- | -------- | -------- | -------- 
Save and lookup waiting on table always | No | 0 | 0 | 2149 
&nbsp; | Yes | 0 | 0 | 2366 
Save and lookup waiting on table only on retries | No | 0 | 0 | 2419 
&nbsp; | Yes | 0 | 0 | 2687 
Lookup dirty reading, save waiting on table only on retries | No | 0 | 0 | 2654 
&nbsp; | Yes | 0 | 3 | 2436 

Resources:
- [How to start up mnesia in a cluster?](https://elixirforum.com/t/how-to-start-up-mnesia-in-a-cluster/24158/4)
- [How to add a node to an mnesia cluster?](https://stackoverflow.com/questions/787755/how-to-add-a-node-to-an-mnesia-cluster/788847#788847)
- [Data replication across nodes](https://github.com/sheharyarn/memento/issues/17)
- [Distribution and fault tolerance](http://erlang.org/doc/apps/mnesia/Mnesia_chap5.html#distribution-and-fault-tolerance)
- [Ensure Mnesia schema replication](https://stackoverflow.com/questions/38033514/erlang-ensure-mnesia-schema-replication)
- [Bulk loading into Mnesia](https://www.metabrew.com/article/on-bulk-loading-data-into-mnesia)
- [Loading large number of records into Mnesia](https://elixirforum.com/t/can-i-batch-write-large-number-of-record-to-mnesia-at-the-same-time/18482/6)
- [Ways to retrieve all records from a table](http://erlang.org/pipermail/erlang-questions/2005-August/016441.html)
