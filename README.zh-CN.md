# CmdTabUltra

[English](./README.md) | [简体中文](./README.zh-CN.md)

CmdTabUltra 是一个 macOS 窗口恢复工具。当你通过 `Cmd-Tab` 切换回某个应用时，它会恢复该应用的最小化窗口，或在 macOS 只激活应用但没有显示窗口时重新打开窗口。

## 功能

- 通过 `Cmd-Tab` 切换应用后恢复最小化窗口
- 当应用没有标准可见窗口时尝试重新打开窗口
- 当应用处于激活状态但没有窗口时尝试新建窗口
- 提供本地控制面板，用于查看服务状态、开机自启、诊断信息和语言设置
- 支持恢复策略开关和排除应用 Bundle ID
- 显示最近处理记录，便于本地诊断
- 通过当前用户的 LaunchAgent 运行后台服务

## 环境要求

- macOS 11 或更高版本
- Xcode Command Line Tools
- 为 CmdTabUltra 授予辅助功能权限

## 安装

本地构建并安装：

```sh
make install
```

构建 DMG：

```sh
make dmg
open dist/CmdTabUltra-<version>.dmg
```

安装后打开 `CmdTabUltra.app`，授予辅助功能权限，然后在控制面板中启动服务。

## 开发

常用命令：

```sh
make help
make universal
make bundle
make zip
make dmg
make pkg
make lint
make format
make clean
```

发布版本号只需要修改 [VERSION](./VERSION)。打包产物、app 元数据、安装包文件名和 release tag 都会使用这个文件作为唯一版本来源。

仓库结构：

```text
src/          Swift 源码
VERSION       发布版本号
resources/    图标和本地化资源
scripts/      本地辅助脚本
packaging/    安装包元数据
docs/         开发说明
dist/         生成产物
```

贡献和维护说明见 [CONTRIBUTING.md](./CONTRIBUTING.md) 和 [docs/development.md](./docs/development.md)。

## 说明

CmdTabUltra 使用公开 macOS API 和辅助功能权限。从控制面板启动后台服务时，应用会将 `com.jint233.cmdtabultra.plist` 写入 `~/Library/LaunchAgents/`。

`dist/` 中的生成产物不应提交。

## License

Apache License 2.0。详见 [LICENSE](./LICENSE)。
