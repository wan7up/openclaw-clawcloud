#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
IMAGE_NAME=${IMAGE_NAME:-openclaw-arm64}
IMAGE_TAG=${IMAGE_TAG:-local}
PLATFORMS=${PLATFORMS:-linux/arm64}
PUSH=${PUSH:-0}
LOAD=${LOAD:-1}
BUILDER_NAME=${BUILDER_NAME:-multiarch}
DOCKERFILE=${DOCKERFILE:-Dockerfile}

cd "$SCRIPT_DIR"

command -v docker >/dev/null 2>&1 || { echo '[build] missing docker' >&2; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo '[build] docker buildx is required' >&2; exit 1; }

docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER_NAME" --driver docker-container --use >/dev/null
else
  docker buildx use "$BUILDER_NAME" >/dev/null
fi
docker buildx inspect --bootstrap >/dev/null

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"
ARGS=(build -f "$DOCKERFILE" --platform "$PLATFORMS" --progress plain -t "$IMAGE_REF")
if [[ "$PUSH" == "1" ]]; then
  ARGS+=(--push)
elif [[ "$LOAD" == "1" ]]; then
  ARGS+=(--load)
else
  ARGS+=(--output=type=image,push=false)
fi
ARGS+=(.)

echo "[build] image: $IMAGE_REF"
echo "[build] dockerfile: $DOCKERFILE"
echo "[build] platforms: $PLATFORMS"
docker buildx "${ARGS[@]}"
