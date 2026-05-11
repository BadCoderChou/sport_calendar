# SportCalendar 应用重构实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将单页应用拆分为 6 页面架构，接入 OBS 数据源，适配深色模式

**Architecture:** 底部三 Tab（首页/球队/我的）+ 子页面跳转（TeamDetail/MatchDetail/Settings）。DataService 三级 fallback（沙箱缓存 → OBS HTTP → rawfile）。深色模式通过 resources/base + resources/dark 双目录实现。

**Tech Stack:** HarmonyOS NEXT API 6.0.2, ArkTS, @kit.ArkUI (router, Tabs), @kit.NetKit (http)

**Spec:** `docs/superpowers/specs/2026-05-07-app-restructure-design.md`

---

## Phase 1: 基础设施（颜色、权限、数据层）

### Task 1: 深色模式颜色资源

**Files:**
- Modify: `entry/src/main/resources/base/element/color.json`
- Create: `entry/src/main/resources/dark/element/color.json`

- [ ] **Step 1: 创建浅色颜色资源**

`entry/src/main/resources/base/element/color.json`:
```json
{
  "color": [
    { "name": "start_window_background", "value": "#FFFFFF" },
    { "name": "page_bg", "value": "#F5F5F5" },
    { "name": "card_bg", "value": "#FFFFFF" },
    { "name": "card_bg_subscribed", "value": "#E8F5E9" },
    { "name": "text_primary", "value": "#333333" },
    { "name": "text_secondary", "value": "#666666" },
    { "name": "text_hint", "value": "#999999" },
    { "name": "brand_primary", "value": "#1976D2" },
    { "name": "brand_success", "value": "#4CAF50" },
    { "name": "brand_danger", "value": "#FF5252" },
    { "name": "brand_warning", "value": "#FF9800" },
    { "name": "divider_color", "value": "#F0F0F0" },
    { "name": "overlay_bg", "value": "#33000000" },
    { "name": "loading_bg", "value": "#F2FFFFFF" }
  ]
}
```

- [ ] **Step 2: 创建深色颜色资源**

创建目录 `entry/src/main/resources/dark/element/`，写入 `color.json`:
```json
{
  "color": [
    { "name": "start_window_background", "value": "#1A1A1A" },
    { "name": "page_bg", "value": "#1A1A1A" },
    { "name": "card_bg", "value": "#2D2D2D" },
    { "name": "card_bg_subscribed", "value": "#1B3A1B" },
    { "name": "text_primary", "value": "#E5E5E5" },
    { "name": "text_secondary", "value": "#AAAAAA" },
    { "name": "text_hint", "value": "#777777" },
    { "name": "brand_primary", "value": "#64B5F6" },
    { "name": "brand_success", "value": "#81C784" },
    { "name": "brand_danger", "value": "#EF5350" },
    { "name": "brand_warning", "value": "#FFB74D" },
    { "name": "divider_color", "value": "#3D3D3D" },
    { "name": "overlay_bg", "value": "#66000000" },
    { "name": "loading_bg", "value": "#F22D2D2D" }
  ]
}
```

- [ ] **Step 3: 构建验证** — 在 DevEco Studio 中构建确认资源文件无报错

---

### Task 2: INTERNET 权限 + 字符串资源

**Files:**
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/resources/base/element/string.json`

- [ ] **Step 1: 在 module.json5 的 requestPermissions 数组中添加 INTERNET 权限**

在现有 `WRITE_CALENDAR` 权限后添加：
```json5
{
  "name": "ohos.permission.INTERNET",
  "reason": "$string:internet_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
}
```

- [ ] **Step 2: 在 string.json 中添加 internet_reason 字符串**

在现有字符串数组中添加：
```json
{"name": "internet_reason", "value": "用于从云端获取最新赛程数据"}
```

- [ ] **Step 3: 构建验证**

---

### Task 3: OBS 端点常量 + TeamStore 扩展

**Files:**
- Create: `entry/src/main/ets/constants/ApiConfig.ets`
- Modify: `entry/src/main/ets/services/TeamStore.ets`
- Modify: `entry/src/main/ets/model/MatchEvent.ets`

- [ ] **Step 1: 创建 ApiConfig.ets**

```typescript
export const OBS_BASE_URL = 'https://sportcalendar.obs.cn-north-4.myhuaweicloud.com';
export const META_PATH = 'meta.json';
```

- [ ] **Step 2: 在 TeamStore 中添加 OBS 同步版本相关方法**

在 TeamStore 类末尾添加：
```typescript
static async getSyncVersion(): Promise<number> {
  const pref = await TeamStore.getPref();
  const val = await pref.get('syncVersion', 0);
  return val as number;
}

