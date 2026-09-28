// The referee: what a game played online did to the two ratings.
//
// Each device used to work out its own rating and send it to Game Center, and
// a modified build could send anything. Here nothing a device says about a
// rating is believed. Both players tell the referee that a game began, and
// both report how it ended — each signed by Game Center (identity.mjs), so a
// report is the player's own and nobody else's. The referee rates a game only
// when it has happened between these two, and only on a result it can stand
// behind:
//
// - both reports agree, and the moves play to the result they claim, where the
//   board can say (mate, stalemate, a draw by the rules); or
// - one report, when the other player also began the game and has said
//   nothing since — they left, their app closed, their phone died. A player
//   who says they lost is taken at their word; one who says they won is, once
//   the other has had time to say otherwise. Two reports that disagree rate
//   nothing.
//
// Then the rules the app states: only a game found by the open search is
// rated, not one from an invitation, not a rematch, not one of fewer than two
// moves, and only one a day against the same opponent. And Glicko, from the
// ratings kept here, not the ones the players arrived with.
//
// The store is anything with get/put/list/remove/publish (store.mjs over S3,
// or a Map in the tests). Every rating, on every clock, lives in one file,
// written conditionally, with who has played whom today and which games it
// has applied — so a game settled twice, by two requests at once or by a
// retry, is counted once. One file is plenty for the app's size; when it is
// not, this is the part to move to a database.
import { Chess } from 'chess.js';

import { FLOOR, NEW_DEVIATION, STARTING, grown, updated } from './glicko.mjs';

export const STATE = 'ratings-state/v1';
export const PUBLIC = 'media/ratings/v1';
export const CLOCKS = [3, 5, 10, 15, 30];
/** How long a lone report waits for the other player's. */
export const CONFIRM_MS = 10 * 60_000;
/** A game nobody has reported is given its clocks, twice, and an hour. */
const unreported = (minutes) => (2 * minutes + 60) * 60_000;
const DAY = 86_400_000;
const REASONS = new Set(['checkmate', 'resignation', 'timeout', 'stalemate', 'insufficientMaterial',
  'repetition', 'fiftyMoveRule', 'agreement', 'disconnected']);
const OUTCOMES = { win: 1, draw: 0.5, loss: 0 };
const opposite = { win: 'loss', loss: 'win', draw: 'draw', white: 'black', black: 'white' };

const gameKey = (id) => `${STATE}/games/${id}`;
const RATINGS = `${STATE}/ratings.json`;
const pendingKey = (id) => `${STATE}/pending/${id}.json`;
const pairKey = (a, b) => [a, b].sort().join('|');

/** What a request says about a game, checked for shape before anything is stored. */
export function ticket(body) {
  const { gameID, minutes, openPool, gameNumber, color } = body ?? {};
  if (typeof gameID !== 'string' || !/^[A-Za-z0-9-]{8,80}$/.test(gameID)) throw new Error('no game');
  if (!CLOCKS.includes(minutes)) throw new Error('no such clock');
  if (!['white', 'black'].includes(color)) throw new Error('no colour');
  if (!Number.isInteger(gameNumber) || gameNumber < 1) throw new Error('no game number');
  return { gameID, minutes, openPool: openPool === true, gameNumber, color };
}

export function report(body) {
  const base = ticket(body);
  const { moves, outcome, reason } = body;
  if (!Array.isArray(moves) || moves.length > 1000 || !moves.every((m) => typeof m === 'string' && /^[a-h][1-8][a-h][1-8][qrbn]?$/.test(m))) {
    throw new Error('no moves');
  }
  if (!(outcome in OUTCOMES)) throw new Error('no outcome');
  if (!REASONS.has(reason)) throw new Error('no reason');
  return { ...base, moves, outcome, reason };
}

