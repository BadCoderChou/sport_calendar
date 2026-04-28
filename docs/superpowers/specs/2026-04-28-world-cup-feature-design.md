# 世界杯订阅功能设计文档

日期: 2026-04-28
状态: 已批准

## 概述

在现有中超联赛赛程日历应用中新增 **2026 世界杯** 订阅功能。用户通过顶部 Tabs 切换"中超联赛"和"🏆 世界杯"两个视图，以国家为维度订阅世界杯赛程到系统日历。

## 需求确认

| 决策项 | 选择 |
|--------|------|
| 导航方式 | HarmonyOS 原生 Tabs 组件 |
| 国家范围 | 热门 12 强队 + "展开全部 48 国" 折叠 |
| 国旗来源 | Emoji 国旗（零资源文件） |
| 展开方式 | 原地展开（点击后追加显示） |

## 数据源

- **ICS API**: `https://api.sports-calendar.com/ics/soccer/fifa-world-cup/2026/matches.ics?lang=zh&team={countryId}`
- **格式**: 标准 ICS (RFC 5545)，与中超完全一致，现有 IcsParser 可直接复用
- **参赛国数**: 48 支
- **赛事时间**: 2026年6月11日 ~ 6月28日（小组赛 3 轮）

## 数据模型

### 新增接口: WorldCupTeam

```typescript
export interface WorldCupTeam {
  id: string;       // 如 'brazil', 'argentina'（对应 ICS API 的 team 参数）
  name: string;     // 中文名：'巴西'、'阿根廷'
  emoji: string;    // 国旗 emoji：'🇧🇷'、'🇦🇷'
  isHot: boolean;   // 是否为热门强队（前 12 个置顶显示）
}
```

### WORLD_CUP_TEAMS 数组

48 支球队，前 12 个 `isHot: true`：

**热门 12 强** (isHot=true): Brazil, Argentina, France, Germany, Spain, England, Portugal, Netherlands, USA, Uruguay, Japan, South Korea

**其余 36 国** (isHot=false): 按英文名排序，包括 Mexico, Canada, Colombia, Croatia, Egypt, Morocco, Saudi Arabia, Australia, Switzerland, Belgium, Iran, Senegal, Poland, Sweden, Tunisia, Denmark, Austria, Czech Republic, Serbia, Ukraine, Wales, Scotland, Panama, Costa Rica, Jamaica, Ecuador, Peru, Bolivia, Paraguay, Chile, Venezuela, Curaçao, Cape Verde, DR Congo, Ghana, Ivory Coast, Mali, Nigeria, South Africa, Algeria, Bosnia-Herzegovina, Haiti, New Zealand, Iraq, Jordan, Uzbekistan, China PR, Oman, Qatar

### ICS URL 函数

```typescript
export const WC_ICS_BASE_URL =
  'https://api.sports-calendar.com/ics/soccer/fifa-world-cup/2026/matches.ics';

export function getWorldCupIcsUrl(countryId: string): string {
  return `${WC_ICS_BASE_URL}?lang=zh&team=${countryId}`;
}
```

### 日历命名

- 前缀: `'世界杯-'`
- 使用中文名: `'世界杯-巴西'`、`'世界杯-阿根廷'`（与中超 `中超-北京国安` 风格一致）

## UI 设计

### 整体结构

```
Tabs 组件
├── Tab 1: "中超联赛" (现有内容不变)
│   ├── Header: 标题 + 副标题
│   ├── Team Grid (2列 Flex wrap)
│   ├── Attribution 文字
│   └── Button Bar (订阅 / 删除)
│
└── Tab 2: "🏆 世界杯" (新增)
    ├── Header: "2026 世界杯赛程日历"
    ├── Hot Teams Grid (3列 Flex wrap, 12个)
    ├── "展开全部 48 国" 按钮
    ├── All Teams Grid (3列 Flex wrap, 36个, 条件渲染)
    └── Button Bar (订阅 / 删除)
```

### 布局参数对比

| 参数 | 中超 Tab | 世界杯 Tab |
|------|---------|-----------|
| 宫格列数 | 2 | 3 |
| 卡片宽度 | 45% | 33% |
| 卡片高度 | 62px | 52px |
| Logo/Emoji 尺寸 | 32x32 (图片) | 20px (emoji) |
| 名称字号 | 9px | 7.5px |
| 展开按钮 | 无 | 有 |

### 展开交互

- 默认状态: 仅显示 12 个热门国家
- 点击 "▼ 展开全部 48 国家": 设置 `wcExpanded = true`，追加渲染 36 国
- 再次点击收起: `wcExpanded = false`
- 展开后按钮文字变为 "▲ 收起"

## 状态管理

### Index.ets 新增状态

