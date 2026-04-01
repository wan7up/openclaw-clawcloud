# v0.1.8 发布说明（中文）

## v0.1.8：ClawCloud Run 通用公开候选版

这是当前面向 **ClawCloud Run** 的 OpenClaw 适配版公开候选版本。

这一版的目标不是继续增加定制逻辑，而是把前面已经验证可用的方案，整理成一个**适合公开复用**的版本。

---

### 这个版本解决了什么

相较于官方镜像，这个适配版主要处理了 ClawCloud Run 场景下的几个实际问题：

- 将 OpenClaw 状态目录放到可持久化的 `/data/.openclaw`
- 将 workspace 放到 `/data/workspace`
- 通过 `nginx` 暴露外部 `8080` 端口，并反代到内部 gateway
- 启动时根据环境变量生成最小 `openclaw.json`
- 避免依赖 SSH 或复杂手工初始化步骤

---

### v0.1.8 的重点改动

- 去掉了测试阶段写死在镜像里的默认值
- 改为 **ENV 驱动**，方便其他用户复用
- 补充了更完整的 README
- 新增 `.env.example`
- 明确说明了 `OPENCLAW_ALLOWED_ORIGIN` 的填写方式
- 补充了 WebUI pairing 卡住时的 terminal 兜底方法

---

### 部署时需要注意

#### 1. 必须挂载持久化目录
请在 ClawCloud Run 中将 **Local Storage** 挂载到：

```text
/data
```

OpenClaw 的关键状态会写到：

- `/data/.openclaw`
- `/data/workspace`

如果更新镜像时继续使用同一个 `/data` 挂载，记录和状态通常会保留。

#### 2. `OPENCLAW_ALLOWED_ORIGIN` 必须填写正确
这个值必须填写为 **ClawCloud Run 分配给你的实际公网域名 origin**，例如：

```text
https://your-app.us-west-1.clawcloudrun.com
```

注意：
- 不要填 `127.0.0.1`
- 不要填容器内部地址
- 不要带路径
- 必须是完整 origin（协议 + 域名）

#### 3. 用户自己的 API 参数请通过 ENV 注入
这一版开始，不再在镜像中写死：
- `OPENAI_BASE_URL`
- `OPENAI_API_KEY`
- 用户自己的测试模型

如果你使用 OpenAI-compatible / relay / proxy，请自行配置：
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_MODEL`（可选）

---

### 当前已验证情况

已验证通过：

- WebUI 可打开
- webchat 可连接
- 对话可正常使用
- 同一 `/data` 挂载下，重部署后状态仍保留

---

### 已知现象（当前不阻塞）

#### 1. 容器内运行 `openclaw doctor --fix` 可能出现以下提示
- `pairing required`
- `Gateway not running`
- `systemd not installed`

在 ClawCloud Run 容器场景下，这些很多时候只是自检噪音。
如果以下功能都正常：

- WebUI 能打开
- 能聊天
- 状态能持久化

那么这些提示通常不构成阻塞问题。

#### 2. WebUI 模型/provider badge 可能显示成 `azure`
当前测试中发现，WebUI 列表或 badge 有时会显示成 `azure` 之类的标签。
如果实际模型选择正确、聊天正常、模型自报正常，可暂时视为展示层问题。

---

### pairing 兜底方法（仅在异常时使用）
正常目标是不需要进入 terminal 手动 pairing。

但如果 WebUI pairing 卡住，可以按 README 中记录的兜底方法操作：

1. 刷新 WebUI，生成新的 pending request
2. 在 terminal 中查看 `/data/.openclaw/devices/pending.json`，拿到 request id 后执行 `openclaw gateway call device.pair.approve --params '{"requestId":"REQUEST_ID"}'`
3. 手动批准对应 requestId
4. 检查 `/data/.openclaw/devices/paired.json`

这属于异常场景下的 workaround，不应作为正常前置步骤。

---

### 版本说明
- `v0.1.3`：第一版确认可用的基线版本
- `v0.1.4` / `v0.1.5`：中间实验版本，曾引入回归，不建议使用
- `v0.1.8`：当前适合公开复用的 ENV 驱动候选版

---

### 参考文件
详见：

- `deploy/clawcloudrun-openclaw/README.md`
- `deploy/clawcloudrun-openclaw/.env.example`
