# Bitcoin Cash II Core Docker Stack

This project builds and runs the bitcoincashII Core daemon inside Docker using a minimal Debian base.

Source repository:  
https://github.com/BitcoincashII/bitcoincashII-core

---

## Overview

This stack provides a reproducible environment to run a Bitcoin Cash II full node with wallet support enabled.

### Features

- Builds:
  - bitcoincashIId (daemon)
  - bitcoincashII-cli (RPC client)
  - bitcoincashII-tx
  - bitcoincashII-wallet
- Wallet support enabled:
  - --enable-wallet
  - --with-incompatible-bdb (required for modern Debian compatibility)
- Runs as non-root user (bitcoincashii)
- Persistent blockchain + wallet storage via bind mount
- Simple Docker Compose workflow

---

## Project Structure

- Dockerfile — Multi-stage build (builder + runtime)
- docker-entrypoint.sh — Initializes config and starts daemon
- docker-compose.yml — Defines the `coind` service
- .env — Runtime configuration (RPC, ports, etc.)

---

## Quick Start

### 1. Configure environment

Edit `.env` and set a strong RPC password:

```bash
COIND_RPC_PASSWORD=replace_me_with_a_real_password
```

---

### 2. Build and start the node

```bash
docker compose up -d --build
```

---

### 3. View logs

```bash
docker compose logs -f coind
```

---

### 4. Call RPC from host (optional)

If RPC port is exposed:

```bash
curl --user "$COIND_RPC_USER:$COIND_RPC_PASSWORD" \
  --data-binary '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}' \
  -H 'content-type: text/plain;' \
  http://127.0.0.1:${COIND_RPC_PORT}
```

---

## Using the CLI (Recommended)

The easiest way to interact with your node is via `bitcoincashII-cli` inside the container.

### Basic usage

```bash
docker compose exec -u bitcoincashii coind bitcoincashII-cli \
  -datadir=/home/bitcoincashii/.bitcoincashII \
  -conf=/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf \
  <command>
```

---

### Example: Get blockchain info

```bash
docker compose exec -u bitcoincashii coind bitcoincashII-cli \
  -datadir=/home/bitcoincashii/.bitcoincashII \
  -conf=/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf \
  getblockchaininfo
```

---

### Example: Check wallet balance

```bash
docker compose exec -u bitcoincashii coind bitcoincashII-cli \
  -datadir=/home/bitcoincashii/.bitcoincashII \
  -conf=/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf \
  getbalance
```

---

### Example: Generate a new address

```bash
docker compose exec -u bitcoincashii coind bitcoincashII-cli \
  -datadir=/home/bitcoincashii/.bitcoincashII \
  -conf=/home/bitcoincashii/.bitcoincashII/bitcoincashII.conf \
  getnewaddress
```

---

### List all available commands

```bash
docker compose exec -u bitcoincashii coind bitcoincashII-cli help
```

---

## Data & Configuration

- Container data dir:  
  /home/bitcoincashii/.bitcoincashII

- Config file:  
  /home/bitcoincashii/.bitcoincashII/bitcoincashII.conf

- Host mount:  
  ./dot-bitcoincashii:/home/bitcoincashii/.bitcoincashII

On first startup, a minimal config file is automatically created if missing.

Default bootstrap peers are also ensured in the config:

- 144.202.73.66:8339 (Dallas, USA)
- 108.61.190.83:8339 (Frankfurt, Germany)
- 64.176.215.202:8339 (New Jersey, USA)
- 45.32.138.29:8339 (Silicon Valley, USA)
- 139.180.132.24:8339 (Singapore)

To override this list, set `COIND_BOOTSTRAP_NODES` in `.env` as a comma-separated list:

```bash
COIND_BOOTSTRAP_NODES=144.202.73.66:8339,108.61.190.83:8339
```

---

## Ports

Mainnet defaults:

- P2P: 8339
- RPC: 8342

By default:
- P2P is exposed to host
- RPC is internal only (safer)

To expose RPC, uncomment the port mapping in docker-compose.yml.

---

## Common Commands

### Stop the stack

```bash
docker compose down
```

---

### Rebuild from scratch

```bash
docker compose build --no-cache
```

---

## Build Customization

You can override build arguments in docker-compose.yml:

- BITCOINCASHII_REPO_URL
- BITCOINCASHII_REF
- MAKE_JOBS

### Example

```bash
BITCOINCASHII_REF=v27.0.0 docker compose build
```

---

## Notes

- Wallet support is explicitly enabled
- Uses --with-incompatible-bdb for Debian compatibility
- UPnP is disabled (--without-miniupnpc) due to upstream incompatibility
- Never expose RPC publicly without firewall protection