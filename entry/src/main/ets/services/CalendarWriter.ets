/**
 * CalendarWriter — Writes match events to the system calendar via @kit.CalendarKit.
 *
 * ## API Research Summary (verified from DevEco Studio 6.0 SDK .d.ts)
 *
 * ### Import & Entry Point
 *   import { calendarManager } from '@kit.CalendarKit';
 *   const mgr = calendarManager.getCalendarManager(context);
 *
 * ### Key Methods (all confirmed available)
 *   - mgr.createCalendar(CalendarAccount) -> Promise<Calendar>
 *   - mgr.deleteCalendar(Calendar) -> Promise<void>
 *   - mgr.getAllCalendars() -> Promise<Calendar[]>
 *   - mgr.getCalendar(CalendarAccount?) -> Promise<Calendar>
 *   - cal.addEvent(Event) -> Promise<number>       // returns event ID
 *   - cal.updateEvent(Event) -> Promise<void>      // Event.id required for update
 *   - cal.deleteEvent(id: number) -> Promise<void>
 *   - cal.deleteEvents(ids: number[]) -> Promise<void>
 *   - cal.getEvents(EventFilter?, (keyof Event)[]) -> Promise<Event[]>
 *
 * ### Type Details
 *   - CalendarAccount: { name: string, type: CalendarType, displayName?: string }
 *   - CalendarType.LOCAL = 'local'
 *   - Event.id: number (set by system after addEvent)
 *   - Event.identifier: string (since API 12 — used for UID-based dedup)
 *   - Event.location: Location { location?: string }
 *   - Event.reminderTime: number[]  (minutes-before-event reminders)
 *   - Event.type: EventType.NORMAL | IMPORTANT
 *   - ServiceType.SPORTS_EVENTS = 'SportsEvents'
 *   - EventFilter: static filterById / filterByTime / filterByTitle
 *
 * ### Permissions (already declared in module.json5)
 *   ohos.permission.READ_CALENDAR
 *   ohos.permission.WRITE_CALENDAR
 */

import { calendarManager } from '@kit.CalendarKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { Team, CALENDAR_NAME_PREFIX } from '../constants/Teams';
import { MatchEvent } from '../model/MatchEvent';

const DOMAIN = 0x0000;

/** Helper: obtain the application context for calendarManager */
function getApplicationContext(): common.UIAbilityContext {
  return getContext() as common.UIAbilityContext;
}

