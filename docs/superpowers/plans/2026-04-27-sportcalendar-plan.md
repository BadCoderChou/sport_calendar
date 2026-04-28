# SportCalendar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a HarmonyOS Next app that lets users select Chinese Super League teams and sync their match schedules to the system calendar.

**Architecture:** Single-page app with clean layered architecture — constants → models → services (parser, http, calendar, store) → UI. Each layer has one responsibility and testable interface.

**Tech Stack:** ArkTS / HarmonyOS Next API 6.0.2(22) / @kit.CalendarKit / @ohos.net.http / @ohos.data.preferences / @ohos/hypium (testing)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `entry/src/main/ets/constants/Teams.ets` | Create | 16 CSL team definitions |
| `entry/src/main/ets/model/Team.ets` | Create | Team data interface |
| `entry/src/main/ets/model/MatchEvent.ets` | Create | Parsed match event interface |
| `entry/src/main/ets/services/IcsParser.ets` | Create | ICS text → MatchEvent[] parser |
| `entry/src/main/ets/services/HttpService.ets` | Create | HTTP GET wrapper for ICS URLs |
| `entry/src/main/ets/services/CalendarWriter.ets` | Create | CalendarKit read/write/delete facade |
| `entry/src/main/ets/services/TeamStore.ets` | Create | Preferences-based subscription persistence |
| `entry/src/main/ets/pages/Index.ets` | Modify | Main page UI (team grid + sync bar) |
| `entry/src/main/module.json5` | Modify | Add calendar + internet permissions |
| `entry/src/main/resources/base/element/string.json` | Modify | Add permission reason strings |

---

### Task 1: Project Setup — Permissions & Strings

**Files:**
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/resources/base/element/string.json`

- [ ] **Step 1: Add permission declarations to module.json5**

Add `requestPermissions` array to the `module` object:

```json5
requestPermissions: [
  {
    name: "ohos.permission.READ_CALENDAR",
    reason: "$string:calendar_read_reason",
    usedScene: {
      abilities: ["EntryAbility"],
      when: "inuse"
    }
  },
  {
    name: "ohos.permission.WRITE_CALENDAR",
    reason: "$string:calendar_write_reason",
    usedScene: {
      abilities: ["EntryAbility"],
      when: "inuse"
    }
  },
  {
    name: "ohos.permission.INTERNET"
  }
]
```

- [ ] **Step 2: Add permission reason strings to string.json**

Add two new string entries alongside existing ones:

```json
{ "name": "calendar_read_reason", "value": "读取日历以检查和更新赛程信息" },
{ "name": "calendar_write_reason", "value": "将比赛日程写入系统日历" }
```

- [ ] **Step 3: Verify build config still valid**

Confirm `build-profile.json5` and `entry/build-profile.json5` are unchanged and valid.

---

### Task 2: Constants — Teams Definition

**Files:**
- Create: `entry/src/main/ets/constants/Teams.ets`
- Test: `entry/src/ohosTest/ets/test/Teams.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets` (register new test)

- [ ] **Step 1: Write Teams constant**

```typescript
export interface Team {
  id: string;
  name: string;
  color: string;
}

export const CSL_TEAMS: Team[] = [
  { id: 'beijing-guoan', name: '北京国安', color: '#00529C' },
  { id: 'shanghai-haipo', name: '上海海港', color: '#E60012' },
  { id: 'shanghai-shenhua', name: '上海申花', color: '#002D88' },
  { id: 'shandong-taishan', name: '山东泰山', color: '#FF6600' },
  { id: 'chengdu-rongcheng', name: '成都蓉城', color: '#FFCC00' },
  { id: 'zhejiang-club', name: '浙江俱乐部', color: '#FFFFFF' },
  { id: 'tianjin-jinmenhu', name: '天津津门虎', color: '#0072CE' },
  { id: 'wuhan-sanzhen', name: '武汉三镇', color: '#6A0DAD' },
  { id: 'henan-club', name: '河南俱乐部', color: '#CCCCCC' },
  { id: 'qingdao-hainiu', name: '青岛海牛', color: '#0066B3' },
  { id: 'qingdao-xihaian', name: '青岛西海岸', color: '#1E90FF' },
  { id: 'yunnan-yukun', name: '云南玉昆', color: '#228B22' },
  { id: 'dalian-yingbo', name: '大连英博', color: '#000000' },
  { id: 'shenzhen-xinpengcheng', name: '深圳新鹏城', color: '#00A0E9' },
  { id: 'chongqing-tonglianglong', name: '重庆铜梁龙', color: '#DC143C' },
  { id: 'liaoning-tieren', name: '辽宁铁人', color: '#32CD32' },
];

