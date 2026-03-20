# OpenClaw for ClawCloud Run

A minimal, practical adaptation of the official OpenClaw image for **ClawCloud Run**.

This prototype exists to solve the real problems that show up on ClawCloud Run:

- writable state should live on mounted storage, not under the image user's home
- first-run setup should work without SSH-heavy manual steps
- the platform needs a normal HTTP entrypoint on `8080`
- WebUI + WebSocket traffic must be proxied correctly

---

## What this image changes

Compared with the upstream `ghcr.io/openclaw/openclaw` image, this adaptation intentionally does only a small set of things:

- stores OpenClaw state under `/data/.openclaw`
- stores workspace data under `/data/workspace`
- generates a minimal `openclaw.json` from environment variables on startup
- runs `nginx` as the external HTTP/WebSocket entrypoint on port `8080`
- proxies requests to the internal OpenClaw gateway on `127.0.0.1:18789`

The goal is **not** to redesign OpenClaw. The goal is to make it deploy cleanly on ClawCloud Run.

---

## Current status

### Verified baseline
- `v0.1.3` was the first confirmed working baseline
- later experiments `v0.1.4` and `v0.1.5` introduced regressions and should not be treated as stable references
- `v0.1.8` is the current **public, env-driven candidate** intended for general reuse

### Verified working behavior
Current testing confirms:

- WebUI opens correctly
- webchat connects correctly
- chat works
- state persists when the same `/data` volume is reused

---

## Important design rule

This image is meant to be reusable by other users.

So:

> **Do not hardcode deployment-specific API URLs, keys, or user-specific defaults into the image.**

Anything user-specific should be injected through environment variables at deploy time.

---

## Required ClawCloud Run setup

### 1) Image
Use your published image, for example:

```text
ghcr.io/<yourname>/openclaw-clawcloud:v0.1.8
```

### 2) Port
Set the service port to:

```text
8080
```

### 3) Persistent storage
Mount a writable **Local Storage** volume to:

```text
/data
```

This is critical.

OpenClaw state and workspace are stored at:

- `/data/.openclaw`
- `/data/workspace`

If you redeploy the same app **with the same mounted `/data` volume**, records and state should remain available.

---

## Environment variables

## Required

| Variable | Required | Description |
|---|---:|---|
| `OPENCLAW_GATEWAY_TOKEN` | Yes | Gateway token used by the WebUI / clients |
| `OPENCLAW_ALLOWED_ORIGIN` | Yes | **Must be the ClawCloud Run public app URL origin**, e.g. `https://your-app.us-west-1.clawcloudrun.com` |
| `OPENCLAW_STATE_DIR` | Recommended | Set to `/data/.openclaw` |
| `OPENCLAW_WORKSPACE_DIR` | Recommended | Set to `/data/workspace` |
| `OPENCLAW_GATEWAY_PORT` | Recommended | Set to `18789` |
| `PORT` | Recommended | Set to `8080` |

### If using OpenAI / OpenAI-compatible APIs

| Variable | Required | Description |
|---|---:|---|
| `OPENAI_API_KEY` | Yes | Your OpenAI or OpenAI-compatible API key |
| `OPENAI_BASE_URL` | Optional | Needed for OpenAI-compatible / relay / proxy endpoints |
| `OPENAI_MODEL` | Optional | If set, the startup config will set the primary model to `openai/<OPENAI_MODEL>` and shrink the provider model list to that single model |

### Example

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENCLAW_ALLOWED_ORIGIN=https://your-app.us-west-1.clawcloudrun.com
OPENCLAW_STATE_DIR=/data/.openclaw
OPENCLAW_WORKSPACE_DIR=/data/workspace
OPENCLAW_GATEWAY_PORT=18789
PORT=8080

OPENAI_API_KEY=replace-me
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

---

## Important note about `OPENCLAW_ALLOWED_ORIGIN`

This variable is easy to miss, and it matters.

