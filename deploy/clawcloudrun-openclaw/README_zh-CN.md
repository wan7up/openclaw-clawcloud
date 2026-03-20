# OpenClaw for ClawCloud Run

[English](./README.md) | [简体中文](./README_zh-CN.md)

这是一个面向 **ClawCloud Run** 的、基于官方 OpenClaw 镜像整理出来的**最小实用适配版**。

它的目标很明确：解决 OpenClaw 在 ClawCloud Run 上真实会遇到的那几类问题，而不是重做一套 OpenClaw。

---

## 这个镜像解决什么问题

在 ClawCloud Run 上直接部署 OpenClaw，通常会遇到这些现实问题：

- 可写状态目录不能继续放在镜像用户的 home 下
- 首次启动不应该依赖大量 SSH 手工操作
- 平台需要一个正常的 HTTP 入口（通常是 `8080`）
- WebUI + WebSocket 需要被正确代理

这个适配版的思路是：

- 把状态目录迁到 `/data/.openclaw`
- 把 workspace 迁到 `/data/workspace`
- 启动时根据环境变量生成最小 `openclaw.json`
- 用 `nginx` 作为对外的 HTTP / WebSocket 入口
- 把请求代理到内部 OpenClaw gateway（`127.0.0.1:18789`）

目标不是改造 OpenClaw 本体，而是让它能在 ClawCloud Run 上**干净地部署、运行、保留状态并可继续维护**。

---

## 当前状态

### 已验证基线
- `v0.1.3`：第一个确认可工作的基线版本
- `v0.1.4` / `v0.1.5`：后续实验版本，引入过回归，不应视为稳定基线
- `v0.1.8`：当前公开的 **env-driven 候选发布版**，适合作为对外复用参考

### 已验证行为
目前已确认：

- WebUI 可正常打开
- webchat 可正常连接
- 对话可正常工作
- 复用同一个 `/data` 挂载时，状态可持久化

---

## 重要设计原则

这个镜像是为了让其他用户也能复用，所以：

> **不要把部署专属 API 地址、密钥或用户私有默认值硬编码进镜像。**

所有用户相关配置，都应该在部署时通过环境变量注入。

---

## ClawCloud Run 的必要配置

### 1）镜像
使用你发布好的镜像，例如：

```text
ghcr.io/<yourname>/openclaw-clawcloud:v0.1.8
```

### 2）端口
服务端口设置为：

```text
8080
```

### 3）持久化存储
挂载一个可写的 **Local Storage** 到：

```text
/data
```

这是关键配置。

OpenClaw 的状态与工作区会放在：

- `/data/.openclaw`
- `/data/workspace`

只要你**重新部署时继续复用同一个 `/data` 挂载**，状态就应该保留下来。

---

## 环境变量

## 必填 / 强烈建议

| 变量名 | 是否必需 | 说明 |
|---|---:|---|
| `OPENCLAW_GATEWAY_TOKEN` | 是 | WebUI / 客户端连接 gateway 所需 token |
| `OPENCLAW_ALLOWED_ORIGIN` | 是 | **必须填 ClawCloud Run 分配给你的公网 app URL 的 origin**，例如 `https://your-app.us-west-1.clawcloudrun.com` |
| `OPENCLAW_STATE_DIR` | 建议 | 设为 `/data/.openclaw` |
| `OPENCLAW_WORKSPACE_DIR` | 建议 | 设为 `/data/workspace` |
| `OPENCLAW_GATEWAY_PORT` | 建议 | 设为 `18789` |
| `PORT` | 建议 | 设为 `8080` |

### 如果你使用 OpenAI / OpenAI-compatible API

| 变量名 | 是否必需 | 说明 |
|---|---:|---|
| `OPENAI_API_KEY` | 是 | 你的 OpenAI 或 OpenAI-compatible API key |
| `OPENAI_BASE_URL` | 可选 | 如果你走 OpenAI-compatible / relay / proxy，需要填写 |
| `OPENAI_MODEL` | 可选 | 如填写，启动时会把 primary model 设为 `openai/<OPENAI_MODEL>`，并把 provider 模型列表收缩成这一项 |

### 示例

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENCLAW_ALLOWED_ORIGIN=https://your-app.us-west-1.clawcloudrun.com
OPENCLAW_STATE_DIR=/data/.openclaw
OPENCLAW_WORKSPACE_DIR=/data/workspace
OPENCLAW_GATEWAY_PORT=18789
PORT=8080

