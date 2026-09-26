// Where the feed lives: the media bucket behind brasspawn.com.
//
//   media/feed/v1/latest.json          the app's first request: the newest days, and the list of all days
//   media/feed/v1/days/<date>.json     one day's stories, for going back through the history
//   media/feed/v1/stories/<id>.json    one story, for the site — with its words in every language
//   media/feed/v1/<lang>/…             the same three, in one language: an app reading German reads
//                                      media/feed/v1/de/latest.json and never downloads the other
//                                      twenty-seven; a story without that language's words is in
//                                      English there, and says so ("lang": "en")
//   feed-state/v1/state.json           what the collector has already read — private
//
// The top-level files are English, as they always were, so an app that knows
// nothing of languages reads what it always read.
//
// Everything under media/ is public through the /media/* behaviour on the
// distribution; feed-state/ matches no behaviour, so nothing outside the
// collector can read it.
//
// A story is written once by the collector, as "auto", and again if a person
// rewrites and approves it, as "approved". The collector never touches a story
// that exists. Which statuses the public files carry is FEED_PUBLIC: "all"
// while the feature is being tested, "approved" once only read words go out.
import { LANGS } from './article.mjs';
import { positionAt } from './diagram.mjs';
import { openS3 } from './s3.mjs';

/** The languages with folders of their own; English is the top level. */
const OTHER = LANGS.filter((lang) => lang !== 'en');

/** A story without its other languages — what the English files carry. */
const bare = ({ words, ...story }) => story;

/** A story as one language's files carry it: that language's words, or English and a note that it is. */
export function inLanguage(story, lang) {
  const { words, ...rest } = story;
  const own = words?.[lang];
  return own ? { ...rest, headline: own.headline, lede: own.lede, body: own.body, lang } : { ...rest, lang: 'en' };
}

export const PREFIX = 'media/feed/v1';
const STATE_KEY = 'feed-state/v1/state.json';
/** Which build rendered each story's pages in the other languages — see pages.mjs. */
const PAGES_KEY = 'feed-state/v1/pages.json';
const LATEST_DAYS = 3;

export function openStore({
  bucket = process.env.FEED_BUCKET ?? 'brasspawn-media',
  region = process.env.FEED_REGION ?? 'eu-central-1',
  publicStatuses = (process.env.FEED_PUBLIC ?? 'all') === 'approved' ? ['approved'] : ['auto', 'approved'],
  dryRun = false,
  log = console.error,
} = {}) {
  const s3 = openS3({ bucket, region });

  // A missing key is a 404 only to a caller allowed to list the bucket; to
  // anybody else S3 says 403, which would read here as a failure. The
  // collector's role may list its own prefixes for exactly this reason.
  async function get(key) {
    const text = await s3.get(key);
    return text == null ? null : JSON.parse(text);
  }

  let quietWrites = 0;
  async function put(key, value, { isPublic = true, quiet = false } = {}) {
    if (dryRun) {
      // One line per English file; the twenty-eight languages' copies of it
      // are counted rather than listed.
      if (quiet) quietWrites++;
      else log(`  would write s3://${bucket}/${key}`);
      return;
    }
    await s3.put(key, JSON.stringify(value), {
      contentType: 'application/json; charset=utf-8',
      // Five minutes at the edge. A correction reaches everybody within the
      // quarter hour without anybody invalidating anything, and the files are
      // a few kilobytes.
      cacheControl: isPublic ? 'public,max-age=300' : 'no-store',
    });
  }

  const visible = (story) => publicStatuses.includes(story.status);
  // Each day's file, once read or written, for the rest of the run. Nobody
  // else writes them while the collector runs, and without this every story
  // written read every day there is to list them.
  const dayCache = new Map();
  // Whole stories, other languages and all, as read or written this run: the
  // day files carry the English only, and each language's day file is made
  // from these.
  const fullCache = new Map();
  async function full(story) {
    if (story.words) return story;
    if (!fullCache.has(story.id)) fullCache.set(story.id, (await get(`${PREFIX}/stories/${story.id}.json`)) ?? story);
    return fullCache.get(story.id);
  }
  // Each language's copy of one file, side by side.
  const inEvery = (make) => Promise.all(OTHER.map((lang) => make(lang)));

  return {
    bucket,
    /** Whether the feed's public files carry this story — FEED_PUBLIC. */
    visible,
    /** Every public story, newest day first, as the day files list them. */
    async publicStories(days) {
      const stories = [];
      for (const date of Object.keys(days).sort().reverse()) {
        stories.push(...(await this.day(date)).stories.filter(visible));
      }
      return stories;
    },
    async state() {
      const state = (await get(STATE_KEY)) ?? {};
      return { rounds: {}, games: {}, days: {}, ...state };
    },
    saveState: (state) => put(STATE_KEY, { ...state, updatedAt: new Date().toISOString() }, { isPublic: false }),
    /** A file only the collector reads, and one everybody may: for the reports (reports.mjs). */
    getPrivate: (key) => get(key),
    putPrivate: (key, value) => put(key, value, { isPublic: false }),
    putPublic: (key, value, options = {}) => put(key, value, options),
    async pages() {
      return { done: {}, ...((await get(PAGES_KEY)) ?? {}) };
    },
    savePages: (pages) => put(PAGES_KEY, { ...pages, updatedAt: new Date().toISOString() }, { isPublic: false }),
    story: (id) => get(`${PREFIX}/stories/${id}.json`),
    async day(date) {
      if (!dayCache.has(date)) dayCache.set(date, (await get(`${PREFIX}/days/${date}.json`)) ?? { date, stories: [] });
      return dayCache.get(date);
    },

    /**
     * Write stories, then everything that lists them: each day they fall on,
     * and — unless told to leave it for later — the latest file. `days` is the
     * state's map of date → story ids, the one list of what exists, kept by
     * whoever calls this.
     */
    async write(stories, days, { latest = true } = {}) {
      const touched = new Set();
      for (const given of stories) {
        // A story given without its languages — a change to one field, made
        // from a day file's copy — keeps the languages it already had.
        const story = given.words ? given : { ...(await full(given)), ...given };
        fullCache.set(story.id, story);
        await put(`${PREFIX}/stories/${story.id}.json`, story);
        await inEvery((lang) => put(`${PREFIX}/${lang}/stories/${story.id}.json`, inLanguage(story, lang), { quiet: true }));
        touched.add(story.date);
      }
      for (const date of touched) {
        const kept = new Map((await this.day(date)).stories.map((s) => [s.id, s]));
        for (const story of stories) if (story.date === date) kept.set(story.id, story);
        // A story whose day file predates it being listed still belongs.
        for (const id of days[date] ?? []) if (!kept.has(id)) {
          const story = await this.story(id);
          if (story) kept.set(id, story);
        }
        const shown = order([...kept.values()].filter(visible));
        const day = { date, stories: shown.map(bare) };
        dayCache.set(date, day);
        await put(`${PREFIX}/days/${date}.json`, day);
        const whole = await Promise.all(shown.map(full));
        await inEvery((lang) => put(`${PREFIX}/${lang}/days/${date}.json`,
          { date, lang, stories: whole.map((story) => inLanguage(story, lang)) }, { quiet: true }));
      }
      if (latest) await this.writeLatest(days);
    },

    async writeLatest(days) {
      const dates = Object.keys(days).sort().reverse();
      const index = [];
      const stories = [];
      for (const date of dates) {
        const day = await this.day(date);
        const shown = day.stories.filter(visible);
        if (!shown.length) continue;
        index.push({ date, count: shown.length });
        if (index.length <= LATEST_DAYS) stories.push(...order(shown));
      }
      const file = (list, extra = {}) => ({
        version: 1,
        generatedAt: new Date().toISOString(),
        source: { name: 'Lichess broadcasts', url: 'https://lichess.org/broadcast' },
        ...extra,
        days: index,
        stories: list,
      });
      await put(`${PREFIX}/latest.json`, file(stories.map(bare)));
      const whole = await Promise.all(stories.map(full));
      await inEvery((lang) => put(`${PREFIX}/${lang}/latest.json`,
        file(whole.map((story) => inLanguage(story, lang)), { lang }), { quiet: true }));
      if (dryRun && quietWrites) log(`  … and ${quietWrites} copies in the other ${OTHER.length} languages`);
      quietWrites = 0;
    },
  };
}

