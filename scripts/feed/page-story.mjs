// A stored story as the website's story page takes it — for the build, which
// writes one module per story (site.mjs), and for the collector, which renders
// the page of a story newer than the last deploy (pages.mjs). One function for
// both, so a page made either way is made from the same story.
import { Chess } from 'chess.js';

import { positionAt } from './diagram.mjs';
import { reportFor } from './reports.mjs';

/** The story, with the board it is about worked out if the stored copy has none. */
export function forSite(story) {
  const sans = story.moves.split(' ');
  const board = story.fen ? { fen: story.fen, last: story.last ?? null } : positionAt(sans, story.key?.ply ?? sans.length);
  return {
    id: story.id,
    status: story.status,
    date: story.date,
    headline: story.headline,
    lede: story.lede ?? story.body.split(/(?<=[.!?])\s+(?=[A-Z0-9])/)[0],
    event: story.event,
    white: story.white,
    black: story.black,
    result: story.result,
    fen: board.fen,
    last: board.last,
    opening: story.opening,
    moves: story.moves,
    key: story.key,
    body: story.body,
    url: pageURL(story.id),
    source: story.source,
    report: reportFor(story),
  };
}

/** Where a story's page is — the one address, whichever of the two made it. */
export function pageURL(id) {
  return `https://brasspawn.com/today/${id}`;
}

/**
 * Every position of the game and the move that made it, for the story page's
 * replay. Worked out here so the site ships no chess rules: a page steps
 * through a list of boards it was handed. A few kilobytes a story, and only
 * in the story's own page — never in the list.
 */
export function line(moves) {
  const chess = new Chess();
  const out = [{ fen: chess.fen(), last: null }];
  for (const san of moves.split(' ')) {
    const move = chess.move(san);
    out.push({ fen: chess.fen().split(' ')[0], last: { from: move.from, to: move.to } });
  }
  return out;
}

/** The whole of what a story page is drawn from: the story, and its replay. */
export function pageStory(story) {
  const { status, ...page } = forSite(story);
  return { ...page, line: line(story.moves) };
}
