#!/bin/bash

function show_usage_and_exit {
cat << EOF

forces the instance to leave Abbr cluster

usage: $0 options

OPTIONS:
  -h      show this message
  -i      instance to leave

EOF
exit 0
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
  report="instance 1 left the cluster"
elif [ "$INSTANCE" == "2" ]; then
  report="instance 2 left the cluster"
else
  echo "could not determine the instance"
  exit 1
fi

curl -X POST http://localhost:400$INSTANCE/api/cluster/leave
echo $report
