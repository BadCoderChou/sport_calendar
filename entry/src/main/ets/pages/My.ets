import { router, promptAction } from '@kit.ArkUI';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { TeamStore } from '../services/TeamStore';
import { CSL_TEAMS, WORLD_CUP_TEAMS, WC_CALENDAR_NAME_PREFIX, Team } from '../constants/Teams';
import { DataService } from '../services/DataService';
import { CalendarWriter } from '../services/CalendarWriter';

@Entry
@Component
struct MyPage {
  @State subscribedCslIds: string[] = [];
  @State subscribedWcIds: string[] = [];
  @State lastSyncTime: string = '';
  @State isSyncing: boolean = false;
  @State isUnsubscribing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadState();
  }

  async loadState(): Promise<void> {
    this.subscribedCslIds = await TeamStore.getSubscribedIds();
    this.subscribedWcIds = await TeamStore.getWcSubscribedIds();
    const syncTime = await TeamStore.getLastDataSyncTime();
    this.lastSyncTime = syncTime > 0 ? this.formatDateTime(syncTime) : '从未同步';
  }

  async syncData(): Promise<void> {
    this.isSyncing = true;
    try {
      const context = getContext() as common.UIAbilityContext;
      const count = await DataService.syncIfNeeded(context);
      await TeamStore.setLastSyncTime(Date.now());
      await this.loadState();
      promptAction.showToast({
        message: count > 0 ? `已同步 ${count} 个文件` : '数据已是最新',
        duration: 2000,
        alignment: Alignment.Center,
      });
    } catch (e) {
      promptAction.showToast({ message: '同步失败，请检查网络', duration: 2000 });
    } finally {
      this.isSyncing = false;
    }
  }

  async unsubscribeAll(): Promise<void> {
    this.isUnsubscribing = true;
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(getContext(),
        ['ohos.permission.WRITE_CALENDAR']);
      if (result.authResults[0] !== 0) {
        promptAction.showToast({ message: '需要日历权限', duration: 2000 });
        return;
      }

      // 删除所有 CSL 日历
      for (const id of this.subscribedCslIds) {
        const team = CSL_TEAMS.find(t => t.id === id);
        if (team) {
          await CalendarWriter.deleteCalendar(team);
        }
      }
      // 删除所有世界杯日历
      for (const id of this.subscribedWcIds) {
        const wcTeam = WORLD_CUP_TEAMS.find(t => t.id === id);
        if (wcTeam) {
          const teamParam: Team = { id: wcTeam.id, name: wcTeam.name, color: '', logo: '' };
          await CalendarWriter.deleteCalendar(teamParam, WC_CALENDAR_NAME_PREFIX);
        }
      }
      await TeamStore.setSubscribedIds([]);
      await TeamStore.setWcSubscribedIds([]);
      await this.loadState();
      promptAction.showToast({ message: '已取消全部订阅', duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请重试', duration: 2000 });
    } finally {
      this.isUnsubscribing = false;
    }
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
          .padding({ right: 12 })
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
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column() {
          if (this.subscribedCslIds.length === 0 && this.subscribedWcIds.length === 0) {
            // 空状态
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
            .padding({ top: 80 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // CSL 分组
            if (this.subscribedCslIds.length > 0) {
              this.SectionHeader('中超联赛')
              Column() {
                ForEach(this.subscribedCslIds, (id: string) => {
                  this.MyCslRow(id)
                }, (id: string) => id)
              }
              .width('100%')
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
            }

            // 世界杯分组
            if (this.subscribedWcIds.length > 0) {
              this.SectionHeader('世界杯')
              Column() {
                ForEach(this.subscribedWcIds, (id: string) => {
                  this.MyWcRow(id)
                }, (id: string) => id)
              }
              .width('100%')
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
            }
          }

          // 操作按钮
          Column() {
            Button(this.isSyncing ? '同步中...' : '刷新赛程数据')
              .width('100%')
              .height(44)
              .fontSize(15)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.brand_primary'))
              .borderRadius(10)
              .enabled(!this.isSyncing)
              .onClick(() => this.syncData())

            if (this.subscribedCslIds.length > 0 || this.subscribedWcIds.length > 0) {
              Button(this.isUnsubscribing ? '取消中...' : '取消全部订阅')
                .width('100%')
                .height(44)
                .fontSize(15)
                .fontColor($r('app.color.brand_danger'))
                .backgroundColor(Color.Transparent)
                .borderWidth(1)
                .borderColor($r('app.color.brand_danger'))
                .borderRadius(10)
                .margin({ top: 12 })
                .enabled(!this.isUnsubscribing)
                .onClick(() => this.unsubscribeAll())
            }

            // 信息区
            Text(`上次同步: ${this.lastSyncTime}`)
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
              .margin({ top: 20 })
          }
          .width('100%')
          .padding({ top: 24 })

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
          .margin({ top: 32, bottom: 24 })
        }
        .padding({ left: 16, right: 16, top: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  MyCslRow(id: string) {
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
  MyWcRow(id: string) {
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

  private formatDateTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())} ${this.pad(d.getHours())}:${this.pad(d.getMinutes())}`;
  }

  private pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }
}
