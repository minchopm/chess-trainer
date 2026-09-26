// The Lichess broadcast API, and the PGN it sends.
//
// Broadcasts are the official relays of over-the-board events — the moves are
// the moves, as played. Lichess asks API users to make one request at a time
// and to back off for a full minute on a 429, so every call here goes through
// one queue with a pause between calls, and a 429 waits rather than retries.

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const ORIGIN = 'https://lichess.org';
const AGENT = 'BrassPawnFeed/1 (+https://brasspawn.com; support@brasspawn.com)';
const GAP_MS = 1200;

let last = 0;

async function get(path, { accept = 'application/json' } = {}) {
  for (let attempt = 0; attempt < 4; attempt++) {
    const wait = last + GAP_MS - Date.now();
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));
    last = Date.now();
    let response;
    try {
      response = await fetch(ORIGIN + path, { headers: { 'User-Agent': AGENT, Accept: accept } });
      if (response.status === 429) {
        console.error(`  429 from ${path} — waiting a minute, as Lichess asks`);
        await new Promise((r) => setTimeout(r, 61_000));
        continue;
      }
      // A server error is worth one more look; a client error is not.
      if (response.status >= 500) throw new Error(`${response.status} from Lichess`);
      if (!response.ok) throw Object.assign(new Error(`${response.status} ${response.statusText} for ${path}`), { final: true });
      return accept === 'application/json' ? await response.json() : await response.text();
    } catch (error) {
      if (error.final || attempt === 3) throw error;
      // A dropped connection or a 5xx: back off and ask again.
      console.error(`  ${error.cause?.code ?? error.message} on ${path} — trying again`);
      await new Promise((r) => setTimeout(r, 3000 * (attempt + 1)));
    }
  }
  throw new Error(`gave up on ${path}`);
}

/**
 * The featured broadcasts: live now, and the most recently finished — going
 * back `pages` pages of twenty for a backfill. Lichess stops answering past
 * page five, so a page that does not come back ends the list.
 */
export async function topBroadcasts({ pages = 1 } = {}) {
  const first = await get('/api/broadcast/top?page=1');
  const all = [...(first.active ?? []), ...(first.past?.currentPageResults ?? [])];
  for (let n = 2; n <= pages; n++) {
    try {
      const page = await get(`/api/broadcast/top?page=${n}`);
      all.push(...(page.past?.currentPageResults ?? []));
      if (!page.past?.nextPage) break;
    } catch {
      break;
    }
  }
  return all;
}

/** One tour with its rounds and, for a multi-section event, its sibling tours. */
export function tour(id) {
  return get(`/api/broadcast/${id}`);
}

/**
 * A round's games. Asked for only once a round is over, when it no longer
 * changes — so a backfill run by hand can keep them in FEED_CACHE_DIR and a
 * second run does not download the month again.
 */
export async function roundPgn(id) {
  const dir = process.env.FEED_CACHE_DIR;
  const file = dir && join(dir, `round-${id}.pgn`);
  if (file) {
    try {
      return await readFile(file, 'utf8');
    } catch {}
  }
  const pgn = await get(`/api/broadcast/round/${id}.pgn`, { accept: 'application/x-chess-pgn' });
  if (file) {
    await mkdir(dir, { recursive: true });
    await writeFile(file, pgn);
  }
  return pgn;
}

/**
 * A PGN file as a list of games: tags, the moves in SAN, and the clock after
 * each move where the relay sent one.
 *
 * Written out rather than handed to chess.js's `loadPgn` because the relay
 * interleaves a clock comment with every move and the clocks are wanted — a
 * move played with two minutes left is a different story from the same move
 * with an hour.
 */
export function parsePgn(text) {
  const games = [];
  for (const chunk of text.split(/\n\s*\n(?=\[)/)) {
    const tags = {};
    for (const match of chunk.matchAll(/^\[(\w+)\s+"((?:[^"\\]|\\.)*)"\]\s*$/gm)) {
      tags[match[1]] = match[2].replace(/\\"/g, '"');
    }
    if (!tags.White) continue;
    const movetext = chunk.replace(/^\[.*\]\s*$/gm, '').trim();
    const sans = [];
    const clocks = [];
    // Variations are dropped — a relay does not send them, and a stray one
    // would otherwise be read as moves of the game.
    let body = movetext;
    while (/\([^()]*\)/.test(body)) body = body.replace(/\([^()]*\)/g, ' ');
    const tokens = body.match(/\{[^}]*\}|[^\s{}]+/g) ?? [];
    for (const token of tokens) {
      if (token.startsWith('{')) {
        const clock = /\[%clk (\d+):(\d+):(\d+)\]/.exec(token);
        if (clock && sans.length) clocks[sans.length - 1] = +clock[1] * 3600 + +clock[2] * 60 + +clock[3];
        continue;
      }
      if (/^\d+\.+$/.test(token) || /^\$\d+$/.test(token)) continue;
      if (/^(1-0|0-1|1\/2-1\/2|\*)$/.test(token)) continue;
      const san = token.replace(/^\d+\.+/, '').replace(/[?!]+$/, '');
      if (san) sans.push(san);
    }
    games.push({ tags, sans, clocks });
  }
  return games;
}
