# OpenClaw for ClawCloud Run

[English](./README.md) | [简体中文](./README_zh-CN.md)

有在用 ClawCloud Run 的朋友，可能都发现了：直接部署 OpenClaw，经常会踩到各种坑。为了让龙虾能在 ClawCloud Run 上顺利跑起来，我专门整理了这个适配版本。

This repository provides a practical adaptation of **OpenClaw** for **ClawCloud Run**, focused on solving the deployment issues people commonly hit in this environment.

## 这个仓库解决什么问题

相比直接使用官方镜像，这个适配版主要处理了以下几个现实问题：

- 将 OpenClaw 状态放到可持久化的 `/data/.openclaw`
- 将 workspace 放到 `/data/workspace`
- 用 `nginx` 暴露外部 `8080` 入口，并转发到内部 gateway
- 启动时根据环境变量生成最小可用配置
- 尽量减少首次部署时对 terminal / 手工操作的依赖

## 当前状态

- `v0.1.3`：第一版确认可用的基线版本
- `v0.1.8`：当前适合公开复用的 ENV 驱动候选版
- 已验证：
  - WebUI 可打开
  - webchat 可连接
  - 对话可正常使用
  - 同一 `/data` 挂载下，重部署后状态仍保留

## 快速开始

在 ClawCloud Run 部署时，至少要注意这几件事：

1. 将 **Local Storage** 挂载到 `/data`
2. 服务端口使用 `8080`
3. 正确填写 `OPENCLAW_ALLOWED_ORIGIN`
4. 通过 ENV 提供你自己的 API 参数（如 `OPENAI_API_KEY` / `OPENAI_BASE_URL`）

## ClawCloud Run 部署步骤（Create App）

下面这套可以直接对应到 **ClawCloud Run → Create App** 页面：

### 1. Image Name
填写你要部署的镜像，例如：

```text
ghcr.io/wan7up/openclaw-clawcloud:v0.1.8
```

如果你 fork 或自己重新发布，请改成你自己的 GHCR 地址，例如：

```text
ghcr.io/<yourname>/openclaw-clawcloud:v0.1.8
```

### 2. Port
填写：

```text
8080
```

### 3. Local Storage
添加一个可写的 **Local Storage**，挂载路径填写：

```text
/data
```

### 4. Environment Variables
至少建议填写这些：

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENCLAW_ALLOWED_ORIGIN=https://your-app.us-west-1.clawcloudrun.com
OPENCLAW_STATE_DIR=/data/.openclaw
OPENCLAW_WORKSPACE_DIR=/data/workspace
OPENCLAW_GATEWAY_PORT=18789
PORT=8080
```

如果你使用 OpenAI 或 OpenAI-compatible：

```env
OPENAI_API_KEY=replace-me
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

> 如果你填写了 `OPENAI_BASE_URL`，也建议同时填写 `OPENAI_MODEL`。否则某些版本下可能出现配置校验失败。

### 5. 部署完成后验证
部署完成后建议立刻做这几步：

1. 打开 ClawCloud Run 分配给你的公网地址
2. 确认 WebUI 可以正常打开
3. **首次部署 / 新环境第一次进入时，通常需要先完成 pairing；这是正常初始化流程，不代表部署失败**
4. 发一句简单消息，确认聊天可用
5. 如果你用了持久化存储，重部署后再确认记录是否还在

### `OPENCLAW_ALLOWED_ORIGIN` 很重要
这个值必须填写为 **ClawCloud Run 分配给你的实际公网域名 origin**，例如：

```text
https://your-app.us-west-1.clawcloudrun.com
```

不要填：
- `127.0.0.1`
- 容器内部地址
- 带路径的 URL

## 文档

详细部署说明请看：

- [deploy/clawcloudrun-openclaw/README.md](deploy/clawcloudrun-openclaw/README.md)
- [deploy/clawcloudrun-openclaw/.env.example](deploy/clawcloudrun-openclaw/.env.example)
- [deploy/clawcloudrun-openclaw/RELEASE_NOTES_zh-CN.md](deploy/clawcloudrun-openclaw/RELEASE_NOTES_zh-CN.md)

## 说明

这个仓库的目标是做一个**适合 ClawCloud Run 场景的最小适配版**，而不是重写 OpenClaw 本体。

因此，这里的改动会尽量保持克制：
- 优先解决部署问题
- 优先保证 WebUI / chat / 持久化可用
- 避免把用户自己的 API 默认值硬编码进镜像

如果你只是想快速部署并跑起来，这个仓库就是为这个目的准备的。
