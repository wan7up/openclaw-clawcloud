#!/usr/bin/env bash
set -euo pipefail

RCLONE_REMOTE="${RCLONE_REMOTE:-ocbackup:}"
RCLONE_PATH="${RCLONE_PATH:-openclaw-migration}"
WORKDIR="${WORKDIR:-/root/restore/openclaw-migration}"
CHECK_ONLY=0
FROM_REMOTE=0
YES=0
ARCHIVE=""
MANIFEST=""

usage() {
  cat <<'EOF'
Usage:
  restore-openclaw-migration.sh --from-remote [--archive <filename>] [--check-only]
  restore-openclaw-migration.sh --archive <path> --sha256 <path> [--check-only]
  restore-openclaw-migration.sh --from-remote --yes

Options:
  --from-remote         Download backup from rclone remote (default remote: ocbackup:openclaw-migration)
  --archive <path>      Local archive path, or remote filename when used with --from-remote
  --sha256 <path>       Local sha256 manifest path
  --check-only          Only download (if needed) + verify; do not extract
  --yes                 Skip confirmation before extracting to /
  --workdir <path>      Temporary working directory (default: /root/restore/openclaw-migration)
  -h, --help            Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --from-remote) FROM_REMOTE=1 ;;
    --archive) ARCHIVE="${2:?missing value for --archive}"; shift ;;
    --sha256) MANIFEST="${2:?missing value for --sha256}"; shift ;;
    --check-only) CHECK_ONLY=1 ;;
    --yes) YES=1 ;;
    --workdir) WORKDIR="${2:?missing value for --workdir}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

mkdir -p "$WORKDIR"

if [ "$FROM_REMOTE" = "1" ]; then
  REMOTE_DIR="${RCLONE_REMOTE%/}/${RCLONE_PATH#/}"

  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(rclone lsf "$REMOTE_DIR" | grep '^openclaw-migration-.*\.tar\.gz$' | sort | tail -n1)"
  fi

  if [ -z "$ARCHIVE" ]; then
    echo "No remote archive found in $REMOTE_DIR" >&2
    exit 1
  fi

  ARCHIVE_BASENAME="$(basename "$ARCHIVE")"
  MANIFEST_BASENAME="${ARCHIVE_BASENAME%.tar.gz}.sha256"
  LOCAL_ARCHIVE="$WORKDIR/$ARCHIVE_BASENAME"
  LOCAL_MANIFEST="$WORKDIR/$MANIFEST_BASENAME"

  echo "[1/4] Downloading archive from remote"
  rclone copyto "$REMOTE_DIR/$ARCHIVE_BASENAME" "$LOCAL_ARCHIVE"
  rclone copyto "$REMOTE_DIR/$MANIFEST_BASENAME" "$LOCAL_MANIFEST"

  ARCHIVE="$LOCAL_ARCHIVE"
  MANIFEST="$LOCAL_MANIFEST"
else
  if [ -z "$ARCHIVE" ] || [ -z "$MANIFEST" ]; then
    echo "For local restore you must provide both --archive and --sha256" >&2
    usage
    exit 1
  fi
fi

if [ ! -f "$ARCHIVE" ]; then
  echo "Archive not found: $ARCHIVE" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "SHA256 manifest not found: $MANIFEST" >&2
  exit 1
fi

echo "[2/4] Verifying checksum"
sha256sum -c "$MANIFEST"

if [ "$CHECK_ONLY" = "1" ]; then
  echo "Check-only mode complete. Verified: $ARCHIVE"
  exit 0
fi

cat <<EOF
[3/4] Restore target
Archive : $ARCHIVE
SHA256  : $MANIFEST
Target  : /

This will extract files back to their original absolute paths under /root/... .
EOF

if [ "$YES" != "1" ]; then
  read -r -p "Proceed with extraction to / ? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

echo "[4/4] Extracting"
tar xzf "$ARCHIVE" -C /

echo
echo "Restore complete. Quick checks:"
for p in \
  /root/.openclaw/openclaw.json \
  /root/.openclaw/workspace \
  /root/.openclaw/extensions \
  /root/.openclaw/cron \
  /root/.openclaw/telegram \
  /root/.config/systemd/user/openclaw-gateway.service.d/override.conf; do
  if [ -e "$p" ]; then
    echo "  OK  $p"
  else
    echo "  MISS $p"
  fi
done

echo
echo "Suggested next commands:"
echo "  openclaw doctor --non-interactive"
echo "  openclaw gateway status"
