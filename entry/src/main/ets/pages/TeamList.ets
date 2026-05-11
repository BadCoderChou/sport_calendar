import { router } from '@kit.ArkUI';
import { TeamStore } from '../services/TeamStore';
import { CSL_TEAMS, WORLD_CUP_TEAMS, Team, WorldCupTeam } from '../constants/Teams';

@Entry
@Component
struct TeamListPage {
  @State currentLeague: number = 0;
  @State subscribedCslIds: string[] = [];
  @State subscribedWcIds: string[] = [];

  async aboutToAppear(): Promise<void> {
    this.subscribedCslIds = await TeamStore.getSubscribedIds();
    this.subscribedWcIds = await TeamStore.getWcSubscribedIds();
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
        Text('选择球队')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))

      // 联赛 Tab
      Tabs({ index: this.currentLeague }) {
        TabContent() {
          this.CslGrid()
        }.tabBar('中超联赛')

        TabContent() {
          this.WcGrid()
        }.tabBar('世界杯')
      }
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentLeague = index;
      })
      .barMode(BarMode.Fixed)
      .animationDuration(200)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  CslGrid() {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(CSL_TEAMS, (team: Team) => {
          this.TeamCard(team.name, team.logo, true, this.subscribedCslIds.includes(team.id), () => {
            router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
          })
        }, (team: Team) => team.id)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WcGrid() {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(WORLD_CUP_TEAMS, (team: WorldCupTeam) => {
          this.WcTeamCard(team.name, team.emoji, this.subscribedWcIds.includes(team.id), () => {
            router.pushUrl({ url: 'pages/TeamDetail', params: { teamId: team.id } });
          })
        }, (team: WorldCupTeam) => team.id)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TeamCard(name: string, logo: ResourceStr, isCsl: boolean, subscribed: boolean, action: () => void) {
    Column() {
      Stack() {
        Image(logo)
          .width(44)
          .height(44)
          .borderRadius(8)
        if (subscribed) {
          Text('✓')
            .fontSize(12)
            .fontColor(Color.White)
            .width(18)
            .height(18)
            .borderRadius(9)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.brand_success'))
            .position({ x: '70%', y: -4 })
        }
      }
      .width(44)
      .height(44)
      Text(name)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .constraintSize({ maxWidth: 76 })
    }
    .width(80)
    .height(80)
    .margin({ left: 6, right: 6, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(subscribed ? $r('app.color.card_bg_subscribed') : $r('app.color.card_bg'))
    .borderWidth(subscribed ? 1.5 : 0)
    .borderColor(subscribed ? $r('app.color.brand_success') : Color.Transparent)
    .onClick(action)
  }

  @Builder
  WcTeamCard(name: string, emoji: string, subscribed: boolean, action: () => void) {
    Column() {
      Stack() {
        Text(emoji)
          .fontSize(30)
        if (subscribed) {
          Text('✓')
            .fontSize(12)
            .fontColor(Color.White)
            .width(18)
            .height(18)
            .borderRadius(9)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.brand_success'))
            .position({ x: '70%', y: -4 })
        }
      }
      .width(44)
      .height(44)
      Text(name)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .constraintSize({ maxWidth: 76 })
    }
    .width(80)
    .height(80)
    .margin({ left: 6, right: 6, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(subscribed ? $r('app.color.card_bg_subscribed') : $r('app.color.card_bg'))
    .borderWidth(subscribed ? 1.5 : 0)
    .borderColor(subscribed ? $r('app.color.brand_success') : Color.Transparent)
    .onClick(action)
  }
}
