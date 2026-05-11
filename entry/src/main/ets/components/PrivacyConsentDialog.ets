import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Component
export struct PrivacyConsentDialog {
  onAgree: () => void = () => {};

  build() {
    Column() {
      Column() {
        Text('隐私政策提示')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('在使用赛事日历之前，请您仔细阅读并了解')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(22)

        Row() {
          Text('《隐私协议》')
            .fontSize(13)
            .fontColor($r('app.color.brand_primary'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              router.pushUrl({ url: 'pages/PrivacyPolicy' });
            })
        }
        .margin({ top: 4, bottom: 4 })

        Text('我们将严格按照政策内容保护您的个人信息安全。您可随时在应用内删除已订阅的赛程日历。')
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
          .lineHeight(20)
          .margin({ bottom: 20 })

        Row() {
          Button('不同意')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.page_bg'))
            .fontColor($r('app.color.text_secondary'))
            .borderRadius(22)
            .height(40)
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => {
              const ctx = getContext() as common.UIAbilityContext;
              ctx.terminateSelf();
            })

          Button('同意')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.brand_primary'))
            .fontColor(Color.White)
            .borderRadius(22)
            .height(40)
            .fontSize(14)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.onAgree();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .margin({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
  }
}