OPENAI_API_KEY=replace-me
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

---

## 关于 `OPENCLAW_ALLOWED_ORIGIN` 的特别说明

这个变量很容易漏掉，而且非常重要。

它必须填写成 **ClawCloud Run 实际分配给你的公网 origin**，例如：

```text
https://your-app.us-west-1.clawcloudrun.com
```

不要填写：
- `127.0.0.1`
- 容器内部地址
- 随便猜的域名
- 带完整路径的 URL（比如 `/chat`）

它必须只是 **origin**：
- scheme
- host
- 可选端口

不要额外带 path。

---

## 首次部署检查清单

部署完成后，建议按这个顺序检查：

1. 打开 WebUI
2. 发一条简单测试消息
3. 如果你在用 OpenAI-compatible API，检查 `/data/.openclaw/openclaw.json`，确认环境变量是否按预期写入
4. 保留同一个 `/data` 挂载重新部署一次，确认状态仍然存在

---

## 一些已知但不一定阻塞的问题

下面这些在容器环境里可能出现，但**不一定代表部署失败**：

### `openclaw doctor --fix` 可能会报：
- `pairing required`
- `Gateway not running`
- `systemd not installed`

在 ClawCloud Run 里，这些有时只是噪音，因为：
- gateway 本来就是前台在跑
- 容器里没有 systemd 是正常的
- CLI 自检有时拿不到它期待的运行上下文

如果以下条件成立：
- WebUI 能打开
- chat 能用
- 状态能持久化

那这些 doctor 报错通常**不是阻塞问题**。

### Provider badge 可能显示奇怪标签
WebUI 里的 model/provider badge 有时可能显示成例如 `azure` 之类的标签。

如果：
- 实际所选模型是对的
- 自报模型是对的
- 对话能正常工作

那优先把它看成一个**展示层问题**，而不是运行层故障。

---

## Pairing fallback（终端应急方案）

**正常目标**：正确部署后，不应依赖终端手工配对。

但在早期验证阶段（例如 `v0.1.3` 附近），确实出现过某些 ClawCloud Run 会话需要在容器终端里做一次手工批准，才能把 WebUI 配对卡死的状态解开。

所以如果 WebUI pairing 卡住，可以把下面步骤当作 **fallback workaround**，而不是标准流程。

### 第 1 步：刷新 WebUI，生成新的 pending request
刷新一次 WebUI，然后立刻执行：

```bash
cat /data/.openclaw/devices/pending.json
```

应该能看到新的 `requestId`。

### 第 2 步：手工批准这个 requestId
把下面的 `NEW_ID` 替换成你刚看到的 request ID：

```bash
node --input-type=module -e "import('/app/dist/plugin-sdk/device-pair.js').then(async m => { const r = await m.approveDevicePairing('NEW_ID','/data/.openclaw'); console.log(JSON.stringify(r,null,2)); }).catch(err => { console.error(err); process.exit(1); })"
```

### 第 3 步：确认它进入 `paired.json`

```bash
cat /data/.openclaw/devices/paired.json
```

如果批准成功，`paired.json` 就不应该还是空的。

### 重要说明
如果你发现每次新部署都要靠这个 workaround 才能进，先重新检查：

- `OPENCLAW_ALLOWED_ORIGIN`
- 它是否**精确等于**当前 ClawCloud Run 的公网 origin
- 你是否复用了旧的 `/data`，带入了历史状态

---

## 本目录里有哪些文件

- `Dockerfile` — 镜像定义
- `entrypoint.sh` — 启动流程
- `configure.cjs` — env → `openclaw.json` 的最小生成器
- `nginx.conf.template` — 反向代理配置
- `.env.example` — ClawCloud Run 部署示例环境变量

---

## 为什么用 `configure.cjs` 而不是 `configure.js`

官方镜像在 `/app` 下运行于 ESM 环境。

因此这里采用：

- `configure.cjs`
- `/app/...`

这样可以避开 CommonJS / ESM 的兼容问题。

---

## 项目定位

这个适配版不是第三方平台特化魔改，也不是为了把 OpenClaw 改得面目全非。

它的定位很简单：

> 用尽量小的一层适配，把官方 OpenClaw 稳定带到 ClawCloud Run 上。

如果未来官方镜像或官方部署方式原生支持这类平台，那么这层适配的意义就应该逐步下降。

在那之前，这份原型的价值，就是帮你绕过真实世界里那些部署坑。
