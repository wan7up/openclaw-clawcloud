#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-loopback}"
CONFIG_MODE="${OPENCLAW_CONFIG_MODE:-generate}"

export OPENCLAW_STATE_DIR="$STATE_DIR"
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"
export OPENCLAW_GATEWAY_PORT="$GATEWAY_PORT"
export OPENCLAW_GATEWAY_BIND="$GATEWAY_BIND"

mkdir -p /data
mkdir -p "$STATE_DIR" "$WORKSPACE_DIR"
chmod 700 "$STATE_DIR" || true

# Keep plugin installer default path (~/.openclaw) aligned with the persistent state dir.
mkdir -p "$HOME"
HOME_OPENCLAW="${HOME%/}/.openclaw"
if [ "$HOME_OPENCLAW" != "$STATE_DIR" ]; then
  rm -rf "$HOME_OPENCLAW" 2>/dev/null || true
  ln -s "$STATE_DIR" "$HOME_OPENCLAW"
else
  echo "[entrypoint] ~/.openclaw already points at state dir path; skip symlink"
fi
mkdir -p "$HOME/.npm"

chown -R node:node /data "$STATE_DIR" "$WORKSPACE_DIR" "$HOME/.npm" || true
if [ -L "$HOME_OPENCLAW" ]; then
  chown -h node:node "$HOME_OPENCLAW" || true
fi

if [ ! -f "$STATE_DIR/openclaw.json" ]; then
  echo "[entrypoint] no existing config, generating initial config"
else
  echo "[entrypoint] existing config found: $STATE_DIR/openclaw.json"
fi

echo "[entrypoint] state dir: $STATE_DIR"
echo "[entrypoint] workspace dir: $WORKSPACE_DIR"
echo "[entrypoint] gateway port: $GATEWAY_PORT"
echo "[entrypoint] gateway bind: ${GATEWAY_BIND:-<preserve-existing-or-default>}"
echo "[entrypoint] config mode: $CONFIG_MODE"

if [ "$CONFIG_MODE" = "manual" ] && [ -f "$STATE_DIR/openclaw.json" ]; then
  echo "[entrypoint] manual config mode enabled; preserving existing $STATE_DIR/openclaw.json"
else
  setpriv --reuid=node --regid=node --clear-groups \
    node /app/arm64/configure.cjs
fi

cd /app
exec setpriv --reuid=node --regid=node --clear-groups \
  node openclaw.mjs gateway --allow-unconfigured
