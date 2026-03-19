#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const STATE_DIR = (process.env.OPENCLAW_STATE_DIR || '/data/.openclaw').replace(/\/+$/, '');
const WORKSPACE_DIR = (process.env.OPENCLAW_WORKSPACE_DIR || '/data/workspace').replace(/\/+$/, '');
const CONFIG_PATH = path.join(STATE_DIR, 'openclaw.json');
const GATEWAY_PORT = parseInt(process.env.OPENCLAW_GATEWAY_PORT || '18789', 10);
const GATEWAY_BIND = process.env.OPENCLAW_GATEWAY_BIND || 'loopback';
const GATEWAY_TOKEN = process.env.OPENCLAW_GATEWAY_TOKEN || '';

fs.mkdirSync(STATE_DIR, { recursive: true });
fs.mkdirSync(WORKSPACE_DIR, { recursive: true });

let config = {};
try {
  config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
} catch {}

config.gateway = config.gateway || {};
config.gateway.port = GATEWAY_PORT;
config.gateway.bind = GATEWAY_BIND;
config.gateway.mode = config.gateway.mode || 'local';
config.gateway.controlUi = config.gateway.controlUi || {};
config.gateway.controlUi.enabled = true;

if (GATEWAY_TOKEN) {
  config.gateway.auth = config.gateway.auth || {};
  config.gateway.auth.mode = 'token';
  config.gateway.auth.token = GATEWAY_TOKEN;
}

config.agents = config.agents || {};
config.agents.defaults = config.agents.defaults || {};
config.agents.defaults.workspace = WORKSPACE_DIR;
config.agents.defaults.model = config.agents.defaults.model || {};

if (!config.agents.defaults.model.primary) {
  if (process.env.OPENAI_API_KEY) {
    config.agents.defaults.model.primary = 'openai/gpt-5.2';
  } else if (process.env.ANTHROPIC_API_KEY) {
    config.agents.defaults.model.primary = 'anthropic/claude-opus-4-5-20251101';
  }
}

fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
console.log('[configure] wrote', CONFIG_PATH);