export class CalendarWriter {
  /**
   * Write match events to a per-team calendar.
   *
   * Calendar name format: "中超-{teamName}" (e.g. "中超-北京国安").
   * Uses identifier-based deduplication: existing events matched by ICS UID are updated,
   * new events are added.
   *
   * @param team  The team whose matches are being written
   * @param events Parsed match events from ICS
   * @returns Number of events successfully written
   */
  static async writeEvents(team: Team, events: MatchEvent[], serviceDesc?: string): Promise<number> {
    try {
      const calendarName = CALENDAR_NAME_PREFIX + team.name; // e.g. "中超-北京国安"
      const context = getApplicationContext();
      const mgr = calendarManager.getCalendarManager(context);
      const calendar = await CalendarWriter.getOrCreateCalendar(mgr, calendarName);

      let writtenCount = 0;
      let skippedCount = 0;

      for (const event of events) {
        try {
          await CalendarWriter.writeOrUpdateEvent(calendar, team.id, event, serviceDesc);
          writtenCount++;
        } catch (e) {
          hilog.warn(DOMAIN, 'SportCalendar',
            'Failed to write event %{public}s: %{public}s', event.uid, JSON.stringify(e));
          skippedCount++;
        }
      }

      hilog.info(DOMAIN, 'SportCalendar',
        '%{public}s: wrote=%{public}d, skipped=%{public}d, total=%{public}d',
        team.name, writtenCount, skippedCount, events.length);
      return writtenCount;
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'writeEvents failed: %{public}s', JSON.stringify(e));
      throw new Error(`写入日历失败: ${String(e)}`);
    }
  }

  /**
   * Delete the entire calendar for a team (removes all events + calendar container).
   * Called when user unsubscribes from a team.
   */
  static async deleteCalendar(team: Team): Promise<void> {
    try {
      const targetName = CALENDAR_NAME_PREFIX + team.name;
      const context = getApplicationContext();
      const mgr = calendarManager.getCalendarManager(context);

      hilog.info(DOMAIN, 'SportCalendar', 'deleteCalendar: looking for %{public}s', targetName);

      // List all calendars and find the one matching our naming convention
      const calendars = await mgr.getAllCalendars();
      hilog.info(DOMAIN, 'SportCalendar', 'deleteCalendar: total calendars=%{public}d', calendars.length);

      for (const cal of calendars) {
        const account = cal.getAccount();
        hilog.info(DOMAIN, 'SportCalendar',
          '  calendar: name=%{public}s, type=%{public}s', account.name, account.type);
      }

      const target = calendars.find((cal) => {
        const account = cal.getAccount();
        return account.name === targetName && account.type === calendarManager.CalendarType.LOCAL;
      });

      if (target) {
        // deleteCalendar removes the calendar AND all its events
        await mgr.deleteCalendar(target);
        hilog.info(DOMAIN, 'SportCalendar', 'Deleted calendar: %{public}s', targetName);
      } else {
        hilog.warn(DOMAIN, 'SportCalendar',
          'Calendar NOT FOUND for deletion: %{public}s', targetName);
      }
    } catch (e) {
      hilog.error(DOMAIN, 'SportCalendar', 'deleteCalendar failed: %{public}s', JSON.stringify(e));
      throw new Error(`删除日历失败: ${String(e)}`);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /**
   * Get an existing local calendar by name, or create a new one.
   * Uses CalendarType.LOCAL so the calendar lives on-device only.
   */
  private static async getOrCreateCalendar(
    mgr: calendarManager.CalendarManager,
    name: string,
  ): Promise<calendarManager.Calendar> {
    // Try to find existing calendar with matching name
    const calendars = await mgr.getAllCalendars();
    const existing = calendars.find((cal) => {
      const account = cal.getAccount();
      return account.name === name && account.type === calendarManager.CalendarType.LOCAL;
    });

    if (existing) {
      return existing;
    }

    // Create new local calendar
    const account: calendarManager.CalendarAccount = {
      name: name,
      type: calendarManager.CalendarType.LOCAL,
    };
    const calendar = await mgr.createCalendar(account);

    hilog.info(DOMAIN, 'SportCalendar', 'Created new calendar: %{public}s', name);
    return calendar;
  }

  /**
   * Write or update a single event by UID (stored in Event.identifier).
   *
   * Strategy:
   * 1. Query existing events in this calendar that match our title prefix
   * 2. Find one where identifier == event.uid
   * 3. If found: call updateEvent (preserves system event ID, reminders, etc.)
   * 4. If not found: call addEvent (creates new event)
   *
   * The Event.identifier field (since API 12) stores the ICS UID for reliable dedup.
   */
  private static async writeOrUpdateEvent(
    calendar: calendarManager.Calendar,
    teamId: string,
    event: MatchEvent,
    serviceDesc?: string,
  ): Promise<void> {
    const scopedUid = CalendarWriter.buildIdentifier(teamId, event.uid);
    const existing = await CalendarWriter.findEventByIdentifier(calendar, scopedUid);

    if (existing && existing.id !== undefined) {
      // Update existing event — must include the system-assigned id
      const updatedEvent: calendarManager.Event = {
        id: existing.id,
        type: calendarManager.EventType.NORMAL,
        title: event.title,
        location: { location: event.location },
        startTime: event.startTime,
        endTime: event.endTime,
        description: event.description,
        reminderTime: [event.reminderMinutes],
        service: {
          type: calendarManager.ServiceType.SPORTS_EVENTS,
          uri: '',
          description: serviceDesc || '中超联赛赛程',
        },
        identifier: scopedUid,
      };

      try {
        await calendar.updateEvent(updatedEvent);
        return;
      } catch (_) {
        // If update fails (e.g., event was deleted externally), fall through to add
        hilog.warn(DOMAIN, 'SportCalendar',
          'Update failed for uid=%{public}s, will re-add', event.uid);
      }
    }

    // Create new event
    const newEvent: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: event.title,
      location: { location: event.location },
      startTime: event.startTime,
      endTime: event.endTime,
      description: event.description,
      reminderTime: [event.reminderMinutes],
      service: {
        type: calendarManager.ServiceType.SPORTS_EVENTS,
        uri: '',
        description: serviceDesc || '中超联赛赛程',
      },
      identifier: scopedUid,
    };

    await calendar.addEvent(newEvent);
  }

  /**
   * Build a team-scoped identifier to avoid UID collisions across team calendars.
   *
   * When two teams play each other (e.g., 上海海港 vs 天津津门虎), the ICS API
   * returns the same UID in both teams' ICS feeds. Without scoping, the second
   * team's write would match the first team's existing event (via getEvents()
   * which may return cross-calendar results) and update it instead of creating
   * a new one in the correct calendar.
   */
  private static buildIdentifier(teamId: string, uid: string): string {
    return `${teamId}:${uid}`;
  }

  /**
   * Find an event within a calendar by its ICS UID (stored in Event.identifier).
   *
   * Since EventFilter does not have a filterByIdentifier method, we use getEvents()
   * without a filter to retrieve all events, then match on identifier.
   *
   * For calendars with many events this could be slow; an optimization would be
   * to use filterByTitle with the event title as a narrow-down first pass.
   *
   * Falls back gracefully: returns undefined if enumeration fails or no match found.
   */
  private static async findEventByIdentifier(
    calendar: calendarManager.Calendar,
    uid: string,
  ): Promise<calendarManager.Event | undefined> {
    try {
      // Fetch all events in this calendar, then search in-memory for matching identifier
      const events = await calendar.getEvents();

      if (events && Array.isArray(events)) {
        return events.find((e) => e.identifier === uid);
      }

      return undefined;
    } catch (e) {
      // getEvents may fail due to permissions or other reasons; fall back to always-add
      hilog.warn(DOMAIN, 'SportCalendar',
        'getEvents failed during UID lookup, skipping dedup: %{public}s', JSON.stringify(e));
      return undefined;
    }
  }
}
