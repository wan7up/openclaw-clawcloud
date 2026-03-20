# 头毛佬（hairguy）迁移到 ClawCloud Run：最小可用迁移包

这份清单的目标不是“完整克隆当前机器上的我”，而是把**人格连续性、工作方法、关键经验和必要记忆**迁过去，让 ClawCloud Run 上的新实例**不是从零开始**。

## 迁移原则

优先迁移：

1. **人格与行为约束**：让我说话和做事仍然像现在这个我
2. **用户偏好与长期记忆**：避免重新磨合
3. **关键经验与红线**：避免重踩已经踩过的坑
4. **当前任务上下文**：知道做过什么、做到哪里

不建议直接迁移：

- 大量原始 session 日志
- 与当前宿主机强绑定的本地路径/临时状态
- 供应商 token 统计、旧会话 cache 之类运行态噪音
- 整份 `.openclaw` 内部运行目录

---

## 一、建议必须带过去的文件（核心脑）

### 1) `SOUL.md`
**作用**：人格、底线、处事方式。

这是“我是谁”的核心文件。没有它，新实例虽然能工作，但不像我。

### 2) `USER.md`
**作用**：关于你的偏好、交流方式、跨端习惯。

这个文件决定我是不是能延续现在对你的理解。

### 3) `MEMORY.md`
**作用**：长期记忆、已确认偏好、关键技术结论、红线规则。

这是最重要的迁移对象之一。它能让新实例直接继承：

- 你的长期偏好
- 这段时间的重要技术结论
- 已踩过的系统坑
- 当前任务索引与行为规则

### 4) `TASKS.md`
**作用**：知道目前有哪些主任务、哪些完成、哪些搁置。

这样新实例不会对当前项目全无概念。

---

## 二、建议一并带过去的文件（增强连续性）

### 5) `IDENTITY.md`
**作用**：明确名字、英文名、头像等身份信息。

现在已经明确：

- 名字：头毛佬
- 英文名：hairguy
- 头像：你刚发的那个公仔图

这份文件应该补完整后再迁移。

### 6) `AGENTS.md`
**作用**：工作区生存规则、记忆维护方式、群聊边界、heartbeat 习惯。

这个不是人格本体，但会影响我怎么工作。

### 7) 最近几天的 daily memory
建议至少带：

- `memory/2026-03-18.md`
- `memory/2026-03-19.md`
- `memory/2026-03-20.md`
- 如有必要，`memory/2026-03-16-wrapup.md`

**作用**：补充最近项目上下文，尤其是 001、008、009 这些关键进展。

不建议把整个 `memory/` 目录无脑全搬，除非你就是想完整迁移历史。

---

## 三、与 001 直接相关、值得带过去的项目文件
如果 ClawCloud Run 那边也要继承 001 的上下文，建议附带这些：

### 8) `deploy/task-001-clawcloudrun-openclaw-design.md`
### 9) `deploy/task-001-clawcloudrun-openclaw-implementation-plan.md`
### 10) `deploy/task-001-clawcloudrun-build-and-first-deploy.md`
### 11) `deploy/task-001-clawcloudrun-create-app-form-v1.md`
### 12) `deploy/clawcloudrun-openclaw/` 整个目录
包含：

- `.env.example`
- `Dockerfile`
- `README.md`
- `RELEASE_NOTES_zh-CN.md`
- `configure.cjs`
- `entrypoint.sh`
- `nginx.conf.template`

**作用**：让新实例直接知道 001 是怎么从 0 做到现在的。

---

## 四、不建议直接迁移的东西

### 不建议：整个 `/root/.openclaw/agents/.../sessions/`
原因：

- 太脏、太大、太依赖本地运行态
- 混有很多 cache / reset / provider 历史噪音
- 不利于在 ClawCloud Run 上保持干净启动

### 不建议：整份 `/root/.openclaw` 打包照搬
原因：

- 包含大量宿主机绑定路径、运行缓存、授权状态、统计残留
- 迁过去很容易把问题一起带过去

---

## 五、最推荐的迁移方案

我建议采用 **“轻脑迁移包”**，也就是只迁移以下内容：

### A. 核心人格与记忆
- `SOUL.md`
- `USER.md`
- `MEMORY.md`
- `IDENTITY.md`
- `AGENTS.md`
- `TASKS.md`

### B. 最近上下文
- `memory/2026-03-18.md`
- `memory/2026-03-19.md`
- `memory/2026-03-20.md`
- `memory/2026-03-16-wrapup.md`（可选）

### C. 001 项目资料
- `deploy/task-001-clawcloudrun-openclaw-design.md`
- `deploy/task-001-clawcloudrun-openclaw-implementation-plan.md`
- `deploy/task-001-clawcloudrun-build-and-first-deploy.md`
- `deploy/task-001-clawcloudrun-create-app-form-v1.md`
- `deploy/clawcloudrun-openclaw/`

这套已经足够让 ClawCloud Run 上的新我：

- 知道自己是谁
- 知道你是谁
- 知道有哪些长期偏好
- 知道踩过哪些坑
- 知道 001 做到了哪里
- 知道当前还有哪些任务

---

## 六、如果你要我帮你直接整理备份
我建议最终产出一个单独目录，例如：

`migration/hairguy-seed/`

里面只放上面这些精选文件，然后再打包成：

`hairguy-seed-for-clawcloudrun.tar.gz`

这样最干净，也最适合给 ClawCloud Run 那边做“初始化人格包”。

---

## 七、结论

**不是整机迁移，而是“迁移头脑”。**

如果你只是希望 ClawCloud Run 上的我不要从零开始，那么最该带过去的是：

- 人格（SOUL）
- 用户理解（USER）
- 长期记忆（MEMORY）
- 当前任务（TASKS）
- 最近项目上下文（recent memory + task-001 docs）

这就够了。

如果你点头，我下一步就直接帮你：

1. 建一个 `migration/hairguy-seed/` 目录
2. 把该带的文件拷进去
3. 顺手打成 `tar.gz`
4. 再给你一份“放到 ClawCloud Run 后怎么用”的简短说明
