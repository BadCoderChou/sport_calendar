# 世界杯订阅功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking。

**Goal:** 在 SportCalendar 应用中新增 2026 世界杯赛程订阅功能，通过 Tabs 切换中超/世界杯两个视图

**Architecture:** 原生 Tabs 组件包裹现有中超内容 + 新增世界杯 Tab。Teams.ets 新增 48 国数据定义，TeamStore.ets 新增 WC 存储 key，Index.ets 重构为双 Tab 布局，CalendarWriter.ets 参数化 service 描述。IcsParser/HttpService 完全复用。

**Tech Stack:** ArkTS (HarmonyOS Next API 6.0.2), ArkUI (Tabs/Flex/Stack), @kit.CalendarKit, Preferences storage

**Spec:** `docs/superpowers/specs/2026-04-28-world-cup-feature-design.md`

---

### Task 1: Teams.ets — 新增世界杯数据定义

**Files:**
- Modify: `entry/src/main/ets/constants/Teams.ets`

- [ ] **Step 1: 新增 WorldCupTeam 接口**

在 `Team` 接口后面添加：

```typescript
export interface WorldCupTeam {
  id: string;       // 如 'brazil', 'argentina'（对应 ICS API 的 team 参数）
  name: string;     // 中文名：'巴西'、'阿根廷'
  emoji: string;    // 国旗 emoji：'🇧🇷'、'🇦🇷'
  isHot: boolean;   // 是否为热门强队（前 12 个置顶显示）
}
```

- [ ] **Step 2: 新增世界杯常量和函数**

在文件末尾（`CALENDAR_NAME_PREFIX` 之后）添加：

```typescript
export const WC_ICS_BASE_URL =
  'https://api.sports-calendar.com/ics/soccer/fifa-world-cup/2026/matches.ics';

export function getWorldCupIcsUrl(countryId: string): string {
  return `${WC_ICS_BASE_URL}?lang=zh&team=${countryId}`;
}

export const WC_CALENDAR_NAME_PREFIX = '世界杯-';
```

- [ ] **Step 3: 新增 WORLD_CUP_TEAMS 数组（48 国）**

完整 48 支球队定义。前 12 个 `isHot: true`，其余 `isHot: false`：

