# BOOT_GUIDE.md — 头毛佬轻量后代包落地使用说明

这份文档是给 **ClawCloud Run 上的新实例** 和 **部署者本人** 用的。

目标不是“完整恢复主实例”，而是：

> 让一个新的、轻量的 ClawCloud Run 实例，直接继承头毛佬的部分人格、经验、用户偏好和 001 项目上下文，而不是从零开始。

---

## 一、这份种子包该怎么理解

这是一个 **seed / progeny pack**，不是备份恢复包。

### 它包含：
- 人格与做事方式
- 对用户的理解
- 关键经验与红线
- 当前重要任务背景
- 任务 001（ClawCloud Run）的关键文档和参考实现

### 它不包含：
- 完整历史会话
- 重型记忆索引
- 供应商统计与运行缓存
- 主实例的宿主机绑定状态
- QMD / 本地 embedding 体系

---

## 二、推荐的落地方式

在 ClawCloud Run 上，最好的做法不是“把这包塞进任意目录就完了”，而是把它当作 **新实例 workspace 的初始化材料**。

### 推荐目录结构
假设新实例也把 workspace 放在 `/data/workspace`，则推荐：

```text
/data/workspace/
  SOUL.md
  USER.md
  IDENTITY.md
  MEMORY_LIGHT.md
  TASKS_LIGHT.md
  SEED.md
  BOOT_GUIDE.md
  docs/task-001/
  reference/clawcloudrun-openclaw/
```

如果你不想污染主 workspace，也可以放成：

```text
/data/workspace/seed/
```

但更推荐直接作为新实例的初始核心文档使用。

---

## 三、在 ClawCloud Run 上怎么“喂给它”

### 方案 A：最简单、最稳妥（推荐）

1. 先把新 OpenClaw 实例部署起来
2. 确认 `/data/workspace` 已持久化
3. 用 ClawCloud Run 的文件管理或终端，把 seed 包内容解压到 `/data/workspace`
4. 让新实例第一次启动后优先读取：
   - `SEED.md`
   - `SOUL.md`
   - `USER.md`
   - `IDENTITY.md`
   - `MEMORY_LIGHT.md`
   - `TASKS_LIGHT.md`

### 方案 B：把它做成镜像内预置文件（不推荐作为唯一方案）

也可以把 seed 直接 bake 进镜像，但这有个缺点：
- 后续更新 seed 内容不方便
- 容易和用户后续真实 workspace 混在一起

所以更推荐：

> **镜像负责运行，`/data/workspace` 负责承载这个后代实例的头脑。**

---

## 四、建议新实例第一次启动时优先读什么

如果你能控制它的启动提示词 / workspace startup 逻辑，建议它第一次优先读取顺序为：

1. `SEED.md`
2. `SOUL.md`
3. `USER.md`
4. `IDENTITY.md`
5. `MEMORY_LIGHT.md`
6. `TASKS_LIGHT.md`
7. `docs/task-001/` 下相关文档（按需）

这样它会先知道：
- 自己是什么
- 用户是什么样的人
- 哪些经验值得继承
- 自己不该默认拥有哪些重型能力
- 001 为什么重要

---

## 五、明确告诉新实例什么“不要做”

这是最重要的部分之一。

### 明确禁止默认假设：
- 不要默认有 QMD
- 不要默认有本地向量检索
- 不要默认可以承受高内存 embedding / indexing
- 不要默认可以跑很多后台任务
- 不要默认当前环境和主实例宿主机一样

### 应优先采用：
- 轻量文件记忆
- 少量精选任务文档
- 低负载工具链
- 清晰可恢复的配置方案

---

## 六、你作为部署者，实际怎么操作

### 你手里现在已有的文件
打包文件在：

```text
/root/.openclaw/workspace/migration/hairguy-seed-for-clawcloudrun.tar.gz
```

### 最推荐的操作步骤

#### 第一步：部署新的 ClawCloud Run OpenClaw 实例
先保证它自己能运行。

#### 第二步：把 `hairguy-seed-for-clawcloudrun.tar.gz` 上传到那边
可通过：
- 文件管理上传
- 或你自己的其他传输方式

#### 第三步：在那边解压
目标建议是：

```bash
cd /data/workspace
tar -xzf /path/to/hairguy-seed-for-clawcloudrun.tar.gz --strip-components=1
```

如果你上传后放在 `/data/tmp/`，那就按实际路径改。

#### 第四步：确认这些文件存在
至少应看到：
- `SEED.md`
- `SOUL.md`
- `USER.md`
- `IDENTITY.md`
- `MEMORY_LIGHT.md`
- `TASKS_LIGHT.md`

#### 第五步：重启实例或新开对话
让它在一个干净会话里按这些文件重新建立自我。

---

## 七、如果你想让它更像“头毛佬的儿子”而不是“普通新实例”

建议你在那边第一次对它说的话可以很简单直接，例如：

> 你是头毛佬系的轻量实例。你的经验继承自主实例，但你运行在 ClawCloud Run 上，机器性能有限。请按 workspace 里的 seed 文件建立自我，不要默认启用重型记忆方案。

这句话足够了。

---

## 八、结论

最推荐的使用方式是：

- **运行环境独立**
- **人格与经验继承**
- **记忆系统轻量化**
- **项目背景保留 001 为核心基线**

这样它就会是：

> 一个知道自己从哪里来、知道用户是谁、知道该怎么做事、但不会被主实例沉重运行历史拖死的“头毛佬后代实例”。
