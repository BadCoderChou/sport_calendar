export interface Team {
  id: string;
  name: string;
  color: string;
  logo: ResourceStr;
}

export interface WorldCupTeam {
  id: string;       // 如 'brazil', 'argentina'（对应 ICS API 的 team 参数）
  name: string;     // 中文名：'巴西'、'阿根廷'
  emoji: string;    // 国旗 emoji：'🇧🇷'、'🇦🇷'
  isHot: boolean;   // 是否为热门强队（前 12 个置顶显示）
}

export const CSL_TEAMS: Team[] = [
  { id: 'beijing-guoan', name: '北京国安', color: '#00AA33', logo: $r('app.media.beijing_guoan') },
  { id: 'chengdu-rongcheng', name: '成都蓉城', color: '#FFCC00', logo: $r('app.media.chengdu_rongcheng') },
  { id: 'dalian-yingbo', name: '大连英博', color: '#000000', logo: $r('app.media.dalian_yingbo') },
  { id: 'henan-fc', name: '河南俱乐部', color: '#CCCCCC', logo: $r('app.media.henan_club') },
  { id: 'qingdao-hainiu', name: '青岛海牛', color: '#0066B3', logo: $r('app.media.qingdao_hainiu') },
  { id: 'qingdao-xihaian', name: '青岛西海岸', color: '#1E90FF', logo: $r('app.media.qingdao_xihaian') },
  { id: 'shandong-taishan', name: '山东泰山', color: '#FF6600', logo: $r('app.media.shandong_taishan') },
  { id: 'shanghai-port', name: '上海海港', color: '#E60012', logo: $r('app.media.shanghai_haipo') },
  { id: 'shanghai-shenhua', name: '上海申花', color: '#002D88', logo: $r('app.media.shanghai_shenhua') },
  { id: 'shenzhen-peng-city', name: '深圳新鹏城', color: '#00A0E9', logo: $r('app.media.shenzhen_xinpengcheng') },
  { id: 'tianjin-jinmen-tiger', name: '天津津门虎', color: '#0072CE', logo: $r('app.media.tianjin_jinmenhu') },
  { id: 'wuhan-sanzhen', name: '武汉三镇', color: '#6A0DAD', logo: $r('app.media.wuhan_sanzhen') },
  { id: 'yunnan-yukun', name: '云南玉昆', color: '#228B22', logo: $r('app.media.yunnan_yukun') },
  { id: 'zhejiang-professional', name: '浙江俱乐部', color: '#0066CC', logo: $r('app.media.zhejiang_club') },
  { id: 'chongqing-tonglianglong', name: '重庆铜梁龙', color: '#DC143C', logo: $r('app.media.chongqing_tonglianglong') },
  { id: 'liaoning-tieren', name: '辽宁铁人', color: '#32CD32', logo: $r('app.media.liaoning_tieren') },
];

export function getTeamById(id: string): Team | undefined {
  return CSL_TEAMS.find(t => t.id === id);
}

export const CALENDAR_NAME_PREFIX = '中超-';

export const WC_CALENDAR_NAME_PREFIX = '世界杯-';

