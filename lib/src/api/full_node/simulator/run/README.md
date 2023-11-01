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
docker run -p 5000:80 chia-simulator-enhanced
```

The simulator can be interacted with from the host system.

Use this command to farm a block.

```bash
curl -d '{
  "address": "xch1etymwk6cgrf2uk56qj8s78xl0nks05sg9nfncs77qh4m0hg7tsuq4d60yx",
  "guarantee_tx_block": true
}' \
 -H "Content-Type: application/json" -X POST http://localhost:5000/farm_block
```

Use this command to get the blockchain state. You may verify that the previous command successfully farmed a block by checking the height property in the JSON output.

```bash
curl -d '{}' -H "Content-Type: application/json" \
 -X POST http://localhost:5000/get_blockchain_state
```

Install and use JQ for a more readable output.
```bash
brew install jq
```
```bash
curl -d '{}' -H "Content-Type: application/json" \
 -X POST http://localhost:5000/get_blockchain_state | jq
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
root@0c929e41a294:/chia-blockchain# curl --insecure --cert /root/.chia/simulator/main/config/ssl/daemon/private_daemon.crt \
                                         --key /root/.chia/simulator/main/config/ssl/daemon/private_daemon.key \
                                         -d '{
                                            "address": "xch1etymwk6cgrf2uk56qj8s78xl0nks05sg9nfncs77qh4m0hg7tsuq4d60yx",
                                            "guarantee_tx_block": true
                                            }' \
                                         -H "Content-Type: application/json" -X POST https://0.0.0.0:8555/farm_block

```

The following command overrides `docker-start.sh` allowing for exploration of the container environment.

```bash
docker run -p 8555:8555 -v "$(pwd)/temp/chia_plots":/root/.chia/mainnet/test-plots -it chia_sim:latest bash
```