Set it to the **actual public origin assigned by ClawCloud Run**.

Example:

```text
https://stvxaykoiull.us-west-1.clawcloudrun.com
```

Do **not** put:
- `127.0.0.1`
- container-internal addresses
- random guessed domains
- a full path like `/chat`

It must be the **origin only**:
- scheme
- host
- optional port

No extra path.

---

## First deployment checklist

After deployment, verify these in order:

1. Open the WebUI
2. Send one simple test message
3. If using OpenAI-compatible APIs, inspect `/data/.openclaw/openclaw.json` and confirm your env values were written as expected
4. Redeploy the same app while keeping the same `/data` mount, then confirm state still exists

---

## Known non-blocking behavior

These may appear in container-based environments and are **not necessarily deployment failures**:

### `openclaw doctor --fix` may report:
- `pairing required`
- `Gateway not running`
- `systemd not installed`

In ClawCloud Run, this can be normal noise because:
- the gateway is already running in the container foreground model
- systemd is not expected inside the container
- CLI self-checks may not have the scopes they expect

If these are true:
- WebUI opens
- chat works
- state persists

then those doctor messages are usually **not blocking**.

### Provider badge may show unexpected labels
The WebUI model/provider badge may sometimes show labels like `azure` even when the actual runtime behavior is acceptable.

If:
- the selected model is correct
- the self-reported model is correct
- chat works

then treat this as a **display-layer issue** unless proven otherwise.

---

## Pairing fallback (terminal workaround)

**Normal goal:** a correct deployment should not require terminal-based manual pairing.

In practice, early validation (for example around the `v0.1.3` stage) showed that some ClawCloud Run sessions could still get unstuck only after a one-time manual approval in the container terminal.

So if WebUI pairing appears stuck, use this as a **fallback workaround**, not the normal expected flow.

### Step 1: refresh WebUI to generate a fresh pending request
Refresh the WebUI once, then immediately run:

```bash
cat /data/.openclaw/devices/pending.json
```

This should show a new `requestId`.

### Step 2: approve that specific requestId manually
Replace `NEW_ID` below with the actual request ID you just saw:

```bash
node --input-type=module -e "import('/app/dist/plugin-sdk/device-pair.js').then(async m => { const r = await m.approveDevicePairing('NEW_ID','/data/.openclaw'); console.log(JSON.stringify(r,null,2)); }).catch(err => { console.error(err); process.exit(1); })"
```

### Step 3: confirm it moved into `paired.json`

```bash
cat /data/.openclaw/devices/paired.json
```

If approval succeeded, `paired.json` should no longer be empty.

### Important note
If you repeatedly need this workaround on fresh deployments, first re-check:

- `OPENCLAW_ALLOWED_ORIGIN`
- whether it exactly matches the real ClawCloud Run public origin
- whether you are using the same persisted `/data` mount or carrying over old state

---

## Files in this directory

- `Dockerfile` — image definition
- `entrypoint.sh` — startup flow
- `configure.cjs` — env → `openclaw.json` minimal generator
- `nginx.conf.template` — reverse proxy config

---

## Why `configure.cjs` instead of `configure.js`

The upstream image runs in an ESM environment under `/app`.

So this adaptation uses:

- `configure.cjs`
- `/app/...`

instead of older incorrect assumptions like:

- `configure.js`
- `/opt/openclaw/app`

This is intentional and required for compatibility with the upstream image layout.

---

## Publishing guidance

If you publish this image or repo for other users:

- keep deployment-specific values out of the image
- document env variables clearly
- treat `/data` mounting as mandatory
- keep the adaptation minimal
- prefer stability over clever provider rewrites

---

## Summary

If you want a version of OpenClaw that can be deployed on ClawCloud Run and reused by others, the key pieces are:

- `/data` persistent storage
- correct `OPENCLAW_ALLOWED_ORIGIN`
- port `8080`
- minimal startup config generation
- no hardcoded user-specific API defaults

That is the whole point of this adaptation.
