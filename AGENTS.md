# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Overview

`opencode-srv` is a self-hosted Docker setup that runs an OpenCode server and exposes it over HTTP on port 4000.

## Repository Structure

- `compose.yml` — Docker Compose definition for the OpenCode server.
- `opencode.dockerfile` — Image definition (Debian 13 base, Node.js 26, OpenCode v2 installed via npm, Google Chrome stable plus its apt runtime deps).
- `chrome-headless` — On-demand headless Chrome launcher installed as `/usr/local/bin/chrome-headless`.
- `README.md` — Human-facing documentation (what the compose file does and how to run it).

## Architecture

- The compose service `opencode-srv` (container name: `opencode`) builds from the Docker context with `opencode.dockerfile`.
- The image runs as the unprivileged `opencode` user; the entrypoint sources its profile and runs `opencode serve` on port `4000`.
- Published port: host `4000` — container `4000`.
- Server password comes from the `OPENCODE_SERVER_PASSWORD` env var, defaulting to `change_me`.
- The image installs Google Chrome stable from Google's official apt repo together with the `chrome-headless` launcher. Chrome is installed only; nothing (including the entrypoint) starts it automatically.
- DevTools remote debugging binds `127.0.0.1:9222` inside the container only. There is deliberately no port mapping for 9222 and none should be added; consumers use `docker exec`.

## Persistent State (host-mounted volumes)

| Host path | Container path | Purpose |
|---|---|---|
| `/usr/opencode/config` | `/root/.config/opencode` | UI config |
| `/usr/opencode/data` | `/home/opencode/.local/share/opencode` | Sessions, cache, auth |
| `/usr/opencode/workspace` | `/home/opencode/workspace` | Working directory for OpenCode projects |

## How to Run

```bash
docker compose up -d --build
```

Server available at `http://localhost:4000`.

## Agent Guidelines

- Changes to the server behavior should be made in `compose.yml` / `opencode.dockerfile` and reflected in `README.md`.
- Keep host paths in the compose volumes section in sync with the documented volume table.
- Do not change the container port mapping (`4000:4000`) without also updating the entrypoint, ports, and README.
- The default server password must be overridden via `OPENCODE_SERVER_PASSWORD` before exposing the server.
- Keep `chrome-headless` flags and the "Headless Chrome" README section in sync with the Chrome install steps in `opencode.dockerfile`; Chrome is on-demand only and 9222 must stay unpublished.
