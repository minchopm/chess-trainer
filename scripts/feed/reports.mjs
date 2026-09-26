// The Olympiad's reports: one for every round, and one for the event, in every
// language the feed is written in — built from olympiad.mjs's counts, written
// beside the feed, and rendered as pages on the site.
//
//   media/feed/v1/reports/index.json          the reports there are, newest first
//   media/feed/v1/reports/<id>.json           one, in English
//   media/feed/v1/<lang>/reports/<id>.json    and in each other language
//   feed-state/v1/olympiad.json               the rounds already read — private
//
// Pages: /reports/<id> and /<slug>/reports/<id>, rendered like a new story's
// (pages.mjs), with the deployed build's renderer.
import { LANGS } from './article.mjs';
import { eventNumbers, readOlympiad, roundNumbers, standings } from './olympiad.mjs';
import { eventWords, place, roundWords, sectionName, teamName } from './report-words.mjs';

export const REPORTS = 'media/feed/v1/reports';
const STATE = 'feed-state/v1/olympiad.json';

/** The Olympiad the collector is following: the one in Lichess's top broadcasts now. */
export const OLYMPIAD = { tour: process.env.FEED_OLYMPIAD ?? 'n1pPI5Q0', slug: 'chess-olympiad-2026' };

/**
 * The report a story from the Olympiad links to: the event's, which is there
 * from the first report on and never goes — a round's is written only once
 * every section has finished the round, and a story is written sooner.
 */
export function reportFor(story) {
  const year = OLYMPIAD.slug.match(/\d{4}$/)?.[0];
  const name = story.event?.name ?? '';
  return /Olympiad/i.test(name) && name.includes(year) ? OLYMPIAD.slug : null;
}

const SITE = 'https://brasspawn.com';
const slugOf = (lang) => ({ 'pt-BR': 'pt-br', 'zh-Hans': 'zh-hans', 'zh-Hant': 'zh-hant' })[lang] ?? lang;
export const reportURL = (id, lang = 'en') => (lang === 'en' ? `${SITE}/reports/${id}` : `${SITE}/${slugOf(lang)}/reports/${id}`);

function localTeams(section, lang) {
  const named = (team) => ({ team, name: teamName(team, lang) });
  return {
    ...section,
    name: sectionName(section.key, lang),
    top: section.top.map((m) => ({ ...m, homeName: teamName(m.home, lang), awayName: teamName(m.away, lang) })),
    table: section.table.map((row) => ({ ...row, ...named(row.team) })),
    upsets: section.upsets.map((u) => ({
      ...u,
      winner: { ...u.winner, teamName: u.winner.team && teamName(u.winner.team, lang) },
      loser: { ...u.loser, teamName: u.loser.team && teamName(u.loser.team, lang) },
    })),
  };
}

/** The upsets worth a line: a player rated 2300 or more, beaten by one rated at least 100 below. */
function notable(numbers) {
  return numbers.upsets.filter((u) => u.loser.elo >= 2300 && u.gap >= 100).slice(0, 5);
}

/**
 * Every report the data allows, in English, with the stories that belong to
 * each: a round's report for every finished round, and the event's.
 */
export function buildReports(data, stories) {
  const [open] = Object.values(data.sections);
  const rounds = Number(data.info.format?.match(/(\d+)-round/)?.[1]) || Math.max(...Object.values(data.sections).map((r) => r.length));
  const played = Math.min(...Object.values(data.sections).map((r) => r.at(-1)?.number ?? 0));
  const event = {
    name: data.name,
    short: 'Olympiad',
    location: data.info.location ?? null,
    dates: data.dates ? data.dates.map((ms) => new Date(ms).toISOString().slice(0, 10)) : null,
    format: data.info.format ?? null,
    tc: data.info.tc ?? null,
    website: data.info.website ?? null,
    standings: data.info.standings ?? null,
    broadcast: 'https://lichess.org/broadcast',
  };
  const olympiadStories = stories.filter((s) => /Olympiad/i.test(s.event?.name ?? '') && s.event.name.includes(data.name.split(' | ')[0]));
  const reports = [];
  for (const { number, date } of open ?? []) {
    if (number > played) continue;
    const sections = Object.entries(data.sections).map(([key, rs]) => {
      const round = rs.find((r) => r.number === number);
      const numbers = roundNumbers(round);
      return {
        key,
        top: round.matches.filter((m) => m.complete).slice(0, 6).map((m) => ({ home: m.home, away: m.away, score: m.score })),
        table: standings(rs, number).slice(0, 12),
        numbers: { games: numbers.games, white: numbers.white, black: numbers.black, draws: numbers.draws },
        upsets: notable(numbers),
      };
    });
    reports.push({
      id: `${OLYMPIAD.slug}-round-${number}`,
      kind: 'round',
      date,
      round: number,
      rounds,
      played,
      event,
      sections,
      stories: olympiadStories.filter((s) => s.event.round === number).map((s) => ({ id: s.id })),
    });
  }
  const all = Object.values(data.sections).flat();
  reports.push({
    id: OLYMPIAD.slug,
    kind: 'event',
    date: open?.find((r) => r.number === played)?.date ?? null,
    round: played,
    rounds,
    played,
    event,
    sections: Object.entries(data.sections).map(([key, rs]) => ({
      key,
      top: [],
      table: standings(rs, played).slice(0, 12),
      numbers: (({ games, white, black, draws }) => ({ games, white, black, draws }))(eventNumbers(rs)),
      upsets: [],
    })),
    numbers: eventNumbers(all),
    reports: reports.map((r) => ({ id: r.id, round: r.round, date: r.date })).reverse(),
    stories: olympiadStories.slice(0, 8).map((s) => ({ id: s.id })),
  });
  return reports;
}

