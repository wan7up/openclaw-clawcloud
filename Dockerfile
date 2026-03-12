FROM ghcr.io/openclaw/openclaw:latest

USER root

RUN apt-get update \
    && apt-get install -y gosu \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
