# SportCalendar 应用重构设计

> 日期：2026-05-07
> 目标：拆分单页应用为多页面架构，接入 OBS 数据源，适配深色模式，通过华为应用市场审核

## 1. 背景

华为应用市场以"功能太单一"驳回上架申请。当前应用为单文件 Index.ets（1132 行），所有功能集中在 3 个 Tab 中。同时缺少深色模式适配，部分字号低于 8fp。

## 2. 页面架构

### 2.1 导航结构

底部三 Tab 导航 + 子页面跳转：

```
[首页]         [球队]         [我的]
HomePage       TeamListPage    MyPage
  │                │              │
  └→ MatchDetail   └→ TeamDetail  └→ SettingsPage
                       │
                       └→ MatchDetail
```

### 2.2 页面清单

| 页面 | 路由 | 职责 |
|------|------|------|
| HomePage | `pages/Index` | 近期比赛卡片、推荐关注、数据刷新时间 |
| TeamListPage | `pages/TeamList` | 中超/世界杯 Tab 切换，球队宫格选择 |
| TeamDetailPage | `pages/TeamDetail` | 球队全部赛程列表、比分状态、订阅按钮 |
| MyPage | `pages/My` | 已订阅管理、同步状态、设置入口 |
| SettingsPage | `pages/Settings` | 深色模式开关、隐私协议、版本信息、清除缓存 |
| MatchDetailPage | `pages/MatchDetail` | 单场比赛详情（时间、对阵、地点、状态） |

### 2.3 路由配置

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

### 2.4 文件结构

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets            # HomePage
│   ├── TeamList.ets         # 球队列表页
│   ├── TeamDetail.ets       # 球队详情页
│   ├── My.ets               # 我的订阅页
│   ├── Settings.ets         # 设置页
│   ├── MatchDetail.ets      # 比赛详情页
│   ├── PrivacyPolicy.ets    # 隐私协议（已有）
│   └── Changelog.ets        # 更新日志（已有）
├── components/
│   ├── MatchListSheet.ets   # 保留
│   ├── UpcomingCard.ets     # 保留
│   ├── OnboardingOverlay.ets # 保留
│   ├── PrivacyConsentDialog.ets # 保留
│   ├── MatchCard.ets        # 新增 - 比赛卡片
│   ├── TeamCard.ets         # 新增 - 球队卡片
│   └── TabBar.ets           # 新增 - 底部导航栏
├── services/
│   ├── DataService.ets      # 改造 - OBS + 本地 fallback
│   ├── TeamStore.ets        # 保留
│   ├── IcsParser.ets        # 保留
│   └── CalendarWriter.ets   # 保留
├── constants/
│   └── Teams.ets            # 保留
└── model/
    └── MatchEvent.ets       # 保留