/** A report in one language: its words, its teams' names, its stories' headlines. */
export function inLanguage(report, lang, storyHeadlines) {
  const words = report.kind === 'round' ? roundWords(report, lang) : eventWords(report, lang);
  return {
    ...report,
    lang,
    ...words,
    // Where, the country in the language, for the page's line under the title.
    where: report.event.location ? place(report.event.location, lang) : null,
    sections: report.sections.map((section) => localTeams(section, lang)),
    stories: report.stories.map((s) => ({ ...s, headline: storyHeadlines(s.id, lang) })).filter((s) => s.headline),
  };
}

/**
 * Read what is new, build every report, write them in every language, and
 * return them in every language — for pages.mjs to render. `budgetMs` bounds
 * the reading: the first time is every round of the event, and at Lichess's
 * pace that is ten minutes, so it is spread over as many runs as it takes, a
 * round at a time. Once the last round is in, the broadcast is not asked again.
 */
export async function writeReports({ store, stories, budgetMs = 5 * 60_000, log = console.error }) {
  const known = (await store.getPrivate(STATE)) ?? {};
  const started = Date.now();
  let data = known.complete ? known.data : null;
  if (!data) {
    data = await readOlympiad(OLYMPIAD.tour, known.data?.sections ?? {}, log, () => Date.now() - started > budgetMs);
    const played = Math.min(...Object.values(data.sections).map((r) => r.at(-1)?.number ?? 0));
    const rounds = Number(data.info.format?.match(/(\d+)-round/)?.[1]) || Infinity;
    await store.putPrivate(STATE, { data, complete: played >= rounds, updatedAt: new Date().toISOString() });
  }
  if (!Object.values(data.sections).every((rounds) => rounds.length)) return [];

  // The stories that have their page, and their headlines in every language.
  const withPages = stories.filter((s) => s.url === `${SITE}/today/${s.id}`);
  const reports = buildReports(data, withPages);
  const full = new Map();
  for (const id of new Set(reports.flatMap((r) => r.stories.map((s) => s.id)))) full.set(id, await store.story(id));
  const storyHeadlines = (id, lang) => {
    const story = full.get(id);
    return story ? (lang !== 'en' && story.words?.[lang]?.headline) || story.headline : null;
  };

  const other = LANGS.filter((lang) => lang !== 'en');
  const written = [];
  for (const report of reports) {
    const byLang = Object.fromEntries(LANGS.map((lang) => [lang, inLanguage(report, lang, storyHeadlines)]));
    await store.putPublic(`${REPORTS}/${report.id}.json`, byLang.en);
    await Promise.all(other.map((lang) => store.putPublic(`media/feed/v1/${lang}/reports/${report.id}.json`, byLang[lang], { quiet: true })));
    written.push({ id: report.id, date: report.date, byLang });
  }
  const index = (lang) => ({
    version: 1,
    generatedAt: new Date().toISOString(),
    reports: written
      .map(({ byLang }) => byLang[lang])
      .map(({ id, kind, date, round, headline, lede }) => ({ id, kind, date, round, headline, lede }))
      .sort((a, b) => (b.kind === 'event') - (a.kind === 'event') || (b.round ?? 0) - (a.round ?? 0)),
  });
  await store.putPublic(`${REPORTS}/index.json`, index('en'));
  await Promise.all(other.map((lang) => store.putPublic(`media/feed/v1/${lang}/reports/index.json`, index(lang), { quiet: true })));
  log(`  ${reports.length} Olympiad reports in ${LANGS.length} languages`);
  return written;
}
