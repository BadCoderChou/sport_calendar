import { router, promptAction } from '@kit.ArkUI';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { DataService } from '../services/DataService';
import { IcsParser } from '../services/IcsParser';
import { CalendarWriter } from '../services/CalendarWriter';
import { TeamStore } from '../services/TeamStore';
import { CSL_TEAMS, WORLD_CUP_TEAMS, WC_CALENDAR_NAME_PREFIX, Team } from '../constants/Teams';
import { MatchEvent } from '../model/MatchEvent';

@Entry
@Component
struct TeamDetailPage {
  @State teamName: string = '';
  @State teamLogo: ResourceStr = '';
  @State teamEmoji: string = '';
  @State isSubscribed: boolean = false;
  @State matches: MatchEvent[] = [];
  @State isLoading: boolean = true;
  @State isToggling: boolean = false;

  private teamId: string = '';
  private isCsl: boolean = true;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, string>;
    this.teamId = params?.teamId || '';
    this.isCsl = CSL_TEAMS.some(t => t.id === this.teamId);

    const context = getContext() as common.UIAbilityContext;
    const icsPath = this.isCsl ? `csl/${this.teamId}.ics` : `wc/${this.teamId}.ics`;

    if (this.isCsl) {
      const team = CSL_TEAMS.find(t => t.id === this.teamId);
      if (team) {
        this.teamName = team.name;
        this.teamLogo = team.logo;
      }
      this.isSubscribed = await TeamStore.isSubscribed(this.teamId);
    } else {
      const team = WORLD_CUP_TEAMS.find(t => t.id === this.teamId);
      if (team) {
        this.teamName = team.name;
        this.teamEmoji = team.emoji;
      }
      this.isSubscribed = await TeamStore.isWcSubscribed(this.teamId);
    }

    try {
      const ics = await DataService.loadIcs(context, icsPath);
      const events = IcsParser.parse(ics);
      events.sort((a, b) => a.startTime - b.startTime);
      this.matches = events;
    } catch (e) {
      promptAction.showToast({ message: '加载赛程数据失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async toggleSubscribe(): Promise<void> {
    this.isToggling = true;
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(getContext(),
        ['ohos.permission.WRITE_CALENDAR']);
      if (result.authResults[0] !== 0) {
        promptAction.showToast({ message: '需要日历权限', duration: 2000 });
        return;
      }

      if (this.isSubscribed) {
        // 取消订阅
        const cslTeam = CSL_TEAMS.find(t => t.id === this.teamId);
        const wcTeam = WORLD_CUP_TEAMS.find(t => t.id === this.teamId);
        const teamParam: Team = this.isCsl && cslTeam
          ? cslTeam
          : { id: wcTeam!.id, name: wcTeam!.name, color: '', logo: '' };
        const prefix = this.isCsl ? undefined : WC_CALENDAR_NAME_PREFIX;
        await CalendarWriter.deleteCalendar(teamParam, prefix);
        if (this.isCsl) {
          await TeamStore.toggleSubscription(this.teamId);
        } else {
          await TeamStore.toggleWcSubscription(this.teamId);
        }
        this.isSubscribed = false;
        promptAction.showToast({ message: '已取消订阅', duration: 2000 });
      } else {
        // 订阅
        if (this.matches.length === 0) {
          promptAction.showToast({ message: '暂无赛程数据', duration: 2000 });
          return;
        }
        const cslTeam = CSL_TEAMS.find(t => t.id === this.teamId);
        const wcTeam = WORLD_CUP_TEAMS.find(t => t.id === this.teamId);
        const teamParam: Team = this.isCsl && cslTeam
          ? cslTeam
          : { id: wcTeam!.id, name: wcTeam!.name, color: '', logo: '' };
        const prefix = this.isCsl ? undefined : WC_CALENDAR_NAME_PREFIX;
        const desc = this.isCsl ? '中超联赛赛程' : '世界杯赛程';
        await CalendarWriter.writeEvents(teamParam, this.matches, desc, prefix);
        if (this.isCsl) {
          await TeamStore.toggleSubscription(this.teamId);
        } else {
          await TeamStore.toggleWcSubscription(this.teamId);
        }
        this.isSubscribed = true;
        promptAction.showToast({ message: `已订阅 ${this.matches.length} 场比赛`, duration: 2000 });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请重试', duration: 2000 });
    } finally {
      this.isToggling = false;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
          .padding({ right: 12 })
        Text(this.teamName || '球队详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

      // 球队信息区
      Row() {
        if (this.isCsl && this.teamLogo) {
          Image(this.teamLogo)
            .width(48)
            .height(48)
            .borderRadius(8)
            .margin({ right: 12 })
        } else if (this.teamEmoji) {
          Text(this.teamEmoji)
            .fontSize(36)
            .margin({ right: 12 })
        }
        Text(this.teamName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Button(this.isSubscribed ? '已订阅' : '订阅')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.isSubscribed ? $r('app.color.brand_success') : $r('app.color.brand_primary'))
          .borderRadius(20)
          .height(36)
          .enabled(!this.isToggling)
          .onClick(() => this.toggleSubscribe())
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .alignItems(VerticalAlign.Center)

      // 赛程列表
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color($r('app.color.brand_primary'))
          Text('加载中...')
            .fontSize(14)
            .fontColor($r('app.color.text_hint'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.matches.length === 0) {
        Column() {
          Text('暂无赛程数据')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.matches, (event: MatchEvent) => {
            ListItem() {
              this.MatchRow(event)
            }
          }, (event: MatchEvent) => event.uid)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .divider({ strokeWidth: 1, color: $r('app.color.divider_color') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  MatchRow(event: MatchEvent) {
    Row() {
      Column() {
        Text(this.formatDate(event.startTime))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        Text(this.formatTime(event.startTime))
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 2 })
      }
      .width(70)

      Text(event.title)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(event.status === 'finished' ? '已结束' : '未开始')
        .fontSize(12)
        .fontColor(event.status === 'finished'
          ? $r('app.color.text_hint')
          : $r('app.color.brand_success'))
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: 'pages/MatchDetail', params: { teamId: this.teamId, matchUid: event.uid } });
    })
  }

  private formatDate(ts: number): string {
    const d = new Date(ts);
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    return `${this.pad(d.getHours())}:${this.pad(d.getMinutes())}`;
  }

  private pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }
}
