import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';

export class DataService {
  static async loadIcs(context: common.UIAbilityContext, fileName: string): Promise<string> {
    try {
      const rawFile = await context.resourceManager.getRawFileContent(fileName);
      return buffer.from(rawFile.buffer).toString('utf-8');
    } catch (e) {
      throw new Error(`加载赛程数据失败: ${fileName}`);
    }
  }
}
