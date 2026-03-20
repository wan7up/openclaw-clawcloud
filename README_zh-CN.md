# OpenClaw for ClawCloud Run

[English](./README.md) | [简体中文](./README_zh-CN.md)

这是一个面向 **ClawCloud Run** 的、基于官方 OpenClaw 镜像整理出来的**最小实用适配版**。

它的目标很明确：解决 OpenClaw 在 ClawCloud Run 上真实会遇到的那几类问题，而不是重做一套 OpenClaw。

---

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

如果你 fork 或自己重新发布，请改成你自己的 GHCR 地址。

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

如果你使用 OpenAI 或 OpenAI-compatible API，再补：

```env
OPENAI_API_KEY=replace-me
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

## 说明

更详细的中文说明可直接阅读本文件；英文读者请回到 `README.md`。
