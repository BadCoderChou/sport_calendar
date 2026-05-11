import { MatchEvent } from '../model/MatchEvent';

@Component
export struct UpcomingCard {
  events: MatchEvent[] = [];
  expanded: boolean = true;

  build() {
    if (this.events.length === 0) {
      this.emptyTip()
    } else {
      Column() {
        // Header row (tappable)
        Row() {
          Text('⏰ 即将开始')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand_primary'))
            .layoutWeight(1)
          Text(this.expanded ? '▼' : '▶')
            .fontSize(10)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 6, bottom: 4 })
        .onClick(() => { this.expanded = !this.expanded; })

        if (this.expanded) {
          ForEach(this.events.slice(0, 3), (event: MatchEvent) => {
            this.upcomingRow(event)
          }, (event: MatchEvent) => event.uid.toString())
        }
      }
      .width('100%')
      .padding(8)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(8)
      .margin({ left: 12, right: 12, top: 4 })
    }
  }

  @Builder
  emptyTip() {
    Row() {
      Text('⏰')
        .fontSize(14)
      Text('订阅球队后，即将开始的比赛将在此处展示')
        .fontSize(11)
        .fontColor($r('app.color.text_hint'))
        .margin({ left: 6 })
    }
    .width('100%')
    .padding(12)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_bg'))
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 4 })
  }

  @Builder
  upcomingRow(event: MatchEvent) {
    Row() {
      Text(this.formatCountdown(event.startTime - Date.now()))
        .fontSize(10)
        .fontColor($r('app.color.card_bg'))
        .fontWeight(FontWeight.Medium)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(4)
        .backgroundColor(event.startTime - Date.now() < 3600000 ? $r('app.color.brand_warning') : $r('app.color.brand_primary'))

      Column() {
        Text(event.title)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.formatTime(event.startTime))
          .fontSize(9)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(8)
    .backgroundColor(event.status === 'finished' ? $r('app.color.page_bg') : $r('app.color.card_bg'))
    .borderRadius(4)
    .margin({ bottom: 3 })
  }

  formatTime(ts: number): string {
    const d = new Date(ts);
    const month = d.getMonth() + 1;
    const day = d.getDate();
    const hour = String(d.getHours()).padStart(2, '0');
    const min = String(d.getMinutes()).padStart(2, '0');
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return `${month}/${day} ${weekDays[d.getDay()]} ${hour}:${min}`;
  }

  formatCountdown(diffMs: number): string {
    if (diffMs <= 0) return '即将开始';
    const days = Math.floor(diffMs / 86400000);
    if (days > 0) return `还剩 ${days} 天`;
    const hours = Math.floor(diffMs / 3600000);
    const mins = Math.round((diffMs % 3600000) / 60000);
    if (hours > 0) return `还剩 ${hours} 小时 ${mins} 分`;
    return `还剩 ${mins} 分`;
  }
}