static async setSyncVersion(version: number): Promise<void> {
  const pref = await TeamStore.getPref();
  await pref.put('syncVersion', version);
  await pref.flush();
}

static async getLastDataSyncTime(): Promise<number> {
  const pref = await TeamStore.getPref();
  const val = await pref.get('lastDataSyncTime', 0);
  return val as number;
}

static async setLastDataSyncTime(time: number): Promise<void> {
  const pref = await TeamStore.getPref();
  await pref.put('lastDataSyncTime', time);
  await pref.flush();
}
```

- [ ] **Step 3: 构建验证**

---

### Task 4: DataService OBS 集成

**Files:**
- Modify: `entry/src/main/ets/services/DataService.ets`

- [ ] **Step 1: 重写 DataService，实现三级 fallback**

完整替换 DataService.ets 内容。核心逻辑：
1. `loadIcs(ctx, path)` — 读沙箱缓存 → 缓存无则从 OBS HTTP 拉取 → 失败读 rawfile
2. `fetchMeta()` — HTTP GET meta.json，解析为 MetaInfo
3. `syncIfNeeded(ctx)` — 比对 TeamStore 中的 syncVersion，有更新则下载变化的文件到沙箱
4. `clearCache(ctx)` — 删除沙箱中缓存的 ICS 文件
5. `getCachedIcs(ctx, path)` — 读沙箱文件，无则返回 null

使用 `@kit.NetKit` 的 `http.createHttp()` 发起 GET 请求。
使用 `@kit.ArkUI` 的 `fs`（从 `@kit.CoreFileKit`）读写沙箱文件。

沙箱路径: `${ctx.filesDir}/ics_cache/`

- [ ] **Step 2: 构建验证**

---

## Phase 2: 新页面创建

### Task 5: 路由配置 + Settings 页面

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Create: `entry/src/main/ets/pages/Settings.ets`

- [ ] **Step 1: 更新 main_pages.json**

添加新路由：
```json
{
  "src": [
    "pages/Index",
    "pages/TeamList",
    "pages/TeamDetail",
    "pages/My",
    "pages/Settings",
    "pages/MatchDetail",
    "pages/PrivacyPolicy",
    "pages/Changelog"
  ]
}
```

- [ ] **Step 2: 创建 Settings.ets**

页面内容：
- 顶部导航栏（返回按钮 + 标题"设置"）
- 「系统外观设置」行 → 点击调用 `openAppSettings()`（复用 Index 中已有的跳转逻辑）
- 「清除缓存」行 → 点击调用 `DataService.clearCache(ctx)` + Toast 提示
- 「隐私协议」行 → `router.pushUrl({ url: 'pages/PrivacyPolicy' })`
- 「更新日志」行 → `router.pushUrl({ url: 'pages/Changelog' })`
- 版本号 `v1.1.0`
- 所有颜色使用 `$r('app.color.xxx')`

- [ ] **Step 3: 构建验证**

---

### Task 6: MatchDetail 页面

**Files:**
- Create: `entry/src/main/ets/pages/MatchDetail.ets`

- [ ] **Step 1: 创建 MatchDetail.ets**

从 `router.getParams()` 获取 `teamId` + `matchUid` 参数。
通过 `DataService.loadIcs(ctx, path)` 加载 ICS → `IcsParser.parse()` → 找到 uid 匹配的 MatchEvent。

页面布局：
- 顶部导航栏（返回按钮 + "比赛详情"）
- 对阵信息（event.title，大字号）
- 日期时间（格式化显示）
- 地点（event.location）
- 状态标签：未开始（绿色）/ 已结束（灰色）
- 「添加到日历」按钮 → 请求日历权限 → `CalendarWriter.writeEvents()`
- 所有颜色使用 `$r('app.color.xxx')`

- [ ] **Step 2: 构建验证**

---

### Task 7: TeamDetail 页面

**Files:**
- Create: `entry/src/main/ets/pages/TeamDetail.ets`

- [ ] **Step 1: 创建 TeamDetail.ets**

从 `router.getParams()` 获取 `teamId` 参数。
判断是 CSL 还是 WorldCup 球队（通过 `getTeamById` / `getWorldCupTeamById`）。
加载 ICS 数据：`DataService.loadIcs(ctx, isCsl ? 'csl/${id}.ics' : 'wc/${id}.ics')`。

页面布局：
- 顶部导航栏（返回按钮 + 球队名称）
- 球队信息区：logo/emoji + 名称 + 订阅按钮（切换订阅状态）
- 赛程列表：ForEach 渲染所有 MatchEvent，每条显示日期/时间/对阵/状态
- 点击比赛 → `router.pushUrl({ url: 'pages/MatchDetail', params: { teamId, matchUid: event.uid } })`
- 所有颜色使用 `$r('app.color.xxx')`

- [ ] **Step 2: 构建验证**

---

### Task 8: TeamList 页面

**Files:**
- Create: `entry/src/main/ets/pages/TeamList.ets`

- [ ] **Step 1: 创建 TeamList.ets**

从当前 Index.ets 的 Tab1（中超）和 Tab2（世界杯）中提取逻辑。

页面结构：
- 顶部：标题"选择球队"
- Tab 切换：中超联赛 / 世界杯（用 @State currentLeague 控制）
- 球队宫格：Flex + ForEach，复用 CSL_TEAMS / WORLD_CUP_TEAMS
- 已订阅的球队显示绿色边框 + ✓ 标记
- 点击球队 → `router.pushUrl({ url: 'pages/TeamDetail', params: { teamId } })`
- 底部按钮栏：「订阅所选」+ 「删除日程」（仅当有选中球队时显示）
- 所有颜色使用 `$r('app.color.xxx')`

- [ ] **Step 2: 构建验证**

---

### Task 9: My 页面

**Files:**
- Create: `entry/src/main/ets/pages/My.ets`

- [ ] **Step 1: 创建 My.ets**

从当前 Index.ets 的 Tab3（我的）中提取逻辑。

页面结构：
- 顶部：标题"我的订阅"
- 无订阅时：空状态提示（邮箱图标 + 文字引导）
- 有订阅时：CSL 分组列表 + 世界杯分组列表，每行显示球队名 + "已订阅"
  - 点击 → `router.pushUrl({ url: 'pages/TeamDetail', params: { teamId } })`
- 「刷新赛程数据」按钮 → 调用 `DataService.syncIfNeeded(ctx)` + 重新写入日历
- 「取消全部订阅」按钮 → 删除所有日历 + 清空订阅
- 信息区：上次同步时间、版本号
- 底部：隐私协议 + 更新日志入口
- 设置入口 → `router.pushUrl({ url: 'pages/Settings' })`
- 所有颜色使用 `$r('app.color.xxx')`

- [ ] **Step 2: 构建验证**

---

## Phase 3: 重构首页

### Task 10: 重写 Index.ets 为 HomePage

**Files:**
- Rewrite: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: 重写 Index.ets**

删除当前 1132 行的全部内容。新 HomePage 包含：

- 隐私弹窗（保留现有逻辑：`privacyAgreed` 状态 + `PrivacyConsentDialog`）
- 底部三 Tab 导航：首页 / 球队 / 我的
  - Tab1（首页）：近期比赛 + 热门球队快捷入口
  - Tab2（球队）：使用 `@Builder` 内联 Tab2 内容，嵌入 TeamList 的逻辑
  - Tab3（我的）：使用 `@Builder` 内联 Tab3 内容，嵌入 My 的逻辑

> 注意：Tab2 和 Tab3 仍然内联在 HomePage 中（通过 @Builder），因为 HarmonyOS Tabs 组件要求 TabContent 在同一个 @Component 内。子页面跳转用 router.pushUrl。

首页 Tab 内容：
- 顶部：应用名 + 最后刷新时间
- UpcomingCard（近期比赛，从 DataService 加载）
- 热门球队区域（CSL 4-6 个 + 世界杯 4-6 个），点击 → `router.pushUrl('pages/TeamDetail', { teamId })`
- 鸣谢文字
- 启动时调用 `DataService.syncIfNeeded(ctx)` 静默同步

所有颜色使用 `$r('app.color.xxx')`。

- [ ] **Step 2: 构建验证**

---

## Phase 4: 深色模式颜色替换

### Task 11: 替换所有硬编码颜色

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/TeamList.ets`
- Modify: `entry/src/main/ets/pages/TeamDetail.ets`
- Modify: `entry/src/main/ets/pages/My.ets`
- Modify: `entry/src/main/ets/pages/Settings.ets`
- Modify: `entry/src/main/ets/pages/MatchDetail.ets`
- Modify: `entry/src/main/ets/pages/PrivacyPolicy.ets`
- Modify: `entry/src/main/ets/components/UpcomingCard.ets`
- Modify: `entry/src/main/ets/components/MatchListSheet.ets`
- Modify: `entry/src/main/ets/components/OnboardingOverlay.ets`
- Modify: `entry/src/main/ets/components/PrivacyConsentDialog.ets`

