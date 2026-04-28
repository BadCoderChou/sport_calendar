import { Team, CSL_TEAMS, getIcsUrl, WorldCupTeam, WORLD_CUP_TEAMS, getWorldCupIcsUrl, WC_CALENDAR_NAME_PREFIX } from '../constants/Teams';
import { IcsParser } from '../services/IcsParser';
import { HttpService } from '../services/HttpService';
import { CalendarWriter } from '../services/CalendarWriter';
import { TeamStore } from '../services/TeamStore';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State subscribedIds: string[] = [];
  @State syncing: boolean = false;
  @State lastSyncTime: number = 0;
  @State currentTab: number = 0;
  @State subscribedWcIds: string[] = [];
  @State wcExpanded: boolean = false;
  @State wcSyncing: boolean = false;
  @State wcLastSyncTime: number = 0;

  aboutToAppear(): void {
    this.loadSubscriptionState();
  }

  aboutToDisappear(): void {
    HttpService.destroy();
  }

  async loadSubscriptionState(): Promise<void> {
    try {
      let ids = await TeamStore.getSubscribedIds();
      // Migrate legacy team IDs to current IDs
      const LEGACY_ID_MAP: Record<string, string> = {
        'shanghai-haipo': 'shanghai-port',
        'zhejiang-club': 'zhejiang-professional',
        'tianjin-jinmenhu': 'tianjin-jinmen-tiger',
        'henan-club': 'henan-fc',
        'shenzhen-xinpengcheng': 'shenzhen-peng-city',
      };
      let migrated = false;
      for (let i = 0; i < ids.length; i++) {
        const newId = LEGACY_ID_MAP[ids[i]];
        if (newId) {
          ids[i] = newId;
          migrated = true;
        }
      }
      if (migrated) {
        await TeamStore.setSubscribedIds(ids);
      }
      this.subscribedIds = ids;
      this.lastSyncTime = await TeamStore.getLastSyncTime();

      // Load World Cup subscription state
      try {
        let wcIds = await TeamStore.getWcSubscribedIds();
        this.subscribedWcIds = wcIds;
        this.wcLastSyncTime = await TeamStore.getWcLastSyncTime();
      } catch (e) {
        const error = e as Error;
        hilog.error(DOMAIN, 'SportCalendar', 'Failed to load WC state: %{public}s', JSON.stringify(error));
      }
    } catch (e) {
      const error = e as Error;
      hilog.error(DOMAIN, 'SportCalendar', 'Failed to load state: %{public}s', JSON.stringify(error));
    }
  }

  async onTeamTap(teamId: string): Promise<void> {
    if (this.syncing) return;

    const team = CSL_TEAMS.find(t => t.id === teamId);
    if (!team) return;

    const wasSubscribed = this.subscribedIds.includes(teamId);

    // If untapping a subscribed team, delete its calendar first
    if (wasSubscribed) {
      try {
        await this.requestCalendarPermission();
        await CalendarWriter.deleteCalendar(team);
      } catch (e) {
        hilog.warn(DOMAIN, 'SportCalendar', 'Delete calendar on untap failed: %{public}s', JSON.stringify(e));
      }
    }

    await TeamStore.toggleSubscription(teamId);
    await this.loadSubscriptionState();

    const isNowSubscribed = this.subscribedIds.includes(teamId);
    promptAction.showToast({
      message: isNowSubscribed ? `已选择${team.name}` : `已取消选择${team.name}`,
      duration: 1500,
      alignment: Alignment.Center,
    });
  }

  async onDeleteAllTap(): Promise<void> {
    if (this.syncing || this.subscribedIds.length === 0) return;

    hilog.info(DOMAIN, 'SportCalendar', 'onDeleteAllTap: subscribedIds=%{public}s', JSON.stringify(this.subscribedIds));
    await this.requestCalendarPermission();
    hilog.info(DOMAIN, 'SportCalendar', 'onDeleteAllTap: permission requested, proceeding...');

    try {
      for (const teamId of this.subscribedIds) {
        const team = CSL_TEAMS.find(t => t.id === teamId);
        if (team) {
          hilog.info(DOMAIN, 'SportCalendar', 'onDeleteAllTap: deleting calendar for %{public}s', team.name);
          await CalendarWriter.deleteCalendar(team);
          hilog.info(DOMAIN, 'SportCalendar', 'onDeleteAllTap: deleted %{public}s OK', team.name);
        }
      }
      await TeamStore.setSubscribedIds([]);
      await this.loadSubscriptionState();
      promptAction.showToast({ message: '已删除选中球队的赛程日历', duration: 2000, alignment: Alignment.Center });
    } catch (e) {
      const error = e as Error;
      hilog.error(DOMAIN, 'SportCalendar', 'DeleteAll failed: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '删除失败，请重试', duration: 2000, alignment: Alignment.Center });
    }
  }

  async onSubscribeTap(): Promise<void> {
    if (this.syncing || this.subscribedIds.length === 0) return;

    await this.requestCalendarPermission();

    this.syncing = true;
    let totalImported = 0;

    try {
      for (const teamId of this.subscribedIds) {
        const team = CSL_TEAMS.find(t => t.id === teamId);
        if (!team) continue;

        try {
          const url = getIcsUrl(teamId);
          const icsText = await HttpService.fetchIcs(url);
          const events = IcsParser.parse(icsText);
          const count = await CalendarWriter.writeEvents(team, events);
          await TeamStore.setLastSyncCount(teamId, count);
          totalImported += count;
        } catch (e) {
          hilog.error(DOMAIN, 'SportCalendar', 'Sync failed for %{public}s: %{public}s',
            teamId, JSON.stringify(e));
        }
      }

      const now = Date.now();
      await TeamStore.setLastSyncTime(now);
      this.lastSyncTime = now;

      promptAction.showToast({ message: `已订阅 ${totalImported} 场比赛`, duration: 2000, alignment: Alignment.Center });
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Subscribe error: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '订阅失败，请检查网络后重试', duration: 2000, alignment: Alignment.Center });
    } finally {
      this.syncing = false;
    }
  }

  async onWcTeamTap(countryId: string): Promise<void> {
    if (this.wcSyncing) return;

    const country = WORLD_CUP_TEAMS.find(t => t.id === countryId);
    if (!country) return;

    const wasSubscribed = this.subscribedWcIds.includes(countryId);

    if (wasSubscribed) {
      try {
        await this.requestCalendarPermission();
        await CalendarWriter.deleteCalendar({ id: country.id, name: country.name, color: '', logo: '' } as Team);
      } catch (e) {
        hilog.warn(DOMAIN, 'SportCalendar', 'Delete WC calendar on untap failed: %{public}s', JSON.stringify(e));
      }
    }

    const added = await TeamStore.toggleWcSubscription(countryId);
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

  async requestCalendarPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(getContext(),
        ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']);
      hilog.info(DOMAIN, 'SportCalendar',
        'Permission result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const error = e as Error;
      hilog.error(DOMAIN, 'SportCalendar', 'Permission request failed: %{public}s', JSON.stringify(error));
    }
  }

  formatLastSyncTime(): string {
    if (!this.lastSyncTime) return '尚未同步';
    const date = new Date(this.lastSyncTime);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const min = String(date.getMinutes()).padStart(2, '0');
    return `${month}-${day} ${hour}:${min}`;
  }

  getSubscribedNames(): string {
    let names: string[] = [];
    for (const id of this.subscribedIds) {
      const found = CSL_TEAMS.find(t => t.id === id);
      if (found && found.name) {
        names.push(found.name);
      }
    }
    return names.join('、');
  }

  isTeamSubscribed(teamId: string): boolean {
    return this.subscribedIds.includes(teamId);
  }

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

  build() {
    Stack() {
      Tabs({ index: this.currentTab, barPosition: BarPosition.End }) {
        // --- Tab 1: 中超联赛 ---
        TabContent() {
          Scroll() {
            Column() {
            // Header (不变)
            Column() {
              Text('中超联赛赛程日历')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 8, bottom: 1 })
              Text('选择球队 → 订阅日程 / 删除日程')
                .fontSize(10)
                .fontColor('#888888')
                .margin({ bottom: 6 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            // Team Grid (不变)
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(CSL_TEAMS, (team: Team) => {
                Stack() {
                  Column() {
                    Image(team.logo)
                      .width(32)
                      .height(32)
                      .objectFit(ImageFit.Contain)
                      .margin({ bottom: 2 })

                    Text(team.name)
                      .fontSize(9)
                      .fontColor(this.isTeamSubscribed(team.id) ? '#2e7d32' : '#333333')
                      .fontWeight(this.isTeamSubscribed(team.id) ? FontWeight.Medium : FontWeight.Regular)
                      .maxLines(1)
                      .textAlign(TextAlign.Center)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)

                  if (this.isTeamSubscribed(team.id)) {
                    Text('\u2713')
                      .fontSize(11)
                      .fontColor('#ffffff')
                      .fontWeight(FontWeight.Bold)
                      .width(18)
                      .height(18)
                      .borderRadius(9)
                      .backgroundColor('#4caf50')
                      .textAlign(TextAlign.Center)
                      .position({ x: '100%', y: 0 })
                      .translate({ x: '-50%', y: '-25%' })
                      .zIndex(10)
                  }
                }
                .width('45%')
                .height(62)
                .margin(4)
                .padding(4)
                .backgroundColor(this.isTeamSubscribed(team.id) ? '#e8f5e9' : '#ffffff')
                .borderRadius(8)
                .border(this.isTeamSubscribed(team.id) ? { width: 2, color: '#4caf50' } : { width: 0 })
                .shadow(this.isTeamSubscribed(team.id) ? { radius: 3, color: '#4caf5020' } : { radius: 3, color: '#0000000D' })
                .onClick(() => this.onTeamTap(team.id))
              }, (team: Team) => team.id)
            }
            .padding({ left: 12, right: 12 })

            // Attribution
            Text('鸣谢：fclogo.top 提供球队 logo | sports-calendar.com 提供赛程赛果')
              .fontSize(8)
              .fontColor('#bbbbbb')
              .textAlign(TextAlign.Center)
              .margin({ top: 2, bottom: 0 })
            Text('球队按拼音排序')
              .fontSize(7)
              .fontColor('#cccccc')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 4 })

            // Sync Bar
            Row() {
              if (!this.syncing) {
                Button(this.subscribedIds.length === 0 ? '请先选择球队' : '订阅日程')
                  .type(ButtonType.Normal)
                  .backgroundColor(this.subscribedIds.length === 0 ? '#cccccc' : '#1976d2')
                  .fontColor(Color.White)
                  .borderRadius(14)
                  .height(28)
                  .fontSize(11)
                  .enabled(this.subscribedIds.length > 0)
                  .onClick(() => this.onSubscribeTap())
              }

              if (this.subscribedIds.length > 0 && !this.syncing) {
                Button('删除日程')
                  .type(ButtonType.Normal)
                  .backgroundColor('#ff5252')
                  .fontColor(Color.White)
                  .borderRadius(14)
                  .height(28)
                  .fontSize(11)
                  .margin({ left: 8 })
                  .onClick(() => this.onDeleteAllTap())
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 4, bottom: 8 })
          }
          .width('100%').backgroundColor('#f5f5f5')
            }
          .scrollBar(BarState.Off)
          }
        .tabBar(this.cslTabBar)

        // --- Tab 2: 世界杯 ---
        TabContent() {
          Scroll() {
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

            // Expand/Collapse button — 固定在宫格下方，始终可见
            Row() {
              Text(this.wcExpanded ? '▲ 收起' : '▼ 展开全部 48 个国家')
                .fontSize(10)
                .fontColor('#1976d2')
                .fontWeight(FontWeight.Medium)
                .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                .backgroundColor('#e3f2fd')
                .borderRadius(16)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 6, bottom: 4 })
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
          .width('100%').backgroundColor('#f5f5f5')
            .padding({ bottom: 12 })
            }
          .scrollBar(BarState.Off)
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

  // Tab bar builders — 底部胶囊式分段控制器（参考 JD 分类页风格）
  @Builder
  cslTabBar() {
    Column() {
      Text('中超联赛')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentTab === 0 ? '#ffffff' : '#666666')
    }
    .width('100%')
    .height(28)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 8, right: 8 })
    .backgroundColor(this.currentTab === 0 ? '#333333' : '#f0f0f0')
    .borderRadius(14)
  }

  @Builder
  wcTabBar() {
    Column() {
      Text('🏆 世界杯')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentTab === 1 ? '#ffffff' : '#666666')
    }
    .width('100%')
    .height(28)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 8, right: 8 })
    .backgroundColor(this.currentTab === 1 ? '#333333' : '#f0f0f0')
    .borderRadius(14)
  }
}

