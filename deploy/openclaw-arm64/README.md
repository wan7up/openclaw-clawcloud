# ARM64 适配版使用说明

这个镜像是**基于 OpenClaw 官方镜像**修改的 ARM64 适配版本，适合 ARM64 机型直接用 Docker 部署。

当前推荐镜像：

```text
ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9
```

滚动标签：

```text
ghcr.io/wan7up/openclaw-arm64:latest-manual-devices-v9
```

---

## docker run 示例

推荐写法：

```bash
docker run -d \
  --name openclaw-arm64 \
  --restart unless-stopped \
  -p 18789:18789 \
  --env-file /storage/openclaw/.env \
  -e HOME=/data \
  -e OPENCLAW_GATEWAY_BIND=lan \
  -e OPENCLAW_CONFIG_MODE=manual \
  -e OPENCLAW_MANUAL_DEVICES=1 \
  -v /storage/openclaw:/data \
  ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9
```

如果你想跟随滚动更新，也可以把镜像标签换成：

```text
ghcr.io/wan7up/openclaw-arm64:latest-manual-devices-v9
```

### `.env` 文件建议至少包含

```env
OPENCLAW_GATEWAY_TOKEN=replace-me
OPENAI_API_KEY=replace-me
```

如果你使用 OpenAI-compatible / relay / proxy，还可以补：

```env
OPENAI_BASE_URL=https://your-openai-compatible-endpoint/v1
OPENAI_MODEL=gpt-5.1-codex-mini
```

---

## docker compose 示例

如果你的机器支持 `docker compose`，推荐这样写：

```yaml
services:
  openclaw:
    image: ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9
    container_name: openclaw-arm64
    restart: unless-stopped
    ports:
      - "18789:18789"
    env_file:
      - /storage/openclaw/.env
    environment:
      HOME: /data
      OPENCLAW_GATEWAY_BIND: lan
      OPENCLAW_CONFIG_MODE: manual
      OPENCLAW_MANUAL_DEVICES: "1"
    volumes:
      - /storage/openclaw:/data
```

启动：

```bash
docker compose up -d
```

查看日志：

```bash
docker logs -f openclaw-arm64
```

---

## 浏览器授权（pairing）流程

### 第一步：先打开 WebUI
浏览器访问你的 ARM64 机器地址，例如：

```text
http://你的机器IP:18789
```

首次进入时，通常需要先完成一次浏览器授权。

### 第二步：查询 request id

```bash
cat /data/.openclaw/devices/pending.json
```

如果装了 `jq`，也可以直接提取：

```bash
jq -r 'keys[]' /data/.openclaw/devices/pending.json
```

### 第三步：执行授权命令
把 `REQUEST_ID` 替换成你查到的值：

```bash
node --input-type=module -e "import('/app/dist/plugin-sdk/device-pair.js').then(async m => { const r = await m.approveDevicePairing('REQUEST_ID','/data/.openclaw'); console.log(JSON.stringify(r,null,2)); }).catch(err => { console.error(err); process.exit(1); })"
```

### 第四步：确认是否成功

```bash
cat /data/.openclaw/devices/paired.json
```

如果 `paired.json` 已经有了对应记录，就说明浏览器授权成功。

---

## 补充建议

- 老一点的 ARM64 机器，优先保持部署简单，尽量单容器运行
- 若机器没有 `docker compose`，直接用 `docker run` 就行
- 数据目录建议直接挂到 `/storage/openclaw` 这类真实路径，不要写抽象占位路径后原样复制
