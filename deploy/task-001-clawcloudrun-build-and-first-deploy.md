# 任务 001：ClawCloud Run 适配镜像构建与首次部署流程

> 目标：把当前最小适配版原型真正推进到“可 build、可 push、可第一次实测部署”的阶段。

---

## 1. 镜像构建目标

当前原型目录：

```text
deploy/clawcloudrun-openclaw/
```

建议将其构建为你自己的镜像，例如：

```text
ghcr.io/<yourname>/openclaw-clawcloud:latest
```

或带版本：

```text
ghcr.io/<yourname>/openclaw-clawcloud:v0.1
```

### 当前状态结论（2026-03-20）
- **`v0.1.3` = 第一版成功基线**
- 已验证：WebUI 可打开、webchat 可连接、对话可用
- `v0.1.4` / `v0.1.5` 为后续失败实验版，曾引入回归；文档中不再把它们视为候选基线
- **`v0.1.8` = 当前公开候选发布版**：已整理为面向 GitHub/其他用户复用的 env-driven 版本；仓库首页 README、`.env.example`、中文发布说明、GitHub Release 均已补齐

---

## 2. 推荐镜像仓库

第一选择建议：**GHCR**（GitHub Container Registry）

### 原因
- 你已经有 GitHub 环境
- 和源码/文档放一起方便
- 免费、顺手
- 对这种实验性镜像很合适

### 备选
- Docker Hub

---

## 3. 本地构建命令（第一版）

在工作区执行：

```bash
cd /root/.openclaw/workspace/deploy/clawcloudrun-openclaw

docker build -t ghcr.io/<yourname>/openclaw-clawcloud:latest .
```

如果你想先本地测试一个临时 tag：

```bash
docker build -t openclaw-clawcloud:dev .
```

---

## 4. 推送到 GHCR（示意）

### 登录 GHCR
```bash
echo '<GITHUB_TOKEN>' | docker login ghcr.io -u <your-github-username> --password-stdin
```

### 推送
```bash
docker push ghcr.io/<yourname>/openclaw-clawcloud:latest
```

---

## 5. 第一次本地预跑（强烈建议）

在上 ClawCloud Run 之前，建议先本地 docker 跑一下，先验证原型至少能启动。

### 示例命令
```bash
docker run --rm -it \
  -p 8080:8080 \
  -e OPENCLAW_GATEWAY_TOKEN=test-token-123 \
  -e OPENAI_API_KEY=<your_key> \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -e OPENCLAW_GATEWAY_PORT=18789 \
  -e OPENCLAW_GATEWAY_BIND=loopback \
  -e PORT=8080 \
  -v openclaw-clawcloud-data:/data \
  ghcr.io/<yourname>/openclaw-clawcloud:latest
```

### 本地预跑时重点检查
1. 容器是否直接退出
2. 日志里是否仍有 `EACCES`
3. `/healthz` 是否能返回 200
4. 根页面是否可打开
5. `/data/.openclaw/openclaw.json` 是否生成

---

## 6. 第一次 ClawCloud Run 实测部署流程

### 第一步：准备镜像
先把镜像 push 到 GHCR / Docker Hub。

### 第二步：Create App 填表
按文件：

```text
deploy/task-001-clawcloudrun-create-app-form-v1.md
```

逐项填写。

### 第三步：挂载 Local Storage
挂载到：

```text
/data
```

### 第四步：填写最小 env
至少填：
- `OPENCLAW_GATEWAY_TOKEN`
- `OPENAI_API_KEY`（或你实际使用的 provider key）
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`
- `OPENCLAW_GATEWAY_PORT=18789`
- `PORT=8080`
- `OPENCLAW_GATEWAY_BIND=loopback`

### 第五步：启动并观察
重点看：
- 是否 Running
- 是否 BackOff
- 日志里是否有 `EACCES`
- `/healthz`
- UI 是否打开
- **当前已验证成功基线：`v0.1.3`**。该版本已实测通过：WebUI 可打开、webchat 可连、对话可用。后续实验标签 `v0.1.4` / `v0.1.5` 曾引入回归，不应作为基线参考。
- 如果使用 OpenAI-compatible 中转（`OPENAI_BASE_URL`），不要先凭猜测修改 provider 结构；应先检查 `v0.1.3` 实际生成的 `/data/.openclaw/openclaw.json`，确认当前到底是通过哪条配置路径在工作，再决定是否需要最小增量优化。

---

## 7. 第一次实测的成功标准

只要第一次实测满足以下几点，就说明方向是对的：

- [ ] 不 BackOff
- [ ] `/data/.openclaw/openclaw.json` 成功生成
- [ ] 没有旧的 `/home/node/.openclaw` 权限报错
- [ ] `/healthz` 正常
- [ ] UI 能打开

如果这几条成立，即使 Control UI 认证还需要细调，也已经证明：

> “官方镜像 + 最小适配层” 这条路是走得通的。

---

## 8. 失败时的优先判断

### 情况 A：构建失败
优先检查：
- `Dockerfile` 是否引用了当前官方镜像可用 tag
- nginx 是否安装成功
- entrypoint 路径是否正确

### 情况 B：容器启动失败
优先检查：
- env 是否漏填
- `OPENCLAW_GATEWAY_TOKEN` 是否存在
- 是否至少有一个 provider key

### 情况 C：UI 打不开
优先检查：
- 外部端口是不是 8080
- nginx 配置是否生效
- `/healthz` 是否正常
- **先回到已验证成功基线 `v0.1.3` 做对照**。如果 `v0.1.3` 正常，而新版本异常，则默认视为新补丁引入回归，不要继续猜环境问题。

### 情况 D：UI 打开但 Control UI 连不上
这时再进入下一阶段：
- 继续调 Control UI / origin / device auth 的兼容项
- 但要先保留一条纪律：**不要在没有对照 `v0.1.3` 实际配置落盘结果之前，随意重写 provider / Control UI 相关结构**

---

## 9. 下一步建议

完成本文件后，下一步建议直接做：

### A. 补一份“本地测试清单”
方便在正式推镜像前先本机自测

### B. 记录任务 001 当前状态
把任务状态写进 `TASKS.md` / 当日 memory，说明已经进入“原型 + 首次构建/部署准备”阶段。
