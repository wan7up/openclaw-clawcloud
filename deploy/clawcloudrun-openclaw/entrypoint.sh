#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
EXTERNAL_PORT="${PORT:-8080}"
NGINX_CONF="/etc/nginx/conf.d/openclaw.conf"

export OPENCLAW_STATE_DIR="$STATE_DIR"
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"
export OPENCLAW_GATEWAY_PORT="$GATEWAY_PORT"

mkdir -p /data "$STATE_DIR" "$WORKSPACE_DIR"
mkdir -p "$STATE_DIR/agents/main/sessions" "$STATE_DIR/credentials"
chmod 700 "$STATE_DIR" || true

# Make plugin installers that write to ~/.openclaw land on the same persistent state dir.
mkdir -p "$HOME"
HOME_OPENCLAW="${HOME%/}/.openclaw"
heal_self_referential_link "$HOME_OPENCLAW"

mkdir -p "$STATE_DIR" "$WORKSPACE_DIR"
chmod 700 "$STATE_DIR" || true

if [ "$HOME_OPENCLAW" != "$STATE_DIR" ]; then
  rm -rf "$HOME_OPENCLAW" 2>/dev/null || true
  ln -s "$STATE_DIR" "$HOME_OPENCLAW"
else
  echo "[entrypoint] ~/.openclaw already points at state dir path; skip symlink"
fi
mkdir -p "$HOME/.npm"

if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  echo "[entrypoint] ERROR: OPENCLAW_GATEWAY_TOKEN is required" >&2
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENROUTER_API_KEY:-}" ] && [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "[entrypoint] ERROR: at least one provider API key env var is required" >&2
  exit 1
fi

echo "[entrypoint] state dir: $STATE_DIR"
echo "[entrypoint] workspace dir: $WORKSPACE_DIR"
echo "[entrypoint] gateway port: $GATEWAY_PORT"
echo "[entrypoint] external port: $EXTERNAL_PORT"

node /app/clawcloudrun/configure.cjs

export BASIC_AUTH_BLOCK=""
if [ -n "${AUTH_PASSWORD:-}" ]; then
  AUTH_USERNAME="${AUTH_USERNAME:-admin}"
  apt-get update >/dev/null 2>&1 || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apache2-utils >/dev/null 2>&1 || true
  htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USERNAME" "$AUTH_PASSWORD" >/dev/null 2>&1
  export BASIC_AUTH_BLOCK='auth_basic "OpenClaw";\n        auth_basic_user_file /etc/nginx/.htpasswd;'
fi

export OPENCLAW_GATEWAY_TOKEN
export GATEWAY_PORT
export EXTERNAL_PORT

envsubst '${OPENCLAW_GATEWAY_TOKEN} ${GATEWAY_PORT} ${EXTERNAL_PORT} ${BASIC_AUTH_BLOCK}' < /app/clawcloudrun/nginx.conf.template > "$NGINX_CONF"

mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/starting.html <<'EOF'
<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>OpenClaw starting</title></head>
<body style="font-family:sans-serif;background:#111;color:#eee;display:flex;min-height:100vh;align-items:center;justify-content:center;">
<div style="text-align:center"><h1>OpenClaw is starting</h1><p>Please wait a moment…</p></div>
<script>setTimeout(function(){location.reload()},3000)</script>
</body>
</html>
EOF

nginx

cd /app
exec openclaw gateway run
