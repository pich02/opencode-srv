#!/bin/bash
set -e

# Start Docker daemon in the background (Docker-in-Docker).
# Runs as root (container started with user: root in compose.yml).
dockerd > /var/log/dockerd.log 2>&1 &
DOCKER_PID=$!

# Wait for Docker daemon to be ready (up to 30 seconds).
for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon is ready"
        break
    fi
    if ! kill -0 "$DOCKER_PID" 2>/dev/null; then
        echo "Docker daemon exited unexpectedly. Logs:"
        cat /var/log/dockerd.log 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon failed to start within 30 seconds. Logs:"
    cat /var/log/dockerd.log 2>/dev/null || true
    exit 1
fi

# Auto-update OpenCode before serving (opt-out: OPENCODE_AUTO_UPDATE=false).
AUTO_UPDATE="${OPENCODE_AUTO_UPDATE:-true}"
case "${AUTO_UPDATE,,}" in
  false|0|no)
    echo "OpenCode auto-update skipped (OPENCODE_AUTO_UPDATE=${AUTO_UPDATE})"
    ;;
  *)
    echo "Checking for OpenCode updates..."
    if timeout 120s gosu opencode bash -lc 'opencode upgrade'; then
      echo "OpenCode update check complete"
    else
      echo "Warning: OpenCode update failed; continuing with installed version"
    fi
    ;;
esac

# Drop to the unprivileged opencode user and start OpenCode server.
export HOME=/home/opencode
exec gosu opencode bash -lc 'opencode serve --hostname 0.0.0.0 --port 4000 --log-level debug --print-logs'
