// The Olympiad reports' words, in every language the feed is written in.
//
// Built the way article.mjs builds a story's, and for the same reason: a
// report is published unread, so it is made of facts in fixed sentences and
// nothing else. The sentences have no verbs a team or a player could be the
// subject of — "Uzbekistan 3½–½ Armenia", "Leaders by match points — Open:
// India (18)" — which is also what keeps them grammatical in the languages
// whose verbs take the gender of a country's name.
//
// Countries are named in the reader's language from the ICU region names,
// where the team's English name is exactly one of them; anything else — a
// second team, "Chinese Taipei", a federation's own team — keeps the name the
// broadcast gives it, with its number.

const W = {
  en: { olympiad: 'Chess Olympiad', round: (r) => `round ${r}`, Round: (r) => `Round ${r}`, open: 'Open', women: 'Women', top: 'Top boards', leaders: 'Leaders by match points', after: (r) => `the table after round ${r}`, final: 'the final table', rounds: (n) => `${n} rounds`, swiss: 'a Swiss system for teams', played: (p, n) => `${p} of ${n} rounds played` },
  bg: { olympiad: 'Шахматна олимпиада', round: (r) => `${r}. кръг`, Round: (r) => `${r}. кръг`, open: 'Открит турнир', women: 'Жени', top: 'Първите дъски', leaders: 'Водачи по мачови точки', after: (r) => `класирането след ${r}. кръг`, final: 'крайното класиране', rounds: (n) => `${n} кръга`, swiss: 'швейцарска система за отбори', played: (p, n) => `изиграни ${p} от ${n} кръга` },
  de: { olympiad: 'Schacholympiade', round: (r) => `Runde ${r}`, Round: (r) => `Runde ${r}`, open: 'Open', women: 'Frauen', top: 'Spitzenbretter', leaders: 'Spitze nach Mannschaftspunkten', after: (r) => `die Tabelle nach Runde ${r}`, final: 'die Abschlusstabelle', rounds: (n) => `${n} Runden`, swiss: 'Schweizer System für Mannschaften', played: (p, n) => `${p} von ${n} Runden gespielt` },
  fr: { olympiad: 'Olympiade d’échecs', round: (r) => `ronde ${r}`, Round: (r) => `Ronde ${r}`, open: 'Open', women: 'Féminin', top: 'Premiers échiquiers', leaders: 'En tête aux points de match', after: (r) => `le classement après la ronde ${r}`, final: 'le classement final', rounds: (n) => `${n} rondes`, swiss: 'système suisse par équipes', played: (p, n) => `${p} rondes jouées sur ${n}` },
  es: { olympiad: 'Olimpiada de Ajedrez', round: (r) => `ronda ${r}`, Round: (r) => `Ronda ${r}`, open: 'Absoluto', women: 'Femenino', top: 'Primeros tableros', leaders: 'Líderes por puntos de match', after: (r) => `la clasificación tras la ronda ${r}`, final: 'la clasificación final', rounds: (n) => `${n} rondas`, swiss: 'sistema suizo por equipos', played: (p, n) => `${p} de ${n} rondas jugadas` },
  it: { olympiad: 'Olimpiadi degli scacchi', round: (r) => `turno ${r}`, Round: (r) => `Turno ${r}`, open: 'Open', women: 'Femminile', top: 'Prime scacchiere', leaders: 'In testa per punti match', after: (r) => `la classifica dopo il turno ${r}`, final: 'la classifica finale', rounds: (n) => `${n} turni`, swiss: 'sistema svizzero a squadre', played: (p, n) => `${p} turni giocati su ${n}` },
  'pt-BR': { olympiad: 'Olimpíada de Xadrez', round: (r) => `rodada ${r}`, Round: (r) => `Rodada ${r}`, open: 'Absoluto', women: 'Feminino', top: 'Primeiras mesas', leaders: 'Líderes em pontos de match', after: (r) => `a tabela após a rodada ${r}`, final: 'a tabela final', rounds: (n) => `${n} rodadas`, swiss: 'sistema suíço por equipes', played: (p, n) => `${p} de ${n} rodadas jogadas` },
  ru: { olympiad: 'Шахматная олимпиада', round: (r) => `тур ${r}`, Round: (r) => `Тур ${r}`, open: 'Открытый турнир', women: 'Женский турнир', top: 'Первые доски', leaders: 'Лидеры по командным очкам', after: (r) => `таблица после ${r}-го тура`, final: 'итоговая таблица', rounds: (n) => `${n} туров`, swiss: 'швейцарская система, командный зачёт', played: (p, n) => `сыграно ${p} из ${n} туров` },
  pl: { olympiad: 'Olimpiada szachowa', round: (r) => `runda ${r}`, Round: (r) => `Runda ${r}`, open: 'Open', women: 'Kobiety', top: 'Czołowe szachownice', leaders: 'Liderzy w punktach meczowych', after: (r) => `tabela po rundzie ${r}`, final: 'tabela końcowa', rounds: (n) => `${n} rund`, swiss: 'system szwajcarski drużynowo', played: (p, n) => `rozegrano ${p} z ${n} rund` },
  cs: { olympiad: 'Šachová olympiáda', round: (r) => `${r}. kolo`, Round: (r) => `${r}. kolo`, open: 'Open', women: 'Ženy', top: 'Nejvyšší šachovnice', leaders: 'Na čele podle zápasových bodů', after: (r) => `tabulka po ${r}. kole`, final: 'konečná tabulka', rounds: (n) => `${n} kol`, swiss: 'švýcarský systém pro družstva', played: (p, n) => `odehráno ${p} z ${n} kol` },
  nl: { olympiad: 'Schaakolympiade', round: (r) => `ronde ${r}`, Round: (r) => `Ronde ${r}`, open: 'Open', women: 'Vrouwen', top: 'Topborden', leaders: 'Aan kop op matchpunten', after: (r) => `de stand na ronde ${r}`, final: 'de eindstand', rounds: (n) => `${n} ronden`, swiss: 'Zwitsers systeem voor teams', played: (p, n) => `${p} van ${n} ronden gespeeld` },
  sv: { olympiad: 'Schackolympiaden', round: (r) => `rond ${r}`, Round: (r) => `Rond ${r}`, open: 'Öppen', women: 'Damer', top: 'Toppborden', leaders: 'I topp på matchpoäng', after: (r) => `tabellen efter rond ${r}`, final: 'sluttabellen', rounds: (n) => `${n} ronder`, swiss: 'schweizersystem för lag', played: (p, n) => `${p} av ${n} ronder spelade` },
  da: { olympiad: 'Skakolympiaden', round: (r) => `runde ${r}`, Round: (r) => `Runde ${r}`, open: 'Åben', women: 'Damer', top: 'Topbrætterne', leaders: 'Førende på matchpoint', after: (r) => `stillingen efter runde ${r}`, final: 'slutstillingen', rounds: (n) => `${n} runder`, swiss: 'schweizersystem for hold', played: (p, n) => `${p} af ${n} runder spillet` },
  no: { olympiad: 'Sjakkolympiaden', round: (r) => `runde ${r}`, Round: (r) => `Runde ${r}`, open: 'Åpen', women: 'Kvinner', top: 'Toppbrettene', leaders: 'I tet på matchpoeng', after: (r) => `tabellen etter runde ${r}`, final: 'sluttabellen', rounds: (n) => `${n} runder`, swiss: 'monradsystem for lag', played: (p, n) => `${p} av ${n} runder spilt` },
  fi: { olympiad: 'Shakkiolympialaiset', round: (r) => `${r}. kierros`, Round: (r) => `${r}. kierros`, open: 'Avoin', women: 'Naiset', top: 'Kärkilaudat', leaders: 'Kärjessä ottelupisteillä', after: (r) => `taulukko ${r}. kierroksen jälkeen`, final: 'lopputaulukko', rounds: (n) => `${n} kierrosta`, swiss: 'joukkueiden sveitsiläinen järjestelmä', played: (p, n) => `pelattu ${p}/${n} kierrosta` },
  hu: { olympiad: 'Sakkolimpia', round: (r) => `${r}. forduló`, Round: (r) => `${r}. forduló`, open: 'Nyílt', women: 'Női', top: 'Éltáblák', leaders: 'Élen csapatpontok szerint', after: (r) => `a tabella a(z) ${r}. forduló után`, final: 'a végeredmény', rounds: (n) => `${n} forduló`, swiss: 'svájci rendszer csapatoknak', played: (p, n) => `${n} fordulóból ${p} lejátszva` },
  tr: { olympiad: 'Satranç Olimpiyatı', round: (r) => `${r}. tur`, Round: (r) => `${r}. tur`, open: 'Açık', women: 'Kadınlar', top: 'Üst masalar', leaders: 'Maç puanına göre liderler', after: (r) => `${r}. tur sonrası puan durumu`, final: 'final puan durumu', rounds: (n) => `${n} tur`, swiss: 'takımlar için İsviçre sistemi', played: (p, n) => `${n} turun ${p}’i oynandı` },
  el: { olympiad: 'Σκακιστική Ολυμπιάδα', round: (r) => `γύρος ${r}`, Round: (r) => `Γύρος ${r}`, open: 'Ανοιχτό', women: 'Γυναικών', top: 'Πρώτες σκακιέρες', leaders: 'Στην κορυφή σε βαθμούς αγώνα', after: (r) => `η βαθμολογία μετά τον ${r}ο γύρο`, final: 'η τελική βαθμολογία', rounds: (n) => `${n} γύροι`, swiss: 'ελβετικό σύστημα για ομάδες', played: (p, n) => `${p} από ${n} γύρους` },
  he: { olympiad: 'אולימפיאדת השחמט', round: (r) => `סיבוב ${r}`, Round: (r) => `סיבוב ${r}`, open: 'פתוח', women: 'נשים', top: 'הלוחות העליונים', leaders: 'בראש לפי נקודות משחק', after: (r) => `הטבלה אחרי סיבוב ${r}`, final: 'הטבלה הסופית', rounds: (n) => `${n} סיבובים`, swiss: 'שיטה שוויצרית לקבוצות', played: (p, n) => `שוחקו ${p} מתוך ${n} סיבובים` },
  ar: { olympiad: 'أولمبياد الشطرنج', round: (r) => `الجولة ${r}`, Round: (r) => `الجولة ${r}`, open: 'المفتوح', women: 'السيدات', top: 'الطاولات الأولى', leaders: 'المتصدرون بنقاط المباريات', after: (r) => `الترتيب بعد الجولة ${r}`, final: 'الترتيب النهائي', rounds: (n) => `${n} جولة`, swiss: 'النظام السويسري للفرق', played: (p, n) => `لُعبت ${p} من ${n} جولة` },
  hi: { olympiad: 'शतरंज ओलंपियाड', round: (r) => `राउंड ${r}`, Round: (r) => `राउंड ${r}`, open: 'ओपन', women: 'महिला', top: 'शीर्ष बोर्ड', leaders: 'मैच अंकों से शीर्ष पर', after: (r) => `राउंड ${r} के बाद तालिका`, final: 'अंतिम तालिका', rounds: (n) => `${n} राउंड`, swiss: 'टीमों के लिए स्विस प्रणाली', played: (p, n) => `${n} में से ${p} राउंड खेले गए` },
  ja: { olympiad: 'チェス・オリンピアード', round: (r) => `第${r}ラウンド`, Round: (r) => `第${r}ラウンド`, open: 'オープン', women: '女子', top: 'トップボード', leaders: 'マッチポイント首位', after: (r) => `第${r}ラウンド終了時の順位`, final: '最終順位', rounds: (n) => `全${n}ラウンド`, swiss: '団体スイス式', played: (p, n) => `${n}ラウンド中${p}ラウンド終了` },
  ko: { olympiad: '체스 올림피아드', round: (r) => `${r}라운드`, Round: (r) => `${r}라운드`, open: '오픈', women: '여자부', top: '톱 보드', leaders: '매치 포인트 선두', after: (r) => `${r}라운드 후 순위`, final: '최종 순위', rounds: (n) => `${n}라운드`, swiss: '단체 스위스 방식', played: (p, n) => `${n}라운드 중 ${p}라운드 진행` },
  'zh-Hans': { olympiad: '国际象棋奥林匹克', round: (r) => `第${r}轮`, Round: (r) => `第${r}轮`, open: '公开组', women: '女子组', top: '前台', leaders: '按团体分领先', after: (r) => `第${r}轮后的积分榜`, final: '最终积分榜', rounds: (n) => `共${n}轮`, swiss: '团体瑞士制', played: (p, n) => `已赛${p}轮（共${n}轮）` },
  'zh-Hant': { olympiad: '西洋棋奧林匹克', round: (r) => `第${r}輪`, Round: (r) => `第${r}輪`, open: '公開組', women: '女子組', top: '前台', leaders: '按團體分領先', after: (r) => `第${r}輪後的積分榜`, final: '最終積分榜', rounds: (n) => `共${n}輪`, swiss: '團體瑞士制', played: (p, n) => `已賽${p}輪（共${n}輪）` },
  th: { olympiad: 'หมากรุกโอลิมปิก', round: (r) => `รอบที่ ${r}`, Round: (r) => `รอบที่ ${r}`, open: 'โอเพ่น', women: 'หญิง', top: 'กระดานหัวแถว', leaders: 'นำด้วยแต้มแมตช์', after: (r) => `ตารางคะแนนหลังรอบที่ ${r}`, final: 'ตารางคะแนนสุดท้าย', rounds: (n) => `${n} รอบ`, swiss: 'ระบบสวิสประเภททีม', played: (p, n) => `แข่งไปแล้ว ${p} จาก ${n} รอบ` },
  vi: { olympiad: 'Olympiad Cờ vua', round: (r) => `vòng ${r}`, Round: (r) => `Vòng ${r}`, open: 'Mở rộng', women: 'Nữ', top: 'Những bàn đầu', leaders: 'Dẫn đầu theo điểm trận', after: (r) => `bảng xếp hạng sau vòng ${r}`, final: 'bảng xếp hạng chung cuộc', rounds: (n) => `${n} vòng`, swiss: 'hệ Thụy Sĩ đồng đội', played: (p, n) => `đã đấu ${p}/${n} vòng` },
  id: { olympiad: 'Olimpiade Catur', round: (r) => `babak ${r}`, Round: (r) => `Babak ${r}`, open: 'Terbuka', women: 'Putri', top: 'Papan teratas', leaders: 'Memimpin dengan poin pertandingan', after: (r) => `klasemen setelah babak ${r}`, final: 'klasemen akhir', rounds: (n) => `${n} babak`, swiss: 'sistem Swiss beregu', played: (p, n) => `${p} dari ${n} babak dimainkan` },
  ms: { olympiad: 'Olimpiad Catur', round: (r) => `pusingan ${r}`, Round: (r) => `Pusingan ${r}`, open: 'Terbuka', women: 'Wanita', top: 'Papan teratas', leaders: 'Mendahului dengan mata perlawanan', after: (r) => `kedudukan selepas pusingan ${r}`, final: 'kedudukan akhir', rounds: (n) => `${n} pusingan`, swiss: 'sistem Swiss berpasukan', played: (p, n) => `${p} daripada ${n} pusingan dimainkan` },
  ro: { olympiad: 'Olimpiada de Șah', round: (r) => `runda ${r}`, Round: (r) => `Runda ${r}`, open: 'Open', women: 'Feminin', top: 'Primele mese', leaders: 'În frunte la puncte de meci', after: (r) => `clasamentul după runda ${r}`, final: 'clasamentul final', rounds: (n) => `${n} runde`, swiss: 'sistem elvețian pe echipe', played: (p, n) => `${p} din ${n} runde jucate` },
};

