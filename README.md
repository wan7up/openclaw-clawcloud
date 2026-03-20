# OpenClaw for ClawCloud Run

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
