# OpenClaw 备份与恢复说明

## 当前备份目录

### 1) 日常迁移备份
- 本地目录：`/root/backups/openclaw-migration/`
- 远端目录：`ocbackup:/openclaw-migration/`
- 脚本：`/root/.openclaw/workspace/backup/backup-openclaw-migration.sh`
- 内容：面向迁移所需的关键配置、workspace、扩展、cron、telegram 状态、systemd override，以及部分 docker 目录。

### 2) 回滚快照
- 本地目录：`/root/backups/openclaw/`
- 脚本：`/root/.openclaw/workspace/backup/backup-openclaw-snapshot.sh`
- 内容：整份 `~/.openclaw` 的回滚快照，主要用于变更前临时兜底。

---

## 如何手动执行备份

### 日常迁移备份（本地 + 上传到 OpenList）
```bash
bash /root/.openclaw/workspace/backup/backup-openclaw-migration.sh
```

执行后会生成：
- `openclaw-migration-YYYY-MM-DD-HHMMSS.tar.gz`
- `openclaw-migration-YYYY-MM-DD-HHMMSS.sha256`

### 仅本地回滚快照
```bash
bash /root/.openclaw/workspace/backup/backup-openclaw-snapshot.sh
```

---

## 如何验证备份

假设最新文件是：
- `/root/backups/openclaw-migration/openclaw-migration-2026-03-19-184650.tar.gz`
- `/root/backups/openclaw-migration/openclaw-migration-2026-03-19-184650.sha256`

验证命令：
```bash
sha256sum -c /root/backups/openclaw-migration/openclaw-migration-2026-03-19-184650.sha256
```

若输出 `OK`，说明本地归档校验通过。

查看远端文件：
```bash
rclone lsf ocbackup:openclaw-migration/
```

---

## 新服务器恢复流程

## 步骤 1：准备基础环境
在新服务器上先安装：
- OpenClaw
- rclone（如果要从 OpenList 拉取）
- tar / sha256sum

## 步骤 2：取回备份文件
如果远端已有备份：
```bash
mkdir -p /root/restore/openclaw-migration
rclone copy ocbackup:openclaw-migration/ /root/restore/openclaw-migration/
```

## 步骤 3：校验文件
```bash
cd /root/restore/openclaw-migration
sha256sum -c openclaw-migration-YYYY-MM-DD-HHMMSS.sha256
```

## 步骤 4：解包到根目录
**注意：会恢复到 `/root/...` 的原始路径结构。**

```bash
cd /
tar xzf /root/restore/openclaw-migration/openclaw-migration-YYYY-MM-DD-HHMMSS.tar.gz
```

## 步骤 5：检查关键文件
重点检查：
- `/root/.openclaw/openclaw.json`
- `/root/.openclaw/workspace/`
- `/root/.openclaw/extensions/`
- `/root/.openclaw/cron/`
- `/root/.openclaw/telegram/`
- `/root/.config/systemd/user/openclaw-gateway.service.d/override.conf`

## 步骤 6：健康检查与启动
```bash
openclaw doctor --non-interactive
openclaw gateway status
```

如果服务未启动，再按当前环境的标准方式启动/安装网关。

---

## 重要提醒

1. 迁移备份默认**不包含**：
   - `.local-qmd`
   - 浏览器缓存、日志、媒体缓存
   - `agents/*/sessions`
   - `agents/*/qmd`

2. 这是有意为之：
   - 减少体积
   - 避免把大量缓存/临时文件也带走
   - 优先保住“能恢复系统运行”的关键状态

3. 若以后想做“全量冷备份”，应额外保留整份 `~/.openclaw` 原样归档。

---

## 当前自动化策略

- `04:00`：运行日常迁移备份脚本，并上传到 OpenList
- 本地保留最近 2 份迁移备份
- 远端当前为追加保留（如需我再加远端清理策略，可以继续补）
