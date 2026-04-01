# ClawCloud Run 适配版使用说明

这个镜像是**基于 OpenClaw 官方镜像**修改的 ClawCloud Run 适配版本。

当前推荐镜像：

```text
ghcr.io/wan7up/openclaw-clawcloud:v2026.3.31
```

滚动标签：

```text
ghcr.io/wan7up/openclaw-clawcloud:latest
```

---

## ClawCloud Run → Create App 页面怎么填

### 1. Image Name
填写：

```text
ghcr.io/wan7up/openclaw-clawcloud:v2026.3.31
```

如果你想跟随滚动更新，也可以填：

```text
ghcr.io/wan7up/openclaw-clawcloud:latest
```

### 2. Port
填写：

```text
8080
```

### 3. Local Storage
添加一个可写的 Local Storage，挂载到：

```text
/data
```

### 4. Environment Variables
建议至少填写下面这些：

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENCLAW_ALLOWED_ORIGIN=https://your-app.us-west-1.clawcloudrun.com
OPENCLAW_STATE_DIR=/data/.openclaw
OPENCLAW_WORKSPACE_DIR=/data/workspace
OPENCLAW_GATEWAY_PORT=18789
PORT=8080
OPENAI_API_KEY=replace-me
```

如果你使用 OpenAI-compatible / relay / proxy，还可以补：

```env
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

### 5. `OPENCLAW_ALLOWED_ORIGIN` 怎么填
这个值必须填写为 **ClawCloud Run 实际分配给你的公网地址 origin**，例如：

```text
https://your-app.us-west-1.clawcloudrun.com
```

不要填：
- `127.0.0.1`
- 容器内地址
- 带路径的 URL

---

## 部署后怎么验证

建议按这个顺序检查：

1. 打开公网地址，确认 WebUI 能打开
2. 首次进入时，浏览器通常会发起授权请求（pairing）
3. 完成一次浏览器授权
4. 发一条简单消息，确认聊天可用
5. 如果复用同一个 `/data` 存储，重部署后再确认历史状态还在

---

## 浏览器授权（pairing）流程

### 第一步：先让浏览器发起请求
打开 WebUI 页面，等它生成新的授权请求。

### 第二步：查询 request id

```bash
cat /data/.openclaw/devices/pending.json
```

如果装了 `jq`，也可以直接拿 key：

```bash
jq -r 'keys[]' /data/.openclaw/devices/pending.json
```

### 第三步：执行授权命令
把 `REQUEST_ID` 替换成你查到的 request id：

```bash
openclaw gateway call device.pair.approve --params '{"requestId":"REQUEST_ID"}'
```

### 第四步：确认是否成功

```bash
cat /data/.openclaw/devices/paired.json
```

如果这里能看到新设备记录，就说明浏览器已经授权成功。
