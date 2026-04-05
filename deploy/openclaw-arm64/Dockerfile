ARG OPENCLAW_VERSION=2026.4.2
ARG BASE_IMAGE=ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}
FROM ${BASE_IMAGE}

USER root

COPY entrypoint.sh /app/arm64/entrypoint.sh
COPY configure.cjs /app/arm64/configure.cjs

RUN chmod +x /app/arm64/entrypoint.sh

ENV HOME=/data \
    OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    OPENCLAW_GATEWAY_PORT=18789 \
    OPENCLAW_GATEWAY_BIND=lan \
    OPENCLAW_CONFIG_MODE=manual \
    OPENCLAW_MANUAL_DEVICES=1 \
    OPENCLAW_NO_RESPAWN=1

WORKDIR /app

ENTRYPOINT ["/app/arm64/entrypoint.sh"]
