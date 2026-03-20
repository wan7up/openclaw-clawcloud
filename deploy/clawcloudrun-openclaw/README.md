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
- 通过 env + `configure.cjs` 自动生成最小配置
- 使用 nginx 监听外部 `8080` 并反代到内部 gateway `18789`

## 当前已验证基线
- **`v0.1.3` 是目前第一版成功基线**
- 已实测通过：WebUI 可打开、webchat 可连接、对话可用
- 后续实验标签 **`v0.1.4` / `v0.1.5` 曾引入回归**，目前应视为失败实验版，不应作为部署基线参考

## 当前设计原则
- 优先保住 `v0.1.3` 已验证通过的启动链路
- 不为了“看起来更完整”而随意重写模型 provider 结构
- 后续若要优化自定义 API / provider 配置，必须先审计 `v0.1.3` 实际生成的 `openclaw.json`，再做最小增量修改

## 目录文件
- `Dockerfile`：原型镜像定义
- `entrypoint.sh`：启动流程
- `configure.cjs`：env -> openclaw.json 的最小生成器
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
这一版虽然仍是原型，但 `v0.1.3` 已经证明这条适配路线是可行的；后续工作重点不是推翻重来，而是**基于成功基线做保守收敛**。

当前明确结论：
- `configure.cjs` 是必要修复（官方镜像为 ESM 环境，不能继续用 CommonJS 风格的 `configure.js`）
- 启动路径应基于官方镜像的真实工作目录 `/app`，而不是错误的 `/opt/openclaw/app`
- nginx 反代层在 ClawCloud Run 场景下仍然有必要

Control UI / provider / 自定义 API URL 相关优化，后续必须先做现状审计，再做最小变更，避免再次引入像 `v0.1.4` / `v0.1.5` 那样的回归。
