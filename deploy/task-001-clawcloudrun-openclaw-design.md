# 任务 001：ClawCloud Run 部署 OpenClaw 设计稿

## 1. 背景与目标

目标是在 **ClawCloud Run** 这种“托管式 Docker App 平台”上，构建一个 **可长期维护** 的 OpenClaw 部署方案。

### 已知平台特征
- 通过 **Create App** 表单式部署 Docker 镜像
- 提供 **Local Storage** 挂载
- 提供 **文件管理**（可直接修改配置文件）
- 提供 **Terminal**（但体验/能力不如 SSH，不能完全依赖）
- **不提供标准 SSH**
- 有每月约 **5 美元免费额度**，适合作为低成本实验性部署平台

### 部署目标
1. OpenClaw 能稳定启动
2. WebUI / Gateway 可以正常访问
3. 关键数据可持久化
4. 配置尽可能自动生成，不依赖 SSH 手工修复
5. 未来支持升级与维护
6. 出问题时可通过 **文件管理 + Terminal** 做有限补救

---

## 2. 已知问题与真实约束

### 2.1 官方镜像在 ClawCloud Run 上的主要失败点
用户实测日志中出现过：
- `EACCES: permission denied, mkdir '/home/node/.openclaw/canvas'`
- `EACCES: permission denied, mkdir '/home/node/.openclaw/cron'`

这说明：
- 官方镜像默认依赖的状态目录 `/home/node/.openclaw` 在该平台挂载模型下存在写权限问题
- 问题核心不是 OpenClaw 本体功能异常，而是 **容器运行用户 + 挂载卷权限模型** 不匹配

### 2.2 Control UI / 网关连接兼容问题
用户实测第三方镜像可运行，但曾遇到：
- `device signature expired`

这说明：
- 在 ClawCloud Run 的公开访问/反代/域名环境下，OpenClaw 默认的控制台认证模型与平台访问方式存在冲突
- 这不是“服务没起来”，而是“服务起来后 WebUI / Control UI 安全校验不兼容当前环境”

### 2.3 没有 SSH，但并非完全不可操作
ClawCloud Run 约束不是“完全不可维护”，而是：
- 无标准 SSH
- 但有文件管理，可直接修改 `openclaw.json`
- 也有 Terminal，可执行部分命令

因此设计上不能假设用户能随意进入机器做系统级排障，但也不必把平台当成完全只读的黑盒。

---

## 3. 设计原则

### 原则 A：不要把方案建立在“手工进容器修”之上
手工修配置、手动 doctor、手动 chown 只能当补救手段，不能当主流程。

### 原则 B：不要继续依赖 `/home/node/.openclaw`
状态目录必须显式迁移到平台挂载目录，例如 `/data/.openclaw`。

### 原则 C：平台外部入口与内部 Gateway 应解耦
建议使用前置反代（如 nginx）暴露外部 HTTP 端口，而不是直接把 Gateway 裸露给平台。

### 原则 D：尽量保持“官方镜像 + 最小适配层”
长期目标不是依赖第三方镜像，而是做一个：
- 基于官方版本
- 只加入 ClawCloud Run 所需最小改动
- 便于以后升级/回归官方

### 原则 E：文件管理能力必须纳入设计
既然平台能直接改文件，那么方案要允许：
- 启动期自动生成配置
- 之后用户仍能通过文件管理微调 `openclaw.json`

---

## 4. 推荐架构

## 4.1 双层架构

### 外层：nginx / 反代入口
职责：
- 对外监听平台要求的 HTTP 端口（建议 8080）
- 反代到内部 OpenClaw Gateway
- 处理 WebSocket upgrade
- 注入/转发必要认证头
- 提供 `/healthz`
- 可选 basic auth
- 在 Gateway 启动期间返回友好启动页

### 内层：OpenClaw Gateway
职责：
- 真正运行 OpenClaw
- 监听内部端口（建议 18789）
- 只暴露给本容器/本 Pod 内部
- 状态目录与 workspace 显式走 `/data`

---

## 4.2 推荐目录布局
统一使用挂载卷 `/data`：

```text
/data/
  .openclaw/      # 状态目录
  workspace/      # 用户工作区
  config/         # 可选 custom config 模板
  backups/        # 可选，后续如需本地快照可放这里
```