```typescript
export const WORLD_CUP_TEAMS: WorldCupTeam[] = [
  // ===== 热门 12 强 (isHot=true) =====
  { id: 'brazil', name: '巴西', emoji: '🇧🇷', isHot: true },
  { id: 'argentina', name: '阿根廷', emoji: '🇦🇷', isHot: true },
  { id: 'france', name: '法国', emoji: '🇫🇷', isHot: true },
  { id: 'germany', name: '德国', emoji: '🇩🇪', isHot: true },
  { id: 'spain', name: '西班牙', emoji: '🇪🇸', isHot: true },
  { id: 'england', name: '英格兰', emoji: '🇬🇧', isHot: true },
  { id: 'portugal', name: '葡萄牙', emoji: '🇵🇹', isHot: true },
  { id: 'netherlands', name: '荷兰', emoji: '🇳🇱', isHot: true },
  { id: 'usa', name: '美国', emoji: '🇺🇸', isHot: true },       // 东道主
  { id: 'uruguay', name: '乌拉圭', emoji: '🇺🇾', isHot: true },
  { id: 'japan', name: '日本', emoji: '🇯🇵', isHot: true },
  { id: 'south-korea', name: '韩国', emoji: '🇰🇷', isHot: true },

  // ===== 其余 36 国 (isHot=false)，按英文名排序 =====
  // 数据来源: https://sports-calendar.com/zh/soccer/fifa-world-cup/2026/
  // 完整 48 国名单（已去重验证）
  { id: 'algeria', name: '阿尔及利亚', emoji: '🇩🇿', isHot: false },
  { id: 'austria', name: '奥地利', emoji: '🇦🇹', isHot: false },
  { id: 'australia', name: '澳大利亚', emoji: '🇦🇺', isHot: false },
  { id: 'belgium', name: '比利时', emoji: '🇧🇪', isHot: false },
  { id: 'bosnia-herzegovina', name: '波黑', emoji: '🇧🇦', isHot: false },
  { id: 'canada', name: '加拿大', emoji: '🇨🇦', isHot: false },        // 东道主
  { id: 'cape-verde', name: '佛得角', emoji: '🇨🇻', isHot: false },
  { id: 'colombia', name: '哥伦比亚', emoji: '🇨🇴', isHot: false },
  { id: 'costa-rica', name: '哥斯达黎加', emoji: '🇨🇷', isHot: false },
  { id: 'croatia', name: '克罗地亚', emoji: '🇭🇷', isHot: false },
  { id: 'curacao', name: '库拉索', emoji: '🇨🇼', isHot: false },
  { id: 'czech-republic', name: '捷克', emoji: '🇨🇿', isHot: false },
  { id: 'denmark', name: '丹麦', emoji: '🇩🇰', isHot: false },
  { id: 'dr-congo', name: '民主刚果', emoji: '🇨🇩', isHot: false },
  { id: 'ecuador', name: '厄瓜多尔', emoji: '🇪🇨', isHot: false },
  { id: 'egypt', name: '埃及', emoji: '🇪🇬', isHot: false },
  { id: 'ghana', name: '加纳', emoji: '🇬🇭', isHot: false },
  { id: 'haiti', name: '海地', emoji: '🇭🇹', isHot: false },
  { id: 'iran', name: '伊朗', emoji: '🇮🇷', isHot: false },
  { id: 'iraq', name: '伊拉克', emoji: '🇮🇶', isHot: false },
  { id: 'ivory-coast', name: '科特迪瓦', emoji: '🇨🇮', isHot: false },
  { id: 'jamaica', name: '牙买加', emoji: '🇯🇲', isHot: false },
  { id: 'jordan', name: '约旦', emoji: '🇯🇴', isHot: false },
  { id: 'mexico', name: '墨西哥', emoji: '🇲🇽', isHot: false },      // 东道主
  { id: 'morocco', name: '摩洛哥', emoji: '🇲🇦', isHot: false },
  { id: 'new-zealand', name: '新西兰', emoji: '🇳🇿', isHot: false },
  { id: 'nigeria', name: '尼日利亚', emoji: '🇳🇬', isHot: false },
  { id: 'norway', name: '挪威', emoji: '🇳🇴', isHot: false },
  { id: 'oman', name: '阿曼', emoji: '🇴🇲', isHot: false },
  { id: 'panama', name: '巴拿马', emoji: '🇵🇦', isHot: false },
  { id: 'paraguay', name: '巴拉圭', emoji: '🇵🇾', isHot: false },
  { id: 'peru', name: '秘鲁', emoji: '🇵🇪', isHot: false },
  { id: 'poland', name: '波兰', emoji: '🇵🇱', isHot: false },
  { id: 'qatar', name: '卡塔尔', emoji: '🇶🇦', isHot: false },         // 东道主
  { id: 'saudi-arabia', name: '沙特阿拉伯', emoji: '🇸🇦', isHot: false },
  { id: 'scotland', name: '苏格兰', emoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿', isHot: false },
  { id: 'senegal', name: '塞内加尔', emoji: '🇸🇳', isHot: false },
  { id: 'serbia', name: '塞尔维亚', emoji: '🇷🇸', isHot: false },
  { id: 'south-africa', name: '南非', emoji: '🇿🇦', isHot: false },
  { id: 'sweden', name: '瑞典', emoji: '🇸🇪', isHot: false },
  { id: 'switzerland', name: '瑞士', emoji: '🇨🇭', isHot: false },
  { id: 'tunisia', name: '突尼斯', emoji: '🇹🇳', isHot: false },
  { id: 'turkey', name: '土耳其', emoji: '🇹🇷', isHot: false },
  { id: 'ukraine', name: '乌克兰', emoji: '🇺🇦', isHot: false },
  { id: 'uzbekistan', name: '乌兹别克斯坦', emoji: '🇺🇿', isHot: false },
  { id: 'wales', name: '威尔士', emoji: '🏴󠁧󠁢󠁷󠁬󠁳󠁿', isHot: false },
];
// 总计: 12 + 36 = 48 国 ✅
```

> **Emoji 兼容性说明**: England/Scotland/Wales 使用区域指示符 emoji（多码点序列），部分 HarmonyOS 设备可能渲染为字母圆圈。如遇此情况可改用纯文本国旗缩写（ENG/SCO/WAL）作为 fallback。实现时需在真机/模拟器上验证。

