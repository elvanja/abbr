deps: mix.lock mix.exs
	mix deps.get

server: update
	iex -S mix phx.server

test:
	mix test $(filter-out $@, $(MAKECMDGOALS))

start_proxy:
	scripts/haproxy/start.sh

stop_proxy:
	scripts/haproxy/stop.sh

start_dev:
	HTTP_PORT=400${INSTANCE} iex --sname abbr${INSTANCE} -S mix phx.server

start_prod:
	scripts/cluster/start.sh ${ARGS}

stop_prod:
	scripts/cluster/stop.sh ${ARGS}

ci:
	echo "Running formatter..."
	mix format --check-formatted || exit 1
	echo "Compiling with warnings..."
	MIX_ENV=test mix do compile --warnings-as-errors || exit 1
	echo "Running tests..."
	mix test || exit 1
	echo "Running credo..."
	mix credo --strict || exit 1
	echo "Running dialyzer..."
	mix dialyzer || exit 1
