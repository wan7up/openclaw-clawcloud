#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
PORT="${PORT:-8080}"

mkdir -p "$STATE_DIR" "$WORKSPACE_DIR"

export OPENCLAW_STATE_DIR="$STATE_DIR"
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"
export OPENCLAW_GATEWAY_PORT="$GATEWAY_PORT"
export PORT="$PORT"

node /app/clawcloudrun/configure.js

mkdir -p /etc/nginx/conf.d
export DOLLAR='$'
envsubst '${PORT} ${OPENCLAW_GATEWAY_PORT}' < /app/clawcloudrun/nginx.conf.template > /etc/nginx/conf.d/openclaw.conf
rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf 2>/dev/null || true

nginx

cd /opt/openclaw/app
exec openclaw gateway run