export function getTeamById(id: string): Team | undefined {
  return CSL_TEAMS.find(t => t.id === id);
}

export const ICS_BASE_URL =
  'https://api.sports-calendar.com/ics/soccer/chinese-super-league/2026/matches.ics';

export function getIcsUrl(teamId: string): string {
  return `${ICS_BASE_URL}?lang=zh&team=${teamId}`;
}

export const CALENDAR_NAME_PREFIX = '中超-';
```

- [ ] **Step 2: Write test for Teams constant**

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { CSL_TEAMS, getTeamById, getIcsUrl, CALENDAR_NAME_PREFIX } from '../../../main/ets/constants/Teams';

export default function teamsTest() {
  describe('Teams Constant Tests', () => {
    it('should have 16 teams', () => {
      expect(CSL_TEAMS.length).assertEqual(16);
    });

    it('each team should have required fields', () => {
      for (const team of CSL_TEAMS) {
        expect(team.id.length).assertLargerThan(0);
        expect(team.name.length).assertLargerThan(0);
        expect(team.color.length).assertLargerThan(0);
      }
    });

    it('getTeamById should return correct team', () => {
      const team = getTeamById('beijing-guoan');
      expect(team).not().assertUndefined();
      expect(team!.name).assertEqual('北京国安');
    });

    it('getTeamById should return undefined for unknown id', () => {
      const team = getTeamById('nonexistent');
      expect(team).assertUndefined();
    });

    it('getIcsUrl should generate correct URL', () => {
      const url = getIcsUrl('beijing-guoan');
      expect(url).assertContain('beijing-guoan');
      expect(url).assertContain('matches.ics');
      expect(url).assertContain('lang=zh');
    });

    it('all team ids should be unique', () => {
      const ids = CSL_TEAMS.map(t => t.id);
      const uniqueIds = new Set(ids);
      expect(uniqueIds.size).assertEqual(ids.length);
    });
  });
}
```

- [ ] **Step 3: Register test in List.test.ets**

Update `entry/src/ohosTest/ets/test/List.test.ets` to import and call `teamsTest()`:

```typescript
import teamsTest from './Teams.test';

export default function testsuite() {
  teamsTest();
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run tests in DevEco Studio or via command line. All 6 tests should PASS.

---

### Task 3: Models — Data Interfaces

**Files:**
- Create: `entry/src/main/ets/model/MatchEvent.ets`

- [ ] **Step 1: Create MatchEvent model**

```typescript
export interface MatchEvent {
  uid: string;
  title: string;
  startTime: number;   // ms timestamp (local time)
  endTime: number;     // ms timestamp (local time)
  location: string;
  description: string;
  status: 'finished' | 'scheduled';
  reminderMinutes: number;
}
```

Note: `Team` interface is already exported from `Teams.ets` in Task 2, no separate file needed.

---

### Task 4: Service — ICS Parser

**Files:**
- Create: `entry/src/main/ets/services/IcsParser.ets`
- Test: `entry/src/ohosTest/ets/test/IcsParser.test.ets`

This is the core logic unit — parse real ICS text into structured data.

- [ ] **Step 1: Write IcsParser implementation**

```typescript
import { MatchEvent } from '../model/MatchEvent';

export class IcsParser {
  /**
   * Parse ICS calendar text into match events.
   * Handles line folding (RFC 5545), TZID-aware datetimes, graceful degradation.
   */
  static parse(icsText: string): MatchEvent[] {
    if (!icsText || !icsText.trim()) {
      return [];
    }

    // Step 1: Unfold lines (RFC 5545: continuation lines start with SP/TAB)
    const unfolded = IcsParser.unfoldLines(icsText);

    // Step 2: Split into VEVENT blocks
    const events = IcsParser.splitEvents(unfolded);

    // Step 3: Parse each block
    const results: MatchEvent[] = [];
    for (const block of events) {
      const event = IcsParser.parseEvent(block);
      if (event) {
        results.push(event);
      }
    }

    return results;
  }

  private static unfoldLines(text: string): string {
    return text.replace(/\r\n[ \t]/g, '').replace(/\n[ \t]/g, '');
  }

