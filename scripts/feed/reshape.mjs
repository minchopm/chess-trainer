#!/usr/bin/env node
// Write every stored story again in the shape store.mjs writes today — words,
// status and moves untouched — and every day file and the latest file after
// them. For when the shape changes: a field added, a value worked out that
// was not before.
//
//   node scripts/feed/reshape.mjs --dry-run
//   node scripts/feed/reshape.mjs
//   node scripts/feed/reshape.mjs --words    and the words written again by article.mjs:
//                                            every language of every story, and the English
//                                            too of a story nobody has approved
import { articles } from './article.mjs';
import { openStore, stored } from './store.mjs';

const store = openStore({ dryRun: process.argv.includes('--dry-run') });
const rewrite = process.argv.includes('--words');
const state = await store.state();
const stories = [];
for (const ids of Object.values(state.days)) {
  for (const id of ids) {
    const story = await store.story(id);
    if (!story) continue;
    if (!rewrite) {
      stories.push(stored(story));
      continue;
    }
    const { en, ...words } = articles(story);
    // A person's approved words stand; the collector's own are replaced.
    const english = story.status === 'approved' ? {} : { headline: en.headline, lede: en.lede, body: en.body };
    stories.push(stored({ ...story, ...english, words }));
  }
}
await store.write(stories, state.days);
console.error(`${stories.length} stories rewritten across ${Object.keys(state.days).length} days`);
