import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { OBS_BASE_URL, META_PATH } from '../constants/ApiConfig';
import { TeamStore } from './TeamStore';

interface MetaInfo {
  version: number;
  updated: string;
  files: Record<string, number>;
}

const CACHE_DIR = 'ics_cache';

export class DataService {
  static async loadIcs(context: common.UIAbilityContext, path: string): Promise<string> {
    const cached = await DataService.getCachedIcs(context, path);
    if (cached !== null) {
      return cached;
    }
    const fetched = await DataService.fetchAndCache(context, path);
    if (fetched !== null) {
      return fetched;
    }
    return DataService.readRawFile(context, path);
  }

  static async getCachedIcs(context: common.UIAbilityContext, path: string): Promise<string | null> {
    try {
      const cachePath = `${context.filesDir}/${CACHE_DIR}/${path}`;
      if (fs.accessSync(cachePath)) {
        const file = fs.openSync(cachePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(cachePath);
        const buf = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buf);
        fs.closeSync(file);
        return buffer.from(buf).toString('utf-8');
      }
    } catch (_) {
    }
    return null;
  }

  static async fetchAndCache(context: common.UIAbilityContext, path: string): Promise<string | null> {
    try {
      const url = `${OBS_BASE_URL}/${path}`;
      const resp = await DataService.httpGet(url);
      if (resp.responseCode === 200 && resp.result) {
        await DataService.writeCache(context, path, resp.result as string);
        return resp.result as string;
      }
    } catch (_) {
    }
    return null;
  }

  static async readRawFile(context: common.UIAbilityContext, path: string): Promise<string> {
    const rawFile = await context.resourceManager.getRawFileContent(path);
    return buffer.from(rawFile.buffer).toString('utf-8');
  }

  static async fetchMeta(): Promise<MetaInfo | null> {
    try {
      const url = `${OBS_BASE_URL}/${META_PATH}`;
      const resp = await DataService.httpGet(url);
      if (resp.responseCode === 200 && resp.result) {
        return JSON.parse(resp.result as string) as MetaInfo;
      }
    } catch (_) {
    }
    return null;
  }

  static async syncIfNeeded(context: common.UIAbilityContext): Promise<number> {
    const meta = await DataService.fetchMeta();
    if (!meta) {
      return 0;
    }
    const localVersion = await TeamStore.getSyncVersion();
    if (meta.version <= localVersion) {
      return 0;
    }
    let syncCount = 0;
    const keys = Object.keys(meta.files);
    for (let i = 0; i < keys.length; i++) {
      try {
        const fetched = await DataService.fetchAndCache(context, keys[i]);
        if (fetched !== null) {
          syncCount++;
        }
      } catch (_) {
      }
    }
    await TeamStore.setSyncVersion(meta.version);
    await TeamStore.setLastDataSyncTime(Date.now());
    return syncCount;
  }

  static async clearCache(context: common.UIAbilityContext): Promise<void> {
    const cacheDir = `${context.filesDir}/${CACHE_DIR}`;
    try {
      if (fs.accessSync(cacheDir)) {
        const files = fs.listFileSync(cacheDir);
        for (const f of files) {
          fs.unlinkSync(`${cacheDir}/${f}`);
        }
      }
    } catch (_) {
    }
  }

  private static async httpGet(url: string): Promise<http.HttpResponse> {
    const httpClient = http.createHttp();
    try {
      const resp = await httpClient.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000,
        header: { 'Content-Type': 'application/json' },
      });
      return resp;
    } finally {
      httpClient.destroy();
    }
  }

  private static async writeCache(context: common.UIAbilityContext, path: string, content: string): Promise<void> {
    const cacheDir = `${context.filesDir}/${CACHE_DIR}`;
    const dirPath = `${cacheDir}/${path.substring(0, path.lastIndexOf('/'))}`;
    try {
      if (!fs.accessSync(cacheDir)) {
        fs.mkdirSync(cacheDir);
      }
      if (dirPath && !fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath, true);
      }
      const filePath = `${cacheDir}/${path}`;
      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (_) {
    }
  }
}
