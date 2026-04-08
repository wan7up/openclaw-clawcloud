# TASKS.md

## Pending Tasks

- 任务 001：ClawCloud Run 的 OpenClaw 部署实施【当前最新状态（2026-04-07 更新）：这轮修复已完成，但**尚未正式收尾**，当前处于“等待下一次 OpenClaw 官方新版本，以验证真实自动更新是否正确”的观察期。当前正式候选线为 `ghcr.io/wan7up/openclaw-clawcloud:v2026.4.5-restore2`，回退线为 `ghcr.io/wan7up/openclaw-clawcloud:v2026.4.2-pluginfix-restore2`；这两条均已由用户实测可用。自动更新规则已修正并锚定到 4.5 restore2：以后 task001 允许继续滚官方底包版本，但**不得**回到裸 `v{upstream}` / `latest`，也不得退回旧坏线；未来官方出新版本时，需验证自动更新是否仍沿着 restore2 线正确产出新包。另：GHCR 清理规则必须记牢——只能删除旧的顶层废弃 tag 线，不能删除保留顶层 tag 下面的无 tag 子 manifest/version】
- 任务 002：电视直播列表自动化整理【补充并入：服务器侧浏览器任务的人机接力需求——当 AI 浏览器流程遇到扫码/滑块/验证码/人工确认时，需支持用户临时接管同一浏览器会话完成验证，再由 AI 接续执行；方案方向为共享可见浏览器工作台（Tailscale + noVNC + 专用非 headless Chromium profile，RustDesk 备用）】
- 任务 003：多个 claw 互通记忆方案
- 任务 004：御花苑 OpenClaw 部署（补充：评估是否可用 1 核 1G 设备部署轻量 OpenClaw，因处理问题不多）【当前最新状态（2026-04-07 更新）：旧 `manual-devices-v9` 线应继续视为历史污染线，不再作为当前正确方向。当前应以 **official-first / official-min** 线理解和验证 ARM64 包：用户已明确确认可用的是 `ghcr.io/wan7up/openclaw-arm64:2026.4.2-official-min-rc1`；GHCR 上另外可见的 `2026.4.2-official-min` 与 `2026.4.5-official-min` 大概率是 official-min 自动更新线自动跑出的产物，不是 `manual-devices-v9` 那条旧线。就仓库包装逻辑看，`2026.4.5-official-min` 应理解为“同一条 official-min 最小包装线升到 4.5”的产物，值得在 ARM64 真机上继续测试；但它是否与 `2026.4.2-official-min-rc1` 在运行行为上完全等价，仍需真实机器验证。004 当前仍未正式收尾】
- 任务 005：OpenClaw 多个 OpenAI Codex OAuth 账号的手动切换方案【废弃：不再作为任务】
- 任务 006：Telegram / 飞书按用户 ID 白名单直通使用机器人的合理实现方案【已完成（记录性任务）：Telegram 直接改 openclaw.json 白名单；飞书仅企业内使用，后台可指定人员】
- 任务 007：自动搜夸克资源并存放到夸克的可行方案
- 任务 008：OpenClaw 跨服务器备份与恢复方案（含异地备份到网盘/存储）【已基本完成：rclone/OpenList 远端已打通；日常迁移备份支持自动上传；本地/远端保留策略已就位；README 与恢复脚本已补；后续还会增加第二备份位置，并评估是否将“大尺寸回滚备份”也同步上远端（需考虑流量成本）；待将来做一次真实新机恢复演练。补充：2026-04-07 已再次确认 daily migration backup 链已恢复正常，手动备份生成与远端上传均已验证通过】
- 任务 009：OpenClaw 本地记忆与文件系统检索机制的深度优化（解决自定义清单文件与默认 MEMORY.md 检索割裂的结构性失忆问题）【已基本完成；当前已知可选完善项：1) 确认 QMD 索引范围覆盖自定义文件；2) 增加记忆检索失败时的 find/grep fallback；3) 固化一份检索诊断清单】
- 任务 010：修复后台任务完成/失败后不会及时主动汇报的问题【重新打开：此前把 TG 私聊 direct-send 路径判成“已可正式使用”过早，用户在 task004 / libreoffice 实战中给出反证：若用户不追问，最终结果并不会稳定出现在眼前。当前最新结论：1) `system event --mode now` + heartbeat 只能算内部唤醒/补漏，不能作为用户侧及时送达保证；2) CLI `openclaw message send` / `scripts/run-with-notify.sh` 路径虽然可出现内部 success、code=0、甚至 messageId/状态记录，但用户侧最终可见性仍不可靠；3) task010 目前不能视为完成，必须改成以“用户真实看见结果”为唯一验收口径。现阶段文档/模板/登记文件仍保留：`tasks/task-010-background-notify-plan.md`、`tasks/task-010-background-task-templates.md`、`memory/background-tasks.json`、`scripts/run-with-notify.sh`；但状态回退为待修，下一步重点是定位 routing/sessionKey/CLI outbound send 到用户侧之间哪一层丢消息，并修到 Telegram 私聊真实验收通过为止】
