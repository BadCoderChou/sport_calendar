# SportCalendar — 中超联赛赛程日历

基于 **HarmonyOS Next（API 6.0.2）** 的 Stage 模型运动日历应用，将中超联赛 16 支球队的赛季赛程一键订阅到系统日历，支持赛前提醒。

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-Next%20API%206.0.2-blue)

## 功能特性

- **16 支球队赛程** — 覆盖中超联赛全部球队，按拼音排序
- **一键订阅** — 选择球队后点击"订阅日程"，自动拉取 ICS 数据写入系统日历
- **独立日历** — 每支球队生成独立的系统日历（`中超-{队名}`），互不干扰
- **赛前提醒** — 默认赛前 **2 小时**推送通知
- **智能去重** — 基于作用域 UID 隔离，两队对决比赛各自独立写入双方日历
- **便捷管理** — 支持单支球队取消选择（同步删除对应日历）、批量删除全部日历
- **Loading 反馈** — 订阅过程中显示居中加载遮罩，防止重复操作

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | ArkTS (TypeScript for HarmonyOS) |
| UI 框架 | ArkUI (声明式 UI) |
| 日历 API | `@kit.CalendarKit` (系统日历读写) |
| 网络请求 | 原生 HTTP (fetch ICS 文本) |
| 数据解析 | 自研 ICS Parser (RFC 5545) |
| 本地存储 | Preferences (`@ohos.data.preferences`) |
| 构建工具 | Hvigor (DevEco Studio 内置) |
| 测试框架 | `@ohos/hypium` |

## 项目结构

```
SportCalendar/
├── AppScope/                  # 应用级配置
│   └── app.json5            # bundleName, icon, version
├── entry/                     # 主模块（唯一模块）
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets    # UIAbility 入口
│   │   │   ├── pages/
│   │   │   │   └── Index.ets           # 主页面（球队选择 + 订阅）
│   │   │   ├── services/
│   │   │   │   ├── CalendarWriter.ets # 日历读写（创建/删除/写入事件）
│   │   │   │   ├── HttpService.ets     # HTTP 请求（ICS 拉取）
│   │   │   │   ├── IcsParser.ets       # ICS 文件解析器
│   │   │   │   └── TeamStore.ets      # 本地持久化存储
│   │   │   ├── constants/
│   │   │   │   └── Teams.ets          # 球队定义、ICS URL、常量
│   │   │   └── model/
│   │   │       └── MatchEvent.ets      # 赛事事件数据模型
│   │   └── module.json5         # 权限声明、页面路由
│   └── src/ohosTest/            # 单元测试
├── oh-package.json5            # 依赖管理（ohpm）
├── build-profile.json5         # 构建配置（SDK 版本、签名）
└── hvigorfile.ts               # Hvigor 构建脚本
```

## 核心架构

### 数据流

```
sports-calendar.com API
        ↓ (HTTPS GET, ICS 格式)
    HttpService.fetchIcs()
        ↓ (原始 ICS 文本)
    IcsParser.parse()
        ↓ (MatchEvent[])
    CalendarWriter.writeEvents(team, events)
        ↓ (@kit.CalendarKit)
    系统日历 (每队独立 calendar)
```

### UID 冲突处理

当两支球队在赛季中有多次对决（如上海海港 vs 天津津门虎），ICS API 对同一场比赛返回**相同 UID**。解决方案：

```
原始 UID: 2434479
  → 上海海港日历: identifier = "shanghai-port:2434479"
  → 天津津门虎日历: identifier = "tianjin-jinmen-tiger:2434479"
```

通过 `{teamId}:{uid}` 作用域前缀确保每个日历内的 identifier 天然唯一，避免跨日历误匹配更新。

### 权限说明

| 权限 | 用途 | 申请时机 |
|------|------|----------|
| `ohos.permission.READ_CALENDAR` | 读取系统日历 | 删除日历时 |
| `ohos.permission.WRITE_CALENDAR` | 写入赛事到日历 | 订阅/删除日历时 |
| `ohos.permission.INTERNET` | 网络请求拉取 ICS | 订阅赛程时 |

## 数据来源

| 资源 | 提供方 | 用途 |
|------|--------|------|
| 球队 Logo | [fclogo.top](https://fclogo.top) | 16 支中超球队官方/社区 Logo |
| 赛程数据 | [sports-calendar.com](https://sports-calendar.com) | ICS 格式日历订阅源 |

> 球队按拼音排序：北京国安、成都蓉城、大连英博、河南俱乐部、青岛海牛、青岛西海岸、山东泰山、上海海港、上海申花、深圳新鹏城、天津津门虎、武汉三镇、云南玉昆、浙江俱乐部、重庆铜梁龙、辽宁铁人

## 开发环境要求

- **IDE**: DevEco Studio 6.0+
- **SDK**: HarmonyOS Next API 6.0.2 (22)
- **设备**: 手机/模拟器（需支持日历功能）
- **Node.js**: DevEco Studio 内置

## 构建 & 运行

### 构建

在 DevEco Studio 中：
1. 打开项目
2. **Build → Make Project**（或快捷键）

### 运行

1. 通过 DevEco Studio 连接模拟器或真机
2. 点击 **Run**

### 测试

```bash
# 在 DevEco Studio Terminal 中执行
hvigorw test --mode unit -p module=entry@default -s product=default
```

测试文件位于 `entry/src/ohosTest/ets/test/`。

## License

MIT