- [ ] **Step 4: 新增辅助函数**

```typescript
export function getWorldCupTeamById(id: string): WorldCupTeam | undefined {
  return WORLD_CUP_TEAMS.find(t => t.id === id);
}
```

- [ ] **Step 5: 验证编译**

在 DevEco Studio 中 Build → Make Project，确认 Teams.ets 无语法错误。

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/constants/Teams.ets
git commit -m "feat: 新增世界杯 48 国数据定义 (WorldCupTeam / WORLD_CUP_TEAMS)"
```

---

### Task 2: TeamStore.ets — 新增世界杯存储方法

**Files:**
- Modify: `entry/src/main/ets/services/TeamStore.ets`

- [ ] **Step 1: 新增世界杯订阅 ID 存取方法**

在 `toggleSubscription()` 方法之后添加：

```typescript
// --- World Cup subscription state ---

static async getWcSubscribedIds(): Promise<string[]> {
  const pref = await TeamStore.getPref();
  const json = await pref.get('wc_subscribedIds', '[]');
  return JSON.parse(json as string) as string[];
}

static async setWcSubscribedIds(ids: string[]): Promise<void> {
  const pref = await TeamStore.getPref();
  await pref.put('wc_subscribedIds', JSON.stringify(ids));
  await pref.flush();
}

static async toggleWcSubscription(countryId: string): Promise<boolean> {
  const ids = await TeamStore.getWcSubscribedIds();
  const index = ids.indexOf(countryId);
  if (index >= 0) {
    ids.splice(index, 1);
  } else {
    ids.push(countryId);
  }
  await TeamStore.setWcSubscribedIds(ids);
  return index < 0;
}

static async isWcSubscribed(countryId: string): Promise<boolean> {
  const ids = await TeamStore.getWcSubscribedIds();
  return ids.includes(countryId);
}
```

- [ ] **Step 2: 新增世界杯同步时间存取方法**

在上述方法之后添加：

```typescript
static async getWcLastSyncTime(): Promise<number> {
  const pref = await TeamStore.getPref();
  const val = await pref.get('wc_lastSyncTime', 0);
  return val as number;
}

static async setWcLastSyncTime(time: number): Promise<void> {
  const pref = await TeamStore.getPref();
  await pref.put('wc_lastSyncTime', time);
  await pref.flush();
}
```

> 注意: `setLastSyncCount` 和 `getLastSyncCount` 已是通用的（接受任意 teamId 参数），世界杯复用即可，无需新增 WC 版本。

- [ ] **Step 3: 验证编译**

Build → Make Project，确认无错误。

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/services/TeamStore.ets
git commit -m "feat: TeamStore 新增世界杯订阅状态存储方法"
```

---

### Task 3: CalendarWriter.ets — 参数化 service 描述

**Files:**
- Modify: `entry/src/main/ets/services/CalendarWriter.ets`

- [ ] **Step 1: writeEvents 方法新增 serviceDesc 可选参数**

修改 `writeEvents` 方法签名和内部调用：

```typescript
// 修改前 (第63行)
static async writeEvents(team: Team, events: MatchEvent[]): Promise<number> {

// 修改后
static async writeEvents(team: Team, events: MatchEvent[], serviceDesc?: string): Promise<number> {
```

方法体内部的 `writeOrUpdateEvent` 调用也需要传入 `serviceDesc`：

```typescript
// 修改前 (第75行)
await CalendarWriter.writeOrUpdateEvent(calendar, team.id, event);

// 修改后
await CalendarWriter.writeOrUpdateEvent(calendar, team.id, event, serviceDesc);
```

- [ ] **Step 2: writeOrUpdateEvent 方法新增 serviceDesc 参数**

```typescript
// 修改前 (第180行)
private static async writeOrUpdateEvent(
  calendar: calendarManager.Calendar,
  teamId: string,
  event: MatchEvent,
): Promise<void> {

// 修改后
private static async writeOrUpdateEvent(
  calendar: calendarManager.Calendar,
  teamId: string,
  event: MatchEvent,
  serviceDesc?: string,
): Promise<void> {
```

