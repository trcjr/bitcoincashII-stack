# Bitcoin Cash II Core Docker Stack

This stack builds and runs `bitcoincashIId` from:

- https://github.com/BitcoincashII/bitcoincashII-core

It uses Debian `stable-slim` as the base image and compiles with wallet support enabled.

## What this stack does

- Builds `bitcoincashIId`, `bitcoincashII-cli`, `bitcoincashII-tx`, and `bitcoincashII-wallet`
- Enables wallet support during configure:
  - `--enable-wallet`
  - `--with-incompatible-bdb` (required on modern Debian packages for legacy Berkeley DB support)
- Runs the daemon as non-root user `bitcoincashii`
- Persists blockchain and wallet data in `./dot-bitcoincashii`

## File layout

- `Dockerfile`: Multi-stage build (builder + runtime)
- `docker-entrypoint.sh`: Creates `bitcoincashII.conf` if missing and starts daemon
- `docker-compose.yml`: Single `coind` service for BCH2
- `.env`: Runtime settings (ports, RPC auth, optional extra args)

## Quick start

1. Edit `.env` and set a strong RPC password:

```bash
COIND_RPC_PASSWORD=replace_me_with_a_real_password
```

2. Build and start:

```bash
docker compose up -d --build
```

3. Check logs:

```bash
docker compose logs -f coind
```

4. Call RPC from host (if RPC port is published):

```bash
curl --user "$COIND_RPC_USER:$COIND_RPC_PASSWORD" \
  --data-binary '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}' \
  -H 'content-type: text/plain;' \
  http://127.0.0.1:${COIND_RPC_PORT}
```

## Data and config

Defaults in this stack:

- Data directory: `/home/bitcoincashii/.bitcoincashII`
- Config file: `/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf`
- Host bind mount: `./dot-bitcoincashii:/home/bitcoincashii/.bitcoincashII`

On first start, the entrypoint writes a minimal config if one does not exist.

## Ports

Mainnet defaults:

- P2P: `8339`
- RPC: `8342`

By default, only P2P is published to host in `docker-compose.yml`.
RPC is exposed only inside the Compose network unless you uncomment the RPC port mapping.

## Common commands

Stop stack:

```bash
docker compose down
```

Rebuild after changing Dockerfile or source ref:

```bash
docker compose build --no-cache
```

Run CLI in the container:

```bash
docker compose exec coind bitcoincashII-cli \
  -datadir=/home/bitcoincashii/.bitcoincashII \
  -conf=/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf \
  getblockchaininfo
```

## Build customization

`docker-compose.yml` passes build args you can change:

- `BITCOINCASHII_REPO_URL` (default official BCH2 repo)
- `BITCOINCASHII_REF` (default `main`)
- `MAKE_JOBS` (parallel compile jobs)

Example:

```bash
BITCOINCASHII_REF=v27.0.0 docker compose build
```

## Notes

- Wallet support is explicitly enabled.
- `--with-incompatible-bdb` is used to build with distro Berkeley DB packages on Debian stable.
- UPnP is disabled at build time (`--without-miniupnpc`) due upstream API incompatibility with current Debian stable `miniupnpc` headers.
- Keep RPC credentials private; do not expose RPC publicly without firewall controls.
