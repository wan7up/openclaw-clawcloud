#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%F-%H%M%S)"
OUTROOT="${BACKUP_ROOT:-$HOME/backups/openclaw-migration}"
RCLONE_REMOTE="${RCLONE_REMOTE:-ocbackup:}"
RCLONE_PATH="${RCLONE_PATH:-openclaw-migration}"
UPLOAD_REMOTE="${UPLOAD_REMOTE:-1}"
mkdir -p "$OUTROOT"
ARCHIVE="$OUTROOT/openclaw-migration-$STAMP.tar.gz"
MANIFEST="$OUTROOT/openclaw-migration-$STAMP.sha256"

INCLUDES=(
  /root/.openclaw/openclaw.json
  /root/.openclaw/workspace
  /root/.openclaw/workspace-agentb
  /root/.openclaw/workspace-agentc
  /root/.openclaw/extensions
  /root/.openclaw/cron
  /root/.openclaw/telegram
  /root/.config/systemd/user/openclaw-gateway.service.d/override.conf
  /home/docker/cliproxyapi
  /home/docker/gcli2api
)

ARGS=()
for p in "${INCLUDES[@]}"; do
  [ -e "$p" ] && ARGS+=("${p#/}")
done

cd /
tar czf "$ARCHIVE" \
  --exclude='root/.openclaw/workspace/.local-qmd' \
  --exclude='root/.openclaw/workspace/.git' \
  --exclude='root/.openclaw/browser' \
  --exclude='root/.openclaw/logs' \
  --exclude='root/.openclaw/media' \
  --exclude='root/.openclaw/backups' \
  --exclude='root/.cache' \
  --exclude='root/.npm' \
  --exclude='root/.node-llama-cpp' \
  --exclude='root/.openclaw/agents/*/qmd' \
  --exclude='root/.openclaw/agents/*/sessions' \
  "${ARGS[@]}"

sha256sum "$ARCHIVE" > "$MANIFEST"

if [ "$UPLOAD_REMOTE" = "1" ]; then
  REMOTE_DIR="${RCLONE_REMOTE%/}/${RCLONE_PATH#/}"
  rclone mkdir "$REMOTE_DIR"
  rclone copyto "$ARCHIVE" "$REMOTE_DIR/$(basename "$ARCHIVE")"
  rclone copyto "$MANIFEST" "$REMOTE_DIR/$(basename "$MANIFEST")"
fi

# Keep only the most recent 2 backups
ls -1dt "$OUTROOT"/openclaw-migration-*.tar.gz 2>/dev/null | awk 'NR>2' | xargs -r rm -f
ls -1dt "$OUTROOT"/openclaw-migration-*.sha256 2>/dev/null | awk 'NR>2' | xargs -r rm -f

echo "Archive : $ARCHIVE"
echo "SHA256  : $MANIFEST"
if [ "$UPLOAD_REMOTE" = "1" ]; then
  echo "Remote : $REMOTE_DIR/$(basename "$ARCHIVE")"
  echo "Remote : $REMOTE_DIR/$(basename "$MANIFEST")"
fi
