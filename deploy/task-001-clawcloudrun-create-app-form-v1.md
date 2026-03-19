# 任务 001：ClawCloud Run Create App 表单填写说明（第一版）

> 目标：给 **ClawCloud Run** 的 Create App 页面提供一份可直接对照填写的说明。
> 说明：这是基于当前“最小适配版原型”整理的第一版，重点先保证 **能部署、能启动、能访问**。

---

## 1. 前提

在正式填写表单前，默认你已经有：

1. 一个可部署的自定义镜像（后续将基于 `deploy/clawcloudrun-openclaw/` 目录构建）
2. 一个可用模型 API key（如 OpenAI / OpenRouter / Gemini 等）
3. 一个随机生成的 gateway token
4. 一个 Local Storage 挂载

### 建议先准备

#### Gateway Token
可本地生成一个固定随机值：

```bash
openssl rand -hex 32
```

记成：
- `OPENCLAW_GATEWAY_TOKEN=<生成结果>`

#### 模型 Key
第一版至少准备一个，例如：
- `OPENAI_API_KEY=...`

---

## 2. Create App 推荐填写（第一版）

## 基础信息

### App Name
建议填：

```text
openclaw
```

或：

```text
openclaw-clawcloud
```

### Container Image
这里应填写 **你后续 build/push 的自定义镜像地址**。

示例（占位）：

```text
ghcr.io/<yourname>/openclaw-clawcloud:latest
```

> 第一版不建议长期直接依赖第三方镜像；目标是使用你自己的官方适配版镜像。

---

## 端口

### Public / Exposed Port
填：

```text
8080
```

### 原因
- 外部入口由 nginx 监听 `8080`
- OpenClaw gateway 仍在容器内部使用 `18789`
- 不建议直接把 gateway 裸露给平台

---

## 3. Local Storage

### Mount Path
填：

```text
/data
```

### 原因
第一版方案中，关键目录统一放在 `/data` 下：

```text
/data/.openclaw
/data/workspace
```

这可以绕开官方镜像默认 `/home/node/.openclaw` 的权限问题。

### 注意
- ClawCloud Run 要求至少保留一个 Local Storage
- 这个挂载是必须的，不是可选项

---

## 4. 环境变量（第一版最小集）

## 必填环境变量

### 1) Gateway Token
```text
OPENCLAW_GATEWAY_TOKEN=<你的随机 token>
```

### 2) Provider Key（至少一个）
如果先走 OpenAI：

```text
OPENAI_API_KEY=<你的 key>
```

如果以后改成别的 provider，再换对应环境变量。

### 3) 状态目录
```text
OPENCLAW_STATE_DIR=/data/.openclaw
```

### 4) Workspace 目录
```text
OPENCLAW_WORKSPACE_DIR=/data/workspace
```

### 5) 内部 Gateway 端口
```text
OPENCLAW_GATEWAY_PORT=18789
```

### 6) 外部 HTTP 端口
```text
PORT=8080
```

### 7) Gateway bind
```text
OPENCLAW_GATEWAY_BIND=loopback
```

---

## 可选环境变量

### Basic Auth（建议后续加）
如果你想先给 WebUI 套一层最简单的 HTTP Basic Auth，可以加：

```text
AUTH_USERNAME=admin
AUTH_PASSWORD=<一个强密码>
```

### Allowed Origin（仅在需要时）
如果后续发现 Control UI / origin 校验有问题，再考虑加：

```text
OPENCLAW_ALLOWED_ORIGIN=https://你的公开地址
```

> 这一项先不要乱填。只有在确认是 origin 问题时再加。

---

## 5. 第一版推荐填写总表

| 项目 | 推荐值 |
|---|---|
| App Name | `openclaw` |
| Image | `ghcr.io/<yourname>/openclaw-clawcloud:latest` |
| Public Port | `8080` |
| Local Storage Mount Path | `/data` |
| `OPENCLAW_GATEWAY_TOKEN` | 随机 32-byte hex |
| `OPENAI_API_KEY` | 你的 key |
| `OPENCLAW_STATE_DIR` | `/data/.openclaw` |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` |
| `OPENCLAW_GATEWAY_PORT` | `18789` |
| `PORT` | `8080` |
| `OPENCLAW_GATEWAY_BIND` | `loopback` |
| `AUTH_USERNAME` | `admin`（可选） |
| `AUTH_PASSWORD` | 自定义强密码（可选） |

---

## 6. 首次部署后应该检查什么

部署完成后，按这个顺序检查：

### 1) 容器是否稳定 Running
不要出现持续 BackOff / CrashLoop。

### 2) 健康检查是否正常
访问：

```text
https://你的域名/healthz
```

理想结果：
- 返回 200
- 即使 gateway 仍在启动，也至少不应直接炸掉

### 3) WebUI 是否能打开
访问根路径 `/`，确认页面能正常打开。

### 4) 文件管理里是否生成了配置
看 `/data/.openclaw/openclaw.json` 是否存在。

### 5) 是否仍有权限报错
重点搜日志里有没有：
- `EACCES`
- `permission denied`
- `mkdir '/home/node/.openclaw/...` 类似错误

如果还有，说明仍有路径没迁干净。

---

## 7. 如果失败，优先看哪几类问题

### A. 一启动就 BackOff
优先检查：
- env 是否漏了 `OPENCLAW_GATEWAY_TOKEN`
- 是否至少填了一个 provider key
- 镜像是否构建成功

### B. WebUI 打不开
优先检查：
- Public Port 是否填了 `8080`
- nginx 是否启动
- `/healthz` 是否正常

### C. WebUI 能打开但连接网关失败
优先怀疑：
- websocket 代理
- gateway token 注入
- Control UI / origin / 设备认证兼容问题

### D. 日志出现 `EACCES`
优先怀疑：
- `/data` 写权限
- 仍有目录写到了 `/home/node/.openclaw`

---

## 8. 第一版的保守建议

1. **先不要一上来塞很多 provider / channel 配置**
   - 第一版先只保证 OpenClaw 基座能跑

2. **先不要依赖 WebUI 自升级**
   - 升级策略以后按“换镜像 + 保留 `/data`”处理

3. **先不要过早引入复杂 Control UI 危险兼容项**
   - 只在确认报错模式后再加

---

## 9. 当前阶段结论

这份表单说明的定位是：

> 用于任务 001 的第一轮“最小可行部署”尝试。

如果这轮部署能做到：
- 容器稳定运行
- UI 可访问
- `/data` 成功持久化

那么下一步再继续：
1. 完善 Control UI 兼容配置
2. 固化最终镜像构建方式
3. 输出真正可直接复用的最终部署方案
