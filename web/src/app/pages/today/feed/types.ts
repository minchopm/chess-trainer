/**
 * A story in the daily feed, as the site builds it.
 *
 * The same story the app downloads, plus the positions worked out in advance:
 * the site has no chess rules in it, and does not need them to draw a board.
 * See scripts/feed/publish.mjs, which writes everything under this folder
 * except this file.
 */

export interface Score {
  readonly cp: number | null;
  readonly mate: number | null;
}

export interface Player {
  readonly name: string;
  readonly short: string;
  readonly title: string | null;
  readonly elo: number | null;
  readonly team: string | null;
}

export interface FeedEvent {
  readonly name: string;
  readonly short: string;
  readonly section: string | null;
  readonly round: number | null;
  readonly location: string | null;
  readonly url: string | null;
}

export interface KeyMoment {
  /** mistake: the loser's move that decided it. breakthrough: the winner's.
   *  swing: in a draw, the chance that came and went. */
  readonly kind: 'mistake' | 'breakthrough' | 'swing';
  /** Half-moves played up to and including the key move. */
  readonly ply: number;
  readonly played: string;
  readonly better: string | null;
  readonly reply: string | null;
  readonly replyPlayed: boolean;
  /** Stockfish's scores, from White's side, before and after the move. */
  readonly before: Score;
  readonly after: Score;
  /** Seconds on the mover's clock after the move, where the broadcast sent one. */
  readonly clock?: number | null;
}

/** Enough to list a story and draw its board. */
export interface StorySummary {
  readonly id: string;
  readonly date: string;
  readonly headline: string;
  readonly lede: string;
  readonly event: FeedEvent;
  readonly white: Player;
  readonly black: Player;
  readonly result: '1-0' | '0-1' | '1/2-1/2';
  /** The board the story is about: after the key move, or the final one. */
  readonly fen: string;
  readonly last: { readonly from: string; readonly to: string } | null;
  /**
   * The story's address, as the feed has it: its own page once one has been
   * made — by a deploy, or by the collector for a story newer than it — and
   * /today/story?id= for a story from before the collector made pages.
   */
  readonly url?: string;
}

/** One position of a game and the move that made it; the first has none. */
export interface LinePosition {
  readonly fen: string;
  readonly last: { readonly from: string; readonly to: string } | null;
}

export interface Story extends StorySummary {
  /** Every position of the game, for the replay. Absent on a story read live from the feed. */
  readonly line?: readonly LinePosition[];
  readonly opening: { readonly eco: string | null; readonly name: string | null };
  readonly moves: string;
  readonly key: KeyMoment | null;
  readonly body: string;
  readonly url: string;
  readonly source: { readonly name: string; readonly url: string | null };
}
