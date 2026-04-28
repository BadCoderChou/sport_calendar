import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

const STORE_NAME = 'sportcalendar_store';

export class TeamStore {
  private static pref: preferences.Preferences | null = null;

  private static async getPref(): Promise<preferences.Preferences> {
    if (!TeamStore.pref) {
      const context = getContext() as common.UIAbilityContext;
      TeamStore.pref = await preferences.getPreferences(context, STORE_NAME);
    }
    return TeamStore.pref!;
  }

  static async getSubscribedIds(): Promise<string[]> {
    const pref = await TeamStore.getPref();
    const json = await pref.get('subscribedIds', '[]');
    return JSON.parse(json as string) as string[];
  }

  static async setSubscribedIds(ids: string[]): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('subscribedIds', JSON.stringify(ids));
    await pref.flush();
  }

  static async getLastSyncTime(): Promise<number> {
    const pref = await TeamStore.getPref();
    const val = await pref.get('lastSyncTime', 0);
    return val as number;
  }

  static async setLastSyncTime(time: number): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('lastSyncTime', time);
    await pref.flush();
  }

  static async getLastSyncCount(teamId: string): Promise<number> {
    const pref = await TeamStore.getPref();
    const countsJson = await pref.get('lastSyncCounts', '{}');
    const counts = JSON.parse(countsJson as string) as Record<string, number>;
    return counts[teamId] || 0;
  }

  static async setLastSyncCount(teamId: string, count: number): Promise<void> {
    const pref = await TeamStore.getPref();
    const countsJson = await pref.get('lastSyncCounts', '{}');
    const counts = JSON.parse(countsJson as string) as Record<string, number>;
    counts[teamId] = count;
    await pref.put('lastSyncCounts', JSON.stringify(counts));
    await pref.flush();
  }

  static async isSubscribed(teamId: string): Promise<boolean> {
    const ids = await TeamStore.getSubscribedIds();
    return ids.includes(teamId);
  }

  static async toggleSubscription(teamId: string): Promise<boolean> {
    const ids = await TeamStore.getSubscribedIds();
    const index = ids.indexOf(teamId);
    if (index >= 0) {
      ids.splice(index, 1);
    } else {
      ids.push(teamId);
    }
    await TeamStore.setSubscribedIds(ids);
    return index < 0;
  }

  // --- World Cup subscription state ---

  static async getWcSubscribedIds(): Promise<string[]> {
    const pref = await TeamStore.getPref();
    const json = await pref.get('wc_subscribedIds', '[]');
    return JSON.parse(json as string) as string[];
  }

  static async setWcSubscribedIds(ids: string[]): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('wc_subscribedIds', JSON.stringify(ids));
    await pref.flush();
  }

  static async toggleWcSubscription(countryId: string): Promise<boolean> {
    const ids = await TeamStore.getWcSubscribedIds();
    const index = ids.indexOf(countryId);
    if (index >= 0) {
      ids.splice(index, 1);
    } else {
      ids.push(countryId);
    }
    await TeamStore.setWcSubscribedIds(ids);
    return index < 0;
  }

  static async isWcSubscribed(countryId: string): Promise<boolean> {
    const ids = await TeamStore.getWcSubscribedIds();
    return ids.includes(countryId);
  }

  static async getWcLastSyncTime(): Promise<number> {
    const pref = await TeamStore.getPref();
    const val = await pref.get('wc_lastSyncTime', 0);
    return val as number;
  }

  static async setWcLastSyncTime(time: number): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('wc_lastSyncTime', time);
    await pref.flush();
  }
}
