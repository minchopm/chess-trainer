// The collector, on a schedule: EventBridge runs it every two hours, and each
// run reads the rounds that have finished since the last one. See collect.mjs.
import { collect } from './collect.mjs';
import { openPages, translatePages } from './pages.mjs';
import { openStore } from './store.mjs';

export const handler = async (event, context) => {
  const dryRun = process.env.FEED_DRY_RUN === '1';
  const log = (line) => console.log(line);

  // { "renderCheck": "<story id>" } renders that story's page and writes
  // nothing — to see that the packaged renderer runs here, on this Node,
  // before a new story depends on it.
  if (event?.renderCheck) {
    const story = await openStore({ log }).story(event.renderCheck);
    if (!story) return { error: `no story ${event.renderCheck}` };
    const started = Date.now();
    const writes = [];
    await openPages({ dryRun: true, log: (line) => writes.push(line.trim()) }).page(story);
    return { rendered: story.id, ms: Date.now() - started, node: process.version, writes };
  }

  const store = openStore({ dryRun, log });
  // Each new story's page on the site, with the renderer of the build that
  // is deployed — packaged beside this file by deploy-lambda.sh.
  const site = openPages({ dryRun, log });

  // { "pages": true } is a site deploy asking for the other languages' pages
  // in its new build, now rather than over the next few runs: no collecting,
  // the whole of the time on pages.
  let written = [];
  if (!event?.pages) {
    // Stop starting games with three minutes in hand. A game takes a minute or
    // two, and the writes after it must never be cut off halfway.
    const budgetMs = Math.max(60_000, context.getRemainingTimeInMillis() - 180_000);
    written = await collect({ store, site, budgetMs, workers: Number(process.env.FEED_WORKERS ?? 1), log });
  }

  // The story pages in every other language, as long as there is time: new
  // stories first, then whatever an earlier build rendered.
  const { days } = await store.state();
  const pagesBudget = Math.max(0, context.getRemainingTimeInMillis() - 90_000);
  const { fresh, done, left } = await translatePages({ store, site, days, budgetMs: pagesBudget, log });
  await site.lists(await store.publicStories(days), done);
  await site.announce(fresh);
  return { written: written.map((story) => story.id), newPages: fresh.length, left };
};
