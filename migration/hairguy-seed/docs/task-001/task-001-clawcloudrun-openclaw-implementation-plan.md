# 任务 001：ClawCloud Run 部署 OpenClaw 实施计划

基于 `task-001-clawcloudrun-openclaw-design.md`，本文件将任务 001 从“设计阶段”推进到“实施阶段”，明确：
- 应先做什么
- 每一步的目标是什么
- 每一步如何验证
- 哪些点必须保守处理

---

## 1. 实施总目标

产出一个 **基于官方 OpenClaw 镜像的 ClawCloud Run 适配版**，满足：

1. 可以通过 ClawCloud Run 的 **Create App** 成功部署
2. 不依赖 SSH 才能完成首次启动
3. WebUI / Gateway 可正常访问
4. 状态与 workspace 能持久化到 `/data`
5. 后续升级时主要通过“换镜像 + 保持 `/data`”完成
6. 出问题时可通过 **文件管理 + Terminal** 做有限排障

---

## 2. 交付物清单

实施阶段建议最终产出以下文件：

```text
deploy/
  task-001-clawcloudrun-openclaw-design.md
  task-001-clawcloudrun-openclaw-implementation-plan.md
  clawcloudrun-openclaw/
    Dockerfile
    entrypoint.sh
    configure.js
    README.md
    nginx.conf.template        # 如需要
    openclaw.base.json         # 可选：最小 custom config 模板
```

### 每个文件职责
- `Dockerfile`：基于官方镜像加最小适配层
- `entrypoint.sh`：启动前准备目录、跑 configure、启动反代与 gateway
- `configure.js`：把 env / 模板 / persisted config 组合成最终 `openclaw.json`
- `README.md`：写明 ClawCloud Run 表单如何填、部署后如何检查
- `nginx.conf.template`：统一 HTTP / websocket / healthz / token 转发
- `openclaw.base.json`：用于放少量 env 不方便表达的默认结构（可选）

---

## 3. 实施顺序（推荐）

## 第 1 步：定义“最小适配版”边界

### 目标
先明确第一版**只解决最关键阻塞**，不要一上来追求全功能。

### 第一版必须解决
1. 持久化目录迁移到 `/data`
2. Gateway 能稳定启动
3. WebUI 能打开
4. WebSocket 能正常工作
5. 有最小的 env → config 生成能力

### 第一版暂不追求
- 所有 channel 的自动化支持
- 很复杂的插件预装
- 全功能 browser sidecar
- 一次性解决所有 control UI 特殊兼容项

### 验收标准
只要能在 ClawCloud Run 上形成“稳定可访问的 OpenClaw 基座”，第一版就算成功。

---

## 第 2 步：基于官方镜像做最小包装

### 目标
不要重造 OpenClaw，只在官方镜像外层加适配。

### 推荐思路
- `FROM ghcr.io/openclaw/openclaw:latest`
- 安装少量运行所需依赖（如 nginx）
- 复制 `entrypoint.sh` 和 `configure.js`
- 让镜像启动时自动完成：
  1. 创建 `/data/.openclaw` 和 `/data/workspace`
  2. 生成/修补配置
  3. 启动反代
  4. 启动 gateway

### 风险控制
- 不要在第一版里引入大量系统包
- 不要把第三方镜像里与 Linuxbrew / 大量工具链持久化相关的逻辑全搬过来
- 先只保留与 ClawCloud Run 成功运行直接相关的改动

---

## 第 3 步：明确状态目录与 workspace 策略

### 目标
从根上避免 `/home/node/.openclaw` 权限问题。

### 固定策略
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`

### entrypoint 必须做的事
- `mkdir -p /data/.openclaw /data/workspace`
- 明确导出上述环境变量
- 若需要，做轻量权限处理（仅在必要时）

### 验证点
部署后通过文件管理或 Terminal 确认：
- `/data/.openclaw/openclaw.json` 已生成
- `/data/workspace` 存在
- Gateway 启动后不会再报 `canvas` / `cron` 权限错误

---

## 第 4 步：加入最小配置生成器

### 目标
让部署不依赖 SSH 修改 JSON。

### 第一版 configure.js 建议支持的最小字段

#### 基础项
- `OPENCLAW_GATEWAY_TOKEN`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_GATEWAY_BIND`
- `OPENCLAW_STATE_DIR`
- `OPENCLAW_WORKSPACE_DIR`

#### 模型 provider 最小支持
至少先支持：
- `OPENAI_API_KEY`
- 或者用户当前常用的中转 API 相关 baseUrl/key（后续按需要加）

#### Control UI 最小配置
- `gateway.controlUi.enabled`
- `gateway.auth`
- 与 ClawCloud Run 访问兼容所需的最小项（需谨慎验证）

### merge 规则
推荐：
1. 先读模板 JSON（如果有）
2. 再读 persisted config
3. 最后应用 env 覆盖

### 风险控制
- 数组采用 replace
- 不做“看似聪明”的深度自动修复过多逻辑
- 第一版追求可预测性，不追求花哨

---

## 第 5 步：加入反代层（nginx）

