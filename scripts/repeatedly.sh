#!/bin/bash

function show_usage_and_exit {
cat << EOF

runs another command repeatedly for the supplied duration
next command execution has a random backoff

usage: $0 options

OPTIONS (* are mandatory):
  -h      show this message
  -d      *how long to keep running, in seconds
  -c      *command to run
  -n      minimum backoff, in seconds
  -x      maximum backoff, in seconds

EOF
exit $1
}

DURATION=
COMMAND=
MIN_BACKOFF=3
MAX_BACKOFF=15

while getopts "d:c:h" OPTION
do
  case $OPTION in
    d) DURATION=$OPTARG;;
    c) COMMAND=$OPTARG;;
    n) MIN_BACKOFF=$OPTARG;;
    n) MAX_BACKOFF=$OPTARG;;
    h) show_usage_and_exit;;
    ?) show_usage_and_exit;;
  esac
done

test ! "$DURATION" && echo "duration is mandatory" && show_usage_and_exit 1
test ! "$COMMAND" && echo "command is mandatory" && show_usage_and_exit 1

end_time=$(($(date -u +%s) + $DURATION))

while [[ $(date -u +%s) -le $end_time ]]
do
    $COMMAND
    pause_seconds=$(seq 0 $MIN_BACKOFF $MAX_BACKOFF | shuf | head -n1)
    sleep $pause_seconds
done