```

## 3. OBS 数据层

### 3.1 数据流

```
sports-calendar.com API
       ↓ (定时脚本拉取)
  华为云 OBS 桶（公共读）
  ├── csl/*.ics
  ├── wc/*.ics
  └── meta.json
       ↓ (应用 HTTP 拉取)
  DataService
  ├── 1. 请求 meta.json，比对本地版本号
  ├── 2. 有更新 → 拉取变化的 .ics 文件
  ├── 3. 缓存到应用沙箱目录
  └── 4. 网络失败 → 读本地 rawfile 兜底
```

### 3.2 meta.json 格式

```json
{
  "version": 2026050701,
  "updated": "2026-05-07T10:00:00+08:00",
  "files": {
    "csl/beijing-guoan.ics": { "size": 15234, "md5": "abc123" },
    "wc/argentina.ics": { "size": 8901, "md5": "def456" }
  }
}
```

### 3.3 DataService 改造

现有 `loadIcs(ctx, path)` 读 rawfile，改造为三级 fallback：

1. 读应用沙箱缓存（上次拉取的数据）
2. 缓存不存在 → HTTP 从 OBS 拉取并缓存
3. 网络失败 → 读 rawfile（打包时内置的数据）

新增方法：
- `fetchMeta(): MetaInfo` — 拉取 meta.json
- `syncIfNeeded(): number` — 比对版本号，按需同步
- `getCachedIcs(ctx, path): string` — 读沙箱缓存

### 3.4 OBS 桶配置

| 配置项 | 值 |
|--------|------|
| 桶策略 | 公共读 |
| 区域 | cn-north-4 |
| CORS | 允许应用域 |
| meta.json 缓存 | 60s |
| ICS 文件缓存 | 默认 |

## 4. 深色模式

### 4.1 策略

利用 HarmonyOS 资源双目录机制：`resources/base/` + `resources/dark/`，系统跟随设备模式自动切换。

### 4.2 颜色资源

**浅色 (base/element/color.json)**：
- `page_bg`: #F5F5F5
- `card_bg`: #FFFFFF
- `text_primary`: #333333
- `text_secondary`: #666666
- `text_hint`: #999999
- `brand_primary`: #1976D2
- `brand_success`: #4CAF50
- `brand_danger`: #FF5252
- `divider`: #F0F0F0
- `card_bg_subscribed`: #E8F5E9

**深色 (dark/element/color.json)**：
- `page_bg`: #1A1A1A
- `card_bg`: #2D2D2D
- `text_primary`: #E5E5E5
- `text_secondary`: #AAAAAA
- `text_hint`: #777777
- `brand_primary`: #64B5F6
- `brand_success`: #81C784
- `brand_danger`: #EF5350
- `divider`: #3D3D3D
- `card_bg_subscribed`: #1B3A1B

### 4.3 代码改造

所有硬编码颜色替换为 `$r('app.color.xxx')`，约 60-80 处。

### 4.4 不适配的部分

- 球队 logo 图片（保持原样）
- 隐私协议 WebView 内容（跟随系统默认）

## 5. 各页面功能详述

### 5.1 HomePage (Index.ets)

- 顶部：应用标题 + 最后刷新时间
- 近期比赛卡片区域（UpcomingCard 复用）
- CSL 热门球队快捷入口（4-6 个）
- 世界杯热门球队快捷入口（4-6 个）
- 底部：数据来源鸣谢

### 5.2 TeamListPage (TeamList.ets)

- 顶部 Tab：中超联赛 / 世界杯
- 球队宫格（复用当前 Flex + ForEach 逻辑）
- 点击球队 → router.pushUrl('pages/TeamDetail', { teamId })
- 底部：订阅/删除按钮栏

### 5.3 TeamDetailPage (TeamDetail.ets)

- 顶部：球队 logo + 名称 + 订阅状态按钮
- 赛程列表（全部轮次，按时间排序）
- 每场比赛卡片：日期、时间、对阵、比分/状态
- 点击比赛 → router.pushUrl('pages/MatchDetail', { matchUid })

### 5.4 MyPage (My.ets)

- 已订阅球队列表（CSL 分组 + 世界杯分组）
- 一键同步按钮
- 一键取消全部订阅
- 上次同步时间
- 设置入口 → router.pushUrl('pages/Settings')

### 5.5 SettingsPage (Settings.ets)

- 深色模式开关（跟随系统 / 手动切换）
- 清除缓存
- 隐私协议 → router.pushUrl('pages/PrivacyPolicy')
- 更新日志 → router.pushUrl('pages/Changelog')
- 版本号

### 5.6 MatchDetailPage (MatchDetail.ets)

- 比赛信息：对阵、时间、轮次
- 状态：未开始 / 进行中 / 已结束（含比分）
- 添加到日历按钮（单场）

## 6. 已完成项

- [x] 隐私政策同意弹窗 (PrivacyConsentDialog.ets)
- [x] 首次引导覆盖层 (OnboardingOverlay.ets)
- [x] 赛程列表弹窗 (MatchListSheet.ets)
- [x] 近期赛程卡片 (UpcomingCard.ets)
- [x] 字号修复（7.5fp → 8fp）
- [x] TeamStore 持久化方法扩展

## 7. 非代码改动（开发者自行处理）

- 更新华为应用市场的应用截图（6 张，对应 6 个页面）
- 更新应用描述和应用介绍，去掉"日历账户"等不准确描述
- 创建华为云 OBS 桶并配置公共读策略
- 编写数据同步脚本（从 sports-calendar.com 拉取 → 上传 OBS）
- 应用上架时备案信息选择"APP服务器在中国大陆"并完成备案
