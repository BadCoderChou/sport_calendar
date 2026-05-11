import { CSL_TEAMS, WORLD_CUP_TEAMS, Team, WorldCupTeam } from '../constants/Teams';
import { IcsParser } from '../services/IcsParser';
import { DataService } from '../services/DataService';
import { TeamStore } from '../services/TeamStore';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { MatchEvent } from '../model/MatchEvent';
import { UpcomingCard } from '../components/UpcomingCard';
import { OnboardingOverlay } from '../components/OnboardingOverlay';
import { PrivacyConsentDialog } from '../components/PrivacyConsentDialog';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State privacyAgreed: boolean = false;
  @State showOnboarding: boolean = false;

  // Tab 1 (首页) 状态
  @State cslUpcoming: MatchEvent[] = [];
  @State wcUpcoming: MatchEvent[] = [];
  @State lastRefreshTime: string = '';

  // Tab 2 (球队) 状态
  @State subscribedCslIds: string[] = [];
  @State subscribedWcIds: string[] = [];
  @State currentLeague: number = 0;

  // Tab 3 (我的) 状态
  @State mySyncTime: string = '';
  @State isSyncing: boolean = false;

  aboutToAppear(): void {
    this.checkPrivacyConsent();
  }

  async checkPrivacyConsent(): Promise<void> {
    const agreed = await TeamStore.getPrivacyAgreed();
    if (agreed) {
      this.privacyAgreed = true;
      this.initApp();
    }
  }

  onPrivacyAgree(): void {
    TeamStore.setPrivacyAgreed(true);
    this.privacyAgreed = true;
    this.initApp();
  }

  async initApp(): Promise<void> {
    await this.loadState();
    this.checkOnboarding();
    this.computeUpcomingEvents();
    this.silentSync();
  }

  async loadState(): Promise<void> {
    this.subscribedCslIds = await TeamStore.getSubscribedIds();
    this.subscribedWcIds = await TeamStore.getWcSubscribedIds();
    const syncTime = await TeamStore.getLastDataSyncTime();
    this.mySyncTime = syncTime > 0 ? this.formatDateTime(syncTime) : '从未同步';
  }

  async checkOnboarding(): Promise<void> {
    const seen = await TeamStore.getOnboardingSeen();
    if (!seen) {
      this.showOnboarding = true;
    }
  }

  async silentSync(): Promise<void> {
    try {
      const ctx = getContext() as common.UIAbilityContext;
      await DataService.syncIfNeeded(ctx);
      const syncTime = await TeamStore.getLastDataSyncTime();
      this.lastRefreshTime = syncTime > 0 ? this.formatDateTime(syncTime) : '';
    } catch (_) {
    }
  }

  async computeUpcomingEvents(): Promise<void> {
    const now = Date.now();
    const ctx = getContext() as common.UIAbilityContext;

    const cslUpcoming: MatchEvent[] = [];
    for (const id of this.subscribedCslIds) {
      try {
        const icsText = await DataService.loadIcs(ctx, `csl/${id}.ics`);
        const events = IcsParser.parse(icsText);
        const upcoming = events.filter((e: MatchEvent) => e.startTime >= now);
        cslUpcoming.push(...upcoming);
      } catch (_) {
      }
    }
    this.cslUpcoming = cslUpcoming.sort((a: MatchEvent, b: MatchEvent) => a.startTime - b.startTime).slice(0, 3);

    const wcUpcoming: MatchEvent[] = [];
    for (const id of this.subscribedWcIds) {
      try {
        const icsText = await DataService.loadIcs(ctx, `wc/${id}.ics`);
        const events = IcsParser.parse(icsText);
        const upcoming = events.filter((e: MatchEvent) => e.startTime >= now);
        wcUpcoming.push(...upcoming);
      } catch (_) {
      }
    }
    this.wcUpcoming = wcUpcoming.sort((a: MatchEvent, b: MatchEvent) => a.startTime - b.startTime).slice(0, 3);
  }

  async onTabChange(): Promise<void> {
    if (this.currentTab === 0) {
      await this.loadState();
      await this.computeUpcomingEvents();
    } else if (this.currentTab === 1) {
      this.subscribedCslIds = await TeamStore.getSubscribedIds();
      this.subscribedWcIds = await TeamStore.getWcSubscribedIds();
    } else if (this.currentTab === 2) {
      await this.loadState();
    }
  }

  async doRefreshData(): Promise<void> {
    this.isSyncing = true;
    try {
      const ctx = getContext() as common.UIAbilityContext;
      await DataService.syncIfNeeded(ctx);
      await TeamStore.setLastDataSyncTime(Date.now());
      await this.loadState();
    } catch (_) {
    } finally {
      this.isSyncing = false;
    }
  }

  build() {
    if (!this.privacyAgreed) {
      PrivacyConsentDialog({ onAgree: () => this.onPrivacyAgree() })
    } else {
      Stack() {
        Tabs({ index: this.currentTab }) {
          TabContent() {
            this.HomeTab()
          }.tabBar(this.TabBarItem('首页', 0))

          TabContent() {
            this.TeamsTab()
          }.tabBar(this.TabBarItem('球队', 1))

          TabContent() {
            this.MyTab()
          }.tabBar(this.TabBarItem('我的', 2))
        }
        .width('100%')
        .height('100%')
        .barPosition(BarPosition.End)
        .onChange((index: number) => {
          this.currentTab = index;
          this.onTabChange();
        })

        if (this.showOnboarding) {
          OnboardingOverlay({
            show: this.showOnboarding,
            onSkip: async () => {
              this.showOnboarding = false;
              await TeamStore.setOnboardingSeen(true);
            },
            onFinish: async () => {
              this.showOnboarding = false;
              await TeamStore.setOnboardingSeen(true);
            },
          })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  // ========== Tab 1: 首页 ==========
  @Builder
  HomeTab() {
    Scroll() {
      Column() {
        // 标题
        Row() {
          Text('赛事日历')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          if (this.lastRefreshTime) {
            Text(this.lastRefreshTime)
              .fontSize(10)
              .fontColor($r('app.color.text_hint'))
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 近期比赛
        UpcomingCard({ events: [...this.cslUpcoming, ...this.wcUpcoming] })

        // 热门球队 - 中超
        Text('中超联赛')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16, top: 20, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(CSL_TEAMS.slice(0, 6), (team: Team) => {
            this.HotTeamCard(team.name, team.logo, () => {
              router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
            });
          }, (team: Team) => team.id)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })

        // 热门球队 - 世界杯
        Text('世界杯')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16, top: 20, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(WORLD_CUP_TEAMS.slice(0, 8), (team: WorldCupTeam) => {
            this.HotWcTeamCard(team.name, team.emoji, () => {
              router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
            });
          }, (team: WorldCupTeam) => team.id)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })

        // 鸣谢
        Text('数据来源: sports-calendar.com')
          .fontSize(11)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 24, bottom: 16 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  HotTeamCard(name: string, logo: ResourceStr, action: () => void) {
    Column() {
      Image(logo)
        .width(40)
        .height(40)
        .borderRadius(8)
      Text(name)
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
        .constraintSize({ maxWidth: 70 })
    }
    .width(76)
    .height(72)
    .margin({ left: 4, right: 4, bottom: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(10)
    .backgroundColor($r('app.color.card_bg'))
    .onClick(action)
  }

  @Builder
  HotWcTeamCard(name: string, emoji: string, action: () => void) {
    Column() {
      Text(emoji)
        .fontSize(28)
      Text(name)
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
        .constraintSize({ maxWidth: 70 })
    }
    .width(76)
    .height(72)
    .margin({ left: 4, right: 4, bottom: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(10)
    .backgroundColor($r('app.color.card_bg'))
    .onClick(action)
  }

  // ========== Tab 2: 球队 ==========
  @Builder
  TeamsTab() {
    Column() {
      Tabs({ index: this.currentLeague }) {
        TabContent() {
          this.CslGrid()
        }.tabBar('中超联赛')

        TabContent() {
          this.WcGrid()
        }.tabBar('世界杯')
      }
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentLeague = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  CslGrid() {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(CSL_TEAMS, (team: Team) => {
          this.TeamCard(team.name, team.logo, this.subscribedCslIds.includes(team.id), () => {
            router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
          });
        }, (team: Team) => team.id)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WcGrid() {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(WORLD_CUP_TEAMS, (team: WorldCupTeam) => {
          this.WcTeamCard(team.name, team.emoji, this.subscribedWcIds.includes(team.id), () => {
            router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
          });
        }, (team: WorldCupTeam) => team.id)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TeamCard(name: string, logo: ResourceStr, subscribed: boolean, action: () => void) {
    Column() {
      Stack() {
        Image(logo)
          .width(44)
          .height(44)
          .borderRadius(8)
        if (subscribed) {
          Text('✓')
            .fontSize(12)
            .fontColor(Color.White)
            .width(18)
            .height(18)
            .borderRadius(9)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.brand_success'))
            .position({ x: '70%', y: -4 })
        }
      }
      .width(44)
      .height(44)
      Text(name)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .constraintSize({ maxWidth: 76 })
    }
    .width(80)
    .height(80)
    .margin({ left: 6, right: 6, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(subscribed ? $r('app.color.card_bg_subscribed') : $r('app.color.card_bg'))
    .borderWidth(subscribed ? 1.5 : 0)
    .borderColor(subscribed ? $r('app.color.brand_success') : Color.Transparent)
    .onClick(action)
  }

  @Builder
  WcTeamCard(name: string, emoji: string, subscribed: boolean, action: () => void) {
    Column() {
      Stack() {
        Text(emoji)
          .fontSize(30)
        if (subscribed) {
          Text('✓')
            .fontSize(12)
            .fontColor(Color.White)
            .width(18)
            .height(18)
            .borderRadius(9)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.brand_success'))
            .position({ x: '70%', y: -4 })
        }
      }
      .width(44)
      .height(44)
      Text(name)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .constraintSize({ maxWidth: 76 })
    }
    .width(80)
    .height(80)
    .margin({ left: 6, right: 6, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(subscribed ? $r('app.color.card_bg_subscribed') : $r('app.color.card_bg'))
    .borderWidth(subscribed ? 1.5 : 0)
    .borderColor(subscribed ? $r('app.color.brand_success') : Color.Transparent)
    .onClick(action)
  }

  // ========== Tab 3: 我的 ==========
  @Builder
  MyTab() {
    Column() {
      // 标题栏
      Row() {
        Text('我的订阅')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('⚙')
          .fontSize(22)
          .fontColor($r('app.color.text_hint'))
          .onClick(() => router.pushUrl({ url: 'pages/Settings' }))
          .padding({ left: 12 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column() {
          if (this.subscribedCslIds.length === 0 && this.subscribedWcIds.length === 0) {
            Column() {
              Text('📭')
                .fontSize(48)
              Text('还没有订阅任何球队')
                .fontSize(16)
                .fontColor($r('app.color.text_hint'))
                .margin({ top: 12 })
              Text('去「球队」页面选择喜欢的球队吧')
                .fontSize(14)
                .fontColor($r('app.color.text_hint'))
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ top: 60 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            if (this.subscribedCslIds.length > 0) {
              Text('中超联赛')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 12, bottom: 6 })
              Column() {
                ForEach(this.subscribedCslIds, (id: string) => {
                  this.MyCslSubscribedRow(id)
                }, (id: string) => id)
              }
              .width('100%')
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
            }

            if (this.subscribedWcIds.length > 0) {
              Text('世界杯')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 12, bottom: 6 })
              Column() {
                ForEach(this.subscribedWcIds, (id: string) => {
                  this.MyWcSubscribedRow(id)
                }, (id: string) => id)
              }
              .width('100%')
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
            }
          }

          // 刷新按钮
          Button(this.isSyncing ? '同步中...' : '刷新赛程数据')
            .width('100%')
            .height(44)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.brand_primary'))
            .borderRadius(10)
            .margin({ top: 20 })
            .enabled(!this.isSyncing)
            .onClick(() => this.doRefreshData())

          Text(`上次同步: ${this.mySyncTime}`)
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .margin({ top: 12 })

          // 底部入口
          Row() {
            Text('隐私协议')
              .fontSize(14)
              .fontColor($r('app.color.brand_primary'))
              .onClick(() => router.pushUrl({ url: 'pages/PrivacyPolicy' }))
            Text('|')
              .fontSize(14)
              .fontColor($r('app.color.text_hint'))
              .margin({ left: 16, right: 16 })
            Text('更新日志')
              .fontSize(14)
              .fontColor($r('app.color.brand_primary'))
              .onClick(() => router.pushUrl({ url: 'pages/Changelog' }))
          }
          .margin({ top: 24, bottom: 20 })
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  MyCslSubscribedRow(id: string) {
    Row() {
      Image(CSL_TEAMS.find(t => t.id === id)?.logo ?? $r('app.media.startIcon'))
        .width(32)
        .height(32)
        .borderRadius(6)
        .margin({ right: 12 })
      Text(CSL_TEAMS.find(t => t.id === id)?.name ?? '')
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text('已订阅')
        .fontSize(13)
        .fontColor($r('app.color.brand_success'))
      Text('>')
        .fontSize(14)
        .fontColor($r('app.color.text_hint'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: id } });
    })
  }

  @Builder
  MyWcSubscribedRow(id: string) {
    Row() {
      Text(WORLD_CUP_TEAMS.find(t => t.id === id)?.emoji ?? '')
        .fontSize(24)
        .margin({ right: 12 })
      Text(WORLD_CUP_TEAMS.find(t => t.id === id)?.name ?? '')
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text('已订阅')
        .fontSize(13)
        .fontColor($r('app.color.brand_success'))
      Text('>')
        .fontSize(14)
        .fontColor($r('app.color.text_hint'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: id } });
    })
  }

  // ========== Tab Bar ==========
  @Builder
  TabBarItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === index ? $r('app.color.brand_primary') : $r('app.color.text_hint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ========== Utils ==========
  private formatDateTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())} ${this.pad(d.getHours())}:${this.pad(d.getMinutes())}`;
  }

  private pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }
}
