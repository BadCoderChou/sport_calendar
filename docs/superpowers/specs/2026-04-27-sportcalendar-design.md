# SportCalendar 设计文档

## 概述

一个 HarmonyOS Next（API 6.0.2）应用，让用户选择中超球队，将赛程一键同步到系统日历。

**核心价值**：替代 iOS/macOS 的 webcal 日历订阅体验，在鸿蒙生态中实现同样的功能。

## 功能范围

| 功能 | 说明 |
|------|------|
| 球队选择 | 内置 16 支中超球队网格，点击切换订阅状态 |
| 赛程同步 | 拉取 ICS → 解析 → 写入系统独立日历（每队一个） |
| 手动更新 | 「同步赛程」按钮刷新比分和时间变更 |
| 取消订阅 | 点击已订阅卡片 → 确认弹窗 → 删除对应日历 |
| 赛前提醒 | 依赖系统日历，每场比赛前 30 分钟提醒 |

**不做**：自动后台同步、多联赛支持、自定义 ICS 输入、App 内赛程展示、推送通知。

## 技术方案

轻量纯原生：手写 ICS 解析器 + `@kit.CalendarKit` 直接写入。零外部运行时依赖。

### 数据源（已验证）

ICS 订阅地址（已通过实际请求验证，返回有效数据）：
```
https://api.sports-calendar.com/ics/soccer/chinese-super-league/2026/matches.ics?lang=zh&team={id}
```

示例（北京国安，已验证可用）：
```
https://api.sports-calendar.com/ics/soccer/chinese-super-league/2026/matches.ics?lang=zh&team=beijing-guoan
```

ICS 关键字段：
- `SUMMARY`: 比赛标题，已结束含比分（"武汉三镇 0:2 北京国安"），未结束为对阵（"北京国安 对阵 上海海港"）
- `DTSTART` / `DTEND`: UTC 时间
- `LOCATION`: 场地名称
- `UID`: 全局唯一标识，用于去重
- `DESCRIPTION`: 含轮次和比赛状态
- `X-SC-MATCH-STATUS`: finished / scheduled
- `VALARM`: TRIGGER:-PT1800S（赛前 30 分钟提醒）

## 架构

```
entry/src/main/ets/
├── pages/
│   └── Index.ets                 # 主页 UI（唯一页面）
├── model/
│   ├── Team.ets                  # 球队数据模型
│   └── MatchEvent.ets            # 解析后的比赛事件模型
├── services/
│   ├── IcsParser.ets             # ICS 文本解析器
│   ├── CalendarWriter.ets        # CalendarKit 封装（写入/删除）
│   ├── HttpService.ets           # HTTP 请求封装
│   └── TeamStore.ets             # 订阅状态持久化
└── constants/
    └── Teams.ets                 # 16 支中超球队定义
```

### 数据流

```
用户操作 → Index.ets (UI)
         → TeamStore (读写 Preferences 持久化)
         → HttpService.fetchIcs(teamSlug)     // GET ICS URL
         → IcsParser.parse(icsText)           // 文本 → MatchEvent[]
         → CalendarWriter.writeEvents(team, events)  // @kit.CalendarKit
         或 CalendarWriter.deleteCalendar(team)      // 删除日历 + 事件
```

## UI 设计

单页面应用，从上到下：

1. **标题栏**: "中超联赛赛程日历" + 副标题
2. **球队网格**: 4 列布局，每格显示队色圆点 + 队名
   - 未订阅: 白色卡片
   - 已订阅: 绿色边框 + 绿色背景 + 右上角 ✓ 图标
3. **同步栏**: 底部固定区域
   - 显示已订阅数量、上次同步时间
   - 「同步赛程」按钮（无订阅时置灰不可点）

### 交互细节

| 操作 | 行为 |
|------|------|
| 点击未订阅卡片 | 卡片变绿 + ✓，加入订阅列表 |
| 点击「同步赛程」 | Loading 动画 → Toast "已导入 N 场比赛" |
| 点击已订阅卡片 | 弹出确认框「取消订阅？将删除 N 场比赛」→ 确认后删除 |
| 无订阅时 | 同步按钮置灰 |

### 取消订阅确认弹窗

- 标题: "取消订阅 {球队名}？"
- 内容: "将删除该球队的全部赛程日历"（因为实际操作是删除整个 calendar，这样表述始终准确）
- 按钮: "取消" / "确认删除"（红色）

## 权限（需修改 module.json5）

当前 `entry/src/main/module.json5` **无任何权限声明**，实现时必须添加以下内容：

```json5
module: {
  requestPermissions: [
    {
      name: "ohos.permission.READ_CALENDAR",
      reason: "$string:calendar_read_reason",
      usedScene: { abilities: ["EntryAbility"], when: "inuse" }
    },
    {
      name: "ohos.permission.WRITE_CALENDAR",
      reason: "$string:calendar_write_reason",
      usedScene: { abilities: ["EntryAbility"], when: "inuse" }
    },
    {
      name: "ohos.permission.INTERNET"
    }
  ]
}
```

同时在 `resources/base/element/string.json` 中添加对应的 reason 字符串。INTERNET 权限不需要 reason 和 when 字段。

> **注意**: HarmonyOS Next 默认阻止非 TLS 流量。ICS 端点为 HTTPS，如遇问题需检查 `network/security_config.json` 配置。

## 模块设计

### Team (model)

```typescript
interface Team {
  id: string;          // 如 "beijing-guoan"，同时用作 URL 参数
  name: string;        // 如 "北京国安"
  color: string;       // 队色 hex（用于卡片圆点）
}
```

### MatchEvent (model)

