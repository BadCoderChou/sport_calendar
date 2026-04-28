export interface Team {
  id: string;
  name: string;
  color: string;
  logo: ResourceStr;
}

export const CSL_TEAMS: Team[] = [
  { id: 'beijing-guoan', name: '北京国安', color: '#00529C', logo: $r('app.media.team_logos.beijing_guoan') },
  { id: 'shanghai-haipo', name: '上海海港', color: '#E60012', logo: $r('app.media.team_logos.shanghai_haipo') },
  { id: 'shanghai-shenhua', name: '上海申花', color: '#002D88', logo: $r('app.media.team_logos.shanghai_shenhua') },
  { id: 'shandong-taishan', name: '山东泰山', color: '#FF6600', logo: $r('app.media.team_logos.shandong_taishan') },
  { id: 'chengdu-rongcheng', name: '成都蓉城', color: '#FFCC00', logo: $r('app.media.team_logos.chengdu_rongcheng') },
  { id: 'zhejiang-club', name: '浙江俱乐部', color: '#FFFFFF', logo: $r('app.media.team_logos.zhejiang_club') },
  { id: 'tianjin-jinmenhu', name: '天津津门虎', color: '#0072CE', logo: $r('app.media.team_logos.tianjin_jinmenhu') },
  { id: 'wuhan-sanzhen', name: '武汉三镇', color: '#6A0DAD', logo: $r('app.media.team_logos.wuhan_sanzhen') },
  { id: 'henan-club', name: '河南俱乐部', color: '#CCCCCC', logo: $r('app.media.team_logos.henan_club') },
  { id: 'qingdao-hainiu', name: '青岛海牛', color: '#0066B3', logo: $r('app.media.team_logos.qingdao_hainiu') },
  { id: 'qingdao-xihaian', name: '青岛西海岸', color: '#1E90FF', logo: $r('app.media.team_logos.qingdao_xihaian') },
  { id: 'yunnan-yukun', name: '云南玉昆', color: '#228B22', logo: $r('app.media.team_logos.yunnan_yukun') },
  { id: 'dalian-yingbo', name: '大连英博', color: '#000000', logo: $r('app.media.team_logos.dalian_yingbo') },
  { id: 'shenzhen-xinpengcheng', name: '深圳新鹏城', color: '#00A0E9', logo: $r('app.media.team_logos.shenzhen_xinpengcheng') },
  { id: 'chongqing-tonglianglong', name: '重庆铜梁龙', color: '#DC143C', logo: $r('app.media.team_logos.chongqing_tonglianglong') },
  { id: 'liaoning-tieren', name: '辽宁铁人', color: '#32CD32', logo: $r('app.media.team_logos.liaoning_tieren') },
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
