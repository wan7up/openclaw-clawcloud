ARG BASE_IMAGE=ghcr.io/openclaw/openclaw:2026.4.29
FROM ${BASE_IMAGE}

USER root

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx gettext-base \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /app/clawcloudrun/entrypoint.sh
COPY configure.cjs /app/clawcloudrun/configure.cjs
COPY nginx.conf.template /app/clawcloudrun/nginx.conf.template

RUN chmod +x /app/clawcloudrun/entrypoint.sh

ENV HOME=/data \
    OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    OPENCLAW_GATEWAY_PORT=18789 \
    OPENCLAW_GATEWAY_BIND=loopback \
    PORT=8080

EXPOSE 8080

ENTRYPOINT ["/app/clawcloudrun/entrypoint.sh"]
