#!/usr/bin/env bash
set -eo

function get_chia_pid() {
  ps -ef | grep chia_full_node | grep -v grep | awk ' {print $2}'
}

function check_blockchain_state() {
  curl --output /dev/null --silent --fail \
       -d '{}' -H "Content-Type: application/json" -X POST http://0.0.0.0:80/get_blockchain_state
}

chia dev sim create --docker-mode

CHIA_ROOT=/root/.chia/simulator/main

# start ssl sidecar
nginx -g 'daemon off;' &

trap "echo Shutting down ...; kill -9 $(get_chia_pid); exit 1" SIGINT SIGTERM

printf "waiting for chia simulator"
until $(check_blockchain_state); do
    printf '.'
    sleep 1
done
echo ""
echo "simulator is ready"

while [ 1 ]
do
  pid=$(get_chia_pid)
  if [ -z "$pid" ]; then
    exit
  fi
  sleep 3
done
