#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%F-%H%M%S)"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/openclaw-backups}"
TMP_DIR="$BACKUP_ROOT/tmp"
OUT_DIR="$BACKUP_ROOT/out"
ARCHIVE="$OUT_DIR/openclaw-full-$STAMP.tar.gz"
MANIFEST="$OUT_DIR/openclaw-full-$STAMP.sha256"

mkdir -p "$TMP_DIR" "$OUT_DIR"

if [ ! -d "$STATE_DIR" ]; then
  echo "State dir not found: $STATE_DIR" >&2
  exit 1
fi

echo "[1/4] Packing $STATE_DIR"
tar czf "$ARCHIVE" -C "$(dirname "$STATE_DIR")" "$(basename "$STATE_DIR")"

echo "[2/4] Checksumming"
sha256sum "$ARCHIVE" > "$MANIFEST"

echo "[3/4] Done"
echo "Archive : $ARCHIVE"
echo "SHA256  : $MANIFEST"

echo "[4/4] Next step"
echo "Upload with rclone after remote is configured, e.g.:"
echo "  rclone copy \"$OUT_DIR\" ocbackup:openclaw/ --progress"
