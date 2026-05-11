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
    if (!startTime) return null;
    
    const endTimeValue = props['DTEND'] ? IcsParser.parseDateTime(props['DTEND']) : null;
    const endTime = endTimeValue ? endTimeValue : startTime + 7200000; // Default 2h duration

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
      reminderMinutes: 120,
    };
  }

  private static parseProperties(block: string): Record<string, string> {
    const props: Record<string, string> = {};
    const lines = block.split('\n');
    for (const line of lines) {
      const colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        const key = line.substring(0, colonIndex).split(';')[0].toUpperCase();
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
        const parts = cleanDt.split('T');
        const datePart = parts[0];
        const timePart = parts[1];
        const year = parseInt(datePart.substring(0, 4));
        const month = parseInt(datePart.substring(4, 6)) - 1; // JS months are 0-indexed
        const day = parseInt(datePart.substring(6, 8));
        const hour = parseInt(timePart.substring(0, 2));
        const minute = parseInt(timePart.substring(2, 4));
        const second = parseInt(timePart.substring(4, 6)) || 0;

        const date = new Date(Date.UTC(year, month, day, hour, minute, second));

        if (isUTC) {
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
