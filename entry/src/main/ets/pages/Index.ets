import { Team, CSL_TEAMS, getIcsUrl } from '../constants/Teams';
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
  @State showDialog: boolean = false;
  @State dialogTeamName: string = '';
  @State dialogTeamId: string = '';

  aboutToAppear(): void {
    this.loadSubscriptionState();
  }

  aboutToDisappear(): void {
    HttpService.destroy();
  }

  async loadSubscriptionState(): Promise<void> {
    try {
      this.subscribedIds = await TeamStore.getSubscribedIds();
      this.lastSyncTime = await TeamStore.getLastSyncTime();
    } catch (e) {
      const error = e as Error;
      hilog.error(DOMAIN, 'SportCalendar', 'Failed to load state: %{public}s', JSON.stringify(error));
    }
  }

  async onTeamTap(teamId: string): Promise<void> {
    if (this.syncing) return;

    const team = CSL_TEAMS.find(t => t.id === teamId);
    if (!team) return;

    const isNowSubscribed = this.subscribedIds.includes(teamId);
    if (isNowSubscribed) {
      this.dialogTeamName = team.name;
      this.dialogTeamId = team.id;
      this.showDialog = true;
    } else {
      await TeamStore.toggleSubscription(teamId);
      await this.loadSubscriptionState();
    }
  }

  confirmUnsubscribe(): void {
    if (this.dialogTeamId) {
      const team = CSL_TEAMS.find(t => t.id === this.dialogTeamId);
      if (team) {
        this.showDialog = false;
        this.deleteTeamCalendar(team);
      }
    }
  }

  cancelDialog(): void {
    this.showDialog = false;
    this.dialogTeamName = '';
    this.dialogTeamId = '';
  }

  async deleteTeamCalendar(team: Team): Promise<void> {
    try {
      await CalendarWriter.deleteCalendar(team);
      await TeamStore.toggleSubscription(team.id);
      await this.loadSubscriptionState();
      promptAction.showToast({ message: `已删除${team.name}的赛程日历`, duration: 2000 });
    } catch (e) {
      const error = e as Error;
      hilog.error(DOMAIN, 'SportCalendar', 'Delete failed: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '删除日历失败，请重试', duration: 2000 });
    }
  }

  async onSyncTap(): Promise<void> {
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

      promptAction.showToast({ message: `已导入 ${totalImported} 场比赛`, duration: 2000 });
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Sync error: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '同步失败，请检查网络后重试', duration: 2000 });
    } finally {
      this.syncing = false;
    }
  }

  async requestCalendarPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      await atManager.requestPermissionsFromUser(getContext(), ['ohos.permission.WRITE_CALENDAR']);
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

  build() {
    Column() {
      // Header
      Column() {
        Text('中超联赛赛程日历')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 4 })
        Text('选择球队，同步到系统日历')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // Team Grid — fixed 4x4 layout using Rows
      Column() {
        this.TeamRow(0)
        this.TeamRow(1)
        this.TeamRow(2)
        this.TeamRow(3)
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })

      // Sync Bar
      Column() {
        Row() {
          Column() {
            Text(`已订阅 ${this.subscribedIds.length} 支球队`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(this.getSubscribedNames() + ' · 上次同步: ' + this.formatLastSyncTime())
              .fontSize(11)
              .fontColor('#888888')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button(this.syncing ? '同步中...' : '同步赛程')
            .type(ButtonType.Normal)
            .backgroundColor(this.syncing || this.subscribedIds.length === 0 ? '#cccccc' : '#1976d2')
            .fontColor(Color.White)
            .borderRadius(20)
            .height(36)
            .enabled(!this.syncing && this.subscribedIds.length > 0)
            .width(90)
            .onClick(() => this.onSyncTap())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding(14)
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .shadow({ radius: 6, color: '#0000000D', offsetX: 0, offsetY: 1 })
        .margin({ left: 12, right: 12, bottom: 12 })
      }

      // Unsubscribe confirmation dialog
      if (this.showDialog) {
        this.UnsubscribeDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  TeamRow(rowIndex: number) {
    Row() {
      ForEach(CSL_TEAMS.slice(rowIndex * 4, rowIndex * 4 + 4), (team: Team) => {
        Stack() {
          Column() {
            Image(team.logo)
              .width(36)
              .height(36)
              .objectFit(ImageFit.Contain)
              .margin({ bottom: 4 })

            Text(team.name)
              .fontSize(10)
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
              .fontSize(12)
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
        .layoutWeight(1)
        .height(76)
        .margin(4)
        .padding(6)
        .backgroundColor(this.isTeamSubscribed(team.id) ? '#e8f5e9' : '#ffffff')
        .borderRadius(8)
        .border(this.isTeamSubscribed(team.id) ? { width: 2, color: '#4caf50' } : { width: 0 })
        .shadow(this.isTeamSubscribed(team.id) ? { radius: 4, color: '#4caf5020' } : { radius: 4, color: '#0000000D' })
        .onClick(() => this.onTeamTap(team.id))
      }, (team: Team) => team.id)
    }
    .width('100%')
    .height(0)
    .layoutWeight(1)
  }

  @Builder
  UnsubscribeDialogOverlay() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000080')
        .onClick(() => this.cancelDialog())

      Column() {
        Text('\u26A0\uFE0F')
          .fontSize(36)
          .margin({ bottom: 12 })

        Text(`取消订阅${this.dialogTeamName}？`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')

        Text('将删除该球队的全部赛程日历')
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8, bottom: 20 })

        Row() {
          Button('取消')
            .type(ButtonType.Normal)
            .backgroundColor('#f5f5f5')
            .fontColor('#666666')
            .borderRadius(10)
            .layoutWeight(1)
            .height(40)
            .onClick(() => this.cancelDialog())

          Button('确认删除')
            .type(ButtonType.Normal)
            .backgroundColor('#f44336')
            .fontColor(Color.White)
            .borderRadius(10)
            .layoutWeight(1)
            .height(40)
            .margin({ left: 12 })
            .onClick(() => this.confirmUnsubscribe())
        }
        .width('100%')
      }
      .backgroundColor('#ffffff')
      .borderRadius(16)
      .padding(24)
      .margin({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(100)
  }
}