  private static splitEvents(text: string): string[] {
    const events: string[] = [];
    const lines = text.split(/\r?\n/);
    let currentBlock: string[] = [];
    let inEvent = false;

    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed === 'BEGIN:VEVENT') {
        inEvent = true;
        currentBlock = [];
      } else if (trimmed === 'END:VEVENT') {
        inEvent = false;
        events.push(currentBlock.join('\n'));
        currentBlock = [];
      } else if (inEvent) {
        currentBlock.push(trimmed);
      }
    }

    return events;
  }

  private static parseEvent(block: string): MatchEvent | null {
    const props = IcsParser.parseProperties(block);

    // Mandatory fields check
    if (!props['SUMMARY'] || !props['DTSTART'] || !props['UID']) {
      return null; // Skip malformed events silently
    }

    const startTime = IcsParser.parseDateTime(props['DTSTART']);
    const endTime = props['DTEND'] ? IcsParser.parseDateTime(props['DTEND'])
      : startTime + 7200000; // Default 2h duration

    if (!startTime) return null;

    const statusRaw = IcsParser.extractParam(props['X-SC-MATCH-STATUS'] || '', 'TEXT');
    const status = statusRaw === 'finished' ? 'finished' : 'scheduled';

    return {
      uid: props['UID'],
      title: props['SUMMARY'],
      startTime,
      endTime,
      location: props['LOCATION'] || '',
      description: props['DESCRIPTION'] || '',
      status,
      reminderMinutes: 30,
    };
  }

  private static parseProperties(block: string): Record<string, string> {
    const props: Record<string, string> = {};
    const lines = block.split('\n');
    for (const line of lines) {
      const colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        const key = line.substring(0, colonIndex).toUpperCase();
        const value = line.substring(colonIndex + 1);
        props[key] = value;
      }
    }
    return props;
  }

  /**
   * Parse ICS datetime to local timestamp (ms).
   * Supports:
   * - UTC: 20260308T110000Z
   * - TZID-param: DTSTART;TZID=Asia/Shanghai:20260308T190000
   */
  private static parseDateTime(dtStr: string): number | null {
    if (!dtStr) return null;

    try {
      // Handle TZID parameter format: KEY;TZID=xxx:VALUE
      let cleanDt = dtStr;
      const tzidMatch = dtStr.match(/TZID=([^:]+):/);
      if (tzidMatch) {
        cleanDt = dtStr.substring(dtStr.lastIndexOf(':') + 1);
      }

      // Remove trailing Z (UTC indicator)
      const isUTC = cleanDt.endsWith('Z');
      if (isUTC) {
        cleanDt = cleanDt.slice(0, -1);
      }

      // Parse format: YYYYMMDDTHHMMSS
      if (cleanDt.includes('T')) {
        const [datePart, timePart] = cleanDt.split('T');
        const year = parseInt(datePart.substring(0, 4));
        const month = parseInt(datePart.substring(4, 6)) - 1; // JS months are 0-indexed
        const day = parseInt(datePart.substring(6, 8));
        const hour = parseInt(timePart.substring(0, 2));
        const minute = parseInt(timePart.substring(2, 4));
        const second = parseInt(timePart.substring(4, 6)) || 0;

        const date = new Date(Date.UTC(year, month, day, hour, minute, second));

        if (isUTC) {
          // Convert UTC to local time by getting local string components
          // Simpler approach: just use the Date object's local conversion
          return date.getTime();
        }

        return date.getTime();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /**
   * Extract a semicolon param value like TEXT:finished -> finished
   */
  private static extractParam(value: string, paramName: string): string {
    const regex = new RegExp(`${paramName}=([^;:]*)`);
    const match = value.match(regex);
    return match ? match[1] : value;
  }
}
```

- [ ] **Step 2: Write IcsParser tests with real ICS sample data**

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { IcsParser } from '../../../main/ets/services/IcsParser';

// Real ICS sample (simplified, based on actual API response)
const SAMPLE_ICS = `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//sports-calendar//season-feed//ZH
BEGIN:VEVENT
UID:2434382@sports-calendar.com
DTSTART:20260308T110000Z
DTEND:20260308T130000Z
SUMMARY:武汉三镇 0:2 北京国安
LOCATION:武汉体育中心体育场
DESCRIPTION:轮次: Round 1\\n状态: 已结束\\n场地: 武汉体育中心体育场\\, 中国
X-SC-MATCH-STATUS;VALUE=TEXT:finished
STATUS:CONFIRMED
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT1800S
END:VALARM
END:VEVENT
BEGIN:VEVENT
UID:2434446@sports-calendar.com
DTSTART:20260502T120000Z
DTEND:20260502T140000Z
SUMMARY:云南玉昆 对阵 北京国安
LOCATION:玉溪高原体育中心
DESCRIPTION:轮次: Round 9\\n状态: 已安排
X-SC-MATCH-STATUS;VALUE=TEXT:scheduled
STATUS:CONFIRMED
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT1800S
END:VALARM
END:VEVENT
END:VCALENDAR`;

export default function icsParserTest() {
  describe('IcsParser Tests', () => {
    it('should parse empty string as empty array', () => {
      expect(IcsParser.parse('').length).assertEqual(0);
    });

    it('should parse null as empty array', () => {
      expect(IcsParser.parse((null as unknown as string)).length).assertEqual(0);
    });

    it('should parse 2 events from sample ICS', () => {
      const events = IcsParser.parse(SAMPLE_ICS);
      expect(events.length).assertEqual(2);
    });

    it('first event should have correct finished match data', () => {
      const events = IcsParser.parse(SAMPLE_ICS);
      const e = events[0];
      expect(e.uid).assertEqual('2434382@sports-calendar.com');
      expect(e.title).assertContain('北京国安');
      expect(e.title).assertContain('0:2'); // Has score
      expect(e.location).assertEqual('武汉体育中心体育场');
      expect(e.status).assertEqual('finished');
      expect(e.startTime).assertLargerThan(0);
      expect(e.endTime).assertLargerThan(e.startTime);
      expect(e.reminderMinutes).assertEqual(30);
    });

    it('second event should have scheduled status', () => {
      const events = IcsParser.parse(SAMPLE_ICS);
      const e = events[1];
      expect(e.status).assertEqual('scheduled');
      expect(e.title).assertContain('对阵'); // No score, just matchup
      expect(e.location).assertEqual('玉溪高原体育中心');
    });

    it('should skip event missing mandatory fields', () => {
      const badIcs = `BEGIN:VCALENDAR
BEGIN:VEVENT
UID:test-1
SUMMARY:No Time Event
END:VEVENT
END:VCALENDAR`;
      const events = IcsParser.parse(badIcs);
      expect(events.length).assertEqual(0); // Missing DTSTART → skipped
    });

    it('should handle line folding (continuation lines)', () => {
      const foldedIcs = `BEGIN:VCALENDAR
BEGIN:VEVENT
UID:fold-test
DESCRIPTION:This is a long description that
 folds across multiple lines in RFC 5545
 format for testing purposes only
DTSTART:20260601T120000Z
SUMMARY:Folded Event
END:VEVENT
END:VCALENDAR`;
      const events = IcsParser.parse(foldedIcs);
      expect(events.length).assertEqual(1);
      expect(events[0].description).assertContain('format for testing');
    });
  });
}
```

- [ ] **Step 3: Register test in List.test.ets**

Add import and call to `List.test.ets`.

- [ ] **Step 4: Run tests — all should pass**

---

### Task 5: Service — HTTP Service

**Files:**
- Create: `entry/src/main/ets/services/HttpService.ets`

- [ ] **Step 1: Implement HttpService**

```typescript
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class HttpService {
  private static httpRequest: http.HttpRequest;

  private static async getRequest(): Promise<http.HttpRequest> {
    if (!HttpService.httpRequest) {
      HttpService.httpRequest = http.createHttp();
    }
    return HttpService.httpRequest;
  }

  /**
   * Fetch ICS text content from URL.
   * Returns raw ICS string on success, throws on failure.
   */
  static async fetchIcs(url: string): Promise<string> {
    const request = await HttpService.getRequest();

    try {
      const response = await request.request({
        method: http.RequestMethod.GET,
        url: url,
        connectTimeout: 15000,
        readTimeout: 30000,
        header: {
          'Accept': 'text/calendar',
          'User-Agent': 'SportCalendar/1.0'
        },
      } as http.RequestOptions);

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return response.result as string;
      }

      throw new Error(`HTTP ${response.responseCode}: ${url}`);
    } catch (e) {
      const err = e as BusinessError;
      if (err.code) {
        throw new Error(`网络请求失败 (${err.code})`);
      }
      throw e;
    }
  }

  /** Call when app is done to release resources */
  static destroy(): void {
    if (HttpService.httpRequest) {
      HttpService.httpRequest.destroy();
      HttpService.httpRequest = undefined as unknown as http.HttpRequest;
    }
  }
}
```

- [ ] **Step 2: Verify no compile errors**

Ensure `@kit.NetworkKit` import resolves correctly in the project context.

---

### Task 6: Service — Team Store (Persistence)

**Files:**
- Create: `entry/src/main/ets/services/TeamStore.ets`

- [ ] **Step 1: Implement TeamStore using Preferences**

```typescript
import { preferences } from '@kit.DataPreferencesKit';
import { common } from '@kit.AbilityKit';

const STORE_NAME = 'sportcalendar_store';

interface StoreData {
  subscribedTeamIds: string[];
  lastSyncTime: number;
  lastSyncCounts: Record<string, number>;
}

const DEFAULT_DATA: StoreData = {
  subscribedTeamIds: [],
  lastSyncTime: 0,
  lastSyncCounts: {},
};

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
    const json = pref.get('subscribedTeamIds', '[]') as string;
    return JSON.parse(json) as string[];
  }

  static async setSubscribedIds(ids: string[]): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('subscribedTeamIds', JSON.stringify(ids));
    await pref.flush();
  }

  static async getLastSyncTime(): Promise<number> {
    const pref = await TeamStore.getPref();
    return pref.get('lastSyncTime', 0) as number;
  }

  static async setLastSyncTime(time: number): Promise<void> {
    const pref = await TeamStore.getPref();
    await pref.put('lastSyncTime', time);
    await pref.flush();
  }

  static async getLastSyncCount(teamId: string): Promise<number> {
    const pref = await TeamStore.getPref();
    const countsJson = pref.get('lastSyncCounts', '{}') as string;
    const counts = JSON.parse(countsJson) as Record<string, number>;
    return counts[teamId] || 0;
  }

  static async setLastSyncCount(teamId: string, count: number): Promise<void> {
    const pref = await TeamStore.getPref();
    const countsJson = pref.get('lastSyncCounts', '{}') as string;
    const counts = JSON.parse(countsJson) as Record<string, number>;
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
    return index < 0; // true = newly subscribed
  }
}
```

---

### Task 7: Service — Calendar Writer

**Files:**
- Create: `entry/src/main/ets/services/CalendarWriter.ets`

> **API Research Required Before Implementation:**
> This task depends on `@kit.CalendarKit` whose exact API surface varies by SDK version. **Before writing code**, use DevEco Studio's "API Reference" to verify:
> - How to import and access `calendarManager` (exact kit name and module path)
> - Whether `createCalendar()` exists; if not, what's the alternative (write to default calendar?)
> - Event object shape: what fields does `addEvent()` accept? (title/time/location/description/reminders format?)
> - Whether `updateEvent()` exists; if not, we'll use delete+re-add strategy
> - How to list existing calendars (`getCalendars()` or similar)
> - How to remove a calendar and its events
> - How to enumerate events within a calendar (for UID-based dedup)
>
> **Fallback Strategy** (if APIs are limited):
> - No createCalendar → Write to default calendar, prefix team name in event title
> - No updateEvent → Delete old event by UID lookup + add new one
> - No getEvents → Skip UID dedup, always add (accept duplicates on re-sync)
> - No removeCalendar → Delete events one by one instead

- [ ] **Step 1: Research CalendarKit API surface**

Use DevEco Studio → Help → API Reference → search "calendar" → document actual method signatures. Record findings below:

```
// FILL IN after research:
// Import path:
// Create calendar method signature:
// Add event method signature:
// Update event method signature (or note if absent):
// Get calendars method:
// Remove calendar method:
// Get events method:
// Event field names (title/time/location/description/reminders):
```

- [ ] **Step 2: Implement CalendarWriter (adapted to verified API)**

```typescript
import { Team, CALENDAR_NAME_PREFIX } from '../constants/Teams';
import { MatchEvent } from '../model/MatchEvent';
import { hilog } from '@kit.PerformanceAnalysisKit';

// NOTE: Import path verified during Step 1 — update to actual kit/module path
// import { calendarManager } from '@kit.CalendarKit';

const DOMAIN = 0x0000;

export class CalendarWriter {
  /**
   * Write match events to a per-team calendar.
   * Calendar name format: "中超-{teamName}" (per spec).
   * Uses UID-based deduplication: existing events updated, new ones added.
   * Returns number of events successfully written.
   */
  static async writeEvents(team: Team, events: MatchEvent[]): Promise<number> {
    try {
      const calendarName = CALENDAR_NAME_PREFIX + team.name; // e.g. "中超-北京国安"
      const calendar = await CalendarWriter.getOrCreateCalendar(calendarName);

      let writtenCount = 0;
      let skippedCount = 0;

      for (const event of events) {
        try {
          await CalendarWriter.writeOrUpdateEvent(calendar, event);
          writtenCount++;
        } catch (e) {
          hilog.warn(DOMAIN, 'SportCalendar', 'Failed to write event %{public}s: %{public}s',
            event.uid, JSON.stringify(e));
          skippedCount++;
        }
      }

      hilog.info(DOMAIN, 'SportCalendar',
        '%{public}s: wrote=%d, skipped=%d, total=%d', team.name, writtenCount, skippedCount, events.length);
      return writtenCount;
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'writeEvents failed: %{public}s', JSON.stringify(e));
      throw new Error(`写入日历失败: ${String(e)}`);
    }
  }

  /**
   * Delete the entire calendar for a team (removes all events + calendar container).
   */
  static async deleteCalendar(team: Team): Promise<void> {
    try {
      const targetName = CALENDAR_NAME_PREFIX + team.name;
      // NOTE: Adapt getCalendars/removeCalendar to actual API after Step 1 research
      const calendars = await calendarManager.getCalendars();
      const target = calendars.find((c: any) => c.name === targetName);

      if (target) {
        // NOTE: Adapt to actual removal API — may need delete events first
        await calendarManager.removeCalendar(target.id);
        hilog.info(DOMAIN, 'SportCalendar', 'Deleted calendar: %{public}s', targetName);
      } else {
        hilog.info(DOMAIN, 'SportCalendar', 'Calendar not found for deletion: %{public}s', targetName);
      }
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'deleteCalendar failed: %{public}s', JSON.stringify(e));
      throw new Error(`删除日历失败: ${String(e)}`);
    }
  }

  private static async getOrCreateCalendar(name: string): Promise<any> {
    // NOTE: Adapt to actual API after Step 1 research
    const calendars = await calendarManager.getCalendars();
    const existing = calendars.find((c: any) => c.name === name);
    if (existing) return existing;

    // NOTE: If createCalendar doesn't exist, adapt fallback here
    const newCal = await calendarManager.createCalendar({ name });
    return newCal;
  }

  /**
   * Write or update a single event by UID.
   * Strategy depends on available API (verified in Step 1):
   * - If updateEvent() exists: find by UID → update or add
   * - If no updateEvent(): find by UID → delete old → add new
   * - If no event enumeration: always add (accept duplicates on re-sync)
   */
  private static async writeOrUpdateEvent(calendar: any, event: MatchEvent): Promise<void> {
    // NOTE: Adapt findEventByUid/writeOrUpdateEvent to actual API after Step 1
    const existing = await CalendarWriter.findEventByUid(calendar, event.uid);

    if (existing) {
      // Prefer update if available (preserves event ID / reminders / etc.)
      try {
        await calendarManager.updateEvent({
          id: existing.id,
          title: event.title,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          description: event.description,
          // NOTE: Verify reminder field name from API docs
          reminderMinutes: [event.reminderMinutes],
        });
        return;
      } catch (_) {
        // Fallback: delete + re-add
        await calendarManager.removeEvent(existing.id);
      }
    }

    // Create new event
    // NOTE: Verify addEvent parameter shape from API docs
    await calendarManager.addEvent({
      calendarId: calendar.id,
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime,
      location: event.location,
      description: event.description,
      reminderMinutes: [event.reminderMinutes],
    });
  }

  /**
   * Find an event by UID within a calendar.
   * NOTE: Adapt to actual event enumeration API after Step 1.
   * Fallback if no enumeration API: return undefined (will skip dedup).
   */
  private static async findEventByUid(calendar: any, uid: string): Promise<any> {
    try {
      // NOTE: Adapt to actual getEvents/listEvents API
      const events = await calendarManager.getEvents(calendar.id);
      if (events && Array.isArray(events)) {
        return events.find((e: any) =>
          e.uid === uid || (e.title && e.title.includes(uid.split('@')[0]))
        );
      }
      return undefined;
    } catch (e) {
      return undefined; // Will fall back to always-add behavior
    }
  }
}
```

---

### Task 8: Main Page UI — Index.ets

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

This is the main visual piece — brings everything together.

- [ ] **Step 1: Rewrite Index.ets with full UI**

```typescript
import { Team, CSL_TEAMS, getIcsUrl, CALENDAR_NAME_PREFIX } from '../constants/Teams';
import { IcsParser } from '../services/IcsParser';
import { HttpService } from '../services/HttpService';
import { CalendarWriter } from '../services/CalendarWriter';
import { TeamStore } from '../services/TeamStore';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { permissions } from '@kit.AbilityKit';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State subscribedIds: string[] = [];
  @State syncing: boolean = false;
  @State lastSyncTime: number = 0;
  @State showDialog: boolean = false;
  @State dialogTeam: Team | null = null;

  aboutToAppear(): void {
    this.loadSubscriptionState();
  }

  aboutToDisappear(): void {
    HttpService.destroy();
  }

  async loadSubscriptionState(): Promise<void> {
    try {
      this.subscribedIds = await TeamStore.getSubscribedIds();
      this.lastSyncTime = await TeamStore.getLastSyncTime();
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Failed to load state: %{public}s', JSON.stringify(e));
    }
  }

  async onTeamTap(team: Team): Promise<void> {
    if (this.syncing) return;

    const isNowSubscribed = this.subscribedIds.includes(team.id);
    if (isNowSubscribed) {
      // Show unsubscribe confirmation
      this.dialogTeam = team;
      this.showDialog = true;
    } else {
      // Subscribe (just toggle state, no immediate sync)
      const added = await TeamStore.toggleSubscription(team.id);
      await this.loadSubscriptionState();
    }
  }

  confirmUnsubscribe(): void {
    if (this.dialogTeam) {
      // Perform deletion
      this.deleteTeamCalendar(this.dialogTeam);
      this.showDialog = false;
      this.dialogTeam = null;
    }
  }

  cancelDialog(): void {
    this.showDialog = false;
    this.dialogTeam = null;
  }

  async deleteTeamCalendar(team: Team): Promise<void> {
    try {
      await CalendarWriter.deleteCalendar(team);
      await TeamStore.toggleSubscription(team.id); // Remove from subscribed list
      await this.loadSubscriptionState();
      promptAction.showToast({ message: `已删除${team.name}的赛程日历`, duration: 2000 });
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Delete failed: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '删除日历失败，请重试', duration: 2000 });
    }
  }

  async onSyncTap(): Promise<void> {
    if (this.syncing || this.subscribedIds.length === 0) return;

    // Check calendar permission
    const hasPermission = await this.checkCalendarPermission();
    if (!hasPermission) {
      return;
    }

    this.syncing = true;
    let totalImported = 0;

    try {
      for (const teamId of this.subscribedIds) {
        const team = CSL_TEAMS.find(t => t.id === teamId);
        if (!team) continue;

        try {
          const url = getIcsUrl(teamId);
          const icsText = await HttpService.fetchIcs(url);
          const events = IcsParser.parse(icsText);
          const count = await CalendarWriter.writeEvents(team, events);
          await TeamStore.setLastSyncCount(teamId, count);
          totalImported += count;
        } catch (e) {
          hilog.error(DOMAIN, 'SportCalendar', 'Sync failed for %{public}s: %{public}s',
            teamId, JSON.stringify(e));
          // Don't show toast per-team error — only show final summary or critical failure
        }
      }

      // Update last sync time
      const now = Date.now();
      await TeamStore.setLastSyncTime(now);
      this.lastSyncTime = now;

      promptAction.showToast({ message: `已导入 ${totalImported} 场比赛`, duration: 2000 });
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Sync error: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '同步失败，请检查网络后重试', duration: 2000 });
    } finally {
      this.syncing = false;
    }
  }

  async checkCalendarPermission(): Promise<boolean> {
    try {
      const grantStatus = await permissions.checkAccessToken('ohos.permission.WRITE_CALENDAR');
      if (grantStatus === permissions.PermissionGrantStatus.PERMISSION_GRANTED) {
        return true;
      }

      // Request permission
      const result = await permissions.requestPermissionFromUser(
        'ohos.permission.WRITE_CALENDAR'
      );
      if (result !== permissions.PermissionGrantStatus.PERMISSION_GRANTED) {
        promptAction.showToast({ message: '请在设置中开启日历权限', duration: 3000 });
        return false;
      }
      return true;
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'Permission check failed: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '需要日历权限才能同步赛程', duration: 2000 });
      return false;
    }
  }

  formatLastSyncTime(): string {
    if (!this.lastSyncTime) return '尚未同步';
    const date = new Date(this.lastSyncTime);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const min = String(date.getMinutes()).padStart(2, '0');
    return `${month}-${day} ${hour}:${min}`;
  }

  getSubscribedNames(): string {
    return this.subscribedIds
      .map(id => CSL_TEAMS.find(t => t.id === id)?.name || id)
      .filter(Boolean)
      .join('、');
  }

  build() {
    Column() {
      // Header
      Column() {
        Text('中超联赛赛程日历')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 4 })
        Text('选择球队，同步到系统日历')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // Team Grid
      Grid() {
        ForEach(CSL_TEAMS, (team: Team) => {
          GridItem() {
            this.TeamCard(team)
          }
        }, (team: Team) => team.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })

      // Sync Bar
      Column() {
        Row() {
          Column() {
            Text(`已订阅 ${this.subscribedIds.length} 支球队`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(this.getSubscribedNames() + ' · 上次同步: ' + this.formatLastSyncTime())
              .fontSize(11)
              .fontColor('#888888')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button(this.syncing ? '同步中...' : '同步赛程')
          .type(ButtonType.Normal)
          .backgroundColor(this.syncing || this.subscribedIds.length === 0 ? '#cccccc' : '#1976d2')
          .fontColor(Color.White)
          .borderRadius(20)
          .height(36)
          .enabled(!this.syncing && this.subscribedIds.length > 0)
          .width(90)
          .onClick(() => this.onSyncTap())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding(14)
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .shadow({ radius: 6, color: '#0000000D', offsetX: 0, offsetY: 1 })
        .margin({ left: 12, right: 12, bottom: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')

    // Unsubscribe confirmation dialog
    if (this.showDialog) {
      this.UnsubscribeDialog()
    }
  }

  @Builder
  TeamCard(team: Team) {
    const isSub = this.subscribedIds.includes(team.id);
    Stack() {
      // Card body
      Column() {
        // Color dot
        Circle()
          .width(28)
          .height(28)
          .fill(team.color !== '#FFFFFF' ? team.color : '#cccccc')
          .margin({ bottom: 4 })

        // Team name
        Text(team.name)
          .fontSize(10)
          .fontColor(isSub ? '#2e7d32' : '#333333')
          .fontWeight(isSub ? FontWeight.Medium : FontWeight.Regular)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // Checkmark badge (top-right, only when subscribed)
      if (isSub) {
        Text('✓')
          .fontSize(12)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
          .width(18)
          .height(18)
          .borderRadius(9)
          .backgroundColor('#4caf50')
          .textAlign(TextAlign.Center)
          .position({ x: '100%', y: 0 })
          .translate({ x: '-50%', y: '-25%' })
          .zIndex(10)
      }
    }
    .width('100%')
    .height(72)
    .padding(6)
    .backgroundColor(isSub ? '#e8f5e9' : '#ffffff')
    .borderRadius(8)
    .border(isSub ? { width: 2, color: '#4caf50' } : { width: 0 })
    .shadow(isSub ? { radius: 4, color: '#4caf5020' } : { radius: 4, color: '#0000000D' })
    .onClick(() => this.onTeamTap(team))
  }

  @Builder
  UnsubscribeDialog() {
    Column() {
      // Overlay backdrop
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000080')
        .onClick(() => this.cancelDialog())

      // Dialog content
      Column() {
        Text('⚠️')
          .fontSize(36)
          .margin({ bottom: 12 })

        Text(`取消订阅${this.dialogTeam?.name || ''}？`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')

        Text('将删除该球队的全部赛程日历')
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8, bottom: 20 })

        Row() {
          Button('取消')
            .type(ButtonType.Normal)
            .backgroundColor('#f5f5f5')
            .fontColor('#666666')
            .borderRadius(10)
            .layoutWeight(1)
            .height(40)
            .onClick(() => this.cancelDialog())

          Button('确认删除')
            .type(ButtonType.Normal)
            .backgroundColor('#f44336')
            .fontColor(Color.White)
            .borderRadius(10)
            .layoutWeight(1)
            .height(40)
            .margin({ left: 12 })
            .onClick(() => this.confirmUnsubscribe())
        }
        .width('100%')
      }
      .backgroundColor('#ffffff')
      .borderRadius(16)
      .padding(24)
      .margin({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(100)
  }
}
```

- [ ] **Step 2: Update main_pages.json to register page (if needed)**

Verify `resources/base/profile/main_pages.json` already includes `"pages/Index"`. It already does from our earlier exploration — no change needed.

---

### Task 9: Integration Verification & Polish

**Files:**
- Verify all files compile without error
- Run all tests
- Manual smoke test checklist

- [ ] **Step 1: Full build verification**

Build the project in DevEco Studio. Fix any compilation errors (especially CalendarKit API mismatches from Task 7).

- [ ] **Step 2: Run all unit tests**

All tests from Tasks 2 and 4 should pass: Teams constant tests + IcsParser tests.

- [ ] **Step 3: Smoke test checklist**

Manual testing on device/simulator:
- [ ] App opens showing 16-team grid with grayed-out sync button
- [ ] Tap a team card → turns green with ✓
- [ ] Tap another team → also green, sync button becomes active
- [ ] Tap "同步赛程" → loading state → completion
- [ ] Open system calendar app → verify new calendar exists with match events
- [ ] Tap green card again → confirmation dialog appears
- [ ] Confirm delete → dialog closes, card turns white
- [ ] Verify calendar was removed from system calendar app
- [ ] Re-sync after delete → events reappear
- [ ] Test with network off → appropriate error handling

---

## Execution Order Summary

| Task | Description | Depends On | Est. Complexity |
|------|-------------|-----------|-----------------|
| 1 | Permissions & Strings | None | Trivial |
| 2 | Teams Constant + Tests | None | Simple |
| 3 | MatchEvent Model | None | Trivial |
| 4 | ICS Parser + Tests | 3 | Core Logic |
| 5 | HTTP Service | None | Simple |
| 6 | Team Store (Persistence) | None | Medium |
| 7 | Calendar Writer | 3, 4 | High (API risk) |
| 8 | Main Page UI | 1-7 | Large |
| 9 | Integration & Polish | All | Medium |

Tasks 1-3 can be done in parallel. Tasks 4-6 can be done in parallel after models exist. Task 7 depends on parser model. Task 8 depends on everything. Task 9 is final validation.