将两处硬编码的 `'中超联赛赛程'` 替换为参数：

```typescript
// 更新事件 (第199-203行) — 修改前:
service: {
  type: calendarManager.ServiceType.SPORTS_EVENTS,
  uri: '',
  description: '中超联赛赛程',
},

// 修改后:
service: {
  type: calendarManager.ServiceType.SPORTS_EVENTS,
  uri: '',
  description: serviceDesc || '中超联赛赛程',
},
```

新创建事件处（第227-231行）同样替换：

```typescript
service: {
  type: calendarManager.ServiceType.SPORTS_EVENTS,
  uri: '',
  description: serviceDesc || '中超联赛赛程',
},
```

- [ ] **Step 3: 验证编译**

Build → Make Project，确认无错误。中超原有调用路径不受影响（不传 serviceDesc 则默认 `'中超联赛赛程'`）。

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/services/CalendarWriter.ets
git commit -m "feat: CalendarWriter 参数化 serviceDescription 支持世界杯"
```

---

### Task 4: Index.ets — Tabs 重构 + 世界杯 UI（核心任务）

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

这是最大的改动，分多个子步骤完成。

- [ ] **Step 1: 新增 import**

在文件顶部 import 区域追加：

```typescript
import { WorldCupTeam, WORLD_CUP_TEAMS, getWorldCupIcsUrl, WC_CALENDAR_NAME_PREFIX } from '../constants/Teams';
```

- [ ] **Step 2: 新增世界杯状态变量**

在 `@State lastSyncTime: number = 0;` 之后添加：

```typescript
@State currentTab: number = 0;
@State subscribedWcIds: string[] = [];
@State wcExpanded: boolean = false;
@State wcSyncing: boolean = false;
@State wcLastSyncTime: number = 0;
```

- [ ] **Step 3: 修改 loadSubscriptionState 方法**

在现有 `loadSubscriptionState()` 末尾（`this.lastSyncTime = ...` 之后）追加加载世界杯状态：

```typescript
// Load World Cup subscription state
try {
  let wcIds = await TeamStore.getWcSubscribedIds();
  this.subscribedWcIds = wcIds;
  this.wcLastSyncTime = await TeamStore.getWcLastSyncTime();
} catch (e) {
  const error = e as Error;
  hilog.error(DOMAIN, 'SportCalendar', 'Failed to load WC state: %{public}s', JSON.stringify(error));
}
```

- [ ] **Step 4: 新增世界杯交互方法**

在 `requestCalendarPermission()` 方法之前添加以下方法：

```typescript
async onWcTeamTap(countryId: string): Promise<void> {
  if (this.wcSyncing) return;

  const country = WORLD_CUP_TEAMS.find(t => t.id === countryId);
  if (!country) return;

  const wasSubscribed = this.subscribedWcIds.includes(countryId);

  if (wasSubscribed) {
    try {
      await this.requestCalendarPermission();
      // 构造临时 Team 对象用于删除日历（CalendarWriter 只需要 id 和 name）
      await CalendarWriter.deleteCalendar({ id: country.id, name: country.name, color: '', logo: '' } as Team);
    } catch (e) {
      hilog.warn(DOMAIN, 'SportCalendar', 'Delete WC calendar on untap failed: %{public}s', JSON.stringify(e));
    }
  }

  const added = await TeamStore.toggleWcSubscription(countryId);
  // 局部更新状态，避免每次点击都全量重载（loadSubscriptionState 会读 CSL + WC + legacy migration）
  if (added) {
    this.subscribedWcIds = this.subscribedWcIds.concat(countryId);
  } else {
    this.subscribedWcIds = this.subscribedWcIds.filter(id => id !== countryId);
  }

  const isNowSubscribed = added;
  promptAction.showToast({
    message: isNowSubscribed ? `已选择${country.name}` : `已取消选择${country.name}`,
    duration: 1500,
    alignment: Alignment.Center,
  });
}

