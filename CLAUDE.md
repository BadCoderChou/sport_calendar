# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SportCalendar — 一个基于 HarmonyOS Next（API 6.0.2）的 Stage 模型运动日历应用，使用 ArkTS 语言开发。

## Build & Run

项目使用 **Hvigor** 构建系统，通过 DevEco Studio IDE 进行构建和运行。

- **构建**: 在 DevEco Studio 中点击 Build → Make Project（或快捷键）
- **运行**: 通过 DevEco Studio 连接模拟器/真机后点击 Run
- **测试**: 使用 `@ohos/hypium` 测试框架，测试文件位于 `entry/src/ohosTest/ets/test/`
  - 入口文件: `List.test.ets`（聚合所有测试套件）
  - 单个测试文件: `Ability.test.ets`

## Architecture

### 项目结构

```
├── AppScope/              # 应用级全局配置
│   └── app.json5          # bundleName、version、icon 等应用元信息
├── entry/                 # 主模块（唯一模块）
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/EntryAbility.ets   # UIAbility 入口，管理窗口生命周期
│   │   │   ├── pages/Index.ets                  # 首页（当前为模板页面）
│   │   │   └── entrybackupability/             # 备份扩展能力
│   │   ├── resources/     # 资源文件（string/color/media/profile）
│   │   └── module.json5    # 模块声明：abilities、pages 路由、权限
│   └── src/ohosTest/       # 单元测试
├── oh-package.json5        # 依赖声明（ohpm 包管理）
├── build-profile.json5     # 构建配置：SDK 版本、签名、构建模式
└── hvigorfile.ts           # Hvigor 构建脚本入口
```

### 关键架构点

- **Stage 模型**: 应用基于 `UIAbility` + `WindowStage` 架构，`EntryAbility` 负责窗口创建与页面加载
- **页面路由**: 页面注册在 `resources/base/profile/main_pages.json`，通过 `windowStage.loadContent('pages/Index', ...)` 加载
- **资源引用**: 统一使用 `$r()` 引用资源（如 `$r('app.string.app_name')`），支持深色模式（`dark/` 目录）
- **单模块**: 当前仅 `entry` 一个模块，新增功能页面直接在 `entry/src/main/ets/pages/` 下创建 `.ets` 文件并注册到 `main_pages.json`

## Code Style & Lint

- 代码规范由 `code-linter.json5` 定义，启用 `@typescript-eslint/recommended` 和 `@performance/recommended` 规则集
- 安全规则强制检查加密算法安全性（AES/RSA/DSA/DH 等）
- Lint 作用范围: 所有 `**/*.ets` 文件（排除 test/mock/oh_modules/build/.preview）

## Dependencies

| 包 | 用途 |
|---|---|
| `@ohos/hypium` (1.0.25) | 单元测试框架 |
| `@ohos/hamock` (1.0.0) | Mock 测试辅助库 |

无运行时第三方依赖，纯 ArkTS 原生开发。
