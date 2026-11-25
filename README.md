# opencode-srv

A self-hosted Docker setup that runs an [OpenCode](https://opencode.ai) server and makes it available over HTTP.

## Compose files

This repo provides two Compose files:

- **`compose-build-local.yml`**: builds the image from the repository using `opencode.dockerfile` (local build).
- **`compose-dockerhub-latest.yml`**: uses the prebuilt Docker Hub image `pich02/opencode-srv:latest` (no local build).

Both define the same service (`opencode-srv`, container `opencode`), map host port **4000** to container **4000**, set the server password via `OPENCODE_SERVER_PASSWORD` (default `change_me`), mount persistent host directories, and use `restart: unless-stopped`.

### Mounted volumes (common)

| Environment variable | Default host path | Container path | Purpose |
|---|---|---|---|
| `OPENCODE_CONFIG` | `./config` | `/home/opencode/.config/opencode` | Persistent OpenCode UI configuration |
| `OPENCODE_DATA` | `./data` | `/home/opencode/.local/share/opencode` | Session storage, cache, and auth credentials |
| `OPENCODE_WORKSPACE` | `./workspace` | `/home/opencode/workspace` | Working directory for OpenCode projects |
| `DIND_PATH` | `./dind` | `/var/lib/docker` | Docker-in-Docker overlay data |

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- Docker Compose (the `docker compose` plugin is included with modern Docker installations)

## Running

From the repository root:

### Option A: local build (`compose-build-local.yml`)

```bash
docker compose -f compose-build-local.yml up -d --build
```

The first run builds the image from `opencode.dockerfile`; subsequent runs reuse the cache.

Run in the foreground and watch logs:

```bash
docker compose -f compose-build-local.yml up
```

### Option B: Docker Hub latest (`compose-dockerhub-latest.yml`)

```bash
docker compose -f compose-dockerhub-latest.yml pull
docker compose -f compose-dockerhub-latest.yml up -d
```

Run in the foreground and watch logs:

```bash
docker compose -f compose-dockerhub-latest.yml up
```

Docker Hub image: https://hub.docker.com/r/pich02/opencode-srv

## Configuration

The server password is read from the `OPENCODE_SERVER_PASSWORD` environment variable and falls back to `change_me` when unset.

On startup, the entrypoint runs `opencode upgrade` as the `opencode` user before launching the server. If the update fails (for example, no network access), startup continues with the installed version. Set `OPENCODE_AUTO_UPDATE=false` to skip this step (accepted disable values: `false`, `0`, `no`).

Set variables before starting the stack, e.g. in your shell:

```bash
export OPENCODE_SERVER_PASSWORD="your-strong-password"
export OPENCODE_AUTO_UPDATE=true
```

or place them in a `.env` file next to the Compose file:

```dotenv
OPENCODE_SERVER_PASSWORD=your-strong-password
OPENCODE_AUTO_UPDATE=true
```

## Usage

Once the container is running, open:

```
http://localhost:4000
```

## Stopping

Use the same `-f <compose-file>` you started with, e.g.:

```bash
docker compose -f compose-build-local.yml down
# or
docker compose -f compose-dockerhub-latest.yml down
```

## Useful commands

```bash
# View logs (example)
docker compose -f compose-build-local.yml logs -f opencode-srv

# Stop and remove the container (data volumes on the host are kept)
docker compose -f compose-build-local.yml down

# Stop and also remove the containers (images/volumes behavior depends on flags)
docker compose -f compose-build-local.yml down --rmi local
```

## Other

DockerHub pre-build image: https://hub.docker.com/r/pich02/opencode-srv
