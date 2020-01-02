#!/bin/bash

function show_usage_and_exit {
cat << EOF

starts the Abbr cluster

usage: $0 options

OPTIONS:
  -h      show this message
  -n      instance to start, default: all

EOF
exit $1
}

INSTANCE=

while getopts "n:h" OPTION
do
  case $OPTION in
    n) INSTANCE=$OPTARG;;
    h) show_usage_and_exit;;
    ?) show_usage_and_exit;;
  esac
done

instance_ids=()
if [ "$INSTANCE" == "1" ]; then
  instance_ids+=(1)
elif [ "$INSTANCE" == "2" ]; then
  instance_ids+=(2)
else
  instance_ids+=(1)
  instance_ids+=(2)
fi

MIX_ENV=prod mix do compile
for instance_id in "${instance_ids[@]}"; do
  MIX_ENV=prod PORT=400$instance_id elixir --erl "-detached" --sname abbr$instance_id -S mix phx.server
done

echo "cluster started"
