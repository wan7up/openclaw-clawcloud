# OpenClaw ARM64 Docker image

This directory is intentionally separate from `deploy/clawcloudrun-openclaw/`.

> Repo layout note: this project currently uses **one GitHub repository, two GHCR packages, two logical task lines**.
>
> - Task 001 / ClawCloud Run line → `ghcr.io/wan7up/openclaw-clawcloud`
> - Task 004 / ARM64 line → `ghcr.io/wan7up/openclaw-arm64`
>
> Shared repo does **not** mean shared deployment target. This ARM64 line is for separate low-end / non-ClawCloud machines and must remain isolated in docs, tags, and operational reasoning.

## Goal

Build an **official-first, minimal-diff ARM64 package** on top of:

```bash
ghcr.io/openclaw/openclaw:2026.4.5
```

The current rule for this line is:
- start from the official upstream image
- keep only the absolute minimum ARM64 / persistence compatibility changes
- do **not** carry forward old custom startup semantics unless they are proven necessary
- do **not** mix this line with ClawCloud Run-specific fixes
- prefer deleting historical wrapper logic over stacking new patches onto it

## Current image shape

Current package design is intentionally thin:

- base image: `ghcr.io/openclaw/openclaw:2026.4.5`
- platform target: `linux/arm64`
- retained overrides:
  - `HOME=/data`
  - `OPENCLAW_STATE_DIR=/data/.openclaw`
  - `OPENCLAW_WORKSPACE_DIR=/data/workspace`
  - `OPENCLAW_NO_RESPAWN=1`
- no custom entrypoint
- no custom configure script
- no ARM64-specific config mutation layer

Why keep these env vars:
- `HOME=/data` keeps `~/.openclaw` and installer defaults aligned with the mounted persistent volume
- `/data/.openclaw` + `/data/workspace` provide stable persistent layout across container recreation
- `OPENCLAW_NO_RESPAWN=1` is the one retained mitigation from earlier ARM64 investigation, because the CLI respawn/bootstrap path was a real source of hangs on low-end ARM64 hosts

## Files

Primary files now are:

- `Dockerfile` — minimal official-first ARM64 wrapper
- `build.sh` — `docker buildx` helper for ARM64 builds
- `run.sh` — example `docker run` launcher
- `README.md` — current notes for this package line

Historical files still present in this directory should be treated as **legacy investigation artifacts**, not the preferred runtime path:

- old custom entrypoints
- old configure scripts
- slim experiment files
- older manual-devices packaging notes

Until they are cleaned out, do **not** assume they describe the current intended package behavior.

## Recommended image naming

Suggested naming for this line:

```bash
ghcr.io/wan7up/openclaw-arm64:<tag>
```

Examples:

```bash
ghcr.io/wan7up/openclaw-arm64:2026.4.5-official-min
ghcr.io/wan7up/openclaw-arm64:latest-official-min
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
IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=2026.4.5-official-min ./build.sh
```

### 3) Push instead of load

```bash
cd deploy/openclaw-arm64
IMAGE_NAME=ghcr.io/wan7up/openclaw-arm64 IMAGE_TAG=2026.4.5-official-min PUSH=1 LOAD=0 ./build.sh
```

## Minimal target-host run

```bash
docker run -d \
  --name openclaw-arm64 \
  --restart unless-stopped \
  -p 18789:18789 \
  -e HOME=/data \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -e OPENCLAW_NO_RESPAWN=1 \
  -v /storage/openclaw:/data \
  ghcr.io/wan7up/openclaw-arm64:latest-official-min
```

If the host needs env injection, add `--env-file /storage/openclaw/.env`.

## Validation focus for the new line

This new line should be judged against a simple acceptance bar:

1. container starts from the official 2026.4.5 base on real ARM64 hardware
2. state persists correctly under `/data`
3. official plugin install flow remains usable
4. existing user config is not silently clobbered during upgrade
5. no extra custom startup/config logic is introduced unless real evidence forces it

## Status

Current status after the reset decision:
- old ARM64 package line is considered historically polluted and not suitable for more patch-stacking
- `ghcr.io/openclaw/openclaw:2026.4.2` is the only upstream base for the rebuild
- this directory has been reset toward an official-first minimal wrapper
- next required step is real build + runtime validation on ARM64, especially around persistence and official plugin install behavior
or
or
or
