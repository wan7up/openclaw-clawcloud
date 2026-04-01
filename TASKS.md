# TASKS.md

## Pending Tasks

- 任务 001：ClawCloud Run 的 OpenClaw 部署实施【已进入自动追更/自动发包阶段：当前确认可用 GHCR 基线为 `ghcr.io/wan7up/openclaw-clawcloud:v0.1.12`；已补上游版本同步脚本、版本参数化 Dockerfile，以及次日检查+自动发布 workflow 骨架。下一步重点转为真实仓库侧运行验证与首轮自动发布验收】
- 任务 002：电视直播列表自动化整理【补充并入：服务器侧浏览器任务的人机接力需求——当 AI 浏览器流程遇到扫码/滑块/验证码/人工确认时，需支持用户临时接管同一浏览器会话完成验证，再由 AI 接续执行；方案方向为共享可见浏览器工作台（Tailscale + noVNC + 专用非 headless Chromium profile，RustDesk 备用）】
- 任务 003：多个 claw 互通记忆方案
- 任务 004：御花苑 OpenClaw 部署（补充：评估是否可用 1 核 1G 设备部署轻量 OpenClaw，因处理问题不多）
- 任务 005：OpenClaw 多个 OpenAI Codex OAuth 账号的手动切换方案【废弃：不再作为任务】
- 任务 006：Telegram / 飞书按用户 ID 白名单直通使用机器人的合理实现方案【已完成（记录性任务）：Telegram 直接改 openclaw.json 白名单；飞书仅企业内使用，后台可指定人员】
- 任务 007：自动搜夸克资源并存放到夸克的可行方案
- 任务 008：OpenClaw 跨服务器备份与恢复方案（含异地备份到网盘/存储）【已基本完成：rclone/OpenList 远端已打通；日常迁移备份支持自动上传；本地/远端保留策略已就位；README 与恢复脚本已补；后续还会增加第二备份位置，并评估是否将“大尺寸回滚备份”也同步上远端（需考虑流量成本）；待将来做一次真实新机恢复演练】
- 任务 009：OpenClaw 本地记忆与文件系统检索机制的深度优化（解决自定义清单文件与默认 MEMORY.md 检索割裂的结构性失忆问题）【已基本完成；可选完善：1) 确认 QMD 索引范围覆盖自定义文件；2) 增加记忆检索失败时的 find/grep fallback；3) 固化一份检索诊断清单】
- 任务 010：修复后台任务完成/失败后不会及时主动汇报的问题【已收尾（本轮）/ 核心验收通过：`system event --mode now` + heartbeat 已明确降级为内部唤醒/补漏；当前默认主路径为“后台任务完成后直接 outbound send 到当前会话”。方案文档：`tasks/task-010-background-notify-plan.md`；模板文档：`tasks/task-010-background-task-templates.md`；后台任务登记清单：`memory/background-tasks.json`；helper：`scripts/run-with-notify.sh`。本轮已完成：1) Weixin/TG 双侧验证旧路径不合格；2) direct-send smoke test 成功；3) 真正后台 direct-send 自动通知演练成功，用户已确认收到；4) failure-path 与 longer-run 测试通过；5) helper 实际调用演示通过。当前结论：TG 私聊内，这套方案已可正式使用。后续待补边界验证：微信侧、thread/topic 场景，以及更自动化的 helper/skill 固化（非当前阻塞项）】
) failure-path 与 longer-run 测试通过；5) helper 实际调用演示通过。当前结论：TG 私聊内，这套方案已可正式使用。后续待补边界验证：微信侧、thread/topic 场景，以及更自动化的 helper/skill 固化（非当前阻塞项）】
