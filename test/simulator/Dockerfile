FROM python:3.9-slim-buster
EXPOSE 58555 8555 8444 3496 55400

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends git tzdata && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="generate"
ENV service="farmer"
ENV plots_dir="/plots"
# ENV farmer_address=
# ENV farmer_port=
ENV testnet="false"
ENV TZ="UTC"
ENV upnp="true"
ENV log_to_file="true"

# Deprecated legacy options
ENV harvester="false"
ENV farmer="false"

RUN git clone https://github.com/Chia-Network/chia-blockchain.git
WORKDIR /chia-blockchain
RUN git checkout 911f164442e96dda41d7e31e71f5301397301012

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install lsb-release && apt-get -y install sed && apt-get -y install vim

RUN git submodule update --init mozilla-ca
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install wheel && \
    python3 -m pip install --extra-index-url https://pypi.chia.net/simple/ miniupnpc==2.2.2 && \
    python3 -m pip install -e . --extra-index-url https://pypi.chia.net/simple/

RUN sed -i 's/from .full_node_simulator import FullNodeSimulator/from full_node_simulator import FullNodeSimulator/' /chia-blockchain/chia/simulator/start_simulator.py

RUN chmod +x /opt/venv/bin/activate
RUN activate
RUN chia init
COPY docker-start.sh /usr/local/bin/

CMD ["docker-start.sh"]