# ARM64 Slim Release Checklist

## Goal
Promote `deploy/openclaw-arm64/` slim variant from locally validated candidate to publishable tag.

## Already validated locally
- image builds successfully from `Dockerfile.slim`
- wrapper no longer breaks first-run on unconfigured state
- runtime port is `18789`
- slim wrapper initializes state under `/data/.openclaw`
- slim wrapper initializes workspace under `/data/workspace`
- empty `/data` volume first boot creates `/data/.openclaw/openclaw.json`
- restart detects and reuses existing persisted config
- gateway starts successfully in local emulated validation

## Must validate on real ARM64 host before release
1. `docker run` with `-v <host-or-volume>:/data`
2. first boot reaches healthy running state
3. Web UI / gateway reachable on `18789`
4. restart preserves state and does not regenerate a fresh config unexpectedly
5. memory / startup time acceptable on target low-end box
6. no permission issues writing `/data/.openclaw` and `/data/workspace`

## Release actions
1. build and push slim tag
2. inspect published manifest / digest
3. final README pass
4. provide tested run command
5. mark tag as beta or stable based on real-host result