/**
 * Newest day first; within a day, by weight — the score the game was chosen
 * on, so a followed player's win comes before a lesser board's, whichever
 * section either was in.
 */
function order(stories) {
  return stories.sort((a, b) => b.date.localeCompare(a.date) || weight(b) - weight(a) || a.id.localeCompare(b.id));
}

/** The selection score, or for a story stored before it was kept, the next best thing. */
function weight(story) {
  if (typeof story.weight === 'number') return story.weight;
  const elo = Math.max(story.white?.elo ?? 0, story.black?.elo ?? 0);
  return elo - 2500 + (story.result === '1/2-1/2' ? 0 : 250);
}

/** A story as it is stored: the parts the app and the site read, and its status. */
export function stored(story) {
  const person = ({ name, short, title, elo, team }) => ({ name, short, title, elo, team });
  // The board the story is about, worked out here so that the site, which has
  // no chess rules in it, can draw it — and the first sentence, for a list.
  const sans = story.moves.split(' ');
  const { fen, last } = positionAt(sans, story.key?.ply ?? sans.length);
  return {
    id: story.id,
    status: story.status,
    date: story.date,
    rank: story.rank ?? 0,
    weight: weight(story),
    event: story.event,
    white: person(story.white),
    black: person(story.black),
    result: story.result,
    opening: story.opening,
    moves: story.moves,
    ending: story.ending ?? null,
    key: story.key
      ? {
          kind: story.key.kind,
          ply: story.key.ply,
          played: story.key.played,
          better: story.key.better,
          reply: story.key.reply,
          replyPlayed: story.key.replyPlayed,
          before: story.key.before,
          after: story.key.after,
          clock: story.key.clock ?? null,
        }
      : null,
    headline: story.headline,
    lede: story.lede ?? story.body.split(/(?<=[.!?])\s+(?=[A-Z0-9])/)[0],
    body: story.body,
    // The story in every other language the app speaks (article.mjs), for
    // the files each language reads. English is the fields above.
    words: story.words ?? null,
    fen,
    last,
    // The address that works from the moment the story exists: the page that
    // draws a story from the feed. The story's own page replaces it once one
    // is written — by the collector at once, or by a deploy — see pages.mjs.
    url: story.url?.startsWith('https://brasspawn.com/today/') ? story.url : `https://brasspawn.com/today/story?id=${story.id}`,
    source: story.source,
    updatedAt: new Date().toISOString(),
  };
}
