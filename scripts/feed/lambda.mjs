// The collector, on a schedule: EventBridge runs it every two hours, and each
// run reads the rounds that have finished since the last one. See collect.mjs.
import { collect } from './collect.mjs';
import { openStore } from './store.mjs';

export const handler = async (_event, context) => {
  // Stop starting games with three minutes in hand. A game takes a minute or
  // two, and the writes after it must never be cut off halfway.
  const budgetMs = Math.max(60_000, context.getRemainingTimeInMillis() - 180_000);
  const written = await collect({
    // FEED_DRY_RUN=1 reads and analyses and writes nothing — for trying a
    // package before it replaces the one on the schedule.
    store: openStore({ dryRun: process.env.FEED_DRY_RUN === '1', log: (line) => console.log(line) }),
    budgetMs,
    workers: Number(process.env.FEED_WORKERS ?? 1),
    log: (line) => console.log(line),
  });
  return { written: written.map((story) => story.id) };
};
