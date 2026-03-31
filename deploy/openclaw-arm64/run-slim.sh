#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-ghcr.io/wan7up/openclaw-arm64}
IMAGE_TAG=${IMAGE_TAG:-slim}
CONTAINER_NAME=${CONTAINER_NAME:-openclaw-arm64-slim}
HOST_PORT=${HOST_PORT:-18789}
DATA_DIR=${DATA_DIR:-/storage/openclaw}
ENV_FILE=${ENV_FILE:-/storage/openclaw/.env}

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

echo "[run] image: $IMAGE_REF"
echo "[run] container: $CONTAINER_NAME"
echo "[run] port: ${HOST_PORT}:18789"
echo "[run] data dir: $DATA_DIR"
echo "[run] env file: $ENV_FILE"

mkdir -p "$DATA_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[run] missing env file: $ENV_FILE" >&2
  exit 1
fi

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${HOST_PORT}:18789" \
  --env-file "$ENV_FILE" \
  -v "${DATA_DIR}:/data" \
  "$IMAGE_REF"

echo "[run] started: $CONTAINER_NAME"
echo "[run] logs: docker logs -f $CONTAINER_NAME"