export function openReferee({ store, now = () => Date.now(), log = () => {} }) {
  /** A game has begun, as one of its players says. */
  async function begin(player, game) {
    if (await verdictOf(game.gameID)) return { status: 'begun' };
    await store.put(`${gameKey(game.gameID)}/start-${player}.json`, { ...game, player, at: now() });
    await store.put(pendingKey(game.gameID), { gameID: game.gameID, minutes: game.minutes, since: now() }, { ifNoneMatch: true });
    return { status: 'begun' };
  }

  /** A game has ended, as one of its players says: settled now, if it can be. */
  async function end(player, game) {
    const decided = await verdictOf(game.gameID);
    if (decided) return answer(player, decided, game.minutes);
    const key = `${gameKey(game.gameID)}/report-${player}.json`;
    const existing = await store.get(key);
    // A retry of the same report is the same report; a changed one is not taken.
    if (existing && !sameResult(existing.body, game)) return answer(player, await verdictOf(game.gameID), game.minutes);
    if (!existing) await store.put(key, { ...game, player, at: now() });
    await store.put(pendingKey(game.gameID), { gameID: game.gameID, minutes: game.minutes, since: now() }, { ifNoneMatch: true });
    const verdict = await settle(game.gameID, { final: false });
    return answer(player, verdict, game.minutes);
  }

  async function verdictOf(gameID) {
    return (await store.get(`${gameKey(gameID)}/verdict.json`))?.body ?? null;
  }

  /** Everything said about one game, by whom. */
  async function papers(gameID) {
    const starts = new Map();
    const reports = new Map();
    for (const { key } of await store.list(`${gameKey(gameID)}/`)) {
      const name = key.slice(key.lastIndexOf('/') + 1);
      const match = /^(start|report)-([0-9a-f]{32})\.json$/.exec(name);
      if (!match) continue;
      const body = (await store.get(key))?.body;
      if (body) (match[1] === 'start' ? starts : reports).set(match[2], body);
    }
    return { starts, reports };
  }

  /**
   * The verdict on a game, if there can be one yet. `final` is the sweep's:
   * the time to wait for the other player is over.
   */
  async function settle(gameID, { final }) {
    const done = await verdictOf(gameID);
    if (done) return done;
    const { starts, reports } = await papers(gameID);
    const players = new Set([...starts.keys(), ...reports.keys()]);
    const said = [...reports.values()];
    const minutes = said[0]?.minutes ?? [...starts.values()][0]?.minutes;

    if (players.size > 2) return close(gameID, { status: 'void', reason: 'players', minutes });
    if (said.length === 2) {
      const [a, b] = said;
      const agree = a.minutes === b.minutes && a.color === opposite[b.color] && a.outcome === opposite[b.outcome]
        && a.reason === b.reason && a.gameNumber === b.gameNumber && a.moves.join() === b.moves.join();
      if (!agree) return close(gameID, { status: 'void', reason: 'disputed', minutes });
      return decide(gameID, a, b.player, { starts, reports });
    }
    if (!final) return { status: 'pending', minutes };
    if (said.length === 0) return close(gameID, { status: 'void', reason: 'unreported', minutes });
    const [only] = said;
    const other = [...players].find((p) => p !== only.player);
    // The other player never said the game began: an older build, or no game.
    if (!other) return close(gameID, { status: 'void', reason: 'unconfirmed', minutes });
    return decide(gameID, only, other, { starts, reports });
  }

  /** Rate a result that stands, or say why it does not. */
  async function decide(gameID, said, opponent, { starts, reports }) {
    const { minutes, moves, reason, outcome } = said;
    const board = new Chess();
    for (const move of moves) {
      try {
        board.move({ from: move.slice(0, 2), to: move.slice(2, 4), promotion: move[4] });
      } catch {
        return close(gameID, { status: 'void', reason: 'illegal', minutes });
      }
    }
    if (!follows(board, reason, said.color, outcome)) return close(gameID, { status: 'void', reason: 'result', minutes });

    const white = said.color === 'white' ? said.player : opponent;
    const black = white === said.player ? opponent : said.player;
    const whiteScore = OUTCOMES[said.color === 'white' ? outcome : opposite[outcome]];
    const everyone = [...starts.values(), ...reports.values()];
    const unrated = !everyone.every((p) => p.openPool) ? 'invitation'
      : everyone.some((p) => p.gameNumber !== 1) ? 'rematch'
      : moves.length < 2 ? 'aborted'
      : null;
    const base = { minutes, white, black, whiteScore, moves: moves.length, reason };
    if (unrated) return close(gameID, { ...base, status: 'unrated', reason: unrated });

    // The ratings, and the record of who has played whom today, in one write.
    for (let attempt = 0; attempt < 8; attempt++) {
      const held = await store.get(RATINGS);
      const state = held?.body ?? { clocks: {}, pairs: {}, applied: {} };
      const at = now();
      if (state.applied[gameID]) return close(gameID, state.applied[gameID]);
      // One rated game a day against the same opponent, whatever the clock.
      const pair = pairKey(white, black);
      if (state.pairs[pair] && at - state.pairs[pair] < DAY) {
        return close(gameID, { ...base, status: 'unrated', reason: 'sameOpponentToday' });
      }
      const clock = (state.clocks[minutes] ??= {});
      const current = (p) => {
        const record = clock[p];
        if (!record) return { rating: STARTING, deviation: NEW_DEVIATION, games: 0 };
        return { rating: record.rating, deviation: grown(record.deviation, at - record.last), games: record.games };
      };
      const [w, b] = [current(white), current(black)];
      const w2 = updated(w, b, whiteScore);
      const b2 = updated(b, w, 1 - whiteScore);
      const verdict = {
        ...base, status: 'rated', at,
        ratings: {
          [white]: { before: w.rating, after: w2.rating, deviation: w2.deviation, games: w.games + 1 },
          [black]: { before: b.rating, after: b2.rating, deviation: b2.deviation, games: b.games + 1 },
        },
      };
      clock[white] = { rating: w2.rating, deviation: w2.deviation, games: w.games + 1, last: at };
      clock[black] = { rating: b2.rating, deviation: b2.deviation, games: b.games + 1, last: at };
      state.pairs = Object.fromEntries(Object.entries(state.pairs).filter(([, t]) => at - t < DAY));
      state.pairs[pair] = at;
      state.applied = Object.fromEntries(Object.entries(state.applied).filter(([, v]) => at - v.at < 7 * DAY));
      state.applied[gameID] = verdict;
      const written = await store.put(RATINGS, state, held ? { ifMatch: held.etag } : { ifNoneMatch: true });
      if (!written) continue; // somebody else wrote it first: read it again
      await publish(minutes, clock);
      log(`rated ${gameID}: ${white} ${w.rating}→${w2.rating}, ${black} ${b.rating}→${b2.rating}`);
      return close(gameID, verdict);
    }
    throw new Error(`the ratings kept changing under ${gameID}`);
  }

  /** The verdict, written once; whoever writes it first is the one kept. */
  async function close(gameID, verdict) {
    const written = await store.put(`${gameKey(gameID)}/verdict.json`, verdict, { ifNoneMatch: true });
    const kept = written ? verdict : await verdictOf(gameID);
    await store.remove(pendingKey(gameID));
    return kept;
  }

  /** The clock's list, as the app shows it: everybody rated on it, best first. */
  async function publish(minutes, clock) {
    const players = Object.entries(clock)
      .map(([id, p]) => ({ id, rating: p.rating, deviation: Math.round(p.deviation), games: p.games, last: new Date(p.last).toISOString().slice(0, 10) }))
      .sort((a, b) => b.rating - a.rating || a.deviation - b.deviation);
    await store.publish(`${PUBLIC}/${minutes}.json`, { minutes, updated: new Date(now()).toISOString(), players });
  }

  /**
   * A player's online ratings, gone: off every clock and every list, and out of
   * the record of whom they played today. Their games' papers expire with
   * everybody else's, after thirty days.
   */
  async function forget(player) {
    for (let attempt = 0; attempt < 8; attempt++) {
      const held = await store.get(RATINGS);
      if (!held) return { status: 'forgotten' };
      const state = held.body;
      const changed = Object.entries(state.clocks).filter(([, clock]) => clock[player]).map(([minutes]) => Number(minutes));
      for (const minutes of changed) delete state.clocks[minutes][player];
      state.pairs = Object.fromEntries(Object.entries(state.pairs).filter(([pair]) => !pair.split('|').includes(player)));
      if (!(await store.put(RATINGS, state, { ifMatch: held.etag }))) continue;
      for (const minutes of changed) await publish(minutes, state.clocks[minutes]);
      log(`forgot ${player} on ${changed.join(', ') || 'no clock'}`);
      return { status: 'forgotten' };
    }
    throw new Error('the ratings kept changing');
  }

  /** Games whose time to be reported is up, settled on what was said. */
  async function sweep() {
    const settled = [];
    for (const { key } of await store.list(`${STATE}/pending/`)) {
      const pending = (await store.get(key))?.body;
      if (!pending) continue;
      const { reports } = await papers(pending.gameID);
      const lastReport = Math.max(0, ...[...reports.values()].map((r) => r.at));
      const due = reports.size ? lastReport + CONFIRM_MS : pending.since + unreported(pending.minutes);
      if (now() < due) continue;
      settled.push({ gameID: pending.gameID, ...(await settle(pending.gameID, { final: true })) });
    }
    return settled;
  }

  return { begin, end, settle, sweep, forget };
}

