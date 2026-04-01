# ghcr.io/wan7up/openclaw-arm64

Task 004 / ARM64 line.

A non-slim ARM64 OpenClaw package for CoreELEC / low-power ARM boxes, with:
- manual-first defaults
- `HOME=/data`
- `OPENCLAW_CONFIG_MODE=manual`
- `OPENCLAW_MANUAL_DEVICES=1`
- `OPENCLAW_NO_RESPAWN=1` enabled by default as the current mitigation
- rewritten `linux/arm/v8` compatible manifest metadata for older Docker environments

Recommended tags:
- `2026.3.31-manual-devices-v9`
- `latest-manual-devices-v9`

Repository: <https://github.com/wan7up/openclaw-clawcloud>
