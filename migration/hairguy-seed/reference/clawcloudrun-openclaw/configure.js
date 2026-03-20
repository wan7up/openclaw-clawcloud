#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const STATE_DIR = (process.env.OPENCLAW_STATE_DIR || '/data/.openclaw').replace(/\/+$/, '');
const WORKSPACE_DIR = (process.env.OPENCLAW_WORKSPACE_DIR || '/data/workspace').replace(/\/+$/, '');
const CONFIG_PATH = process.env.OPENCLAW_CONFIG_PATH || path.join(STATE_DIR, 'openclaw.json');

fs.mkdirSync(STATE_DIR, { recursive: true });
fs.mkdirSync(WORKSPACE_DIR, { recursive: true });

let config = {};
try {
  config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  console.log('[configure] merged existing config');
} catch {
  console.log('[configure] no existing config, creating fresh');
}

function ensure(obj, ...keys) {
  let cur = obj;
  for (const k of keys) {
    if (!cur[k] || typeof cur[k] !== 'object' || Array.isArray(cur[k])) cur[k] = {};
    cur = cur[k];
  }
  return cur;
}

ensure(config, 'gateway');
config.gateway.port = parseInt(process.env.OPENCLAW_GATEWAY_PORT || '18789', 10);
config.gateway.bind = process.env.OPENCLAW_GATEWAY_BIND || 'loopback';
config.gateway.mode = config.gateway.mode || 'local';

ensure(config, 'gateway', 'auth');
config.gateway.auth.mode = 'token';
config.gateway.auth.token = process.env.OPENCLAW_GATEWAY_TOKEN;

ensure(config, 'gateway', 'controlUi');
if (config.gateway.controlUi.enabled === undefined) config.gateway.controlUi.enabled = true;

ensure(config, 'agents', 'defaults');
config.agents.defaults.workspace = WORKSPACE_DIR;
ensure(config, 'agents', 'defaults', 'model');

if (!config.agents.defaults.model.primary) {
  if (process.env.ANTHROPIC_API_KEY) config.agents.defaults.model.primary = 'anthropic/claude-opus-4-5-20251101';
  else if (process.env.OPENAI_API_KEY) config.agents.defaults.model.primary = 'openai/gpt-5.2';
  else if (process.env.OPENROUTER_API_KEY) config.agents.defaults.model.primary = 'openrouter/anthropic/claude-opus-4-5';
  else if (process.env.GEMINI_API_KEY) config.agents.defaults.model.primary = 'google/gemini-2.5-pro';
}

if (process.env.OPENCLAW_ALLOWED_ORIGIN) {
  config.gateway.allowedOrigins = [process.env.OPENCLAW_ALLOWED_ORIGIN];
}

fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
console.log('[configure] wrote config to', CONFIG_PATH);
