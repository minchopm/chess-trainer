#!/usr/bin/env node
// Put rewritten, approved stories into the feed.
//
//   node scripts/feed/pull.mjs 2026-09-25       # 1. the day's stories → feed/drafts/2026-09-25.json
//                                                # 2. rewrite headline and body; "status": "approved"
//   node scripts/feed/review.mjs 2026-09-25     # 3. read them beside their boards
//   node scripts/feed/publish.mjs               # 4. check every approved draft; writes nothing
//   node scripts/feed/publish.mjs --upload      # 5. and write them over the collector's version
//
// The collector writes every story as "auto", in words that say only what the
// broadcast and the engine say. This is the other way a story gets written:
// by a person, read, and approved. Each approved draft is checked again before
// it goes anywhere — the moves must play, the key move must be the one the
// words name, and nobody is "he" or "she" — and a draft that fails is
// reported and left out, never published half.
import { readdir, readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';

import { openStore, stored } from './store.mjs';
import { moveLabel } from './words.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const upload = process.argv.includes('--upload');

function problems(story) {
  const found = [];
  for (const field of ['id', 'date', 'headline', 'body', 'moves', 'result']) {
    if (!story[field] || typeof story[field] !== 'string') found.push(`no ${field}`);
  }
  if (!/^[a-z0-9-]+$/.test(story.id ?? '')) found.push('id is not a slug');
  if (!['1-0', '0-1', '1/2-1/2'].includes(story.result)) found.push(`result ${story.result}`);
  const sans = (story.moves ?? '').split(' ');
  const chess = new Chess();
  for (const [i, san] of sans.entries()) {
    try {
      chess.move(san);
    } catch {
      found.push(`move ${i + 1} (${san}) does not play`);
      break;
    }
  }
  if (story.key) {
    const { ply, played } = story.key;
    if (!(ply >= 1 && ply <= sans.length)) found.push(`key ply ${ply} is outside the game`);
    else if (sans[ply - 1] !== played) found.push(`key move is ${sans[ply - 1]}, story says ${played}`);
    // The words name the move; the move named has to be the one on the board.
    const label = moveLabel(ply, played);
    if (!story.body.includes(label) && !story.headline.includes(label)) found.push(`the words never mention ${label}`);
  }
  if (/\b(he|she|his|her|him|hers|himself|herself)\b/i.test(`${story.headline} ${story.body}`)) {
    found.push('uses a gendered pronoun — the feed names people instead');
  }
  return found;
}

const store = openStore({ dryRun: !upload });
const state = await store.state();
const approved = [];
const dir = resolve(ROOT, 'feed/drafts');
for (const file of (await readdir(dir)).filter((f) => f.endsWith('.json')).sort()) {
  const drafts = JSON.parse(await readFile(resolve(dir, file), 'utf8'));
  for (const story of drafts.stories) {
    if (story.status !== 'approved') continue;
    const wrong = problems(story);
    if (wrong.length) {
      console.error(`✗ ${story.id}: ${wrong.join('; ')}`);
      continue;
    }
    const live = await store.story(story.id);
    if (live?.status === 'approved' && live.headline === story.headline && live.body === story.body) continue;
    approved.push(stored({ ...story, status: 'approved' }));
    console.error(`✓ ${story.id}${live ? ` (over the ${live.status} version)` : ' (new)'}`);
  }
}

if (!approved.length) {
  console.error('Nothing new to publish.');
} else {
  for (const story of approved) {
    const ids = (state.days[story.date] ??= []);
    if (!ids.includes(story.id)) ids.push(story.id);
  }
  await store.write(approved, state.days);
  if (upload) {
    await store.saveState(state);
    console.error(`Published ${approved.length}. The app has them within five minutes; the site's pages with its next deploy.`);
  } else {
    console.error(`${approved.length} ready. Run again with --upload to publish them.`);
  }
}
