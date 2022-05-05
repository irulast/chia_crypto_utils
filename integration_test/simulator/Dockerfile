FROM python:3.9-slim-buster
EXPOSE 8555

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends git tzdata sed curl procps && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV CHIA_ROOT=/root/.chia/mainnet

RUN git clone https://github.com/Chia-Network/chia-blockchain.git
WORKDIR /chia-blockchain

RUN git submodule update --init mozilla-ca
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install wheel && \
    python3 -m pip install --extra-index-url https://pypi.chia.net/simple/ miniupnpc==2.2.2 && \
    python3 -m pip install -e . --extra-index-url https://pypi.chia.net/simple/

RUN chmod +x /opt/venv/bin/activate && \
    activate && \
    chia init

# TOTAL HACK! By default the simulator is copying config.yaml every time with a hardcoded value of self_hostname: localhost
#             When the chia full_node is run in a docker container it tries to bind against an IPv6 address ::1 which results in a python error
#             "OSError: [Errno 99] error while attempting to bind on address ('::1', 8555, 0, 0): cannot assign requested address"
RUN sed -i 's/self.self_hostname = self.config.get("self_hostname")/self.self_hostname = "0.0.0.0"/' /chia-blockchain/chia/server/start_service.py

COPY docker-start.sh /usr/local/bin/

CMD ["docker-start.sh"]
