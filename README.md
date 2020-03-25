# Ab(b)r[acadabra](https://en.wikipedia.org/wiki/Abracadabra)

```
 █████╗    ██████╗    ██████╗    ██████╗    
██╔══██╗   ██╔══██╗   ██╔══██╗   ██╔══██╗   
███████║   ██████╔╝   ██████╔╝   ██████╔╝   
██╔══██║   ██╔══██╗   ██╔══██╗   ██╔══██╗   
██║  ██║██╗██████╔╝██╗██████╔╝██╗██║  ██║██╗
╚═╝  ╚═╝╚═╝╚═════╝ ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝
```

This is an experiment in distributed Elixir.
Main goal is to try out different ways of synchronising data between nodes and learn in the process.
It makes a lot of production unworthy assumptions.
Consider yourself warned!

## What does it do?

It acts as a URL shortening (aka a.b.b.r.eviating) service.
A seemingly simple problem that can easily get very much ouf of hand, especially if you're shooting for a large scale operation.

Here's a few resources to get you started:
- [URL Shortening: Hashes In Practice](https://blog.codinghorror.com/url-shortening-hashes-in-practice) 
- [How to build a Tiny URL service that scales to billions?](https://medium.com/swlh/how-to-build-a-tiny-url-service-that-scales-to-billions-f6fb5ea22e8c)
- [OTP in Elixir: Learn GenServer by Building Your Own URL Shortener](https://ieftimov.com/post/otp-elixir-genserver-build-own-url-shortener) 

In short (pun intended!) this service will:
- accept a long URL and return a short URL you can share
- accept the short URL and redirect to long URL

## What does it not do?

Well, for starters, it doesn't persist short URLs at all.
Also, it is not particularly interested in giving you the shortest possible short URL.
There's also no real guarantee that it will not create duplicate short URLs.
In short (again, pun intended!) it's not production worthy at all!

## Why bother?

Ah, the big question!
I needed some problem to use as the base for experimenting with distributed Elixir.
One that would be simple enough so as not to draw focus from the main idea and yet complex enough so it's not easily solved once you start applying it in scale.
URL shortening seemed like exactly the type of the problem to use for this.

## Main goal?

Let's set the stage:
- a cluster of nodes processing shortening URL requests and executing the shortened ones
- doing all that without an external data storage
- while surviving network splits, node outages and adding new nodes to the cluster

There are certainly many ways this can be achieved, with or without the self imposed limitation of no external data storage.
And that is exactly the point. The idea is to try out various things at disposal in Elixir ecosystem and see how they apply to the problem.

The aim for each approach is to:
- learn how it works
- see how complex it is to implement
- check out how well it behaves, how reliable and/or fast it is

There will be no final verdict on which approach is best (or worst).
Experience gained from trying out different options is the main goal.

## What approaches can I see here?

Excellent question!
Here's a brief overview of ideas used to tackle this (the order of appearance is totally arbitrary):
- [GenServer](https://hexdocs.pm/elixir/GenServer.html), [ETS](https://elixir-lang.org/getting-started/mix-otp/ets.html) and [RPC](http://erlang.org/doc/man/rpc.html)
- [persistent_term](https://erlang.org/doc/man/persistent_term.html)
- [Mnesia](https://erlang.org/doc/man/mnesia.html)
- [Cachex](https://hexdocs.pm/cachex/getting-started.html)
- [Nebulex](https://github.com/cabol/nebulex)
- [CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
- [Phoenix Presence](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
- [Partisan](https://partisan.cloud)
- [Riak Core](https://github.com/basho/riak_core)

For the moment, only the first one from the list is done.
So stay tuned for more :-)

## I'd like to see it in action!

Sure, got you covered!
You can set up a local cluster to play around with, just execute:
```bash
make start_cluster
make start_proxy
```

This will start two instances of the service and a [HAProxy](http://www.haproxy.org) in front of them.
Note that proxy is built as a [docker](https://www.docker.com) container with appropriate [configuration](scripts/haproxy/haproxy.cfg), so you'll need to build the image via `make build_proxy` before first run.
Proxy should then be available at http://localhost:4000, and it's admin panel can be accessed via `make open_proxy`.

From here, you can shorten any URL via API call like this:
```bash
➜  curl -s -X POST -H 'Content-type: application/json' -d '{"url":"https://info.original.com/very-very-long-slug-to-shorten-consistently-2019?q=2"}' http://localhost:4000/api/urls
{"short_url":"http://localhost:4000/2DD744"}
```

After that, when you open returned short URL in browser, you will be redirected to the long URL.

## Sure, but how does it behave under pressure?

Ah, yes, just shortening the URL is not really that interesting.
You can check out how it behaves under a load easily. You just need to install [k6](https://k6.io) first.
Then you can run a stress test like this:
```bash
make stress_test_cluster VUS=50 DURATION=10s BASE_SHORTEN_URL=https://www.original.com/very-very-long-slug-to-shorten-in-2020
```           

Check out related [stress test script](scripts/stress_test.js) for details on it's usage and the meaning of related environment variables.

You will get a result like this (some data omitted for brevity):
```
    █ create
      ✓ status is 201
      ✓ short URL returned

    █ execute
      ✓ correct redirect
      ✓ status is 302

    checks.....................: 100.00% ✓ 44780 ✗ 0
    create_duration............: avg=23.443109 min=6.727  med=19.431  max=131.708  p(90)=39.7964 p(95)=51.5677
    create_error_rate..........: 0.00%   ✓ 0     ✗ 10558
    execute_duration...........: avg=20.350771 min=4.974  med=17.4915 max=119.457  p(90)=32.2599 p(95)=42.63395
    execute_error_rate.........: 0.00%   ✓ 0     ✗ 11832
    http_req_duration..........: avg=21.8ms    min=4.97ms med=18.37ms max=131.7ms  p(90)=35.73ms p(95)=47.75ms
    http_reqs..................: 22390   2238.992646/s
```       

Most of the data there is already explained in [k6 docs](https://k6.io/docs/getting-started/results-output).
The rest are custom metrics and checks from mentioned script.
Additional checks and metrics of interest might be:
- `█ create` - recap of checks during shortening of long URLs 
- `create_error_rate` - how many errors occurred during shortening of long URLs 
- `█ execute` - recap of checks during executing short URLs 
- `execute_error_rate` - how many errors occurred during executing short URLs  

What happens is:
- stress test submits long URLs
- each submit request lands on one of the instances, balanced via proxy
- long URL is shortened and that information is synchronized between instances
- subsequent requests to short URL are executed on one or the other instance, balanced via proxy
- and are successful because all instances have up to date data

So, ideally, all checks passed and both error rates are at 0.
And for local testing on the started and stable cluster it will be just like that, as the test results show.

## How does it behave given network failures?

That's of most interest after all!
The scenario is very much similar to the ideal case. We start the stress test as before:
```bash
make stress_test_cluster VUS=50 DURATION=10s BASE_SHORTEN_URL=https://www.original.com/very-very-long-slug-to-shorten-in-2020
```

But, instead of leaving the cluster in peace, we make it split randomly during the stress test (this needs to be executed in separate shell):
```bash
➜  make split_cluster_repeatedly DURATION=10
instance 2 left the cluster
instance 2 joined the cluster
instance 2 left the cluster
instance 2 joined the cluster
instance 1 left the cluster
instance 1 joined the cluster
instance 2 left the cluster
instance 2 joined the cluster
```          

The splits occur randomly and last a random duration, distributed across given duration in seconds.
Since it's not easy to create network splits locally, this uses a bit of a trick.
It basically disconnects nodes via API call. See [`Abbr.Cluster`](lib/abbr/cluster.ex) for details.
The effect is the same as network split.

Upon leaving the cluster:
- both instances continue to run, but they have no knowledge of the other instance
- proxy sees them as active, so it continues to balance incoming requests normally
- for short ULRs in already synchronized data, short URL requests will continue to work correctly
- stress test submits new long URLs
- each submit request lands on one of the instances, balanced via proxy
- that instance stores the short URL data
- subsequent requests to short URL are executed on one or the other instance, balanced via proxy
- the instance that processed the submit request normally executes the short URL request  
- but the other instance has no knowledge of that short URL and returns 404

Upon joining the cluster:
- instances synchronize the data between them
- subsequent requests to short URL are executed on one or the other instance, balanced via proxy
- and are successful because all instances have up to date data

You will get a result like this (some data omitted for brevity): 
```bash
    █ create
      ✗ status is 201
       ↳  99% — ✓ 13168 / ✗ 1
      ✗ short URL returned
       ↳  99% — ✓ 13168 / ✗ 1

    █ execute
      ✗ status is 302
       ↳  99% — ✓ 15204 / ✗ 105
      ✗ correct redirect
       ↳  99% — ✓ 15204 / ✗ 105

    checks.....................: 99.62% ✓ 56602 ✗ 212
    create_500.................: 1      0.099998/s
    create_duration............: avg=17.846174 min=5.414  med=16.2    max=102.087  p(90)=25.0489 p(95)=29.1378
    create_error_rate..........: 0.00%  ✓ 1     ✗ 13147
    execute_404................: 105    10.499811/s
    execute_duration...........: avg=16.513127 min=4.29   med=15.257  max=100.729  p(90)=22.734  p(95)=26.408
    execute_error_rate.........: 0.68%  ✓ 105   ✗ 15154
    http_req_duration..........: avg=17.13ms   min=4.29ms med=15.66ms max=102.08ms p(90)=23.84ms p(95)=27.74ms
    http_reqs..................: 28407  2840.648883/s
```

And it behaves exactly as expected, almost.
Submission of long URL to shorten worked in most cases.
But, even those can fail if executed during the network split, because nodes still try to synchronize data to now disconnected node.
Service then rejects such submission with 500 status code, as can be seen in above example.
Also, we now have some get requests to short URL that returned 404, as expected.

## What about network splits that never heal?

Let's see how that goes:
```bash
make stress_test_cluster VUS=50 DURATION=10s BASE_SHORTEN_URL=https://www.original.com/very-very-long-slug-to-shorten-in-2020
```

And in another shell, after the test has been started:
```bash
make leave_cluster INSTANCE=1
```

The result is pretty much the same as with previous case.
The main problem is that the data is in fact never synchronized between nodes in the cluster.
Proxy still sees both instances and balances requests accordingly.
Thus, requests with unknown data hit both instances and we get the same situation with 404s.
Creating also can fail, like described above, if submitting long URL occurs during the split. 

## What about node being shutdown?

Sure! Let's see how it can be tested:
```bash
make stress_test_cluster VUS=50 DURATION=10s BASE_SHORTEN_URL=https://www.original.com/very-very-long-slug-to-shorten-in-2020
```

And in another shell, after the test has been started:
```bash
make stop_cluster INSTANCE=1
```

The result:
```bash
WARN[0006] Request Failed                                error="Post \"http://localhost:4000/api/urls\": EOF"
ERRO[0006] Error creating, status: 0
ERRO[0006] {"status":0,"body":null,"error":"EOF","error_code":1000}

    █ execute
      ✗ status is 302
       ↳  99% — ✓ 5798 / ✗ 21
      ✗ correct redirect
       ↳  99% — ✓ 5798 / ✗ 21

    █ create
      ✗ status is 201
       ↳  99% — ✓ 5506 / ✗ 30
      ✗ short URL returned
       ↳  99% — ✓ 5506 / ✗ 30

    checks.....................: 99.55% ✓ 22608 ✗ 102
    create_503.................: 29     2.899956/s
    create_duration............: avg=34.988533 min=3.1    med=16.641  max=3057.344 p(90)=27.588  p(95)=37.88225
    create_error_rate..........: 0.54%  ✓ 30    ✗ 5506
    execute_503................: 21     2.099968/s
    execute_duration...........: avg=27.821442 min=3.593  med=15.461  max=3107.249 p(90)=23.9268 p(95)=28.1361
    execute_error_rate.........: 0.36%  ✓ 21    ✗ 5798
    http_req_duration..........: avg=31.31ms   min=3.1ms  med=16.06ms max=3.1s     p(90)=25.48ms p(95)=31.51ms
    http_reqs..................: 11355  1135.482718/s
```

Again similar situation as with previous examples.
One noticeable difference is the occurrence of create request failure with status 0.
It is because stopped instance could not complete the response and so the stress test got and empty response.
This didn't occur with network splits simply because instances kept living and were able to complete requests.

## What if a new node joins the cluster?

This time, start only a part of the cluster:
```bash          
make start_cluster INSTANCE=1
```

Now start the tests:
```bash
make stress_test_cluster VUS=50 DURATION=10s BASE_SHORTEN_URL=https://www.original.com/very-very-long-slug-to-shorten-in-2020
```

And in another shell, after the test has been started, join the new node:
```bash
make start_cluster INSTANCE=2
```

And the result:
```bash
    █ create
      ✓ status is 201
      ✓ short URL returned

    █ execute
      ✓ correct redirect
      ✓ status is 302

    checks.....................: 100.00% ✓ 51306 ✗ 0
    create_duration............: avg=19.588962 min=5.042   med=16.7505 max=119.342  p(90)=29.7171 p(95)=39.938
    create_error_rate..........: 0.00%   ✓ 0     ✗ 11990
    execute_duration...........: avg=18.51048  min=3.686   med=16.296  max=128.483  p(90)=26.8914 p(95)=34.1911
    execute_error_rate.........: 0.00%   ✓ 0     ✗ 13663
    http_req_duration..........: avg=19.01ms   min=3.68ms  med=16.52ms max=128.48ms p(90)=28.17ms p(95)=36.37ms
    http_reqs..................: 25653   2565.298032/s
```

New node doesn't start processing the requests until it is synced with the rest of the cluster.
Therefore, there are no errors. 

## Additional notes

For required [Erlang](https://www.erlang.org) and [Elixir](https://elixir-lang.org) versions, check out [.tool-versions](.tool-versions).
You can install them easily via [asdf](https://github.com/asdf-vm/asdf) and related plugins.

There's a [wrk](https://github.com/wg/wrk) stress test [script](scripts/stress_test.lua) as well.
But, had some performance issues with it so decided to go with [k6](https://k6.io) instead.
Another stress test candidate was [Tsung](http://tsung.erlang-projects.org), but could not find a way to submit long URL and use the result to generate further requests.

## Acknowledgments

ASCII art generated by http://patorjk.com/software/taag, using `ANSI Shadow` font.

## License

This source code is released under MIT license.
Check [LICENSE](LICENSE) for more information.