```typescript
@State currentTab: number = 0;          // 0=中超, 1=世界杯
@State subscribedWcIds: string[] = [];   // 世界杯已选国家 ID
@State wcExpanded: boolean = false;      // 是否展开全部国家
@State wcSyncing: boolean = false;       // 世界杯同步状态
@State wcLastSyncTime: number = 0;       // 世界杯上次同步时间
```

### TeamStore 新增 Key

| Key | 类型 | 用途 |
|-----|------|------|
| `wc_subscribed` | `string[]` | 已选世界杯国家 ID 列表 |
| `wc_last_sync` | `number` | 世界杯上次同步时间戳 |
| `wc_last_sync_{id}` | `number` | 单个国家上次同步数量 |

## 文件变更清单

### 1. Teams.ets — 新增世界杯数据

- 新增 `WorldCupTeam` 接口
- 新增 `WORLD_CUP_TEAMS: WorldCupTeam[]` 常量（48 国）
- 新增 `getWorldCupIcsUrl()` 函数
- 新增 `WC_CALENDAR_NAME_PREFIX = '世界杯-'`
- 新增 `getWorldCupTeamById()` 辅助函数

### 2. Index.ets — Tabs 重构

- `build()` 方法外层包裹 `Tabs` + `TabContent`
- 新增世界杯 Tab 内容区:
  - Header（标题 + 副标题）
  - 热门国家宫格（ForEach hotTeams）
  - 展开/收起按钮
  - 全部国家宫格（ForEach restTeams, if wcExpanded）
  - 按钮栏（订阅/删除，复用样式）
- 新增 `onWcTeamTap(countryId)` 方法
- 新增 `onWcSubscribeTap()` 方法
- 新增 `onWcDeleteAllTap()` 方法
- 新增 `toggleWcExpand()` 方法
- Loading 遮罩两套 Tab 共用（根据 currentTab 显示不同文字）
- `onWcSubscribeTap()` 中调用 `TeamStore.setLastSyncCount(wcCountryId, count)` 记录同步数量
- **修复**: 删除 Index.ets 第 269 行重复的 `.fontSize(8)` 调用（预存 bug）
- 中超原有逻辑保持不变

### 3. TeamStore.ets — 新增存储 key

- `getWcSubscribedIds()`: 读取 wc_subscribed
- `setWcSubscribedIds(ids)`: 写入 wc_subscribed
- `toggleWcSubscription(countryId)`: 切换单个国家订阅状态（复用现有 toggleSubscription 模式，操作 wc_subscribed key）
- `getWcLastSyncTime()`: 读取 wc_last_sync
- `setWcLastSyncTime(time)`: 写入 wc_last_sync
- 复用现有的 Preferences 实例和模式

### 4. README.md — 更新文档

- 功能特性增加世界杯描述
- 项目结构更新
- 截图/说明补充

## 需要小幅调整的文件

### CalendarWriter.ets — 参数化 service 描述

当前 `writeOrUpdateEvent()` 硬编码了 `description: '中超联赛赛程'`（第 199、228 行）。需要改为：

**方案**: 给 `writeEvents()` 和 `writeOrUpdateEvent()` 新增可选参数 `serviceDescription?: string`，默认值 `'中超联赛赛程'` 保持向后兼容。世界杯调用时传入 `'世界杯赛程'`。

```typescript
// 修改前
static async writeEvents(team: Team, events: MatchEvent[]): Promise<number> {
  // ...
  await CalendarWriter.writeOrUpdateEvent(calendar, team.id, event);
}

// 修改后
static async writeEvents(team: Team, events: MatchEvent[], serviceDesc?: string): Promise<number> {
  // ...
  await CalendarWriter.writeOrUpdateEvent(calendar, team.id, event, serviceDesc);
}
```

**类型兼容性**: `WorldCupTeam` 无 `color`/`logo` 字段，但 `CalendarWriter.writeEvents()` 只使用 `team.name` 和 `team.id`（通过 `buildIdentifier`），不访问 `color` 或 `logo`。因此无需修改类型签名，只需新增 `serviceDesc` 参数。

## 不变更的文件

- `IcsParser.ets` — ICS 格式一致，无需改动
- `HttpService.ets` — 无需改动
- `MatchEvent.ets` — 无需改动
- `module.json5` — 权限已足够（READ/WRITE_CALENDAR, INTERNET）

## ID 命名空间隔离

中超 teamId 使用连字符格式（如 `beijing-guoan`、`shanghai-port`），世界杯 countryId 使用小写英文（如 `brazil`、`argentina`）。两个命名空间天然不重叠，不存在 ID 冲突风险。存储 key 也通过 `csl_subscribed` / `wc_subscribed` 前缀隔离。

## 实现顺序

1. Teams.ets — 添加世界杯数据定义
2. TeamStore.ets — 添加世界杯存储方法
3. Index.ets — Tabs 重构 + 世界杯 UI + 逻辑
4. README.md — 文档更新
5. 测试验证
