#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%F-%H%M%S)"
OUTROOT="${BACKUP_ROOT:-$HOME/backups/openclaw-migration}"
RCLONE_REMOTE="${RCLONE_REMOTE:-ocbackup:}"
RCLONE_PATH="${RCLONE_PATH:-openclaw-migration}"
UPLOAD_REMOTE="${UPLOAD_REMOTE:-1}"
README_SOURCE="${README_SOURCE:-/root/.openclaw/workspace/backup/OPENCLAW_BACKUP_README.md}"
README_TARGET="$OUTROOT/README.md"
KEEP_LOCAL="${KEEP_LOCAL:-2}"
KEEP_REMOTE="${KEEP_REMOTE:-2}"
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

if [ -f "$README_SOURCE" ]; then
  cp "$README_SOURCE" "$README_TARGET"
fi

if [ "$UPLOAD_REMOTE" = "1" ]; then
  REMOTE_DIR="${RCLONE_REMOTE%/}/${RCLONE_PATH#/}"
  rclone mkdir "$REMOTE_DIR"
  rclone copyto "$ARCHIVE" "$REMOTE_DIR/$(basename "$ARCHIVE")"
  rclone copyto "$MANIFEST" "$REMOTE_DIR/$(basename "$MANIFEST")"
  if [ -f "$README_TARGET" ]; then
    rclone copyto "$README_TARGET" "$REMOTE_DIR/README.md"
  fi

  if [ "$KEEP_REMOTE" -ge 0 ]; then
    old_remote_tars="$(rclone lsf "$REMOTE_DIR" | grep '^openclaw-migration-.*\.tar\.gz$' | sort -r | awk -v keep="$KEEP_REMOTE" 'NR>keep')"
    if [ -n "$old_remote_tars" ]; then
      while IFS= read -r old_tar; do
        [ -z "$old_tar" ] && continue
        old_sha="${old_tar%.tar.gz}.sha256"
        rclone deletefile "$REMOTE_DIR/$old_tar" || true
        rclone deletefile "$REMOTE_DIR/$old_sha" || true
      done <<< "$old_remote_tars"
    fi
  fi
fi

# Keep only the most recent local backups
ls -1dt "$OUTROOT"/openclaw-migration-*.tar.gz 2>/dev/null | awk -v keep="$KEEP_LOCAL" 'NR>keep' | xargs -r rm -f
ls -1dt "$OUTROOT"/openclaw-migration-*.sha256 2>/dev/null | awk -v keep="$KEEP_LOCAL" 'NR>keep' | xargs -r rm -f

echo "Archive : $ARCHIVE"
echo "SHA256  : $MANIFEST"
if [ "$UPLOAD_REMOTE" = "1" ]; then
  echo "Remote : $REMOTE_DIR/$(basename "$ARCHIVE")"
  echo "Remote : $REMOTE_DIR/$(basename "$MANIFEST")"
fi
