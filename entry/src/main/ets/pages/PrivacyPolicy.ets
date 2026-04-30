import { router } from '@kit.ArkUI';

@Entry
@Component
struct PrivacyPolicy {
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

        Text('隐私协议')
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
          Text('赛事日历 隐私协议')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 16 })
            .padding({ left: 20, right: 20 })

          Text('最后更新日期：2026 年 4 月 30 日')
            .fontSize(11)
            .fontColor('#999999')
            .padding({ left: 20, right: 20 })
            .margin({ bottom: 20 })

          this.section('一、应用简介',
            '赛事日历是一款基于 HarmonyOS NEXT 开发的体育赛事赛程订阅工具，支持订阅中超联赛（16 支球队）和 2026 世界杯（48 支国家队）的比赛日程，将赛事信息同步到系统日历中。\n\n本应用为纯本地离线应用，无需联网即可使用全部功能。')

          this.section('二、我们如何收集和使用信息',
            '本应用不收集、不存储、不传输任何个人敏感信息。\n\n• 用户的球队选择偏好仅存储在本地设备中（通过 HarmonyOS 系统 Preferences），不会上传到任何服务器。\n• 应用不会收集您的姓名、手机号、位置信息、设备标识符等个人数据。\n• 本应用不包含任何统计分析 SDK 或第三方追踪代码。')

          this.section('三、需要的系统权限',
            '• 读取日历权限（READ_CALENDAR）：用于检查和管理已写入的比赛日程\n• 写入日历权限（WRITE_CALENDAR）：用于将比赛日程写入系统日历\n\n上述权限仅用于提供应用核心功能，不会用于其他用途。如果您拒绝授权日历权限，应用仍可正常浏览和选择球队，但无法将赛程写入系统日历。')

          this.section('四、数据来源',
            '赛程数据来源于 sports-calendar.com，已内嵌于应用中，仅作赛事信息参考之用。')

          this.section('五、第三方服务',
            '本应用的赛程数据（来源：sports-calendar.com）已内嵌于应用中，不涉及任何网络请求或用户个人信息交互。')

          this.section('六、数据安全',
            '所有数据均存储在您的本地设备中，应用不涉及任何云端数据传输。您可随时在应用中删除已订阅的赛程日历。')

          this.section('七、隐私政策的变更',
            '本隐私政策可能会根据功能更新或法规要求进行修改。变更后的隐私政策将通过应用内更新发布。')

          Text('如有任何疑问，请通过应用商店联系开发者。')
            .fontSize(12)
            .fontColor('#666666')
            .lineHeight(20)
            .padding({ left: 20, right: 20 })
            .margin({ top: 20, bottom: 40 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  section(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })
      Text(content)
        .fontSize(12)
        .fontColor('#666666')
        .lineHeight(20)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .backgroundColor('#ffffff')
    .margin({ bottom: 8 })
  }
}