/** Where the board can say, the result has to be what it says. */
function follows(board, reason, color, outcome) {
  const loserToMove = () => (board.turn() === 'w' ? 'white' : 'black');
  switch (reason) {
    case 'checkmate': {
      if (!board.isCheckmate()) return false;
      const winner = opposite[loserToMove()];
      return outcome === (winner === color ? 'win' : 'loss');
    }
    case 'stalemate': return outcome === 'draw' && board.isStalemate();
    case 'insufficientMaterial': return outcome === 'draw' && board.isInsufficientMaterial();
    case 'repetition': return outcome === 'draw' && board.isThreefoldRepetition();
    case 'fiftyMoveRule': return outcome === 'draw' && Number(board.fen().split(' ')[4]) >= 100;
    case 'agreement': return outcome === 'draw' && !board.isGameOver();
    // Resigning, running out of time and leaving are what the players say;
    // the board can only say the game was not already over.
    default: return outcome !== 'draw' && !board.isGameOver();
  }
}

function sameResult(a, b) {
  return a.outcome === b.outcome && a.reason === b.reason && a.moves.join() === b.moves.join() && a.color === b.color;
}

/** What one player is told: their rating now, and what the game did to it. */
function answer(player, verdict, minutes) {
  if (!verdict) return { status: 'pending', minutes };
  const mine = verdict.ratings?.[player];
  return {
    status: verdict.status,
    reason: verdict.status === 'rated' ? undefined : verdict.reason,
    minutes: verdict.minutes ?? minutes,
    ...(mine ? { rating: mine.after, delta: mine.after - mine.before, deviation: mine.deviation, games: mine.games } : {}),
  };
}

export { FLOOR };
