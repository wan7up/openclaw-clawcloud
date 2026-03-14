# Feishu Bot

这是任务 006 的起步骨架，当前目标：

- 先建立一个普通飞书 Bot webhook 服务
- 按用户 ID 做白名单识别
- 为每个用户绑定独立 alias / sessionKey
- 暂时先不接 OpenClaw，只做接入层

## 当前能力

- `GET /health` 健康检查
- `POST /feishu/webhook` 处理飞书事件
- 支持 `url_verification` challenge
- 读取 `config/users.json` 中的白名单用户配置
- 识别发送者 ID，并映射到 alias / sessionKey

## 使用

1. 复制环境变量

```bash
cp .env.example .env
```

2. 安装依赖

```bash
npm install
```

3. 启动

```bash
npm run dev
```

4. 飞书开放平台里把事件订阅地址填成：

```text
https://你的域名/feishu/webhook
```

## 注意

当前版本只是接入骨架：
- 还没有调用飞书发送消息 API
- 还没有校验签名
- 还没有接 OpenClaw
- 但用户白名单 / alias / sessionKey 的数据模型已经定好了
