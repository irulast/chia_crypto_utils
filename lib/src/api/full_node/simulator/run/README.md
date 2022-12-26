# Simulator

The Chia simulator can be used to write integration tests.

## Running

This starts the simulator running on port 5000 accessible from the host system.

### Local Build and Run
#### Standard Full Node
```bash
docker build . -t chia-simulator
```

#### Enhanced Full Node
```bash
docker build -f Dockerfile.enhanced . -t chia-simulator-enhanced
```

```bash
export FULL_NODE_SIMULATOR_GEN_PATH=$(pwd)
docker run -e TARGET_UID="$(id -u)" -e TARGET_GID="$(id -g)" -e CLIENT_CONFIG_DIR="/temp/config/" \
 -p 5000:8555 \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/test-plots":/root/.chia/test-plots \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/config:/temp/config" \
 chia-simulator-enhanced
```

### Evergreen
```bash
export FULL_NODE_SIMULATOR_GEN_PATH=$(pwd)
docker run -e TARGET_UID="$(id -u)" -e TARGET_GID="$(id -g)" -e CLIENT_CONFIG_DIR="/temp/config/" \
 -p 5000:8555 \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/test-plots":/root/.chia/test-plots \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/config:/temp/config" \
irulast/chia-simulator:evg-enhanced-latest
```

### Intel Mac
```bash
export FULL_NODE_SIMULATOR_GEN_PATH=$(pwd)
docker run -e TARGET_UID="$(id -u)" -e TARGET_GID="$(id -g)" -e CLIENT_CONFIG_DIR="/temp/config/" \
 -p 5000:8555 \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/test-plots":/root/.chia/mainnet/test-plots \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/config:/temp/config" \
 irulast/chia-simulator:latest
```

### M1 Mac
```bash
export FULL_NODE_SIMULATOR_GEN_PATH=$(pwd)
docker run -e TARGET_UID="$(id -u)" -e TARGET_GID="$(id -g)" -e CLIENT_CONFIG_DIR="/temp/config/" \
 -p 5000:8555 \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/test-plots":/root/.chia/mainnet/test-plots \
 -v "$FULL_NODE_SIMULATOR_GEN_PATH/temp/config:/temp/config" \
 irulast/chia-simulator:m1-latest
```

The simulator can be interacted with from the host system.

Use this command to farm a block.

```bash
curl --insecure --cert temp/config/ssl/full_node/private_full_node.crt \
 --key temp/config/ssl/full_node/private_full_node.key \
 -d '{"address": "xch1jln3f7eg65s63khmartj0t6ufsamqnm4xqqzrm7z3t0lux5v6m4spe8ef6"}' \
 -H "Content-Type: application/json" -X POST https://localhost:5000/farm_tx_block
```

Use this command to get the blockchain state. You may verify that the previous command successfully farmed a block by checking the height property in the JSON output.

```bash
curl --insecure --cert temp/config/ssl/full_node/private_full_node.crt \
 --key temp/config/ssl/full_node/private_full_node.key \
 -d '{}' -H "Content-Type: application/json" \
 -X POST https://localhost:5000/get_blockchain_state
```

Install and use JQ for a more readable output.
```bash
brew install jq
```
```bash
curl --insecure --cert temp/config/ssl/full_node/private_full_node.crt \
 --key temp/config/ssl/full_node/private_full_node.key \
 -d '{}' -H "Content-Type: application/json" \
 -X POST https://localhost:5000/get_blockchain_state | jq
```

## Debugging

List the running containers, then exec into the container using the listed container ID in order to interact with the local system.

```bash
docker ps
```

```bash
CONTAINER ID   IMAGE             COMMAND             CREATED          STATUS          PORTS                                                                                 NAMES
0c929e41a294   chia_sim:latest   "docker-start.sh"   23 minutes ago   Up 23 minutes   3496/tcp, 8555/tcp, 55400/tcp, 58555/tcp, 0.0.0.0:5000->8444/tcp, :::5000->8444/tcp   nervous_blackwell
```

```bash
docker exec -it 0c929e41a294 bash
```

You can now run commands in the container:
```bash
root@0c929e41a294:/chia-blockchain# curl --insecure --cert ~/.chia/mainnet/config/ssl/full_node/private_full_node.crt \
                                         --key ~/.chia/mainnet/config/ssl/full_node/private_full_node.key \
                                         -d '{"address": "xch1jln3f7eg65s63khmartj0t6ufsamqnm4xqqzrm7z3t0lux5v6m4spe8ef6"}' \
                                         -H "Content-Type: application/json" -X POST https://localhost:5000/farm_tx_block

```

The following command overrides `docker-start.sh` allowing for exploration of the container environment.

```bash
docker run -p 8555:8555 -v "$(pwd)/temp/chia_plots":/root/.chia/mainnet/test-plots -it chia_sim:latest bash
```
