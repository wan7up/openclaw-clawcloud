# ClawCloud Run OpenClaw（最小适配版原型）

## 目标
这是一个基于官方 OpenClaw 镜像思路的 **ClawCloud Run 最小适配版原型**，目标是先解决：

1. `/home/node/.openclaw` 权限问题
2. 缺少 SSH 导致的首次配置困难
3. 托管平台对 HTTP / WebSocket / 健康检查的要求

## 当前原型边界
本目录当前只追求 MVP：
- 状态目录改走 `/data/.openclaw`
- workspace 改走 `/data/workspace`
- 通过 env + configure.js 自动生成最小配置
- 使用 nginx 监听外部 `8080` 并反代到内部 gateway `18789`

## 目录文件
- `Dockerfile`：原型镜像定义
- `entrypoint.sh`：启动流程
- `configure.js`：env -> openclaw.json 的最小生成器
- `nginx.conf.template`：最小反代模板

## 当前假设
- ClawCloud Run 提供一个可写的 Local Storage 挂载到 `/data`
- 可以通过文件管理直接查看或修改 `/data/.openclaw/openclaw.json`
- 可以通过 Terminal 做有限命令检查，但不依赖它

## 计划中的部署参数（草案）
- Image: 未来 build 后的自定义镜像
- Port: `8080`
- Local Storage Mount Path: `/data`
- 关键 env:
  - `OPENCLAW_GATEWAY_TOKEN`
  - `OPENAI_API_KEY`（或你实际用的 provider key）
  - `OPENCLAW_STATE_DIR=/data/.openclaw`
  - `OPENCLAW_WORKSPACE_DIR=/data/workspace`
  - `OPENCLAW_GATEWAY_PORT=18789`
  - `PORT=8080`

## 注意
这一版还不是最终可用版，而是“实施原型起点”。
Control UI 认证兼容项将继续保守推进，不会在第一版里直接硬塞大量未知字段。
