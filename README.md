# opencode-srv

A self-hosted Docker setup that runs an [OpenCode](https://opencode.ai) server and makes it available over HTTP.

## What the `docker compose.yml` file does

The `compose.yml` file defines a single service, `opencode-srv`, which:

1. **Builds** the OpenCode server image from the repository using `opencode.dockerfile` as the Docker build context and Dockerfile.
2. **Runs** the OpenCode server (`opencode serve`) bound to `0.0.0.0:4000` inside the container, with the server listening on port **4000**.
3. **Maps** port `4000` on the host to port `4000` in the container, so the server is reachable at `http://localhost:4000`.
4. **Sets the server password** via the `OPENCODE_SERVER_PASSWORD` environment variable (defaults to `change_me` if not set in the host environment).
5. **Mounts three host directories** into the container so state persists outside the container:

   | Host path | Container path | Purpose |
   |---|---|---|
   | `/usr/opencode/config` | `/root/.config/opencode` | Persistent OpenCode UI configuration |
   | `/usr/opencode/data` | `/home/opencode/.local/share/opencode` | Session storage, cache, and auth credentials |
   | `/usr/opencode/workspace` | `/home/opencode/workspace` | Working directory for OpenCode projects |

6. **Restarts automatically** (`restart: unless-stopped`) unless the container is stopped manually.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- Docker Compose (the `docker compose` plugin is included with modern Docker installations)

## Running

From the repository root:

```bash
docker compose up -d --build
```

The first run builds the image from `opencode.dockerfile`; subsequent runs reuse the cache.

To run in the foreground and watch logs:

```bash
docker compose up
```

## Configuration

The server password is read from the `OPENCODE_SERVER_PASSWORD` environment variable and falls back to `change_me` when unset.

Set it before starting the stack, e.g. in your shell:

```bash
export OPENCODE_SERVER_PASSWORD="your-strong-password"
```

or place it in a `.env` file next to `compose.yml`:

```dotenv
OPENCODE_SERVER_PASSWORD=your-strong-password
```

## Usage

Once the container is running, open:

```
http://localhost:4000
```

## Headless Chrome

The image installs **Google Chrome stable** from Google's official apt repository so tools inside the container can drive a browser. Chrome is never started by the image or the entrypoint: `/usr/local/bin/chrome-headless` is an on-demand launcher. The Chrome version is whatever Google publishes at build time, so rebuild the image to update it.

Launch it (it runs headless in the foreground; background it yourself when the caller needs the shell back):

```bash
# Foreground, in a dedicated exec
docker exec opencode chrome-headless

# Backgrounded
docker exec -d opencode chrome-headless
```

The launcher `exec`s Chrome, so extra arguments pass straight through:

```bash
docker exec opencode chrome-headless --window-size=1280,720 https://example.com
```

Check the DevTools endpoint from inside the container:

```bash
docker exec opencode curl -s http://127.0.0.1:9222/json/version
```

DevTools/remote debugging listens on `127.0.0.1:9222` **inside the container only**. Port 9222 is not published and must not be published; reach it through `docker exec` (or a browser tool running in the container).

The profile directory defaults to `/home/opencode/.cache/chrome-headless` and can be overridden:

```bash
docker exec -e CHROME_PROFILE_DIR=/tmp/chrome-profile opencode chrome-headless
```

The container runs as the unprivileged `opencode` user, so Chrome writes the profile as that user. If the launcher is invoked as root (for example with `docker exec -u root`), it creates/chowns the directory and runs Chrome as `opencode`. `CHROME_BIN` may point at a different Chrome binary, which must be executable by `opencode`.

The launcher deliberately passes `--no-sandbox` because Chrome's sandbox is unavailable in this container. This assumes a trusted, single-tenant container; do not feed it untrusted web content.

## Stopping

```bash
docker compose down
```

## Useful commands

```bash
# View logs
docker compose logs -f opencode-srv

# Stop and remove the container (data volumes on the host are kept)
docker compose down

# Stop and also remove the containers (volumes are kept unless -v is passed)
docker compose down --rmi local
```

## Other

DockerHub pre-build image : https://hub.docker.com/r/pich02/opencode-srv
