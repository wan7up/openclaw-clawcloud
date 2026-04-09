ARG OPENCLAW_VERSION=2026.4.9
ARG BASE_IMAGE=ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}
FROM ${BASE_IMAGE}

USER root

RUN mkdir -p /data/.openclaw /data/workspace /data/.npm \
  && chown -R node:node /data

ENV HOME=/data \
    OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    OPENCLAW_NO_RESPAWN=1

WORKDIR /app
