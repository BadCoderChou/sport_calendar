# 赛事日历功能增强设计

> **日期：** 2026 年 5 月 6 日
> **背景：** 华为应用商店审核驳回 — 功能单一（仅有添加/删除日程），需丰富应用内容与体验

## 审核反馈

1. **功能单一** — 应用仅有添加/删除日程功能，使用场景有限
2. **UX 规范** — 字体大小 < 8fp（已修复）

## 本次新增功能（4 项）

| # | 功能 | 目的 | 优先级 |
|---|------|------|--------|
| A | 赛程列表展示 | 让用户预览赛程再决定订阅，不再盲订 | P0 |
| B | 「我的」页面优化 | 订阅管理可视化，一键操作 | P0 |
| C | 近期赛程/倒计时卡片 | 给用户打开应用的理由 | P0 |
| D | 首次使用引导 | 降低新用户流失率 | P1 |

## 架构约束

- **纯离线单机应用**，不联网、无服务器
- 数据来源：已有 rawfile 内嵌 ICS 文件（16 CSL + 48 WC）
- 不引入新的系统权限
- 保持现有 3 个 Tab 结构（中超 / 世界杯 / 我的）
- HarmonyOS NEXT API 6.0.2, ArkTS

---

## 功能 A：赛程列表展示

### 交互

点击任意球队卡片 → 底部弹出 HalfModal 展示该队全部赛程。

### 弹窗布局

```
┌──────────────────────────────┐
│  {emoji} {球队名} — 全部赛程   │
│──────────────────────────────│
│                              │
│  MM/DD 周X HH:MM           │
│  {主队} vs {客队}            │
│  🏠 主场/✈ 客场 | ⚽ 状态    │
│                              │
│  ...（Scroll 滚动）          │
│                              │
│  ─────────────────────────── │
│  [   订阅全部到日历 📅   ]   │
└──────────────────────────────┘
```

### 数据流

```
DataService.loadIcs(ctx, "csl/{teamId}.ics")
        ↓ (原始 ICS 文本)
IcsParser.parse(icsText)
        ↓ (MatchEvent[])
按 DTSTART 时间排序
        ↓
渲染到弹窗列表
```

### 状态显示规则

| 条件 | 显示内容 |
|------|---------|
| 比赛未开始 | 时间 + 主客场 + 「未开始」 |
| 比赛已完成 | 比分 + 主客场 + 最终结果 |
| 无 ICS 数据 | 提示「暂无赛程数据」 |

### 组件设计

**新文件：** `MatchListSheet.ets`（可复用组件）

```typescript
@Component
struct MatchListSheet {
  @Prop team: Team
  @Prop events: MatchEvent[]
  @Prop isSubscribed: boolean
  @Require onSubscribe: (team: Team) => void

  build() {
    Column() {
      // Header: 球队名 + 关闭按钮
      // List: 每场比赛一行
      // Footer: 一键订阅按钮（未订阅时显示）
    }
    .height('60%')
  }
}
```

---

## 功能 B：「我的」页面优化

### 改造前后对比

**改造前：**
- 隐私协议入口
- 版本更新记录
- 工具化页面，用户价值感弱

**改造后：**

```
┌──────────────────────────────┐
│  📋 我的订阅                │
│──────────────────────────────│
│                              │
│  已订阅 N 支球队             │
│  ─────────────────────────  │
│                              │
│  ☑ {球队emoji} {球队名}      │
│     {联赛类型}  ✅{N}场      │
│     [ 取消订阅 ]           │
│                              │
│  ...（每支已订阅球队一项）    │
│                              │
│  ─────────────────────────  │
│  [ 🗑️ 一键取消全部订阅 ]     │
│                              │
│  ─────────────────────────  │
│  上次同步: YYYY-MM-DD       │
│  版本: v1.0.0               │
│  [ 隐私协议 ] [ 更新记录 ]   │
└──────────────────────────────┘
```

### 数据来源

- 已订阅列表：`TeamStore.getSubscribedTeams()` （已有）
- 每队事件数：`CalendarWriter.getCalendarEventCount()` （需新增方法）
- 同步时间：`TeamStore.getLastSyncTime(teamId)` （已有）

### 新增逻辑

1. **单项取消**：点击「取消订阅」→ 确认弹窗 → 删除对应日历 + 移除订阅记录
2. **一键全部取消**：二次确认弹窗（AlertDialog）→ 遍历所有已订阅球队逐一删除
3. **空状态**：无已订阅球队时显示引导文字：「还没有订阅任何球队，去中超或世界杯 Tab 选择你关注的球队吧」

---

## 功能 C：近期赛程/倒计时卡片

