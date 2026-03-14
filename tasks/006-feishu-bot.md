# 任务006：飞书 Bot（白名单多用户）

## 目标
先做一个普通飞书 Bot，但从一开始就按“多人共用一个 bot”的方向设计。

## 当前需求
1. 用户 ID 提前写进白名单
2. 多人共用一个 bot
3. bot 对不同用户使用不同称呼
4. bot 为不同用户保留各自记录/上下文

## 当前阶段
先建一个普通飞书 Bot 供个人试用，确认飞书接入、事件订阅、user_id 获取、白名单与 alias/sessionKey 映射都正常。

## 已完成
- 在工作区创建 `feishu-bot/` 项目骨架
- 建立 `config/users.json` 用户白名单配置
- 建立 Fastify webhook 服务
- 支持飞书 `url_verification` challenge
- 支持按发送者 ID 映射 alias / sessionKey

## 下一步
1. 在飞书开放平台创建应用并开启 Bot
2. 获取个人飞书 user_id/open_id
3. 将你的 ID 填入 `config/users.json`
4. 把 webhook 暴露为 HTTPS 地址
5. 在飞书后台配置事件订阅
6. 增加飞书回消息 API 调用
7. 增加签名校验
8. 再接 OpenClaw
