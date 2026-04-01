#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
IMAGE_NAME=${IMAGE_NAME:-clawcloudrun-openclaw}
IMAGE_TAG=${IMAGE_TAG:-local}
PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64}
PUSH=${PUSH:-0}
LOAD=${LOAD:-0}
BUILDER_NAME=${BUILDER_NAME:-multiarch}

cd "$SCRIPT_DIR"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[build] missing command: $1" >&2
    exit 1
  }
}

need_cmd docker

if ! docker buildx version >/dev/null 2>&1; then
  echo "[build] docker buildx is required" >&2
  exit 1
fi

echo "[build] ensuring binfmt/QEMU emulators"
docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null

if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo "[build] creating builder: $BUILDER_NAME"
  docker buildx create --name "$BUILDER_NAME" --driver docker-container --use >/dev/null
else
  docker buildx use "$BUILDER_NAME" >/dev/null
fi

docker buildx inspect --bootstrap >/dev/null

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"
ARGS=(
  build
  --platform "$PLATFORMS"
  --progress plain
  -t "$IMAGE_REF"
)

if [[ -n "${BASE_IMAGE:-}" ]]; then
  ARGS+=(--build-arg "BASE_IMAGE=$BASE_IMAGE")
fi

if [[ "$PUSH" == "1" ]]; then
  ARGS+=(--push)
elif [[ "$LOAD" == "1" ]]; then
  if [[ "$PLATFORMS" == *","* ]]; then
    echo "[build] --load only supports a single platform; current PLATFORMS=$PLATFORMS" >&2
    exit 1
  fi
  ARGS+=(--load)
else
  ARGS+=(--output=type=image,push=false)
fi

ARGS+=(.)

echo "[build] image: $IMAGE_REF"
echo "[build] platforms: $PLATFORMS"
echo "[build] push: $PUSH | load: $LOAD | builder: $BUILDER_NAME"

docker buildx "${ARGS[@]}"

echo "[build] done: $IMAGE_REF"