- [ ] **Step 1: 替换 Index.ets 中的硬编码颜色**

替换规则：
- `'#f5f5f5'` / `'#F5F5F5'` → `$r('app.color.page_bg')`
- `'#ffffff'` / `'#FFFFFF'` → `$r('app.color.card_bg')`
- `'#e8f5e9'` → `$r('app.color.card_bg_subscribed')`
- `'#333333'` → `$r('app.color.text_primary')`
- `'#666666'` → `$r('app.color.text_secondary')`
- `'#999999'` / `'#888888'` → `$r('app.color.text_hint')`
- `'#1976d2'` / `'#1976D2'` → `$r('app.color.brand_primary')`
- `'#4caf50'` / `'#4CAF50'` → `$r('app.color.brand_success')`
- `'#ff5252'` / `'#FF5252'` / `'#d32f2f'` → `$r('app.color.brand_danger')`
- `'#ff9800'` → `$r('app.color.brand_warning')`
- `'#f0f0f0'` / `'#F0F0F0'` / `'#f5f5f5'` (分割线) → `$r('app.color.divider_color')`

- [ ] **Step 2: 同样替换所有其他页面和组件中的硬编码颜色**

每个文件逐一替换。约 60-80 处。

- [ ] **Step 3: 构建验证 + 在模拟器中切换深色模式验证显示效果**

---

## Phase 5: 最终集成

### Task 12: 删除不再需要的代码 + 最终构建

**Files:**
- 可能清理: 已提取到独立页面的冗余代码

- [ ] **Step 1: 检查并清理 Index.ets 中已迁移到独立页面的重复逻辑**

确认 Index.ets 的 HomePage 只保留首页逻辑 + Tab 容器 + 隐私弹窗。所有 TeamDetail/MatchDetail/Settings/My 的独立页面功能完整。

- [ ] **Step 2: 完整构建 `assembleHap`**

在 DevEco Studio 中执行 clean build，确保 0 ERROR。

- [ ] **Step 3: 提交所有改动**

```bash
git add -A
git commit -m "feat: 重构为多页面架构 + OBS 数据源 + 深色模式适配"
```

---

## 构建命令

每个 Task 完成后都需验证构建：

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  clean --mode module -p product=default assembleHap \
  --analyze=normal --parallel --incremental --daemon
```

期望输出：`COMPILE RESULT: SUCCESS` 或 `BUILD SUCCESS`。
