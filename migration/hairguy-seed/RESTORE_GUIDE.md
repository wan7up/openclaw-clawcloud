# RESTORE_GUIDE.md — 如何把头毛佬轻量后代包恢复到 ClawCloud Run

这份文档写给你本人，目标是：

> 一次性说清楚，怎么把 `hairguy-seed-for-clawcloudrun.tar.gz` 放到 ClawCloud Run 那边，并恢复成一个可用的“头毛佬系轻量实例”初始化头脑。

---

## 一、先搞清楚：这不是系统备份恢复

这不是整机恢复，不是把主实例完整搬过去。

你恢复的是：
- 人格
- 经验
- 用户偏好
- 精选任务背景
- 001 相关资料

不是恢复：
- session 历史
- provider 统计
- 本机 cache
- QMD / embedding / 重型检索栈

---

## 二、你手头的文件

当前已经生成好的打包文件：

```text
/root/.openclaw/workspace/migration/hairguy-seed-for-clawcloudrun.tar.gz
```

如果你需要给自己下载、转存、上传，就拿这个文件。

---

## 三、推荐恢复位置

如果你的 ClawCloud Run 实例也是把 workspace 持久化在 `/data/workspace`，那推荐直接恢复到：

```text
/data/workspace
```

原因：
- 这是最直观的 workspace 初始化方式
- 新实例能直接读到这些核心文件
- 不需要再人工搬来搬去

---

## 四、恢复步骤（推荐版）

### 步骤 1：确保新实例已经部署好
先确保新的 ClawCloud Run OpenClaw 自己是能启动的。

至少确认：
- `/data` 已挂载持久化存储
- `/data/workspace` 存在
- OpenClaw 基本能正常启动

### 步骤 2：把压缩包上传到 ClawCloud Run
你可以通过平台的**文件管理**把：

```text
hairguy-seed-for-clawcloudrun.tar.gz
```

上传到例如：

```text
/data/tmp/
```

或其他你方便的临时目录。

### 步骤 3：在终端里解压
进入 ClawCloud Run 提供的 Terminal，执行类似：

```bash
mkdir -p /data/workspace
cd /data/workspace
tar -xzf /data/tmp/hairguy-seed-for-clawcloudrun.tar.gz --strip-components=1
```

#### 解释
- `--strip-components=1` 是因为压缩包顶层目录是 `hairguy-seed/`
- 这样解完后文件会直接落在 `/data/workspace/` 下，而不是多套一层目录

### 步骤 4：确认恢复成功
执行：

```bash
ls -la /data/workspace
```

你应至少看到：

- `SEED.md`
- `SOUL.md`
- `USER.md`
- `IDENTITY.md`
- `MEMORY_LIGHT.md`
- `TASKS_LIGHT.md`
- `BOOT_GUIDE.md`
- `RESTORE_GUIDE.md`

并且还有：

- `docs/task-001/`
- `reference/clawcloudrun-openclaw/`

### 步骤 5：重启服务或新开对话
让它在一个新会话里按这些文件重建自我。

---

## 五、如果你不想直接覆盖 `/data/workspace`

也可以恢复到一个子目录，比如：

```bash
mkdir -p /data/workspace/seed
cd /data/workspace/seed
tar -xzf /data/tmp/hairguy-seed-for-clawcloudrun.tar.gz --strip-components=1
```

这样更安全，不会和已有文件混在一起。

### 这种方式的代价
如果 seed 在子目录里，新实例未必会自动读取。你就需要：
- 手工把其中关键文件再移动到 workspace 根目录
- 或者在第一次对话时明确告诉它去读 `/data/workspace/seed/` 下的文件

所以：
- **想省心：直接解到 `/data/workspace`**
- **想保守：先解到 `/data/workspace/seed` 再人工挑文件**

---

## 六、恢复后第一次该怎么引导它

恢复完成后，建议你第一句话直接说：

> 你是头毛佬系的轻量实例。请按 workspace 里的 `SEED.md`、`SOUL.md`、`USER.md`、`IDENTITY.md`、`MEMORY_LIGHT.md` 建立自我。你运行在 ClawCloud Run 的低性能环境，不要默认使用 QMD 或其他重型记忆方案。

这句话能显著减少它跑偏。

---

## 七、恢复后建议你检查的点

### 1. 它是否知道自己是谁
看它是否能说清：
- 自己是头毛佬系轻量实例
- 不是主实例完整克隆

### 2. 它是否理解用户偏好
看它是否知道：
- 你是 geek / tinkerer
- 对不同主题希望深讲或直给

### 3. 它是否知道性能边界
看它是否会主动避免：
- QMD
- 大索引
- 重 embedding
- 复杂后台任务

### 4. 它是否知道 001 的意义
看它是否知道：
- 001 是第一个真正有难度的试金石任务
- `v0.1.8` 是当前候选发布状态

---

## 八、最稳妥的恢复策略

如果你想把风险降到最低，建议按下面顺序走：

1. 新实例先裸跑成功
2. 再上传 seed 包
3. 先恢复到 `/data/workspace/seed`
4. 看完内容后，再挑核心文件放到 `/data/workspace`
5. 新开一个干净会话，做第一次人格建立

这比一上来全覆盖更稳。

---

## 九、结论

对你来说，最简单的恢复路线就是：

```bash
mkdir -p /data/workspace
cd /data/workspace
tar -xzf /data/tmp/hairguy-seed-for-clawcloudrun.tar.gz --strip-components=1
```

然后新开对话，明确告诉它：
- 你是谁
- 它是谁
- 它是轻量后代实例
- 不要默认启用重型记忆系统

这就够了。
