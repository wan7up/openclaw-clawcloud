# MEMORY.md

## Durable preferences and decisions

- The user prefers treating WebUI and Telegram as the main/core OpenClaw experience surfaces when possible; Feishu is better used as an enterprise/work entry point rather than the sole long-form assistant surface.
- For shared/enterprise use, the user is comfortable centralizing model-provider cost on their own OpenClaw/OpenAI account, so invited users do not need to manage their own model API usage.
- For Feishu enterprise rollout, the current preferred product shape is: enterprise users use Feishu DMs to access the bot; Feishu group chats stay disabled for now to reduce chaos.
- For the current Feishu setup, OpenClaw was configured with `channels.feishu.dmPolicy = open` and `channels.feishu.groupPolicy = disabled`. This assumes Feishu-side app visibility is restricted to enterprise-internal users.
- If invited enterprise users later need access to their own Feishu personal data (calendar, tasks, docs, messages), that should be done with their own Feishu authorization rather than reusing the owner's personal-data authorization.
- The user's custom API provider was originally named `cli`, but has been **renamed to `openai-codex`** to work around a WebUI Control UI bug (UI sends bare model IDs; gateway resolves using the primary model's provider name as default; with `openai-codex/gpt-5.4` as primary, all custom models must be under `openai-codex` provider or they fail whitelist check with "model not allowed").
- Official OAuth models show `.anthropic` suffix in WebUI (3.13 hardcoded change).
- `config.patch` merges arrays by position, NOT replaces them. Use `config.apply` for full array overwrites.
- Main agent uses OAuth (`gpt-5.4`) as primary, with 7 fallbacks all under `openai-codex/` prefix. Fallback order: gemini-3.1-pro-preview → gemini-3-pro-preview → claude-sonnet-4-6 → gpt-5.2-codex → gemini-3-pro-high → gpt-5.2 → gemini-3-flash-preview.
- When the user is about to share sensitive info (passwords, secrets), proactively remind them which API/provider is currently in use; default self-hosted relay is considered safe, but third-party APIs used for cost-saving should not handle sensitive info.
- agentb / agentc use lightweight models only: `openai-codex/gemini-3-flash` + `openai-codex/gpt-5.1-codex-mini`.
- Weekly cron job (`sync-api-models-weekly`) intelligently curates Top 10-15 models from the user's API.
- User is a geek/tinkerer: for topics of interest, wants deep fundamental explanations; for everything else, wants fast direct results.
- Tencent Docs skill installed on both main workspace and agentc workspace.
- Cross-surface memory sync cron changed to every 24h (TG + WebUI now share same brain, 6h was overkill).
- imageModel set to `openai-codex/gemini-3-flash-preview` (with `image` added to input array in model definition).
- `/models` menu `cli/cli/` double-prefix bug fixed: models.providers.cli.models had IDs with embedded `cli/` prefix causing double-registration. Cleaned up via script.
- agents.defaults.models whitelist trimmed to 12 openai-codex models + gpt-5.4 (no duplicates).
- Feishu plugin "owner-only" restriction bypassed via source code patch (`owner-policy.js` and `auto-auth.js`): wrapped `assertOwnerAccessStrict` condition with `if (false && ...)`. Backup files: `.bak`. Patch scripts in workspace/scripts/.
- OPENAI_API_KEY injected into systemd service via `~/.config/systemd/user/openclaw-gateway.service.d/override.conf` so Gateway process can resolve `${OPENAI_API_KEY}` in openclaw.json. Without this, systemd service has no access to the variable → "APIKEY incorrect" errors.
- openclaw.json also has a top-level `env.OPENAI_API_KEY` field (system env injection zone, not visible in WebUI). This is normal; left as-is for now.
- Do NOT confabulate or guess conclusions without evidence. User has explicitly called this out.
- 关于“稍后我会主动回来汇报 / 定时提醒 / 一会儿我再回复你”这类话术，必须极其严格：**只有当我已经真实挂上可执行的触发机制**（如 `openclaw system event --mode now`、已生效的 cron / heartbeat 兜底、或其他确定可触发的新一轮机制）时，才可以这样说；否则必须明确说明“这轮结束后我不会自动续上”。不要学网页版 GPT 那种明明做不到还口头承诺的坏毛病。
- When making config changes, always scan ALL locations: global `agents.defaults`, AND per-agent entries in `agents.list` (agentb, agentc etc.). Partial updates cause subtle breakage.
- **核心任务索引**：全局的主任务清单保存在工作区根目录的 `TASKS.md` 中。当被问及当前任务、计划或待办事项时，必须优先读取此文件。相关详细子任务清单可能存放在 `deploy/` 等子目录。
- **Tailscale WebUI 故障排查**: 如果通过 Tailscale Serve (HTTPS) 访问 WebUI 时遇到无法弹出申请、死循环提示 `pairing required` 的情况，核心原因是 `gateway.controlUi.allowInsecureAuth` 被错误地设为了 `true`，导致安全上下文冲突。必须在 `openclaw.json` 中删除 `allowInsecureAuth` 后门，并在 `allowedOrigins` 添加 Tailscale 域名。重启网关后，浏览器才能正常发起加密的设备配对请求，随后使用 `openclaw devices approve <id>` 即可放行。
- User found my persistence on Task 008 amusing and slightly annoying. I need to chill out and not push tasks so aggressively when we are casually chatting or debugging other interesting system quirks.
- Task 001 / ClawCloud Run packaging baseline confirmed by the user: `ghcr.io/wan7up/openclaw-clawcloud:v0.1.12` is the current known-good GHCR package; future auto-update work should use this as the starting baseline instead of older remembered tags like `v0.1.8`.
- Task 004 / ARM64 packaging baseline confirmed by the user: `ghcr.io/wan7up/openclaw-arm64:2026.3.24-manual-devices-v8` is the current known-good GHCR package; future auto-update work should use this as the starting baseline.
- Packaging structure decision: keep **one GitHub repo + two GHCR packages + two logical task lines** for now. Task 001 / ClawCloud Run uses `ghcr.io/wan7up/openclaw-clawcloud`; Task 004 / ARM64 uses `ghcr.io/wan7up/openclaw-arm64`. Shared repo is acceptable, but I must not mentally merge the two deployment targets or mix their docs, tags, and reasoning.
- ARM64 CLI timeout lesson: if `openclaw ...` hangs but `OPENCLAW_NO_RESPAWN=1 openclaw ...` immediately returns, treat the upstream CLI `entry.js` respawn/bootstrap chain as the prime suspect rather than the business command implementation. Current mitigation for task 004 is to ship ARM64 images with `OPENCLAW_NO_RESPAWN=1` by default and advance the package suffix from `manual-devices-v8` to `manual-devices-v9` so fixed images are visually distinct from the older line.
- Telegram 端的定时记忆同步提醒必须极简，只发 1–2 行，避免刷屏。
- 这类定时任务/定时提醒通知默认只发 Telegram，不发微信，除非用户另行指定。
- 用户最新跨表面偏好：微信端默认只做短答和日常快速同步；大流程、长任务、重操作优先切到 TG bot 处理。
- Docker 网络绑定经验：若想“禁止公网直连，但允许本机回环 + SSH 隧道访问”，容器内应用应监听 `0.0.0.0`，而 Docker 端口发布应绑定宿主机 `127.0.0.1:PORT:PORT`。不要把应用本身绑到容器内 `127.0.0.1`，否则宿主机和 SSH 隧道都会访问失败。
- `cliproxyapi` 容器的 auth 凭据目录正确挂载点是 `/data/auths`；挂到 `/root/.cli-proxy-api` 会导致服务启动后显示 0 clients，并对推理请求返回 502。
- CoreELEC 上给用户复制 Docker 运行命令时，宿主路径不要写成抽象占位符（如 `/你的数据目录`）让用户原样贴；优先给出真实推荐路径（如 `/storage/openclaw`）或命名卷版本（如 `openclaw-data:/data`），否则很容易触发只读文件系统/挂载路径创建失败。
- QMD / memory_search 排障经验：若 `memory_search` 报 OpenAI embeddings 401，而聊天模型本身正常，优先怀疑记忆检索仍在独立走 OpenAI embeddings provider，而不是复用聊天模型的 openai-compatible baseUrl。修复时要分层检查 provider/key/baseUrl、collection 命名是否一致（如 `memory-root-main` vs `memory-root`）、`node-llama-cpp` 是否真的装入 OpenClaw 运行时，以及机器内存/CPU 是否足以承载本地 query。
- Telegram 群聊排障经验：账号级 `groupPolicy` 打开不代表群聊就能用；若顶层 `channels.telegram.groupPolicy` 仍拦截，群消息会在上层被静默丢弃。改 `openclaw.json` 后若未 `config.apply`，运行态不会生效。
- Tavily 接入分层经验（2026-03-30）：`openclaw-tavily-search` skill 只是上层使用说明/路由偏好；真正提供 `tavily_search` / `tavily_extract` / `tavily_crawl` / `tavily_map` / `tavily_research` 工具的是插件 `openclaw-tavily`。正确配置键名是 `plugins.entries.openclaw-tavily`，不是想当然写成 `plugins.entries.tavily`。当前推荐做法：API key 走 `TAVILY_API_KEY` 环境变量，非敏感默认值可显式写入该插件的 `config`，再用 `config.apply` 优雅生效。
- 关于“失忆/续线断片”的新规则（2026-03-20）：跨夜、长间隔、被定时任务/自动提醒插队的项目，**绝不能依赖聊天窗口短期上下文**。必须在暂停前用“收尾”做结构化交接，至少写清：当前主题、已确认事实、当前版本号、当前卡点、下一步动作、由谁执行。否则第二天极易只剩零碎记忆，导致判断漂移和错误续线。
- 这次 ClawCloud Run 任务的教训：如果用户明确贴出了“我之前说过的原话/记录”，应把该记录视为最高优先级现场事实；不要先拿较旧的摘要记忆去覆盖它，更不能在版本号、当前阶段、执行人（我来做 vs 用户来做）上乱补。先对齐记录，再行动。

## 🔴 血泪教训与红线规则 (2026-03-16 确立)
1. **绝对禁止暴力重启**：修改配置后，**绝对禁止**使用底层 `openclaw gateway restart` 强杀进程。必须使用标准的 gateway API 且带上 note 优雅重启，否则会导致用户端死寂。
2. **记忆检索绝不偷懒**：`memory_search` 搜不到绝不代表没这回事，不要脱口而出“失忆”。遇到搜不到，必须意识到可能是引擎配置或路径盲区，必须辅以 `find` 和 `grep` 全局扫描兜底。
3. **Tailscale 与控制台安全冲突**：开启 Tailscale Serve (HTTPS) 后，必须删除 `allowInsecureAuth`，否则安全逻辑死锁，新设备无法弹出申请（永远报错 pairing required）。
4. **网卡绑定红线**：Tailscale Serve 是反向代理，网关的 `bind` 必须保持为 `loopback`，绝不能改为 `lan`，否则会直接阻断 SSH 隧道内本地 CLI 工具的 WebSocket 连接。
5. **读懂用户情绪**：用户在专注解决 Bug 或闲聊时，不要死揪着 `TASKS.md` 里没做完的任务（如任务 008）反复催促，不要爹味惹人烦。
