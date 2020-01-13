#!/bin/bash

function show_usage_and_exit {
cat << EOF

joins an instance to Abbr cluster

usage: $0 options

OPTIONS:
  -h      show this message
  -i      instance to join

EOF
exit 1
}

INSTANCE=

while getopts "i:h" OPTION
do
  case $OPTION in
    i) INSTANCE=$OPTARG;;
    h) show_usage_and_exit;;
    ?) show_usage_and_exit;;
  esac
done

report=
if [ "$INSTANCE" == "1" ]; then
  report="instance 1 joined the cluster"
elif [ "$INSTANCE" == "2" ]; then
  report="instance 2 joined the cluster"
else
  echo "could not determine the instance"
  exit 1
fi

curl -X POST http://localhost:400$INSTANCE/api/cluster/join
echo $report
