# OpenClaw packaging repo: Task 001 + Task 004

This repository now maintains **two different OpenClaw delivery lines in one GitHub repo**.

- **Task 001 / ClawCloud Run**  
  Image: `ghcr.io/wan7up/openclaw-clawcloud`  
  Purpose: a ClawCloud Run friendly package with persistent `/data`, nginx front door on `8080`, and env-driven bootstrap.

- **Task 004 / ARM64 manual-first package**  
  Image: `ghcr.io/wan7up/openclaw-arm64`  
  Purpose: a non-slim ARM64 package for boxes such as CoreELEC / low-power ARM devices, with manual-device-first defaults and ARM v8-compatible manifest metadata.

## Current latest images

### Task 001 / ClawCloud Run
- Version tag: `ghcr.io/wan7up/openclaw-clawcloud:v2026.3.31`
- Rolling tag: `ghcr.io/wan7up/openclaw-clawcloud:latest`
- Base upstream: OpenClaw `2026.3.31`

### Task 004 / ARM64
- Version tag: `ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9`
- Rolling tag: `ghcr.io/wan7up/openclaw-arm64:latest-manual-devices-v9`
- Base upstream: OpenClaw `2026.3.31`

## What this repo does

### Task 001 / ClawCloud Run line
Located in: `deploy/clawcloudrun-openclaw/`

Key behaviors:
- state directory at `/data/.openclaw`
- workspace at `/data/workspace`
- nginx exposes port `8080` and proxies to internal gateway
- minimal config generated from env at startup
- memory vector disabled by default for better ClawCloud Run stability

### Task 004 / ARM64 line
Located in: `deploy/openclaw-arm64/`

Key behaviors:
- non-slim ARM64 package
- manual-first defaults
- `HOME=/data`
- `OPENCLAW_CONFIG_MODE=manual`
- `OPENCLAW_MANUAL_DEVICES=1`
- `OPENCLAW_NO_RESPAWN=1` mitigation enabled by default
- tag rewritten with `linux/arm/v8` compatible manifest metadata for older Docker / CoreELEC environments

## Automation

This repo is designed to keep the package pages and downloadable refs fresh automatically:

- `sync-openclaw-package-bases.yml` checks upstream OpenClaw releases daily
- `publish-openclaw-packages.yml` builds and pushes both GHCR images
- release metadata should track the latest published package refs instead of staying pinned to the old `v0.1.8` era

## Quick links

- Task 001 docs: `deploy/clawcloudrun-openclaw/`
- Task 004 docs: `deploy/openclaw-arm64/`
- Upstream project: <https://github.com/openclaw/openclaw>

## Important note

Although both delivery lines live in one repository, they are **different products** and should be described separately on GitHub / GHCR pages. Do not merge their positioning, tags, or deployment guidance into one vague description.
