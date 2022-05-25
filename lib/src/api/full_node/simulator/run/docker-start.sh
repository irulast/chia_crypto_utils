#!/usr/bin/env bash
set -eo

function get_chia_pid() {
  ps -ef | grep chia_full_node | grep -v grep | awk ' {print $2}'
}

function check_blockchain_state() {
  curl --output /dev/null --silent --fail --insecure \
       --cert /root/.chia/mainnet/config/ssl/full_node/private_full_node.crt \
       --key /root/.chia/mainnet/config/ssl/full_node/private_full_node.key \
       -d '{}' -H "Content-Type: application/json" -X POST https://127.0.0.1:8555/get_blockchain_state
}

python chia/simulator/start_simulator.py &

trap "echo Shutting down ...; kill -9 $(get_chia_pid); exit 1" SIGINT SIGTERM

printf "waiting for chia simulator"
until $(check_blockchain_state); do
    printf '.'
    sleep 1
done

if [[ -n "${CLIENT_CONFIG_DIR+x}" ]]; then
  echo "Copying config directory for client tooling ..."
  cp -R /root/.chia/mainnet/config/. "${CLIENT_CONFIG_DIR}"
  chown -R $TARGET_UID:$TARGET_GID "${CLIENT_CONFIG_DIR}"
fi

while [ 1 ]
do
  pid=$(get_chia_pid)
  if [ -z "$pid" ]; then
    exit
  fi
  sleep 3
done
