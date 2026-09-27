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

import { articles, problems as unsafe } from './article.mjs';
import { openPages, publishPages } from './pages.mjs';
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
  // The collector's own bar, too: nothing that judges a person or reports a
  // feeling nobody reported.
  for (const wrong of unsafe(`${story.headline}\n${story.body}`, 'en')) {
    if (!found.some((f) => f.includes('pronoun'))) found.push(wrong);
  }
  return found;
}

/**
 * The other languages, as the draft has them: each one somebody rewrote —
 * which is any whose words differ from the collector's — kept and checked
 * like the English, and every other made again from the facts. A rewritten
 * language must still name the key move, and has no lede of its own unless
 * it was given one: its first sentence is it.
 */
function languages(story, made) {
  const words = { ...made };
  const found = [];
  const label = story.key ? moveLabel(story.key.ply, story.key.played) : null;
  for (const [lang, own] of Object.entries(story.words ?? {})) {
    if (lang === 'en' || !made[lang]) continue;
    const same = own.headline === made[lang].headline && own.body === made[lang].body;
    if (same) continue;
    if (typeof own.headline !== 'string' || typeof own.body !== 'string' || !own.headline || !own.body) {
      found.push(`${lang}: no headline or body`);
      continue;
    }
    const wrong = unsafe(`${own.headline}\n${own.body}`, lang);
    if (wrong.length) found.push(`${lang}: ${wrong.join(', ')}`);
    if (label && !own.body.includes(label) && !own.headline.includes(label)) found.push(`${lang}: never mentions ${label}`);
    // The first sentence of the first paragraph: a stop followed by a space,
    // but not one after a digit ("der 46. FIDE-Schacholympiade", "+2.27",
    // "30...g4"), or a CJK or Devanagari stop, which needs no space.
    const lede = own.lede ?? own.body.split('\n\n')[0].split(/(?<=(?<!\d)[.!?])\s+|(?<=[。！？।])/u)[0].trim();
    words[lang] = { headline: own.headline, lede, body: own.body };
  }
  return { words, found };
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
    // The approved words are English, and any language rewritten beside
    // them; the others keep the collector's, made from the same facts.
    const { en, ...made } = articles(story);
    const { words, found } = languages(story, made);
    if (found.length) {
      console.error(`✗ ${story.id}: ${found.join('; ')}`);
      continue;
    }
    approved.push(stored({ ...story, status: 'approved', lede: undefined, words }));
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
  // Their pages again, in the approved words — rendered with the local build,
  // so deploy the site first if it has changed since. Only a story the feed
  // makes public gets one.
  const site = openPages({ dryRun: !upload });
  const pages = [];
  for (const [i, story] of approved.entries()) {
    if (!store.visible(story)) continue;
    try {
      pages.push(await site.page(story));
      approved[i] = { ...story, url: pages.at(-1) };
    } catch (error) {
      console.error(`✗ page for ${story.id}: ${error.message}`);
      continue;
    }
    // And in every other language: the collector renders a story's languages
    // once per build, so the pages it made from its own words would stay.
    try {
      await site.translations(story);
    } catch (error) {
      console.error(`✗ languages for ${story.id}: ${error.message}`);
    }
  }
  await store.write(approved, state.days);
  await publishPages({ store, site, days: state.days });
  await site.announce(pages);
  if (upload) {
    await store.saveState(state);
    console.error(`Published ${approved.length}, ${pages.length} pages rewritten. The app has them within five minutes.`);
  } else {
    console.error(`${approved.length} ready. Run again with --upload to publish them.`);
  }
}
