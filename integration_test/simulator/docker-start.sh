#!/usr/bin/env bash
set -eo

if [[ -n "${CLIENT_CONFIG_DIR+x}" ]]; then
  echo "Copying config directory for client tooling ..."
  cp -R /root/.chia/mainnet/config/. "${CLIENT_CONFIG_DIR}"
  chown -R $TARGET_UID:$TARGET_GID "${CLIENT_CONFIG_DIR}"
fi

function get_chia_pid() {
  ps -ef | grep chia_full_node | grep -v grep | awk ' {print $2}'
}

python chia/simulator/start_simulator.py

trap "echo Shutting down ...; kill -9 $get_chia_pid; exit 1" SIGINT SIGTERM

while [ 1 ]
do
  pid=$get_chia_pid
  if [ "$pid"="" ]; then
    exit
  fi
  sleep 3
done