export const REPORT_LANGS = Object.keys(W);

const CJK = (lang) => lang === 'ja' || lang.startsWith('zh');
const RTL = (lang) => lang === 'ar' || lang === 'he';
const isolate = (lang, text) => (RTL(lang) ? `⁨${text}⁩` : text);

/** "3½–½", from the two teams' game points. */
export function matchScore([a, b]) {
  const half = (n) => `${Math.floor(n) || (n % 1 ? '' : '0')}${n % 1 ? '½' : ''}`;
  return `${half(a)}–${half(b)}`;
}

// The English names ICU gives each region, reversed, so a team whose name is
// exactly one can be named in any language.
const REGION = (() => {
  const english = new Intl.DisplayNames(['en'], { type: 'region' });
  const map = new Map();
  for (let a = 65; a <= 90; a++) {
    for (let b = 65; b <= 90; b++) {
      const code = String.fromCharCode(a, b);
      const name = english.of(code);
      if (name && name !== code) map.set(name, code);
    }
  }
  // The names FIDE uses where ICU's differ; nothing political is renamed —
  // "Chinese Taipei" and "Hong Kong, China" keep the broadcast's name.
  for (const [name, code] of [['United States of America', 'US'], ['Czech Republic', 'CZ'], ['Turkey', 'TR'], ['Turkiye', 'TR'], ['Türkiye', 'TR'], ['Korea', 'KR'], ['South Korea', 'KR'], ['Republic of Korea', 'KR'], ['Moldova', 'MD'], ['North Macedonia', 'MK'], ['Bosnia and Herzegovina', 'BA'], ['Ivory Coast', 'CI'], ['Cape Verde', 'CV']]) {
    map.set(name, code);
  }
  for (const keep of ['Taiwan', 'Hong Kong SAR China', 'Macao SAR China', 'Palestinian Territories', 'Kosovo']) map.delete(keep);
  return map;
})();

