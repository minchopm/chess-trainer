#!/usr/bin/env node
// A day's stories out of the feed and into feed/drafts/<date>.json, to be
// rewritten and approved — see publish.mjs.
//
//   node scripts/feed/pull.mjs 2026-09-25
//
// A draft already in the file is kept as it is: pulling twice never throws
// away words somebody has rewritten, and a story the collector added since
// the last pull is added beside them.
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { openStore } from './store.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const date = process.argv[2];
if (!/^\d{4}-\d{2}-\d{2}$/.test(date ?? '')) {
  console.error('usage: node scripts/feed/pull.mjs <yyyy-mm-dd>');
  process.exit(1);
}

// Every story of the day, whatever the public files carry.
const store = openStore({ publicStatuses: ['auto', 'approved'] });
const state = await store.state();
const live = [];
for (const id of state.days[date] ?? []) {
  const story = await store.story(id);
  if (story) live.push(story);
}

const out = resolve(ROOT, `feed/drafts/${date}.json`);
const kept = existsSync(out) ? JSON.parse(await readFile(out, 'utf8')).stories : [];
const byId = new Map(kept.map((s) => [s.id, s]));
let added = 0;
for (const story of live) {
  if (byId.has(story.id)) continue;
  byId.set(story.id, { ...story, status: story.status === 'approved' ? 'approved' : 'draft' });
  added++;
}
await mkdir(dirname(out), { recursive: true });
await writeFile(out, JSON.stringify({ date, pulledAt: new Date().toISOString(), stories: [...byId.values()] }, null, 2) + '\n');
console.error(`${live.length} stories on ${date}; ${added} new in ${out}`);
