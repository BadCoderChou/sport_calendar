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
      expect(events.length).assertEqual(0); // Missing DTSTART -> skipped
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