export const WORLD_CUP_TEAMS: WorldCupTeam[] = [
  // ===== 热门 12 强 (isHot=true) =====
  { id: 'brazil', name: '巴西', emoji: '🇧🇷', isHot: true },
  { id: 'argentina', name: '阿根廷', emoji: '🇦🇷', isHot: true },
  { id: 'france', name: '法国', emoji: '🇫🇷', isHot: true },
  { id: 'germany', name: '德国', emoji: '🇩🇪', isHot: true },
  { id: 'spain', name: '西班牙', emoji: '🇪🇸', isHot: true },
  { id: 'england', name: '英格兰', emoji: '🇬🇧', isHot: true },
  { id: 'portugal', name: '葡萄牙', emoji: '🇵🇹', isHot: true },
  { id: 'netherlands', name: '荷兰', emoji: '🇳🇱', isHot: true },
  { id: 'usa', name: '美国', emoji: '🇺🇸', isHot: true },       // 东道主
  { id: 'uruguay', name: '乌拉圭', emoji: '🇺🇾', isHot: true },
  { id: 'japan', name: '日本', emoji: '🇯🇵', isHot: true },
  { id: 'south-korea', name: '韩国', emoji: '🇰🇷', isHot: true },

  // ===== 其余 36 国 (isHot=false)，按英文名排序 =====
  // 数据来源: https://sports-calendar.com/zh/soccer/fifa-world-cup/2026/
  // 完整 48 国名单（已去重验证）
  { id: 'algeria', name: '阿尔及利亚', emoji: '🇩🇿', isHot: false },
  { id: 'austria', name: '奥地利', emoji: '🇦🇹', isHot: false },
  { id: 'australia', name: '澳大利亚', emoji: '🇦🇺', isHot: false },
  { id: 'belgium', name: '比利时', emoji: '🇧🇪', isHot: false },
  { id: 'bosnia-herzegovina', name: '波黑', emoji: '🇧🇦', isHot: false },
  { id: 'canada', name: '加拿大', emoji: '🇨🇦', isHot: false },        // 东道主
  { id: 'colombia', name: '哥伦比亚', emoji: '🇨🇴', isHot: false },
  { id: 'costa-rica', name: '哥斯达黎加', emoji: '🇨🇷', isHot: false },
  { id: 'croatia', name: '克罗地亚', emoji: '🇭🇷', isHot: false },
  { id: 'czech-republic', name: '捷克', emoji: '🇨🇿', isHot: false },
  { id: 'denmark', name: '丹麦', emoji: '🇩🇰', isHot: false },
  { id: 'ecuador', name: '厄瓜多尔', emoji: '🇪🇨', isHot: false },
  { id: 'egypt', name: '埃及', emoji: '🇪🇬', isHot: false },
  { id: 'iran', name: '伊朗', emoji: '🇮🇷', isHot: false },
  { id: 'ivory-coast', name: '科特迪瓦', emoji: '🇨🇮', isHot: false },
  { id: 'mexico', name: '墨西哥', emoji: '🇲🇽', isHot: false },      // 东道主
  { id: 'morocco', name: '摩洛哥', emoji: '🇲🇦', isHot: false },
  { id: 'new-zealand', name: '新西兰', emoji: '🇳🇿', isHot: false },
  { id: 'nigeria', name: '尼日利亚', emoji: '🇳🇬', isHot: false },
  { id: 'panama', name: '巴拿马', emoji: '🇵🇦', isHot: false },
  { id: 'paraguay', name: '巴拉圭', emoji: '🇵🇾', isHot: false },
  { id: 'peru', name: '秘鲁', emoji: '🇵🇪', isHot: false },
  { id: 'poland', name: '波兰', emoji: '🇵🇱', isHot: false },
  { id: 'qatar', name: '卡塔尔', emoji: '🇶🇦', isHot: false },         // 东道主
  { id: 'saudi-arabia', name: '沙特阿拉伯', emoji: '🇸🇦', isHot: false },
  { id: 'scotland', name: '苏格兰', emoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿', isHot: false },
  { id: 'senegal', name: '塞内加尔', emoji: '🇸🇳', isHot: false },
  { id: 'serbia', name: '塞尔维亚', emoji: '🇷🇸', isHot: false },
  { id: 'south-africa', name: '南非', emoji: '🇿🇦', isHot: false },
  { id: 'sweden', name: '瑞典', emoji: '🇸🇪', isHot: false },
  { id: 'switzerland', name: '瑞士', emoji: '🇨🇭', isHot: false },
  { id: 'tunisia', name: '突尼斯', emoji: '🇹🇳', isHot: false },
  { id: 'turkey', name: '土耳其', emoji: '🇹🇷', isHot: false },
  { id: 'ukraine', name: '乌克兰', emoji: '🇺🇦', isHot: false },
  { id: 'uzbekistan', name: '乌兹别克斯坦', emoji: '🇺🇿', isHot: false },
  { id: 'wales', name: '威尔士', emoji: '🏴󠁧󠁢󠁷󠁬󠁳󠁿', isHot: false },
];
// 总计: 12 + 36 = 48 国 ✅

export function getWorldCupTeamById(id: string): WorldCupTeam | undefined {
  return WORLD_CUP_TEAMS.find(t => t.id === id);
}
