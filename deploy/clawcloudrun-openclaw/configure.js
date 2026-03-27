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

function removeKeyDeep(node, targetKey) {
  let removed = 0;
  if (!node || typeof node !== 'object') return removed;
  if (Array.isArray(node)) {
    for (const item of node) removed += removeKeyDeep(item, targetKey);
    return removed;
  }
  if (Object.prototype.hasOwnProperty.call(node, targetKey)) {
    delete node[targetKey];
    removed += 1;
  }
  for (const value of Object.values(node)) {
    removed += removeKeyDeep(value, targetKey);
  }
  return removed;
}

const removedAllowBotsCount = removeKeyDeep(config, 'allowBots');
if (removedAllowBotsCount > 0 && hadExistingConfig) {
  const backupPath = `${CONFIG_PATH}.bak-before-allowBots-cleanup-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  try {
    fs.copyFileSync(CONFIG_PATH, backupPath);
    console.log(`[configure] backed up existing config to ${backupPath}`);
  } catch (err) {
    console.warn(`[configure] failed to back up existing config before cleanup: ${err.message}`);
  }
  console.log(`[configure] removed ${removedAllowBotsCount} legacy allowBots key(s)`);
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

const hasOpenAIBaseUrl = Boolean(process.env.OPENAI_BASE_URL);
const hasOpenAICredentials = Boolean(process.env.OPENAI_API_KEY);
const hasOpenAIModel = Boolean(process.env.OPENAI_MODEL);

if (hasOpenAICredentials && hasOpenAIModel) {
  config.agents.defaults.model.primary = `openai/${process.env.OPENAI_MODEL}`;
} else if (!config.agents.defaults.model.primary) {
  if (process.env.ANTHROPIC_API_KEY) config.agents.defaults.model.primary = 'anthropic/claude-opus-4-5-20251101';
  else if (process.env.OPENROUTER_API_KEY) config.agents.defaults.model.primary = 'openrouter/anthropic/claude-opus-4-5';
  else if (process.env.GEMINI_API_KEY) config.agents.defaults.model.primary = 'google/gemini-2.5-pro';
  else if (hasOpenAICredentials) config.agents.defaults.model.primary = 'openai/gpt-5.2';
}

// OpenAI / OpenAI-compatible env + optional minimal curated model catalog
if (hasOpenAICredentials || hasOpenAIBaseUrl) {
  ensure(config, 'env');
  if (process.env.OPENAI_API_KEY) config.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  if (process.env.OPENAI_BASE_URL) config.env.OPENAI_BASE_URL = process.env.OPENAI_BASE_URL;

  if (hasOpenAIBaseUrl) {
    ensure(config, 'models', 'providers', 'openai');
    config.models.providers.openai.api = 'openai-completions';
    if (process.env.OPENAI_API_KEY) config.models.providers.openai.apiKey = process.env.OPENAI_API_KEY;
    config.models.providers.openai.baseUrl = process.env.OPENAI_BASE_URL;
    if (hasOpenAIModel) {
      config.models.providers.openai.models = [
        {
          id: process.env.OPENAI_MODEL,
          name: process.env.OPENAI_MODEL,
          reasoning: true,
          input: ['text', 'image']
        }
      ];
    }
  }
}

if (process.env.OPENCLAW_ALLOWED_ORIGIN) {
  ensure(config, 'gateway', 'controlUi');
  config.gateway.controlUi.allowedOrigins = [process.env.OPENCLAW_ALLOWED_ORIGIN];
}

fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
console.log('[configure] wrote config to', CONFIG_PATH);
