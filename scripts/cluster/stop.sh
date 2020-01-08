#!/bin/bash

function show_usage_and_exit {
cat << EOF

stops the Abbr cluster

usage: $0 options

OPTIONS:
  -h      show this message
  -i      instance to stop, default: all

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
  report="stopped instance 1"
elif [ "$INSTANCE" == "2" ]; then
  report="stopped instance 2"
else
  report="stopped both instances"
fi

ps aux | grep "[a]bbr$INSTANCE" | awk '{print $2}' | xargs sudo kill
echo $report
