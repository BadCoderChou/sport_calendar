import abilityTest from './Ability.test';
import teamsTest from './Teams.test';
import icsParserTest from './IcsParser.test';

export default function testsuite() {
  abilityTest();
  teamsTest();
  icsParserTest();
}