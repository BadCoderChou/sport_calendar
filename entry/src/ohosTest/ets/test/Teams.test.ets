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
