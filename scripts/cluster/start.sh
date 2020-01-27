#!/bin/bash

function show_usage_and_exit {
cat << EOF

starts the Abbr cluster

usage: $0 options

OPTIONS:
  -h      show this message
  -i      instance to start, default: all
  -e      environment, default: prod

EOF
exit 0
}

INSTANCE=
ENV=

while getopts "i:e:h" OPTION
do
  case $OPTION in
    i) INSTANCE=$OPTARG;;
    e) ENV=$OPTARG;;
    h) show_usage_and_exit;;
    ?) show_usage_and_exit;;
  esac
done

instance_ids=()
report=
dev_ok=true
if [ "$INSTANCE" == "1" ]; then
  instance_ids+=(1)
  report="started instance 1"
elif [ "$INSTANCE" == "2" ]; then
  instance_ids+=(2)
  report="started instance 2"
elif [ "$INSTANCE" == "all" ]; then
  instance_ids+=(1)
  instance_ids+=(2)
  report="started both instances"
  dev_ok=false
else
  echo "invalid instance to start"
  exit 1
fi

if [ "$ENV" == "dev" ]; then
  if [ $dev_ok == false ]; then
    echo "only one instance can be started in dev mode"
    exit 1
  fi
  HTTP_PORT=400$INSTANCE iex --cookie abbr --sname abbr$INSTANCE -S mix phx.server
else
  MIX_ENV=prod mix do compile
  for instance_id in "${instance_ids[@]}"; do
    MIX_ENV=prod HTTP_PORT=400$instance_id ABBR_HOST=localhost ABBR_PORT=4000 elixir --erl "-detached" --cookie abbr --sname abbr$instance_id -S mix phx.server
  done
  echo $report
fi
