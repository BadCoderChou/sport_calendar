import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DataService } from '../services/DataService';

const DOMAIN = 0xFF00;

@Entry
@Component
struct SettingsPage {
  @State versionName: string = 'v1.1.0';

  async clearCacheAction(): Promise<void> {
    const context = getContext() as common.UIAbilityContext;
    await DataService.clearCache(context);
    promptAction.showToast({ message: '缓存已清除', duration: 2000, alignment: Alignment.Center });
  }

  async openAppSettings(): Promise<void> {
    const context = getContext() as common.UIAbilityContext;
    const bundleName = context.abilityInfo.bundleName;
    try {
      await context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: { pushParams: bundleName },
      });
      return;
    } catch (e) {
      hilog.warn(DOMAIN, 'Settings', 'Direct app settings failed');
    }
    try {
      await context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
      });
    } catch (e2) {
      promptAction.showToast({ message: '请前往系统设置修改应用外观' });
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
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

      // 设置项列表
      Column() {
        this.SettingRow('系统外观设置', () => this.openAppSettings())
        Divider().color($r('app.color.divider_color'))

        this.SettingRow('清除缓存', () => this.clearCacheAction())
        Divider().color($r('app.color.divider_color'))

        this.SettingRow('隐私协议', () => {
          router.pushUrl({ url: 'pages/PrivacyPolicy' });
        })
        Divider().color($r('app.color.divider_color'))

        this.SettingRow('更新日志', () => {
          router.pushUrl({ url: 'pages/Changelog' });
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(12)
      .margin({ top: 16, left: 16, right: 16 })
      .padding({ left: 16, right: 16 })

      // 版本号
      Text(this.versionName)
        .fontSize(12)
        .fontColor($r('app.color.text_hint'))
        .margin({ top: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  SettingRow(title: string, action: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text('>')
        .fontSize(16)
        .fontColor($r('app.color.text_hint'))
    }
    .width('100%')
    .height(52)
    .onClick(action)
  }
}
