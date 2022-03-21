# Simulator

The Chia simulator can be used to write integration tests

## Building

```console
Irulast-MacBook-Pro:simulator irulastdev$ docker build . -t chia_sim
```

## Running

This starts the simulator running on port 5000 accessible from the host system.

```console
docker run -p 5000:8444 -v "$(pwd)/temp/chia_plots":/root/.chia/mainnet/test-plots -it chia_sim:latest
```

The simulator can be interacted with from the host system.

```console
Irulast-MacBook-Pro:simulator irulastdev$ curl --insecure --cert ssl/full_node/public_full_node.crt --key ssl/full_node/public_full_node.key -d '{"puzzle_hash": "97e714fb28d521a8dafbe8d727af5c4c3bb04f75300021efc28adffe1a8cd6eb"}' -H "Content-Type: application/json" -X POST https://localhost:5000/farm_new_block
```

```console
Irulast-MacBook-Pro:simulator irulastdev$ curl --insecure --cert ssl/full_node/public_full_node.crt --key ssl/full_node/public_full_node.key -d '{"puzzle_hash": "97e714fb28d521a8dafbe8d727af5c4c3bb04f75300021efc28adffe1a8cd6eb"}' -H "Content-Type: application/json" -X POST https://localhost:5000/farm_new_block
```

## Debugging

List the running containers then exec into the container to interact with the local system.

```console
Irulast-MacBook-Pro:simulator irulastdev$ docker ps
CONTAINER ID   IMAGE             COMMAND             CREATED          STATUS          PORTS                                                                                 NAMES
0c929e41a294   chia_sim:latest   "docker-start.sh"   23 minutes ago   Up 23 minutes   3496/tcp, 8555/tcp, 55400/tcp, 58555/tcp, 0.0.0.0:5000->8444/tcp, :::5000->8444/tcp   nervous_blackwell

Irulast-MacBook-Pro:simulator irulastdev$ docker exec -it 0c929e41a294 bash
root@0c929e41a294:/chia-blockchain# apt-get install -y procps lsof telnet curl
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  libcurl4 libncurses6 libprocps7 lsb-base psmisc
The following NEW packages will be installed:
  curl libcurl4 libncurses6 libprocps7 lsb-base lsof procps psmisc telnet
0 upgraded, 9 newly installed, 0 to remove and 0 not upgraded.
...

root@0c929e41a294:/chia-blockchain# curl --insecure --cert /root/.chia/mainnet/config/ssl/full_node/public_full_node.crt --key /root/.chia/mainnet/config/ssl/full_node/public_full_node.key -d '{"puzzle_hash": "97e714fb28d521a8dafbe8d727af5c4c3bb04f75300021efc28adffe1a8cd6eb"}' -H "Content-Type: application/json" -X POST https://localhost:8444/farm_new_block

```

The following command overrides `docker-start.sh` allowing for exploration of the container environment.

```console
Irulast-MacBook-Pro:simulator irulastdev$ docker run -p 8555:8555 -v "$(pwd)/temp/chia_plots":/root/.chia/mainnet/test-plots -it chia_sim:latest bash
```
