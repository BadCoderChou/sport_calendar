@Component
export struct OnboardingOverlay {
  @State show: boolean = false;
  @State currentStep: number = 0;
  totalSteps: number = 3;
  onSkip: () => void = () => {};
  onFinish: () => void = () => {};

  private stepTitles: string[] = ['选择联赛', '选择球队', '订阅日程'];
  private stepDescs: string[] = [
    '底部有「中超联赛」和「世界杯」两个分类，点击切换',
    '点击卡片选中你关注的球队，可多选',
    '选中后点击底部「订阅日程」写入系统日历',
  ];

  build() {
    Stack() {
      if (this.show) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.6)')
          .onClick(() => {})

        Column() {
          Row() {
            Text('跳过')
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => this.onSkip())
          }
          .width('100%')
          .justifyContent(FlexAlign.End)

          Blank()

          Row() {
            ForEach([0, 1, 2], (step: number) => {
              Column() {
                if (step === this.currentStep) {
                  Text(`${step + 1}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ffffff')
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor($r('app.color.brand_primary'))
                    .textAlign(TextAlign.Center)
                } else {
                  Text(`${step + 1}`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_hint'))
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .backgroundColor($r('app.color.text_primary'))
                    .textAlign(TextAlign.Center)
                }
              }
              .margin({ left: 4, right: 4 })
            }, (step: number) => step.toString())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Blank()

          Text(`第 ${this.currentStep + 1} 步：${this.stepTitles[this.currentStep]}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')

          Text(this.stepDescs[this.currentStep])
            .fontSize(13)
            .fontColor('#cccccc')
            .margin({ top: 12, left: 24, right: 24 })
            .textAlign(TextAlign.Center)

          Blank()

          Button(this.currentStep < this.totalSteps - 1 ? '下一步 →' : '开始使用 ✓')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.brand_primary'))
            .fontColor(Color.White)
            .borderRadius(16)
            .height(36)
            .fontSize(14)
            .width('70%')
            .margin({ bottom: 40 })
            .onClick(() => {
              if (this.currentStep < this.totalSteps - 1) {
                this.currentStep++;
              } else {
                this.onFinish();
              }
            })

          Row() {
            ForEach([0, 1, 2], (step: number) => {
              Column()
                .width(step === this.currentStep ? 10 : 6)
                .height(4)
                .borderRadius(2)
                .backgroundColor(step === this.currentStep ? $r('app.color.brand_primary') : $r('app.color.divider_color'))
                .margin({ left: 3, right: 3 })
            }, (step: number) => step.toString())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 20 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(this.show ? '100%' : 0)
    .height(this.show ? '100%' : 0)
    .position({ x: 0, y: 0 })
    .zIndex(999)
  }
}
