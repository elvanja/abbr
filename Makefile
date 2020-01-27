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

INSTANCE?=all
ENV?=prod
start_cluster: deps
	scripts/cluster/start.sh -i ${INSTANCE} -e ${ENV}

INSTANCE?=all
stop_cluster:
	scripts/cluster/stop.sh -i ${INSTANCE}

join_cluster:
	scripts/cluster/join.sh -i ${INSTANCE}

leave_cluster:
	scripts/cluster/leave.sh -i ${INSTANCE}

INSTANCES?=2
split_cluster_repeatedly:
	scripts/repeatedly.sh -c "scripts/cluster/net_split.sh -i ${INSTANCES}" -d ${DURATION} ${OPTS}

CONNECTIONS?=50
THREADS?=10
DURATION?=1m
stress_test_cluster:
	wrk -s scripts/stress_test.lua -c${CONNECTIONS} -t${THREADS} -d${DURATION} http://localhost:4000 -- ${BASE_URL}

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
