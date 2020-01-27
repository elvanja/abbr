#!/bin/bash

function show_usage_and_exit {
cat << EOF

randomly chooses one instance in the Abbr cluster
and makes it leave and join the cluster
the absence period is random too

usage: $0 options

OPTIONS:
  -h      show this message
  -i      instancess to choose from

EOF
exit $1
}

INSTANCES=

while getopts "i:h" OPTION
do
  case $OPTION in
    i) INSTANCES=$OPTARG;;
    h) show_usage_and_exit;;
    ?) show_usage_and_exit;;
  esac
done

test ! "$INSTANCES" && echo "instances is mandatory" && show_usage_and_exit 1

instance=$(shuf -i 1-$INSTANCES -n 1)
duration=$(seq 0 .001 3 | shuf | head -n1)

cd "$(dirname "$0")"
./leave.sh -i $instance
sleep $duration
./join.sh -i $instance