async onWcDeleteAllTap(): Promise<void> {
  if (this.wcSyncing || this.subscribedWcIds.length === 0) return;

  await this.requestCalendarPermission();

  try {
    for (const countryId of this.subscribedWcIds) {
      const country = WORLD_CUP_TEAMS.find(t => t.id === countryId);
      if (country) {
        await CalendarWriter.deleteCalendar({ id: country.id, name: country.name, color: '', logo: '' } as Team);
      }
    }
    await TeamStore.setWcSubscribedIds([]);
    await this.loadSubscriptionState();
    promptAction.showToast({ message: '已删除选中国家的赛程日历', duration: 2000, alignment: Alignment.Center });
  } catch (e) {
    const error = e as Error;
    hilog.error(DOMAIN, 'SportCalendar', 'WC DeleteAll failed: %{public}s', JSON.stringify(error));
    promptAction.showToast({ message: '删除失败，请重试', duration: 2000, alignment: Alignment.Center });
  }
}

async onWcSubscribeTap(): Promise<void> {
  if (this.wcSyncing || this.subscribedWcIds.length === 0) return;

  await this.requestCalendarPermission();

  this.wcSyncing = true;
  let totalImported = 0;

  try {
    for (const countryId of this.subscribedWcIds) {
      const country = WORLD_CUP_TEAMS.find(t => t.id === countryId);
      if (!country) continue;

      try {
        const url = getWorldCupIcsUrl(countryId);
        const icsText = await HttpService.fetchIcs(url);
        const events = IcsParser.parse(icsText);
        // 传入临时 Team 对象 + 世界杯 service 描述
        const count = await CalendarWriter.writeEvents(
          { id: country.id, name: country.name, color: '', logo: '' } as Team,
          events,
          '世界杯赛程'
        );
        await TeamStore.setLastSyncCount(countryId, count);
        totalImported += count;
      } catch (e) {
        hilog.error(DOMAIN, 'SportCalendar', 'WC Sync failed for %{public}s: %{public}s',
          countryId, JSON.stringify(e));
      }
    }

    const now = Date.now();
    await TeamStore.setWcLastSyncTime(now);
    this.wcLastSyncTime = now;

    promptAction.showToast({ message: `已订阅 ${totalImported} 场比赛`, duration: 2000, alignment: Alignment.Center });
  } catch (e) {
    hilog.error(DOMAIN, 'SportCalendar', 'WC Subscribe error: %{public}s', JSON.stringify(e));
    promptAction.showToast({ message: '订阅失败，请检查网络后重试', duration: 2000, alignment: Alignment.Center });
  } finally {
    this.wcSyncing = false;
  }
}

toggleWcExpand(): void {
  this.wcExpanded = !this.wcExpanded;
}
```

- [ ] **Step 5: 新增世界杯辅助方法**

在 `isTeamSubscribed()` 之后添加：

```typescript
isWcCountrySubscribed(countryId: string): boolean {
  return this.subscribedWcIds.includes(countryId);
}

getWcSubscribedNames(): string {
  let names: string[] = [];
  for (const id of this.subscribedWcIds) {
    const found = WORLD_CUP_TEAMS.find(t => t.id === id);
    if (found && found.name) {
      names.push(found.name);
    }
  }
  return names.join('、');
}