### 目标
统一外部入口，适配托管平台 HTTP 模式。

### 第一版应支持
- 外部监听 `8080`
- 内部代理到 `127.0.0.1:18789`
- `/healthz` 返回 200
- WebSocket upgrade
- 可传递 Host / X-Forwarded-* 头
- 可选 `Authorization` 注入（如果需要）

### 第一版可选
- Basic Auth
- 启动中等待页

### 风险控制
- 不要在第一版里引入太复杂的多路由结构
- 先保证主 UI 和 websocket 正常

---

## 第 6 步：处理 Control UI / 认证兼容

### 目标
解决“服务能跑，但 Control UI 连不上”的问题。

### 这里必须保守推进
这一步不能照 GPT 口述硬填字段，必须：
1. 对照当前 OpenClaw 版本文档
2. 结合第三方镜像现象与实测推进

### 实施策略
先把这部分拆成两层：

#### 层 A：最保守配置
- 不乱开危险项
- 先看在 `/data` + nginx + gateway token 下是否已足够可用

#### 层 B：平台兼容放宽项（仅在必要时）
如果仍遇到：
- `device signature expired`
- control UI 死循环
- host/origin 不匹配

再单独引入 ClawCloud 专用兼容配置。

### 验证标准
- UI 不仅能打开，还能真正建立与 gateway 的有效连接
- 刷新页面后不会反复进入认证失败/设备签名异常

---

## 第 7 步：输出 ClawCloud Run Create App 表单版说明

### 目标
把部署步骤收敛成一份“照填即可”的表单说明。

### 应明确写出的字段
- App Name
- Image
- Port
- Local Storage Mount Path
- 环境变量（哪些必填、哪些选填）
- 首次部署后如何检查
- 如果失败先看哪几条日志

### 为什么这一项必须单独成文档
因为 ClawCloud Run 本质上就是表单驱动。文档若不落细节，后续重复试错成本很高。

---

## 第 8 步：定义排障 checklist

### 目标
在无 SSH 场景下，给出可操作的排障顺序。

### 推荐检查顺序
1. 容器是否持续 Running，还是 BackOff
2. `/data/.openclaw/openclaw.json` 是否存在
3. 日志里是否还有 `EACCES`
4. `/healthz` 是否能返回 200
5. UI 是否能打开
6. WebSocket / gateway 是否能成功连接
7. 是否出现 `device signature expired`
8. 若失败，优先改 JSON / env，不优先寄希望于 Terminal 手工大修

---

## 4. 第一版最小环境变量建议

### 必填
- `OPENCLAW_GATEWAY_TOKEN=<固定随机值>`
- 一个可用模型 provider 的 key（例如 `OPENAI_API_KEY` 或你当前要用的中转 key）
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`
- `OPENCLAW_GATEWAY_PORT=18789`
- `PORT=8080`

### 可能需要的兼容项（待实测确认）
- `OPENCLAW_GATEWAY_BIND=loopback`
- 与 control UI / origin / device auth 相关的最小兼容配置

### 注意
不要一开始就把一堆第三方镜像的复杂 env 全抄进来。第一版只要最小可用。

---

## 5. MVP 验证清单

当第一版镜像做好后，必须逐条验证：

- [ ] Create App 能成功部署，不再 BackOff
- [ ] `/data/.openclaw` 成功生成配置和状态文件
- [ ] `/data/workspace` 可写
- [ ] 日志中不再出现 `EACCES: mkdir .../.openclaw/*`
- [ ] `/healthz` 正常
- [ ] WebUI 能访问
- [ ] gateway 连接成功
- [ ] 重启容器后状态不丢失
- [ ] 无需 SSH 就能完成首次部署

如果这 9 条全过，说明任务 001 已从“理论可行”进入“工程可用”。

---

## 6. 实施时不建议做的事

### 不建议 1
一开始就完整复制第三方镜像全部逻辑。

原因：
- 会把很多和 ClawCloud Run 成功部署无关的复杂度一起搬进来
- 后续维护会变重

### 不建议 2
把 WebUI 自升级当成主要升级路径。

原因：
- 托管平台更适合镜像升级
- 版本可控性更高

### 不建议 3
把 Terminal 当 SSH 用。

原因：
- 体验和能力不稳定
- 只能作为有限排障辅助

---

## 7. 下一步建议（紧接本计划）

下一步应开始真正产出实现文件：

1. 先写 `deploy/clawcloudrun-openclaw/README.md`
   - 记录 MVP 的目标、目录布局、部署假设

2. 再写第一版：
   - `Dockerfile`
   - `entrypoint.sh`
   - `configure.js`

3. 然后出第一版 ClawCloud Run 表单示意

这样就能从“纯设计”过渡到“可开始试部署”的阶段。

---

## 8. 当前结论

任务 001 的第一阶段（设计）已经完成；
现在进入第二阶段（实施计划）后，路线已经明确：

> 不是继续猜，而是做一个“官方镜像 + 最小适配层”的 ClawCloud Run 版本，
> 并用 `/data`、反代、启动期配置生成把平台限制收编进去。