/** A team's name in a language: the country's, with a second team's number kept. */
export function teamName(team, lang) {
  const [, base, number] = team.match(/^(.*?)(?:\s+(\d+))?$/) ?? [null, team, null];
  const code = REGION.get(base);
  if (!code || lang === 'en') return team;
  const tag = { 'pt-BR': 'pt-BR', 'zh-Hans': 'zh-Hans', 'zh-Hant': 'zh-Hant' }[lang] ?? lang;
  const named = new Intl.DisplayNames([tag], { type: 'region' }).of(code) ?? base;
  return number ? `${named} ${number}` : named;
}

const tagOf = (lang) => `${lang === 'en' ? 'en-GB' : lang}-u-ca-gregory-nu-latn`;
const day = (iso) => new Date(`${iso}T12:00:00Z`);
/** "26 September", in the language — without a closing full stop of its own. */
const date = (iso, lang) =>
  day(iso).toLocaleDateString(tagOf(lang), { day: 'numeric', month: 'long', timeZone: 'UTC' }).replace(/\.$/, '');
/** "16–27 September 2026", as the language writes a range. */
const range = ([from, to], lang) => {
  const format = new Intl.DateTimeFormat(tagOf(lang), { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' });
  const text = format.formatRange(day(from), day(to));
  // Some locales fall back to digits and slashes for a range; the two dates
  // written out read better than that.
  return (/\d+\/\d+/.test(text) ? `${format.format(day(from))}～${format.format(day(to))}` : text).replace(/\.$/, '');
};

/** Each sentence starting with a capital, in the languages that have them. */
const capital = (text, lang) => text.charAt(0).toLocaleUpperCase(lang) + text.slice(1);

/** A place as "City, Country", the country in the language. */
export function place(location, lang) {
  if (!location) return '';
  const parts = location.split(',').map((p) => p.trim());
  const country = parts.pop();
  return [...parts, teamName(country, lang)].join(lang === 'ja' ? '、' : lang.startsWith('zh') ? '，' : ', ');
}

/** How a language puts sentences and lists together. */
function marks(lang) {
  if (lang === 'ja') return { stop: '。', gap: '', list: '、', semi: '、', comma: '、' };
  if (lang.startsWith('zh')) return { stop: '。', gap: '', list: '；', semi: '；', comma: '，' };
  if (lang === 'th') return { stop: '', gap: ' ', list: ' ', semi: ' ', comma: ' ' };
  if (lang === 'hi') return { stop: '।', gap: ' ', list: '; ', semi: '; ', comma: ', ' };
  if (lang === 'ar') return { stop: '.', gap: ' ', list: '؛ ', semi: '؛ ', comma: '، ' };
  return { stop: '.', gap: ' ', list: '; ', semi: '; ', comma: ', ' };
}

/** A round's headline and lede in a language. */
export function roundWords(report, lang) {
  const w = W[lang];
  const colon = CJK(lang) ? '：' : ': ';
  const x = (text) => isolate(lang, text);
  const open = report.sections.find((s) => s.key === 'Open');
  const women = report.sections.find((s) => s.key === 'Women');
  // The top board's match, the winning team first — as a result is said.
  const top = (section) => {
    const match = section?.top[0];
    if (!match) return null;
    const [a, b] = match.score;
    const [first, second, score] = b > a ? [match.away, match.home, [b, a]] : [match.home, match.away, [a, b]];
    return `${x(teamName(first, lang))} ${x(matchScore(score))} ${x(teamName(second, lang))}`;
  };
  const lead = leaders(report, lang);
  const m = marks(lang);
  const headline = `${w.olympiad}${m.comma}${w.round(report.round)}${colon}${top(open) ?? top(women)}`;
  const parts = [
    `${w.Round(report.round)} · ${date(report.date, lang)}${m.stop}`,
    `${w.top} — ${[open && `${w.open}${colon}${top(open)}`, women && `${w.women}${colon}${top(women)}`].filter(Boolean).join(m.semi)}${m.stop}`,
    lead,
  ];
  return { headline, lede: parts.join(m.gap).trim() };
}

/** "Leaders by match points — Open: Uzbekistan (18); Women: China (18)." */
function leaders(report, lang) {
  const w = W[lang];
  const colon = CJK(lang) ? '：' : ': ';
  const m = marks(lang);
  const lead = (section) => section?.table[0] && `${isolate(lang, teamName(section.table[0].team, lang))} (${section.table[0].mp})`;
  const open = report.sections.find((s) => s.key === 'Open');
  const women = report.sections.find((s) => s.key === 'Women');
  return `${w.leaders} — ${[open && `${w.open}${colon}${lead(open)}`, women && `${w.women}${colon}${lead(women)}`].filter(Boolean).join(m.semi)}${m.stop}`;
}

/** The event's headline and lede in a language. */
export function eventWords(report, lang) {
  const w = W[lang];
  const colon = CJK(lang) ? '：' : ': ';
  const x = (text) => isolate(lang, text);
  const m = marks(lang);
  const year = report.event.dates?.[0]?.slice(0, 4) ?? '';
  const city = report.event.location?.split(',')[0] ?? '';
  const final = report.played >= report.rounds;
  const headline = `${w.olympiad} ${year}${m.comma}${x(city)}${colon}${final ? w.final : w.after(report.played)}`;
  const when = report.event.dates ? range(report.event.dates, lang) : '';
  const lede = [
    `${w.rounds(report.rounds)}${m.comma}${w.swiss}${m.stop}`,
    `${x(place(report.event.location, lang))}${when ? `${m.comma}${when}` : ''}${m.stop}`,
    `${w.played(report.played, report.rounds)}${m.stop}`,
    leaders(report, lang),
  ].map((sentence) => capital(sentence, lang)).join(m.gap).trim();
  return { headline, lede };
}

/** The section names a report's tables are headed with. */
export function sectionName(key, lang) {
  return key === 'Women' ? W[lang].women : key === 'Open' ? W[lang].open : key;
}
