// The analysis behind the daily feed: which broadcasts to read, which games
// are worth a story, and where each game turned. Shared by the collector that
// runs in Lambda and by the same collector run by hand for a backfill.
import { Chess } from 'chess.js';

import { winProbability, cpFor } from '../engine-node.mjs';
import { topBroadcasts, tour } from './lichess.mjs';

/** Tours worth reading: the top tier, and for a split event only its top boards. */
export async function candidateTours({ tour: only = null, pages = 1, minTier = 4 } = {}) {
  if (only) return [await tour(only)];
  const featured = (await topBroadcasts({ pages })).filter((b) => (b.tour?.tier ?? 0) >= minTier);
  const seen = new Set();
  const tours = [];
  for (const broadcast of featured) {
    const primary = await tour(broadcast.tour.id);
    // An Olympiad is ten tours — the top twelve matches of the Open, the next
    // twenty-five, and so on, and the same for the Women's section. The
    // players this feed is about are on the first tour of each section.
    const siblings = (primary.group?.tours ?? [{ id: primary.tour.id, name: primary.tour.name }])
      .filter((t) => !/Matches (?!1-)\d/.test(t.name));
    for (const sibling of siblings) {
      if (seen.has(sibling.id)) continue;
      seen.add(sibling.id);
      tours.push(sibling.id === primary.tour.id ? primary : await tour(sibling.id));
    }
  }
  return tours;
}

export function loadPlayers(file) {
  const byId = new Map();
  const byName = new Map();
  for (const p of file.players) {
    byId.set(p.fideId, { ...p, star: true });
    byName.set(p.name, { ...p, star: true });
  }
  for (const p of file.names ?? []) if (!byName.has(p.name)) byName.set(p.name, { ...p, star: false });
  return (name, fideId) => byId.get(Number(fideId)) ?? byName.get(name) ?? null;
}

/**
 * How much a game is worth a place. A followed player is worth more than a
 * hundred rating points; a decisive game more than a draw; a draw between two
 * followed players still makes it.
 */
export function score(game, lookup) {
  const t = game.tags;
  const white = lookup(t.White, t.WhiteFideId);
  const black = lookup(t.Black, t.BlackFideId);
  const stars = (white?.star ? 1 : 0) + (black?.star ? 1 : 0);
  const elo = Math.max(Number(t.WhiteElo) || 0, Number(t.BlackElo) || 0);
  const decisive = t.Result === '1-0' || t.Result === '0-1';
  const short = game.sans.length < 30;
  // An upset is a story on its own: the lower-rated player winning is worth up
  // to three hundred points more, by the size of the gap.
  const winnerElo = Number(t.Result === '1-0' ? t.WhiteElo : t.BlackElo) || 0;
  const loserElo = Number(t.Result === '1-0' ? t.BlackElo : t.WhiteElo) || 0;
  const upset = decisive && winnerElo && loserElo > winnerElo ? Math.min(300, loserElo - winnerElo) : 0;
  return (
    stars * 400 +
    (decisive ? 250 : stars === 2 ? 0 : -400) +
    upset +
    (elo - 2500) +
    (short ? -300 : 0)
  );
}

/**
 * Every position of the game, scored by the engine from White's side, and the
 * move that cost its mover the most.
 *
 * The drop is measured in win probability rather than centipawns, so a pawn
 * thrown away in a level position counts for more than a pawn thrown away when
 * already three pieces down — which is how a person reads a game too.
 */
