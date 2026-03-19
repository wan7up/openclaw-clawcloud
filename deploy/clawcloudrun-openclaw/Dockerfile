FROM ghcr.io/openclaw/openclaw:latest

USER root

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx gettext-base \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /app/clawcloudrun/entrypoint.sh
COPY configure.js /app/clawcloudrun/configure.js
COPY nginx.conf.template /app/clawcloudrun/nginx.conf.template

RUN chmod +x /app/clawcloudrun/entrypoint.sh

ENV OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    OPENCLAW_GATEWAY_PORT=18789 \
    OPENCLAW_GATEWAY_BIND=loopback \
    PORT=8080

EXPOSE 8080

ENTRYPOINT ["/app/clawcloudrun/entrypoint.sh"]
