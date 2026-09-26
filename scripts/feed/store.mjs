// Where the feed lives: the media bucket behind brasspawn.com.
//
//   media/feed/v1/latest.json          the app's first request: the newest days, and the list of all days
//   media/feed/v1/days/<date>.json     one day's stories, for going back through the history
//   media/feed/v1/stories/<id>.json    one story, for the site
//   feed-state/v1/state.json           what the collector has already read — private
//
// Everything under media/ is public through the /media/* behaviour on the
// distribution; feed-state/ matches no behaviour, so nothing outside the
// collector can read it.
//
// A story is written once by the collector, as "auto", and again if a person
// rewrites and approves it, as "approved". The collector never touches a story
// that exists. Which statuses the public files carry is FEED_PUBLIC: "all"
// while the feature is being tested, "approved" once only read words go out.
import { positionAt } from './diagram.mjs';
import { openS3 } from './s3.mjs';

export const PREFIX = 'media/feed/v1';
const STATE_KEY = 'feed-state/v1/state.json';
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

  async function put(key, value, { isPublic = true } = {}) {
    if (dryRun) {
      log(`  would write s3://${bucket}/${key}`);
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
      for (const story of stories) {
        await put(`${PREFIX}/stories/${story.id}.json`, story);
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
        const day = { date, stories: order([...kept.values()].filter(visible)) };
        dayCache.set(date, day);
        await put(`${PREFIX}/days/${date}.json`, day);
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
      await put(`${PREFIX}/latest.json`, {
        version: 1,
        generatedAt: new Date().toISOString(),
        source: { name: 'Lichess broadcasts', url: 'https://lichess.org/broadcast' },
        days: index,
        stories,
      });
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
    lede: story.body.split(/(?<=[.!?])\s+(?=[A-Z0-9])/)[0],
    body: story.body,
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
