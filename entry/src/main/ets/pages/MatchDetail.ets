import { router, promptAction } from '@kit.ArkUI';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { DataService } from '../services/DataService';
import { IcsParser } from '../services/IcsParser';
import { CalendarWriter } from '../services/CalendarWriter';
import { TeamStore } from '../services/TeamStore';
import { CSL_TEAMS, WORLD_CUP_TEAMS, WC_CALENDAR_NAME_PREFIX, Team, WorldCupTeam } from '../constants/Teams';
import { MatchEvent } from '../model/MatchEvent';

@Entry
@Component
struct MatchDetailPage {
  @State matchEvent: MatchEvent | null = null;
  @State teamName: string = '';
  @State isSubscribed: boolean = false;
  @State isLoading: boolean = true;
  @State isWriting: boolean = false;

  private teamId: string = '';
  private matchUid: string = '';

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, string>;
    this.teamId = params?.teamId || '';
    this.matchUid = params?.matchUid || '';

    const context = getContext() as common.UIAbilityContext;
    const isCsl = CSL_TEAMS.some(t => t.id === this.teamId);
    const icsPath = isCsl ? `csl/${this.teamId}.ics` : `wc/${this.teamId}.ics`;

    try {
      if (isCsl) {
        const cslTeam = CSL_TEAMS.find(t => t.id === this.teamId);
        if (cslTeam) { this.teamName = cslTeam.name; }
      } else {
        const wcTeam = WORLD_CUP_TEAMS.find(t => t.id === this.teamId);
        if (wcTeam) { this.teamName = wcTeam.name; }
      }

      this.isSubscribed = isCsl
        ? await TeamStore.isSubscribed(this.teamId)
        : await TeamStore.isWcSubscribed(this.teamId);

      const ics = await DataService.loadIcs(context, icsPath);
      const events = IcsParser.parse(ics);
      this.matchEvent = events.find(e => e.uid === this.matchUid) || null;
    } catch (e) {
      promptAction.showToast({ message: '加载比赛数据失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async addToCalendar(): Promise<void> {
    if (!this.matchEvent) return;
    this.isWriting = true;
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(getContext(),
        ['ohos.permission.WRITE_CALENDAR']);
      if (result.authResults[0] !== 0) {
        promptAction.showToast({ message: '需要日历权限', duration: 2000 });
        return;
      }
      const isCsl = CSL_TEAMS.some(t => t.id === this.teamId);
      const prefix = isCsl ? undefined : WC_CALENDAR_NAME_PREFIX;
      const desc = isCsl ? '中超联赛赛程' : '世界杯赛程';
      let teamParam: Team | null = null;
      if (isCsl) {
        const cslTeam = CSL_TEAMS.find(t => t.id === this.teamId);
        if (cslTeam) { teamParam = cslTeam; }
      } else {
        const wcTeam = WORLD_CUP_TEAMS.find(t => t.id === this.teamId);
        if (wcTeam) { teamParam = { id: wcTeam.id, name: wcTeam.name, color: '', logo: '' }; }
      }
      if (!teamParam) return;
      await CalendarWriter.writeEvents(teamParam, [this.matchEvent!], desc, prefix);
      promptAction.showToast({ message: '已添加到日历', duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '添加失败，请重试', duration: 2000 });
    } finally {
      this.isWriting = false;
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
        Text('比赛详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

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
      } else if (this.matchEvent) {
        // 比赛详情内容
        Scroll() {
          Column() {
            // 对阵信息
            Column() {
              Text(this.matchEvent!.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(20)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)

            // 详情信息卡片
            Column() {
              this.InfoRow('日期', this.formatDate(this.matchEvent!.startTime))
              Divider().color($r('app.color.divider_color'))
              this.InfoRow('时间', this.formatTime(this.matchEvent!.startTime))
              Divider().color($r('app.color.divider_color'))
              this.InfoRow('地点', this.matchEvent!.location || '待定')
              Divider().color($r('app.color.divider_color'))
              Row() {
                Text('状态')
                  .fontSize(15)
                  .fontColor($r('app.color.text_secondary'))
                  .width(60)
                Text(this.matchEvent!.status === 'finished' ? '已结束' : '未开始')
                  .fontSize(15)
                  .fontColor(this.matchEvent!.status === 'finished'
                    ? $r('app.color.text_hint')
                    : $r('app.color.brand_success'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .margin({ top: 12 })
            .padding({ left: 16, right: 16 })

            // 添加到日历按钮
            Button(this.isWriting ? '添加中...' : '添加到日历')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.brand_primary'))
              .borderRadius(10)
              .margin({ top: 24 })
              .enabled(!this.isWriting)
              .onClick(() => this.addToCalendar())
          }
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        // 空状态
        Column() {
          Text('未找到比赛信息')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .width(60)
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Start)
  }

  private formatDate(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())}`;
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    return `${this.pad(d.getHours())}:${this.pad(d.getMinutes())}`;
  }

  private pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }
}
