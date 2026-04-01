# OpenClaw ARM64 Docker image

This directory is intentionally separate from `deploy/clawcloudrun-openclaw/`.

> Repo layout note: this project currently uses **one GitHub repository, two GHCR packages, two logical task lines**.
>
> - Task 001 / ClawCloud Run line → `ghcr.io/wan7up/openclaw-clawcloud`
> - Task 004 / ARM64 line → `ghcr.io/wan7up/openclaw-arm64`
>
> Shared repo does **not** mean shared deployment target. This ARM64 line is for separate low-end / non-ClawCloud machines and must remain isolated in docs, tags, and operational reasoning.

## Goal

Build and deliver a plain Docker image flow for low-end ARM64 deployment targets.

Current task boundary:
- Docker image only
- primary target: `linux/arm64`
- default deployment style: direct `docker run`
- do not mix this with ClawCloud Run adaptation work
- keep ARM64 packaging / validation notes isolated here

## Current image shape

This line now has two intentionally thin variants:

### Standard variant (manual-first, non-slim)
- dockerfile: `Dockerfile`
- base image: `ghcr.io/openclaw/openclaw:2026.3.24`
- runtime entrypoint: custom ARM64 wrapper shared with the slim line
- defaults: `HOME=/data`, `OPENCLAW_CONFIG_MODE=manual`, `OPENCLAW_MANUAL_DEVICES=1`
- goal: keep the image non-slim while preserving the manual-first behavior expected from the earlier `manual-devices` line
- note: this variant is the preferred path when the user explicitly wants a non-slim package rather than the slim runtime experiment

### Slim variant
- dockerfile: `Dockerfile.slim`
- base image: `ghcr.io/openclaw/openclaw:2026.3.24-slim`
- runtime entrypoint: custom lightweight ARM64 wrapper
- state dir: `/data/.openclaw`
- workspace dir: `/data/workspace`
- startup flow: initialize config + state/workspace directories, then start gateway with first-run-safe behavior

This directory is therefore focused on:
1. reproducible ARM64 builds
2. simple registry push / pull flow
3. low-end ARM box deployment with `docker run`
4. keeping this line separate from ClawCloud Run packaging
5. providing a slimmer ARM64 runtime option for low-memory targets

## Files

- `Dockerfile` — minimal runtime image wrapper (standard upstream base)
- `Dockerfile.slim` — minimal runtime image wrapper (upstream slim base)
- `build.sh` — `docker buildx` helper for ARM64 builds, supports custom `DOCKERFILE`
- `run.sh` — example `docker run` launcher for the standard image
- `run-slim.sh` — example `docker run` launcher for the slim image
- `README.md` — usage + deployment notes

## Recommended image naming

Suggested naming for this line:

```bash
ghcr.io/wan7up/openclaw-arm64:<tag>
```

Examples:

```bash
ghcr.io/wan7up/openclaw-arm64:latest
ghcr.io/wan7up/openclaw-arm64:v0.1.0
ghcr.io/wan7up/openclaw-arm64:slim
ghcr.io/wan7up/openclaw-arm64:v0.1.0-slim
```

## Quick build

Build and load a local ARM64 image:

```bash
cd deploy/openclaw-arm64
./build.sh
```

Default behavior:
- image name: `openclaw-arm64`
- tag: `local`
- dockerfile: `Dockerfile`
- platform: `linux/arm64`
- output mode: `--load`

Equivalent resulting image ref:

```bash
openclaw-arm64:local
```

## Common build examples

### 1) Local ARM64 build

```bash
cd deploy/openclaw-arm64
IMAGE_NAME=openclaw-arm64 IMAGE_TAG=test ./build.sh
```

### 2) Build for GHCR naming

```bash
cd deploy/openclaw-arm64
IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=v0.1.0 ./build.sh
```

### 3) Push instead of load

```bash
cd deploy/openclaw-arm64
IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=v0.1.0 PUSH=1 LOAD=0 ./build.sh
```

### 4) Keep this line ARM64-only

```bash
cd deploy/openclaw-arm64
IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=latest PLATFORMS=linux/arm64 PUSH=1 LOAD=0 ./build.sh
```

### 5) Build the new slim variant

```bash
cd deploy/openclaw-arm64
DOCKERFILE=Dockerfile.slim IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=slim PLATFORMS=linux/arm64 PUSH=1 LOAD=0 ./build.sh
```

### 6) Local slim smoke build

