#!/usr/bin/env node
// Write every stored story again in the shape store.mjs writes today — words,
// status and moves untouched — and every day file and the latest file after
// them. For when the shape changes: a field added, a value worked out that
// was not before.
//
//   node scripts/feed/reshape.mjs --dry-run
//   node scripts/feed/reshape.mjs
import { openStore, stored } from './store.mjs';

const store = openStore({ dryRun: process.argv.includes('--dry-run') });
const state = await store.state();
const stories = [];
for (const ids of Object.values(state.days)) {
  for (const id of ids) {
    const story = await store.story(id);
    if (story) stories.push(stored(story));
  }
}
await store.write(stories, state.days);
console.error(`${stories.length} stories rewritten across ${Object.keys(state.days).length} days`);
