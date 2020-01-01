#!/bin/bash
cd "$(dirname "$0")"
./stop.sh
./build.sh
./start.sh
