import { Team } from '../constants/Teams';
import { WorldCupTeam } from '../constants/Teams';
import { MatchEvent } from '../model/MatchEvent';

@Component
export struct MatchListSheet {
  @Prop teamName: string = '';
  @Prop teamEmoji: string = '';
  @Prop teamLogo: ResourceStr = $r('app.media.startIcon');
  @Prop events: MatchEvent[] = [];
  @Prop isSubscribed: boolean = false;
  onSubscribe: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text(`${this.teamEmoji} ${this.teamName} — 全部赛程`)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('✕')
          .fontSize(18)
          .fontColor($r('app.color.text_hint'))
          .onClick(() => this.onClose())
          .padding({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Divider()

      if (this.events.length === 0) {
        Text('暂无赛程数据')
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 40 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.events, (event: MatchEvent) => {
              this.matchRow(event)
            }, (event: MatchEvent) => event.uid.toString())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Divider()

      if (!this.isSubscribed) {
        Button('订阅全部到日历 📅')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .borderRadius(14)
          .height(36)
          .fontSize(14)
          .width('100%')
          .margin({ left: 16, right: 16, bottom: 12, top: 8 })
          .onClick(() => {
            this.onClose();
            this.onSubscribe();
          })
      }
    }
    .width('100%')
    .height('60%')
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  matchRow(event: MatchEvent) {
    Row() {
      Column() {
        Text(this.formatDate(event.startTime))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.formatWeek(event.startTime))
          .fontSize(9)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 2 })
        Text(this.formatTime(event.startTime))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .width(60)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(event.title)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Row() {
          if (event.status === 'finished') {
            Text('已结束')
              .fontSize(10)
              .fontColor($r('app.color.text_hint'))
          } else {
            Text('未开始')
              .fontSize(10)
              .fontColor($r('app.color.brand_success'))
          }
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(10)
    .backgroundColor(event.status === 'finished' ? $r('app.color.page_bg') : $r('app.color.card_bg'))
    .borderRadius(6)
    .margin({ bottom: 4 })
  }

  formatDate(ts: number): string {
    const d = new Date(ts);
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  formatWeek(ts: number): string {
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekDays[new Date(ts).getDay()];
  }

  formatTime(ts: number): string {
    const d = new Date(ts);
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
}
