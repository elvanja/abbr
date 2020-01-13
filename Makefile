deps: mix.lock mix.exs
	mix deps.get

server: deps
	iex -S mix phx.server

test:
	mix test $(filter-out $@, $(MAKECMDGOALS))

start_proxy:
	scripts/haproxy/start.sh

stop_proxy:
	scripts/haproxy/stop.sh

open_proxy:
	open http://localhost:8080

start_cluster: deps
	scripts/cluster/start.sh ${ARGS}

stop_cluster:
	scripts/cluster/stop.sh ${ARGS}

join_cluster:
	scripts/cluster/join.sh ${ARGS}

leave_cluster:
	scripts/cluster/leave.sh ${ARGS}

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