### 推荐环境变量
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`
- `OPENCLAW_GATEWAY_PORT=18789`
- 对外 `PORT=8080`

这样可避免继续依赖 `/home/node/.openclaw`，从根上绕开之前的权限报错路径。

---

## 5. 配置生成策略

由于平台缺少 SSH，不适合靠 CLI 大量人工修配置，因此推荐保留一个 **env → openclaw.json** 的启动期配置层。

### 5.1 推荐优先级
配置来源建议采用 3 层：

1. **custom config 模板**（可选）
2. **持久化已有 config**（保留运行时状态）
3. **环境变量覆盖**（最后生效）

### 5.2 关键要求
- 数组字段使用 **replace**，避免残留/幽灵配置
- 启动脚本不得粗暴覆盖所有用户手改内容
- 允许用户通过文件管理直接改 `openclaw.json`
- 环境变量用于最常见的部署项，复杂项可通过 JSON 处理

### 5.3 结论
ClawCloud Run 场景里，“自动生成配置”不是锦上添花，而是主流程必需。

---

## 6. Control UI / 认证兼容的设计思路

这是当前最需要谨慎验证的部分。

### 已知现象
- 在第三方镜像上，某些更宽松的控制台认证配置似乎能让 WebUI 连接成功
- 但这些配置不一定是 OpenClaw 当前版本的稳定长期推荐方案
- 某些字段在其他环境（例如 Tailscale HTTPS）甚至可能是反效果

### 当前设计立场
1. 把这类设置视为 **ClawCloud Run 专用兼容项**
2. 不把它当成 OpenClaw 的全局最佳实践
3. 最终值必须以 **当前版本文档 + 实测** 为准，而不能直接照抄 GPT 口述

### 后续必须验证的点
- 当前版本实际支持哪些 `gateway.controlUi` 字段
- 在反代场景下最小必要兼容项是什么
- 是否真的需要放宽 device auth
- 是否仅靠 `allowedOrigins` / host header 相关配置即可解决

---

## 7. 为什么第三方镜像能跑：已确认的有效线索

对 `coollabsio/openclaw` 调研后，已确认它至少做了这些适配：

1. **状态目录迁移到 `/data/.openclaw`**
2. **workspace 迁移到 `/data/workspace`**
3. **通过 configure.js 启动期生成/更新 `openclaw.json`**
4. **前置 nginx，将外部 8080 代理到内部 18789**
5. **处理 websocket / token / healthz / basic auth / 启动页**
6. **在 control UI 上启用更偏 PaaS 场景的兼容配置**

这些改动说明：
- 第三方镜像之所以可用，不是“魔法”，而是实打实增加了一层平台适配
- 因此长期正确路线是：**吸收其必要改动，但做成你自己的官方适配版**

---

## 8. 长期维护与升级策略

### 不推荐的路线
- 在 WebUI 内依赖“自动升级”
- 长期依赖第三方镜像作者更新节奏
- 每次靠文件管理手工改配置救火

### 推荐路线
- 自己维护一个基于官方 OpenClaw 的 ClawCloud Run 适配镜像
- 升级流程以“换镜像 + 保留 `/data` 持久化目录”为核心

### 标准升级流程（目标）
1. 备份 `/data/.openclaw` 与 `/data/workspace`
2. 更新镜像版本
3. 重启容器
4. 检查 WebUI / Gateway / channels / config
5. 如有不兼容，再通过文件管理或 Terminal 做小幅修正

---

## 9. 高风险点清单（必须防漏）

### 风险 1：`/data` 也未必天然可写
虽然比 `/home/node/.openclaw` 更合理，但仍需验证：
- 挂载后运行用户是否真有写权限
- 是否需要入口脚本主动 `mkdir -p`
- 是否需要启动期轻量权限修复

### 风险 2：WebSocket 代理不完整
如果反代没正确处理 Upgrade / Connection，UI 可能“看起来能打开，但实际不可用”。

### 风险 3：健康检查机制与 Gateway 启动速度不匹配
如果平台要求很快返回 200，而 OpenClaw 启动较慢，可能出现反复重启。需要健康检查友好页/占位逻辑。

### 风险 4：Control UI 认证兼容项误配
这类字段一旦误配，可能造成：
- 连接不上
- 认证循环
- 某些环境可用、某些环境彻底失效

### 风险 5：缺少 SSH 导致诊断手段受限
所以设计必须尽量“自说明”“自愈化”，而不是依赖复杂现场排障。

### 风险 6：未来 OpenClaw 版本配置结构变动
适配层必须尽量薄，否则每次上游更新都会带来高维护成本。

---

## 10. 最小可行方案（MVP）定义

要判定任务 001 的第一阶段成功，最低标准应是：

1. Create App 部署后容器可持续运行，不 BackOff
2. `/data/.openclaw` 与 `/data/workspace` 成功持久化
3. WebUI 可正常打开
4. Gateway 可以建立有效连接
5. 重启后配置与状态不丢失
6. 无需 SSH 即可完成首次部署

满足以上后，再进入：
- 认证兼容优化
- 自定义配置增强
- 升级流程固化

---

## 11. 当前结论

### 结论 1
任务 001 的本质不是“单纯部署 OpenClaw”，而是：
**把 OpenClaw 适配到一个低权限、低成本、托管式 Docker 平台。**

### 结论 2
第三方镜像已证明这条路可行，问题不在“是否能跑”，而在“如何变成你自己的可维护版本”。

### 结论 3
当前最合理路线是：
- 基于官方镜像
- 保留 `/data` 状态目录策略
- 保留启动期配置生成层
- 保留前置反代层
- 谨慎验证 Control UI 兼容项

---

## 12. 后续实施建议

### 下一步（建议立即执行）
进入“实施设计”阶段，产出：
1. `deploy/task-001-clawcloudrun-openclaw-implementation-plan.md`
2. 一个最小适配版目录，例如：
   - `deploy/clawcloudrun-openclaw/Dockerfile`
   - `deploy/clawcloudrun-openclaw/entrypoint.sh`
   - `deploy/clawcloudrun-openclaw/configure.js`
   - `deploy/clawcloudrun-openclaw/README.md`
3. 一份最终可直接照填的 ClawCloud Run Create App 表单说明

### 实施时优先级
1. 先让官方适配版能稳定启动
2. 再验证 UI / Gateway
3. 最后才做升级与精细化优化
