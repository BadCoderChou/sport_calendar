import { router } from '@kit.ArkUI';

@Entry
@Component
struct Changelog {
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .onClick(() => router.back())
          .padding({ right: 16 })

        Text('版本更新记录')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#ffffff')

      Divider()
        .width('100%')
        .color('#f0f0f0')

      Scroll() {
        Column() {
          // v1.0.0
          this.versionCard('v1.0.0', '2026 年 4 月 30 日', [
            '新增世界杯赛程订阅功能，支持 48 支国家队选择',
            '新增 Tab 页签切换（中超联赛 / 世界杯 / 我的）',
            '世界杯热门 12 强球队置顶显示，支持展开查看全部',
            '日历事件描述优化：世界杯赛事显示"世界杯赛程"',
            '新增隐私协议页面',
            '应用更名为"赛事日历"',
            '全新应用图标',
            '重构为离线单机应用，赛程数据内嵌于应用中，无需联网',
            '支持屏幕自动旋转（跟随系统方向）',
          ])

          // v0.1.0
          this.versionCard('v0.1.0', '2026 年 4 月 28 日', [
            '支持中超联赛 16 支球队赛程订阅',
            '球队选择 → 订阅日程 → 同步到系统日历',
            '支持删除已订阅的赛程日历',
            'ICS 数据解析与日历事件管理',
          ])
        }
        .width('100%')
        .padding({ top: 16 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  versionCard(version: string, date: string, items: string[]) {
    Column() {
      // 版本号 + 日期
      Row() {
        Text(version)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(date)
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      // 更新内容
      ForEach(items, (item: string) => {
        Row() {
          Text('•')
            .fontSize(12)
            .fontColor('#1976d2')
            .margin({ right: 8 })
          Text(item)
            .fontSize(12)
            .fontColor('#666666')
            .lineHeight(18)
        }
        .width('100%')
        .margin({ bottom: 6 })
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundColor('#ffffff')
    .margin({ bottom: 8 })
  }
}
