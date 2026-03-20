# OpenClaw for ClawCloud Run

[English](./README.md) | [简体中文](./README_zh-CN.md)

A minimal, practical adaptation of the official OpenClaw image for **ClawCloud Run**.

This repository exists to solve the real deployment problems people commonly hit when trying to run OpenClaw on ClawCloud Run.

## What this repository solves

Compared with using the upstream image directly, this adaptation focuses on a small set of practical issues:

- storing OpenClaw state under persistent `/data/.openclaw`
- storing workspace data under `/data/workspace`
- exposing external port `8080` through `nginx`, then proxying traffic to the internal gateway
- generating a minimal usable config from environment variables at startup
- reducing first-deploy dependence on terminal-heavy manual fixes

## Current status

- `v0.1.3`: the first confirmed working baseline
- `v0.1.8`: the current public **env-driven candidate** intended for reuse
- verified so far:
  - WebUI opens correctly
  - webchat connects correctly
  - chat works
  - state persists when the same `/data` mount is reused across redeployments

## Quick start

When deploying on ClawCloud Run, pay attention to at least these items:

1. Mount **Local Storage** to `/data`
2. Use service port `8080`
3. Set `OPENCLAW_ALLOWED_ORIGIN` correctly
4. Provide your own API settings through ENV (for example `OPENAI_API_KEY` / `OPENAI_BASE_URL`)

## ClawCloud Run deployment steps (Create App)

The following maps directly to the **ClawCloud Run → Create App** form.

### 1. Image Name
Use the image you published, for example:

```text
ghcr.io/wan7up/openclaw-clawcloud:v0.1.8
```

If you fork or publish your own build, replace it with your own GHCR path, for example:

```text
ghcr.io/<yourname>/openclaw-clawcloud:v0.1.8
```

### 2. Port
Set:

```text
8080
```

### 3. Local Storage
Add a writable **Local Storage** mount and set the mount path to:

```text
/data
```

### 4. Environment Variables
At minimum, these are recommended:

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENCLAW_ALLOWED_ORIGIN=https://your-app.us-west-1.clawcloudrun.com
OPENCLAW_STATE_DIR=/data/.openclaw
OPENCLAW_WORKSPACE_DIR=/data/workspace
OPENCLAW_GATEWAY_PORT=18789
PORT=8080
```

If you use OpenAI or an OpenAI-compatible API:

```env
OPENAI_API_KEY=replace-me
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

## Important note about `OPENCLAW_ALLOWED_ORIGIN`

This variable is critical and easy to misconfigure.

It must be set to the **actual public origin assigned by ClawCloud Run**, for example:

```text
https://your-app.us-west-1.clawcloudrun.com
```

Do **not** use:

- `127.0.0.1`
- container-internal addresses
- guessed domains
- full URLs with extra path segments

## Recommended post-deploy checks

After the first deployment, verify these in order:

1. The WebUI opens
2. You can send one simple test message
3. `/data/.openclaw/openclaw.json` was generated correctly from your ENV values
4. After redeploying with the same `/data` mount, the previous state is still there

## Known but not necessarily blocking issues

### `openclaw doctor --fix` may report:
- `pairing required`
- `Gateway not running`
- `systemd not installed`

Inside ClawCloud Run, those messages can sometimes be noise rather than real blockers.

If all of the following are true:

- WebUI opens
- chat works
- state persists

then those doctor messages are usually **not deployment blockers**.

## Pairing fallback (terminal workaround)

The normal goal is to avoid any manual terminal-based pairing.

However, during early validation, some ClawCloud Run sessions could still get unstuck only after a one-time manual approval from the container terminal. If pairing appears stuck, use the following as a fallback workaround.

1. Refresh the WebUI once
2. In the terminal, run:

```bash
cat /data/.openclaw/devices/pending.json
```

3. Take the new `requestId` and run:

```bash
node --input-type=module -e "import('/app/dist/plugin-sdk/device-pair.js').then(async m => { const r = await m.approveDevicePairing('NEW_ID','/data/.openclaw'); console.log(JSON.stringify(r,null,2)); }).catch(err => { console.error(err); process.exit(1); })"
```

4. Then check:

```bash
cat /data/.openclaw/devices/paired.json
```

## Project position

This adaptation is not trying to reinvent OpenClaw.

Its purpose is simple:

> add the smallest practical compatibility layer needed to run official OpenClaw cleanly on ClawCloud Run.