```typescript
interface MatchEvent {
  uid: string;           // 去重 key
  title: string;         // SUMMARY（含比分或对阵）
  startTime: number;     // 时间戳 ms
  endTime: number;       // 时间戳 ms
  location: string;      // 场地
  description: string;   // 轮次+状态详情
  status: 'finished' | 'scheduled';
  reminderMinutes: number; // 30
}
```

### IcsParser (service)

核心方法: `parse(icsText: string): MatchEvent[]`

实现要点:
1. 按 `BEGIN:VEVENT` / `END:VEVENT` 切分事件块
2. 逐行解析键值对（处理 RFC 5545 行续写：以空格或 TAB 开头的行是上一行的延续）
3. UTC 时间转本地时间戳（Asia/Shanghai），支持 TZID 参数的时区感知时间
4. 从 DESCRIPTION 提取轮次信息
5. 从 X-SC-MATCH-STATUS 提取状态

容错处理（UTF-8 编码假设）:
- 缺少 SUMMARY 或 DTSTART 的 VEVENT 块：跳过并记录日志
- 遇到 RRULE 等不相关字段：忽略，不报错
- 整个文本为空或无 VEVENT：返回空数组而非抛异常

### CalendarWriter (service)

核心方法:
- `writeEvents(team: Team, events: MatchEvent[]): Promise<number>` — 返回写入数量
- `deleteCalendar(team: Team): Promise<void>`

实现要点:
1. 按 calendar 名称 `"中超-{name}"` 查找或创建日历
2. 遍历 events，用 UID 查找已有事件
3. 存在则 `updateEvent()`，不存在则 `addEvent()`
4. 删除时先 `deleteAllEvents()` 再 `removeCalendar()`
5. 每个事件设置 reminder: 30 分钟前

### HttpService (service)

核心方法: `fetchIcs(teamSlug: string): Promise<string>`

- 使用 `@ohos.net.http` 发起 GET 请求
- 超时 15 秒
- 错误处理: 网络超时 / 404 / 解析失败

### TeamStore (service)

使用 `@ohos.data.preferences`（基于 PersistenceMap）持久化，确保 App 重启后数据不丢失:
- `subscribedTeamIds: string[]` — 已订阅球队 ID 列表
- `lastSyncTime: number` — 上次同步时间戳
- `lastSyncCounts: Record<string, number>` — 每队上次导入数量

> 不使用 AppStorage：它是内存存储，App 进程被杀后数据丢失。

### Teams (constant)

16 支 2026 赛季中超球队完整列表，含 id/name/color。id 同时用作 ICS URL 的 team 参数。

## CalendarKit API 验证清单（实现前需确认）

以下 API 在 HarmonyOS Next 6.0.2(22) 中的具体方法名和签名需对照官方文档确认：

- [ ] 创建日历: `calendarManager.createCalendar()` 或类似方法
- [ ] 按名称查找日历: 是否支持按名称查询，或需遍历列表
- [ ] 添加事件: `calendarManager.addEvent()` 的完整参数类型
- [ ] 更新事件: 是否有 `updateEvent()` 方法，或需先删后增
- [ ] 按 UID 查找事件: 是否支持，或需遍历所有事件匹配 UID
- [ ] 删除事件 / 清空日历: `deleteAllEvents()` 或批量删除方式
- [ ] 删除日历: `removeCalendar()` 方法
- [ ] 设置提醒: 事件的 reminder 参数格式

> 如果某些 API 不存在，需要设计替代方案（如先删后增代替更新）。

## 首次启动体验

1. 用户打开 App → 看到完整的 16 队网格（全部白色未订阅状态）+ 置灰的「同步赛程」按钮
2. 无需 onboarding 引导 — 界面自解释：点击球队即可订阅
3. 权限请求时机：**首次点击「同步赛程」按钮时**触发弹窗请求日历权限（而非启动时弹窗打扰）
4. 权限被拒后：Toast 提示 + 引导去设置页

## 应用生命周期

- 同步过程中用户按 Home 键：HTTP 请求继续在后台完成，写入日历不受影响
- App 被系统杀死：同步中断，下次打开时数据以 TeamStore 中记录的 lastSyncTime 为准
- 不做后台保活或前台服务

| 场景 | 处理方式 |
|------|----------|
| 无网络 | Toast "网络连接失败，请检查网络" |
| ICS 请求失败(404/500) | Toast "获取赛程数据失败，请稍后重试" |
| ICS 格式异常 | 跳过该事件，记录日志，继续解析其余 |
| 日历权限被拒 | 引导用户去设置页开启权限 |
| 日历写入失败 | Toast "写入日历失败: {错误原因}" |
| 同步过程中 | 按钮 Loading 禁用重复点击 |

## 中超 16 队列表 (2026 赛季)

| ID | 名称 |
|----|------|
| beijing-guoan | 北京国安 |
| shanghai-haipo | 上海海港 |
| shanghai-shenhua | 上海申花 |
| shandong-taishan | 山东泰山 |
| chengdu-rongcheng | 成都蓉城 |
| zhejiang-club | 浙江俱乐部 |
| tianjin-jinmenhu | 天津津门虎 |
| wuhan-sanzhen | 武汉三镇 |
| henan-club | 河南俱乐部 |
| qingdao-hainiu | 青岛海牛 |
| qingdao-xihaian | 青岛西海岸 |
| yunnan-yukun | 云南玉昆 |
| dalian-yingbo | 大连英博 |
| shenzhen-xinpengcheng | 深圳新鹏城 |
| chongqing-tonglianglong | 重庆铜梁龙 |
| liaoning-tieren | 辽宁铁人 |

> 注: id 值即为 URL 中的 team 参数。beijing-guoan 已通过实际请求验证可用，其余球队 id 需在实现时逐个验证（或从 sports-calendar.com 网页抓取确认）。
