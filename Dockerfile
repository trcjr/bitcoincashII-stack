FROM debian:bookworm-slim@sha256:02274f94f52336abd6ab4a8471ea09966613910ebaeed622429dc7b4b780e804 AS builder

ARG BITCOINCASHII_REPO_URL=https://github.com/BitcoincashII/bitcoincashII-core.git
ARG BITCOINCASHII_REF=main
ARG MAKE_JOBS=1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    pkg-config \
    libtool \
    autotools-dev \
    automake \
    binutils \
    build-essential \
    bsdmainutils \
    python3 \
    libevent-dev \
    libboost-dev \
    libsqlite3-dev \
    libminiupnpc-dev \
    libnatpmp-dev \
    libzmq3-dev \
    systemtap-sdt-dev \
    libqrencode-dev \
    libdb-dev \
    libdb++-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN test -n "${BITCOINCASHII_REPO_URL}" \
 && git clone --depth 1 --branch "${BITCOINCASHII_REF}" "${BITCOINCASHII_REPO_URL}" bitcoincashii-src

WORKDIR /tmp/bitcoincashii-src
RUN ./autogen.sh \
 && mkdir -p build \
 && cd build \
 && ../configure --without-gui --disable-tests --disable-bench --enable-wallet --with-incompatible-bdb --without-miniupnpc \
 && make -j"${MAKE_JOBS}" \
 && strip --strip-unneeded \
    ./src/bitcoincashIId \
    ./src/bitcoincashII-cli \
    ./src/bitcoincashII-tx \
    ./src/bitcoincashII-wallet


FROM debian:bookworm-slim@sha256:02274f94f52336abd6ab4a8471ea09966613910ebaeed622429dc7b4b780e804

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    bash \
    curl \
    libevent-dev \
    libboost-dev \
    libsqlite3-dev \
    libminiupnpc-dev \
    libnatpmp1 \
    libzmq5 \
    libdb-dev \
    libdb++-dev \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash bitcoincashii

WORKDIR /opt/bitcoincashii

COPY --from=builder --chmod=755 /tmp/bitcoincashii-src/build/src/bitcoincashIId /usr/local/bin/bitcoincashIId
COPY --from=builder --chmod=755 /tmp/bitcoincashii-src/build/src/bitcoincashII-cli /usr/local/bin/bitcoincashII-cli
COPY --from=builder --chmod=755 /tmp/bitcoincashii-src/build/src/bitcoincashII-tx /usr/local/bin/bitcoincashII-tx
COPY --from=builder --chmod=755 /tmp/bitcoincashii-src/build/src/bitcoincashII-wallet /usr/local/bin/bitcoincashII-wallet

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bitcoincashIId"]