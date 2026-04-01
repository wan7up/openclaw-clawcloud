#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const STATE_DIR = (process.env.OPENCLAW_STATE_DIR || '/data/.openclaw').replace(/\/+$/, '');
const WORKSPACE_DIR = (process.env.OPENCLAW_WORKSPACE_DIR || '/data/workspace').replace(/\/+$/, '');
const CONFIG_PATH = process.env.OPENCLAW_CONFIG_PATH || path.join(STATE_DIR, 'openclaw.json');

fs.mkdirSync(STATE_DIR, { recursive: true });
fs.mkdirSync(WORKSPACE_DIR, { recursive: true });

let config = {};
let hadExistingConfig = false;
try {
  config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  hadExistingConfig = true;
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
if (process.env.OPENCLAW_GATEWAY_PORT) config.gateway.port = parseInt(process.env.OPENCLAW_GATEWAY_PORT, 10);
else if (config.gateway.port === undefined) config.gateway.port = 18789;

if (process.env.OPENCLAW_GATEWAY_BIND) config.gateway.bind = process.env.OPENCLAW_GATEWAY_BIND;
else if (config.gateway.bind === undefined) config.gateway.bind = 'loopback';

if (config.gateway.mode === undefined) config.gateway.mode = 'local';

ensure(config, 'gateway', 'controlUi');
if (config.gateway.controlUi.enabled === undefined) config.gateway.controlUi.enabled = true;

ensure(config, 'agents', 'defaults');
if (!config.agents.defaults.workspace) config.agents.defaults.workspace = WORKSPACE_DIR;
ensure(config, 'agents', 'defaults', 'model');

if (!config.agents.defaults.model.primary) {
  if (process.env.OPENAI_API_KEY) config.agents.defaults.model.primary = 'openai/gpt-5.2';
  else if (process.env.ANTHROPIC_API_KEY) config.agents.defaults.model.primary = 'anthropic/claude-opus-4-5-20251101';
  else if (process.env.OPENROUTER_API_KEY) config.agents.defaults.model.primary = 'openrouter/anthropic/claude-opus-4-5';
  else if (process.env.GEMINI_API_KEY) config.agents.defaults.model.primary = 'google/gemini-2.5-pro';
}

ensure(config, 'env');
if (process.env.OPENAI_API_KEY) config.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY;
if (process.env.OPENAI_BASE_URL) config.env.OPENAI_BASE_URL = process.env.OPENAI_BASE_URL;
if (process.env.ANTHROPIC_API_KEY) config.env.ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
if (process.env.OPENROUTER_API_KEY) config.env.OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
if (process.env.GEMINI_API_KEY) config.env.GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (process.env.OPENAI_BASE_URL || process.env.OPENAI_API_KEY || process.env.OPENAI_MODEL) {
  ensure(config, 'models', 'providers', 'openai');
  config.models.providers.openai.api = 'openai-completions';
  if (process.env.OPENAI_API_KEY) config.models.providers.openai.apiKey = process.env.OPENAI_API_KEY;
  if (process.env.OPENAI_BASE_URL) config.models.providers.openai.baseUrl = process.env.OPENAI_BASE_URL;

  const desiredId = process.env.OPENAI_MODEL || 'gpt-5.2';
  const existing = Array.isArray(config.models.providers.openai.models) ? config.models.providers.openai.models : [];
  const normalized = existing
    .filter((m) => m && typeof m === 'object')
    .map((m) => ({
      id: m.id || m.name,
      name: m.name || m.id,
      input: Array.isArray(m.input) && m.input.length ? m.input : ['text'],
      contextWindow: typeof m.contextWindow === 'number' ? m.contextWindow : 200000
    }))
    .filter((m) => typeof m.id === 'string' && m.id && typeof m.name === 'string' && m.name);

  const exists = normalized.some((m) => m.id === desiredId || m.name === desiredId);
  if (!exists) {
    normalized.unshift({
      id: desiredId,
      name: desiredId,
      input: ['text'],
      contextWindow: 200000
    });
  }

  config.models.providers.openai.models = normalized;
}

fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
console.log('[configure] wrote config to', CONFIG_PATH, hadExistingConfig ? '(updated)' : '(new)');
