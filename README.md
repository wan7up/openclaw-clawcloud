# OpenClaw 官方镜像适配版本仓库

这个仓库提供两个**基于 OpenClaw 官方镜像**修改的适配版本，分别面向不同的部署环境与机型。

- **ClawCloud Run 适配版**  
  镜像：`ghcr.io/wan7up/openclaw-clawcloud`  
  用途：针对 ClawCloud Run 的运行环境做适配，方便直接部署与持久化使用。

- **ARM64 适配版**  
  镜像：`ghcr.io/wan7up/openclaw-arm64`  
  用途：基于 OpenClaw 官方镜像调整为更适合 ARM64 机型使用的版本。

## 当前最新镜像

### ClawCloud Run 适配版
- 版本标签：`ghcr.io/wan7up/openclaw-clawcloud:v2026.3.31`
- 滚动标签：`ghcr.io/wan7up/openclaw-clawcloud:latest`
- 上游基础版本：OpenClaw `2026.3.31`

### ARM64 适配版
- 版本标签：`ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v9`
- 滚动标签：`ghcr.io/wan7up/openclaw-arm64:latest-manual-devices-v9`
- 上游基础版本：OpenClaw `2026.3.31`

## 两个镜像分别做了什么适配

### ClawCloud Run 适配版
目录：`deploy/clawcloudrun-openclaw/`

主要调整：
- 状态目录改为 `/data/.openclaw`
- workspace 改为 `/data/workspace`
- 使用 `nginx` 暴露 `8080` 入口并转发到内部 gateway
- 启动时根据环境变量生成最小可用配置
- 默认关闭 memory vector，以提高 ClawCloud Run 场景下的稳定性

### ARM64 适配版
目录：`deploy/openclaw-arm64/`

主要调整：
- 基于 OpenClaw 官方镜像修改为更适合 ARM64 机型运行的版本
- 补充适合 ARM64 设备的默认运行配置
- 兼容较老 Docker / CoreELEC 环境的镜像 manifest 标记

## 自动更新与页面维护

这个仓库已经补上自动化流程，用来保持仓库页面和下载信息处于最新状态：

- `sync-openclaw-package-bases.yml`：每日检查 OpenClaw 上游新版本
- `publish-openclaw-packages.yml`：自动构建并推送两个 GHCR 镜像
- `update-release-pages.yml`：自动刷新仓库下载页显示的最新镜像引用

## 说明

这两个镜像都不是对 OpenClaw 本体做大改，而是：

> **基于 OpenClaw 官方镜像，针对不同部署环境和机型做适配修改的版本。**

如果你只是想按自己的场景直接部署，选对应的适配版即可。

## 上游项目

- OpenClaw 官方仓库：<https://github.com/openclaw/openclaw>
- 当前仓库：<https://github.com/wan7up/openclaw-clawcloud>