export async function turningPoint(engine, sans, result, depth) {
  const chess = new Chess();
  const fens = [chess.fen()];
  for (const san of sans) {
    chess.move(san);
    fens.push(chess.fen());
  }
  const ending = chess.isCheckmate()
    ? 'checkmate'
    : chess.isStalemate()
      ? 'stalemate'
      : chess.isThreefoldRepetition()
        ? 'repetition'
        : chess.isInsufficientMaterial()
          ? 'material'
          : null;

  await engine.newGame();
  const evals = [];
  for (const fen of fens) {
    const { lines, terminal } = await engine.analyse(fen, { depth, movetime: 700 });
    if (terminal) {
      // Only the last position can have no moves in it. Mated is lost for the
      // side to move; stalemated is level.
      const turn = fen.split(' ')[1];
      evals.push(chess.isCheckmate() ? { cp: null, mate: turn === 'w' ? -1 : 1 } : { cp: 0, mate: null });
    } else {
      evals.push(lines[0].score);
    }
  }
  const wp = (score) => winProbability(cpFor(score, 'w'));

  const loser = result === '1-0' ? 'b' : result === '0-1' ? 'w' : null;
  const winner = loser === 'w' ? 'b' : loser === 'b' ? 'w' : null;
  const forSide = (score, side) => (side === 'w' ? wp(score) : 1 - wp(score));

  // Looked at again, harder, because these numbers go into a sentence — and a
  // shallow search's jump that a deep one does not confirm was never a jump.
  const deepCache = new Map();
  const deep = async (fen) => {
    if (!deepCache.has(fen)) deepCache.set(fen, await engine.analyse(fen, { depth: 20, movetime: 4000 }));
    return deepCache.get(fen);
  };
  const examine = async (ply) => {
    const mover = ply % 2 === 1 ? 'w' : 'b';
    const beforeLine = await deep(fens[ply - 1]);
    const afterLine = await deep(fens[ply]);
    const before = beforeLine.lines[0]?.score ?? evals[ply - 1];
    const after = afterLine.terminal ? evals[ply] : afterLine.lines[0]?.score ?? evals[ply];
    return { ply, mover, before, after, beforeLine, afterLine, drop: forSide(before, mover) - forSide(after, mover) };
  };

  let best = null;
  let kind = 'mistake';
  if (winner) {
    // Where the game was decided: the move after which the engine rates the
    // winner's position as won and goes on rating it so. Found on the quick
    // scores, then pinned down on deep ones — walking back while the deep
    // search says the win was already there, and forward while it says it was
    // not yet — so that the move named is where a deep search, not a shallow
    // one, sees the game change hands.
    const w = evals.map((e) => forSide(e, winner));
    let crossing = 1;
    for (let i = 1; i < w.length; i++) if (w[i - 1] < 0.7 && w[i] >= 0.7) crossing = i;
    const deepFor = async (i) => {
      const line = await deep(fens[i]);
      return line.terminal ? w[i] : forSide(line.lines[0].score, winner);
    };
    let ply = crossing;
    for (let steps = 0; steps < 14 && ply > 1 && (await deepFor(ply - 1)) >= 0.7; steps++) ply--;
    for (let steps = 0; steps < 14 && ply < fens.length - 1 && (await deepFor(ply)) < 0.7; steps++) ply++;
    best = await examine(ply);
    kind = best.mover === loser ? 'mistake' : 'breakthrough';
  } else {
    // A draw is only a story when somebody had a win and it went. The move
    // that handed it over, while the game was still a game.
    const moves = [];
    for (let ply = 1; ply < fens.length; ply++) {
      const mover = ply % 2 === 1 ? 'w' : 'b';
      const before = forSide(evals[ply - 1], mover);
      moves.push({ ply, drop: before - forSide(evals[ply], mover), alive: before >= 0.3 });
    }
    const shortlist = moves.filter((m) => m.alive).sort((a, b) => b.drop - a.drop).slice(0, 3);
    for (const m of shortlist) {
      const seen = await examine(m.ply);
      if (!best || seen.drop > best.drop) best = seen;
    }
    const winning = (score) => score.mate != null || Math.abs(score.cp) >= 250;
    if (!best || best.drop < 0.2 || !winning(best.after)) return { ending, key: null };
    kind = 'swing';
  }

  const played = sans[best.ply - 1];
  const sanOf = (fen, uci) => {
    if (!uci) return null;
    try {
      return new Chess(fen).move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] })?.san ?? null;
    } catch {
      return null;
    }
  };
  const better = kind === 'mistake' || kind === 'swing' ? sanOf(fens[best.ply - 1], best.beforeLine.best) : null;
  const reply = sanOf(fens[best.ply], best.afterLine.best);
  return {
    ending,
    key: {
      kind,
      ply: best.ply,
      played,
      better: better === played ? null : better,
      reply,
      replyPlayed: reply != null && sans[best.ply] === reply,
      before: best.before,
      after: best.after,
    },
  };
}

export function slugify(text) {
  return text
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
