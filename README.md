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

## Acknowledgments

ASCII art generated by http://patorjk.com/software/taag, using `ANSI Shadow` font.

## License

This source code is released under MIT license.
Check [LICENSE](LICENSE) for more information.
