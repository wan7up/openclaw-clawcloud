#!/bin/sh
set -eu

mkdir -p /home/node/.openclaw
chown -R 1000:1000 /home/node/.openclaw

export HOME=/home/node
export NODE_ENV=production
export TERM=xterm-256color
export XDG_CONFIG_HOME=/home/node/.openclaw

exec gosu 1000:1000 node dist/index.js gateway --allow-unconfigured --bind lan --port 18789
