# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Overview

`opencode-srv` is a self-hosted Docker setup that runs an OpenCode server and exposes it over HTTP on port 4000.

## Repository Structure

- `compose.yml` — Docker Compose definition for the OpenCode server.
- `opencode.dockerfile` — Image definition (Debian 13 base, Node.js 26, OpenCode v2 installed via npm).
- `README.md` — Human-facing documentation (what the compose file does and how to run it).

## Architecture

- The compose service `opencode-srv` (container name: `opencode`) builds from the Docker context with `opencode.dockerfile`.
- Server runs via `/root/.opencode/bin/opencode serve --hostname 0.0.0.0 --port 4000`.
- Published port: host `4000` — container `4000`.
- Server password comes from the `OPENCODE_SERVER_PASSWORD` env var, defaulting to `change_me`.

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