### 位置与样式

每个 Tab（中超/世界杯）球队列表**顶部**，可折叠：

```
┌──────────────────────────────┐
│  ⏰ 即将开始              ▼  │  ← 可折叠，默认展开
│──────────────────────────────│
│                              │
│  🇨🇳 A vs B    周六 15:30  │
│  ⏱ 还剩 2 天 3 小时  🏠     │
│                              │
│  🇨🇳 C vs D    周六 19:00  │
│  ⏱ 还剩 2 天 7 小时  ✈     │
│                              │
└──────────────────────────────┘
         ↓
   （原有球队网格）
```

### 数据计算

```typescript
// 从已解析的 MatchEvent[] 中筛选：
// 1. 只取已订阅球队的赛事
// 2. DTSTART >= 当前时间（未开始的比赛）
// 3. 按 DTSTART 升序排列
// 4. 取前 3 场

function getUpcomingEvents(subscribedTeamIds: string[], allEvents: Map<string, MatchEvent[]>): UpcomingCard[] {
  const now = Date.now();
  return subscribedTeamIds
    .flatMap(id => allEvents.get(id) ?? [])
    .filter(e => e.startTime >= now)
    .sort((a, b) => a.startTime - b.startTime)
    .slice(0, 3);
}
```

### 倒计时格式

| 距比赛时间 | 显示格式 |
|-----------|---------|
| > 24h | `还剩 N 天` |
| < 24h | `还剩 N 小时 M 分` |
| < 1h | `即将开始` |
| 无已订阅球队 | `订阅球队后，即将开始的比赛将在此处展示` |

### 折叠状态

- **展开**：显示最近 3 场赛程卡片
- **折叠**：只显示一行「⏰ 即将开始 N 场比赛」，点击展开

---

## 功能 D：首次使用引导

### 触发条件

应用启动时检查 `Preferences` 中 `hasSeenOnboarding`：
- `undefined` / `false` → 显示引导
- `true` → 跳过

### 引导步骤

| 步骤 | 高亮区域 | 说明文字 |
|------|---------|---------|
| 第 1 步 | 底部 Tab 栏 | 「选择联赛：底部有『中超联赛』和『世界杯』两个分类」 |
| 第 2 步 | 球队网格区域 | 「选择球队：点击卡片选中你关注的球队」 |
| 第 3 步 | 底部按钮栏 | 「订阅日程：选中后点击『订阅日程』写入系统日历」 |

### UI 实现

**新文件：** `OnboardingOverlay.ets`

```typescript
@Component
struct OnboardingOverlay {
  currentStep: number = 0
  totalSteps: number = 3

  build() {
    if (!this.show) return;
    Stack() {
      // 半透明深色遮罩层 (Color.Black, opacity 0.6)
      // 高亮区域（镂空矩形，指向目标控件）
      // 引导文字气泡 + 箭头
      // [跳过] 按钮（右上角小字）
      // [下一步] / [开始使用] 按钮（底部主按钮）
    }.width('100%').height('100%')
  }
}
```

### 步进控制

- 「下一步」→ `currentStep++`
- 最后一步按钮文字变为「开始使用 ✓」
- 点击「开始使用」→ 写入 `hasSeenOnboarding: true` → 关闭遮罩
- 「跳过」→ 直接写入并关闭（不强制看完）

---

## 文件变更清单

### 新增文件

| 文件 | 用途 |
|------|------|
| `components/MatchListSheet.ets` | 赛程列表弹窗组件 |
| `components/OnboardingOverlay.ets` | 首次引导遮罩组件 |
| `components/UpcomingCard.ets` | 近期赛程卡片组件 |

### 修改文件

| 文件 | 变更内容 |
|------|---------|
| `pages/Index.ets` | 集成 4 个功能；球队卡片加点击事件；Tab 顶部加近期赛程卡；「我的」Tab 重构 |
| `services/CalendarWriter.ets` | 新增 `getCalendarEventCount()` 方法 |
| `constants/Teams.ets` | 无变更 |

### 不变文件

- `IcsParser.ets` — 解析逻辑不变
- `DataService.ets` — 数据加载不变
- `TeamStore.ets` — 存储接口不变
- `PrivacyPolicy.ets` — 无变更
- `Changelog.ets` — 无变更
- `module.json5` — 无新权限

## 实现顺序建议

1. **功能 A**（赛程弹窗）— 核心体验增强，数据已有
2. **功能 C**（近期赛程）— 与 A 共享解析逻辑
3. **功能 B**（我的页面）— 独立模块，不影响其他
4. **功能 D**（首次引导）— 最后加，不影响核心流程