formatWcLastSyncTime(): string {
  if (!this.wcLastSyncTime) return '尚未同步';
  const date = new Date(this.wcLastSyncTime);
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  return `${month}-${day} ${hour}:${min}`;
}
```

- [ ] **Step 6: 重构 build() 方法 — 用 Tabs 包裹**

将整个现有 `build()` 内容包裹进 `Tabs` 组件结构。核心变更：

```typescript
build() {
  Stack() {
    Tabs({ index: this.currentTab, barPosition: BarPosition.Start, animationDuration: 200 }) {
      // --- Tab 1: 中超联赛 ---
      TabContent() {
        // 【现有全部内容原封不动搬入此处】
        Column() {
          // Header (不变)
          Column() { ... }.width('100%').alignItems(HorizontalAlign.Center)

          // Team Grid (不变)
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(CSL_TEAMS, (team: Team) => { ... })
          }.padding({ left: 12, right: 12 })

          // Attribution (不变)
          Text('鸣谢：...') ...
          Text('球队按拼音排序') ...

          // Sync Bar (不变)
          Row() { Button('订阅日程') ... Button('删除日程') ... }
        }
        .width('100%').height('100%').backgroundColor('#f5f5f5')
      }
      .tabBar(this.cslTabBar)

      // --- Tab 2: 世界杯 ---
      TabContent() {
        Column() {
          // WC Header
          Column() {
            Text('2026 世界杯赛程日历')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 8, bottom: 1 })
            Text('选择国家 → 订阅日程')
              .fontSize(10)
              .fontColor('#888888')
              .margin({ bottom: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // Hot Countries Grid (3 columns)
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(WORLD_CUP_TEAMS.filter(t => t.isHot), (country: WorldCupTeam) => {
              Stack() {
                Column() {
                  Text(country.emoji)
                    .fontSize(20)
                  Text(country.name)
                    .fontSize(7.5)
                    .fontColor(this.isWcCountrySubscribed(country.id) ? '#2e7d32' : '#333333')
                    .fontWeight(this.isWcCountrySubscribed(country.id) ? FontWeight.Medium : FontWeight.Regular)
                    .maxLines(1)
                    .textAlign(TextAlign.Center)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                if (this.isWcCountrySubscribed(country.id)) {
                  Text('\u2713')
                    .fontSize(10)
                    .fontColor('#ffffff')
                    .fontWeight(FontWeight.Bold)
                    .width(16)
                    .height(16)
                    .borderRadius(8)
                    .backgroundColor('#4caf50')
                    .textAlign(TextAlign.Center)
                    .position({ x: '100%', y: 0 })
                    .translate({ x: '-50%', y: '-25%' })
                    .zIndex(10)
                }
              }
              .width('32%')
              .height(52)
              .margin(2)
              .padding(3)
              .backgroundColor(this.isWcCountrySubscribed(country.id) ? '#e8f5e9' : '#ffffff')
              .borderRadius(6)
              .border(this.isWcCountrySubscribed(country.id) ? { width: 1.5, color: '#4caf50' } : { width: 0 })
              .shadow(this.isWcCountrySubscribed(country.id) ? { radius: 2, color: '#4caf5020' } : { radius: 2, color: '#0000000D' })
              .onClick(() => this.onWcTeamTap(country.id))
            }, (country: WorldCupTeam) => country.id)
          }
          .padding({ left: 8, right: 8 })

          // Expand/Collapse button
          Row() {
            Text(this.wcExpanded ? '▲ 收起' : '▼ 展开全部 48 个国家')
              .fontSize(9)
              .fontColor('#666666')
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 2, bottom: 2 })
          .onClick(() => this.toggleWcExpand())

          // All Countries Grid (conditional - only when expanded)
          if (this.wcExpanded) {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(WORLD_CUP_TEAMS.filter(t => !t.isHot), (country: WorldCupTeam) => {
                Stack() {
                  Column() {
                    Text(country.emoji)
                      .fontSize(18)
                    Text(country.name)
                      .fontSize(7)
                      .fontColor(this.isWcCountrySubscribed(country.id) ? '#2e7d32' : '#333333')
                      .maxLines(1)
                      .textAlign(TextAlign.Center)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)

                  if (this.isWcCountrySubscribed(country.id)) {
                    Text('\u2713')
                      .fontSize(9)
                      .fontColor('#ffffff')
                      .fontWeight(FontWeight.Bold)
                      .width(14)
                      .height(14)
                      .borderRadius(7)
                      .backgroundColor('#4caf50')
                      .textAlign(TextAlign.Center)
                      .position({ x: '100%', y: 0 })
                      .translate({ x: '-50%', y: '-25%' })
                      .zIndex(10)
                  }
                }
                .width('32%')
                .height(48)
                .margin(2)
                .padding(2)
                .backgroundColor(this.isWcCountrySubscribed(country.id) ? '#e8f5e9' : '#ffffff')
                .borderRadius(5)
                .border(this.isWcCountrySubscribed(country.id) ? { width: 1.5, color: '#4caf50' } : { width: 0 })
                .onClick(() => this.onWcTeamTap(country.id))
              }, (country: WorldCupTeam) => country.id)
            }
            .padding({ left: 8, right: 8 })
          }

          // WC Sync Bar
          Row() {
            if (!this.wcSyncing) {
              Button(this.subscribedWcIds.length === 0 ? '请先选择国家' : '订阅日程')
                .type(ButtonType.Normal)
                .backgroundColor(this.subscribedWcIds.length === 0 ? '#cccccc' : '#1976d2')
                .fontColor(Color.White)
                .borderRadius(14)
                .height(26)
                .fontSize(10)
                .enabled(this.subscribedWcIds.length > 0)
                .onClick(() => this.onWcSubscribeTap())
            }

            if (this.subscribedWcIds.length > 0 && !this.wcSyncing) {
              Button('删除日程')
                .type(ButtonType.Normal)
                .backgroundColor('#ff5252')
                .fontColor(Color.White)
                .borderRadius(14)
                .height(26)
                .fontSize(10)
                .margin({ left: 6 })
                .onClick(() => this.onWcDeleteAllTap())
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 2, bottom: 6 })

          Text('数据源：sports-calendar.com')
            .fontSize(7)
            .fontColor('#cccccc')
            .textAlign(TextAlign.Center)
            .margin({ top: 0, bottom: 2 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#f5f5f5')
      }
      .tabBar(this.wcTabBar)
    }

    // Loading overlay (shared between tabs)
    if (this.syncing || this.wcSyncing) {
      Column() {
        LoadingProgress()
          .width(28)
          .height(28)
          .color('#1976d2')

        Text('正在同步赛程...')
          .fontSize(13)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 10 })

        Text(this.currentTab === 0 ? this.getSubscribedNames() : this.getWcSubscribedNames())
          .fontSize(10)
          .fontColor('#888888')
          .margin({ top: 3 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('75%')
          .textAlign(TextAlign.Center)
      }
      .width(180)
      .padding({ top: 24, bottom: 20, left: 20, right: 20 })
      .backgroundColor('rgba(255,255,255,0.95)')
      .borderRadius(14)
      .shadow({ radius: 18, color: '#00000030', offsetX: 0, offsetY: 6 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {})
    }
  }
  .width('100%')
  .height('100%')
}

// Tab bar builders
@Builder
cslTabBar() {
  Column() {
    Text('中超联赛')
      .fontSize(11)
      .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.currentTab === 0 ? '#1976d2' : '#999999')
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

@Builder
wcTabBar() {
  Column() {
    Text('🏆 世界杯')
      .fontSize(11)
      .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.currentTab === 1 ? '#1976d2' : '#999999')
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}
```

- [ ] **Step 7: 修复预存的重复 fontSize bug**

删除 Index.ets 第 269 行重复的 `.fontSize(8)` 调用（该行与第 260 行的 `.fontSize(8)` 重复）。

- [ ] **Step 8: 验证编译**

Build → Make Project，重点检查：
- Tabs/TabContent 语法正确
- ForEach 泛型类型匹配（WorldCupTeam）
- @Builder 方法定义位置正确（struct 内部）
- 无重复声明或未使用变量

- [ ] **Step 9: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: 新增世界杯 Tab — 48国订阅/emoji国旗/热门折叠/Tabs导航"
```

---

### Task 5: README.md — 更新文档

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 更新功能特性列表**

在现有 `- **16 支球队赛程**` 之前添加：

```markdown
- **世界杯订阅** — 2026 世界杯 48 支参赛国赛程，热门 12 强置顶 + 全部展开，以国家维度独立订阅
- **双 Tab 切换** — 中超联赛 / 世界杯独立视图，各自独立的订阅状态和日历管理
```

更新描述首句：

```markdown
基于 **HarmonyOS Next（API 6.0.2）** 的 Stage 模型运动日历应用，支持 **中超联赛** 和 **2026 世界杯** 赛程一键订阅到系统日历。
```

- [ ] **Step 2: 更新项目结构树**

在 `pages/` 下增加说明：

```
│   │   │   └── pages/
│   │   │       └── Index.ets           # 主页面（Tabs: 中超 | 世界杯）
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: README 新增世界杯功能说明"
```

---

## 实现顺序总览

| 任务 | 文件 | 依赖 |
|------|------|------|
| Task 1 | Teams.ets | 无 |
| Task 2 | TeamStore.ets | Task 1 |
| Task 3 | CalendarWriter.ets | 无（可并行于 Task 1/2） |
| Task 4 | Index.ets | Task 1 + 2 + 3 |
| Task 5 | README.md | Task 4 |

Task 3 可与 Task 1/2 并行执行。