```bash
cd deploy/openclaw-arm64
DOCKERFILE=Dockerfile.slim IMAGE_NAME=openclaw-arm64 IMAGE_TAG=slim-test ./build.sh
```

## Low-end ARM target deployment

For old ARM boxes (for example CoreELEC / TV-box style environments), prefer:
- build remotely
- push to registry
- only `pull` + `docker run` on the target host

Do **not** assume:
- `docker compose` exists
- Docker resource controls are fully available
- the box is suitable for heavy long-running workloads

## Minimal target-host run

### Standard image (non-slim, manual-first)

```bash
docker run -d \
  --name openclaw-arm64 \
  --restart unless-stopped \
  -p 18789:18789 \
  -e HOME=/data \
  -e OPENCLAW_GATEWAY_BIND=lan \
  -e OPENCLAW_CONFIG_MODE=manual \
  -e OPENCLAW_MANUAL_DEVICES=1 \
  -v openclaw-data:/data \
  ghcr.io/wan7up/openclaw-arm64:latest
```

### Slim image

```bash
docker run -d \
  --name openclaw-arm64-slim \
  --restart unless-stopped \
  -p 18789:18789 \
  -v openclaw-data:/data \
  ghcr.io/wan7up/openclaw-arm64:slim
```

## Useful runtime commands

### View logs

```bash
docker logs -f openclaw-arm64
```

### Stop

```bash
docker stop openclaw-arm64
```

### Remove

```bash
docker rm -f openclaw-arm64
```

### Inspect image entrypoint

```bash
docker image inspect ghcr.io/wan7up/openclaw-arm64:latest \
  --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
```

## Notes for the current CoreELEC-style target

Current known target profile:
- `aarch64`
- CoreELEC 19.5
- Linux 4.9.269
- Docker 19.03.15
- no `docker compose`
- no swap limit / cpu cfs quota / cpu cfs period support
- roughly 2 GiB RAM, no swap

Operational guidance for that class of machine:
- keep deployment simple
- prefer one container only
- avoid assuming resource limits can protect the host
- treat this as a light-duty node, not a heavy primary server
- prefer a host-side `.env` file plus direct `docker run`
- prefer the `slim` variant first on ~2 GiB RAM class boxes
- for the slim variant, mount the whole `/data` directory; the wrapper persists state to `/data/.openclaw` and workspace to `/data/workspace`

## Current status

- line initialized and first committed at `4a3b85c`
- task boundary explicitly separated from ClawCloud Run packaging
- standard ARM64 image build has been reproduced successfully (`openclaw-arm64:local`)
- current known-good GHCR baseline: `ghcr.io/wan7up/openclaw-arm64:2026.3.24-manual-devices-v8`
- later release strategy for this line: follow upstream OpenClaw release version and publish tags like `ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9`
- current CLI mitigation: ARM64 line now sets `OPENCLAW_NO_RESPAWN=1` by default to avoid the upstream CLI respawn/bootstrap path that can hang on some low-end ARM64 machines
- compatibility note: published ARM64 tags should be rewritten to `linux/arm/v8` manifest metadata after push so older Docker stacks (for example some CoreELEC / Docker 19 hosts) can pull them reliably
- new slim line added:
  - dockerfile: `Dockerfile.slim`
  - upstream base: `ghcr.io/openclaw/openclaw:2026.3.24-slim`
  - local smoke build passed: `openclaw-arm64:slim-test`
  - observed local image size: about `462MB`
- local validation update:
  - initial slim wrapper bug found and fixed: overriding upstream CMD with `openclaw gateway run` broke first-run startup on unconfigured containers
  - slim line upgraded from a thin wrapper to a proper runtime wrapper with dedicated `entrypoint.sh` + `configure.cjs`
  - slim wrapper now initializes and persists state under `/data/.openclaw`, and workspace under `/data/workspace`
  - empty `/data` volume first-boot validation passed: config was created at `/data/.openclaw/openclaw.json`
  - restart validation passed: container detected existing config and reused persisted state
  - local container validation confirmed gateway starts successfully and listens on `18789`
  - beta2 wrapper behavior fix: existing user config is now preserved by default; gateway bind and other fields are no longer forcibly reset on every restart unless explicitly provided via environment variables
  - note: HTTP probing from this amd64 host into emulated arm64 container showed occasional reset/empty-reply behavior during startup, so final user-facing validation still needs a real ARM64 host run
- next checkpoint: publish the slim tag and validate `docker run` on the real ARM64 box
