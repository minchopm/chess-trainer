// The collector, on a schedule: EventBridge runs it every two hours, and each
// run reads the rounds that have finished since the last one. See collect.mjs.
import { collect } from './collect.mjs';
import { openPages } from './pages.mjs';
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

  // Stop starting games with three minutes in hand. A game takes a minute or
  // two, and the writes after it must never be cut off halfway.
  const budgetMs = Math.max(60_000, context.getRemainingTimeInMillis() - 180_000);
  const written = await collect({
    // FEED_DRY_RUN=1 reads and analyses and writes nothing — for trying a
    // package before it replaces the one on the schedule.
    store: openStore({ dryRun, log }),
    // Each new story's page on the site, with the renderer of the build that
    // is deployed — packaged beside this file by deploy-lambda.sh.
    site: openPages({ dryRun, log }),
    budgetMs,
    workers: Number(process.env.FEED_WORKERS ?? 1),
    log,
  });
  return { written: written.map((story) => story.id) };
};
