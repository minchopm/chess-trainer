#!/usr/bin/env node
// Puzzle generator.
//
// Rather than transcribing positions from memory (which risks shipping puzzles
// with wrong or non-unique solutions), puzzles are *mined*: Stockfish plays
// itself at deliberately human-like strength, every position is scanned for an
// evaluation swing, and each candidate is then re-checked at high depth. A
// candidate survives only if the best move is decisively better than the second
// best — that is what makes a puzzle have one answer.
//
//   node scripts/generate-puzzles.mjs --games 40 --workers 4 --out data/tactics.json
import { fork } from 'node:child_process';
import { cpus } from 'node:os';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';
import { createEngine, cpFor, winProbability } from './engine-node.mjs';
import { detectThemes, estimateRating } from './themes.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..');

const CONFIG = {
  // Scanning is cheap and only needs to spot a swing; verification is expensive
  // and decides whether the puzzle is sound. Scanning uses a fixed depth rather
  // than a time budget: a time budget gives different depths on different
  // machines and in different phases, and the resulting noise shows up as
  // phantom "swings" that waste verification time.
  scanDepth: 12,
  verifyDepth: 20,
  // A ceiling on verification: a few positions never reach depth 20 in bounded
  // time, and one of them stalling a worker costs more than the puzzle is worth.
  verifyTimeCap: 6000,
  followDepth: 18,
  // Shallow screen: a position is worth deep verification when one move already
  // looks clearly best and clearly good. Both thresholds sit below the final
  // ones so that shallow-search noise costs recall, not precision.
  screenAdvantageCp: 130,
  screenGapCp: 110,
  // The solution must beat the runner-up by this many centipawns. Centipawns
  // rather than win probability, because win probability saturates: "win a
  // piece" versus "stay equal" is a decisive gap but only ~0.2 in probability.
  uniquenessCp: 140,
  // …and it has to actually achieve something.
  minAdvantageCp: 150,
  // Every later solver move must stay this forced, or the line has branches.
  followUniquenessCp: 100,
  maxSolutionPlies: 9,
  // Weak enough to blunder often, strong enough that the blunders are the kind a
  // human would actually face rather than random nonsense.
  playElo: [1320, 2500],
  gameMoveTime: 60,
  maxGameLength: 80,
  // Stop a game once it is decided beyond interest.
  resignThreshold: 650,
};

function parseArgs(argv) {
  const args = { games: 24, workers: Math.max(1, cpus().length - 2), out: 'data/tactics.json', seed: 1 };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    const value = argv[i + 1];
    if (key in args) args[key] = key === 'out' ? value : Number(value);
  }
  return args;
}

/** Deterministic PRNG so a given seed reproduces the same puzzle set. */
function makeRandom(seed) {
  let state = seed >>> 0 || 1;
  return () => {
    state ^= state << 13;
    state ^= state >>> 17;
    state ^= state << 5;
    state >>>= 0;
    return state / 0x100000000;
  };
}

// --- one game -> candidate positions ----------------------------------------

async function playGame(engine, random) {
  const chess = new Chess();
  await engine.newGame();

  // Both sides play at a similar level, but the level itself varies widely
  // between games. Weak games yield blunt one-movers; strong games yield the
  // subtle, deep tactics that make up the top of the ladder.
  const base = CONFIG.playElo[0] + random() * (CONFIG.playElo[1] - CONFIG.playElo[0]);
  const whiteElo = base + (random() - 0.5) * 200;
  const blackElo = base + (random() - 0.5) * 200;

  // Vary the opening, but stay inside sane chess: pick randomly among the
  // engine's top few shallow choices. Purely random legal moves produce
  // positions no human will ever meet, and occasionally end the game outright.
  const openingPlies = 6 + Math.floor(random() * 8);
  for (let i = 0; i < openingPlies; i += 1) {
    if (chess.isGameOver()) break;
    const { lines } = await engine.analyse(chess.fen(), { depth: 6, multipv: 4 });
    const choices = lines.map((line) => line.move).filter(Boolean);
    const uci = choices.length ? choices[Math.floor(random() * choices.length)] : null;
    if (!uci) break;
    try {
      chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
  }

  // Evaluate as we go with two candidate lines. The play-time eval doubles as
  // the puzzle scan, which removes an entire second pass over the game.
  //
  // The signal we want is not "somebody blundered" but the stricter property a
  // puzzle actually needs: *one* move is far better than every alternative.
  // Screening on that directly, at shallow depth, is both cheaper and a better
  // predictor of what survives deep verification.
  const positions = [];
  const evaluate = async () => {
    if (chess.isGameOver()) return null;
    const { lines } = await engine.analyse(chess.fen(), { depth: CONFIG.scanDepth, multipv: 2 });
    if (!lines.length) return null;
    const turn = chess.turn();
    const best = cpFor(lines[0].score, turn);
    const second = lines[1] ? cpFor(lines[1].score, turn) : -10_000;
    return { score: lines[0].score, bestCp: best, gapCp: best - second, bestMove: lines[0].move };
  };

  positions.push({ fen: chess.fen(), lastMove: null, eval: await evaluate() });

  while (!chess.isGameOver() && chess.history().length < CONFIG.maxGameLength) {
    const elo = chess.turn() === 'w' ? whiteElo : blackElo;
    const uci = await engine.pickMove(chess.fen(), { elo, movetime: CONFIG.gameMoveTime });
    if (!uci) break;
    let move;
    try {
      move = chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
    const info = await evaluate();
    positions.push({ fen: chess.fen(), lastMove: move, eval: info });
    if (!info) break;

    // Adjudicate decided games. Once someone is up a rook, every later mistake
    // produces a "you were winning, now win more" puzzle — not worth the time.
    if (Math.abs(cpFor(info.score, 'w')) > CONFIG.resignThreshold) break;
  }

  return positions;
}

/** Positions where a single move stands out, minus the ones that are trivial. */
function findCandidates(positions) {
  const candidates = [];

  for (let i = 1; i < positions.length; i += 1) {
    const current = positions[i];
    const previous = positions[i - 1];
    if (!current.eval) continue;

    const { bestCp, gapCp, bestMove } = current.eval;
    if (bestCp < CONFIG.screenAdvantageCp) continue;
    if (gapCp < CONFIG.screenGapCp) continue;
    if (bestCp > CONFIG.resignThreshold * 2.5) continue; // already completely won

    // Was the solver already winning before the opponent moved? Then this is
    // technique, not a tactic.
    const solverColor = current.fen.split(' ')[1];
    if (previous.eval && cpFor(previous.eval.score, solverColor) > 400) continue;

    // Plain recaptures also show a big gap — and teach nothing.
    if (current.lastMove?.captured && bestMove?.slice(2, 4) === current.lastMove.to) continue;

    candidates.push({ fen: current.fen, ply: i });
  }

  return candidates;
}

// --- verification -----------------------------------------------------------

/**
 * Confirm a candidate has exactly one good move, then extend it into a full
 * forced line. Returns null when the position fails any soundness check.
 */
async function verifyCandidate(engine, fen) {
  const first = await engine.analyse(fen, {
    depth: CONFIG.verifyDepth,
    movetime: CONFIG.verifyTimeCap,
    multipv: 2,
  });
  if (first.lines.length < 2) return { reason: 'onlyOneLegalMove' };

  const solverColor = fen.split(' ')[1];
  const bestCp = cpFor(first.lines[0].score, solverColor);
  const secondCp = cpFor(first.lines[1].score, solverColor);
  const gapCp = bestCp - secondCp;

  if (gapCp < CONFIG.uniquenessCp) return { reason: 'notUnique' }; // more than one move works
  if (bestCp < CONFIG.minAdvantageCp) return { reason: 'noAdvantage' }; // achieves nothing

  const solution = [];
  const chess = new Chess(fen);

  for (let ply = 0; ply < CONFIG.maxSolutionPlies; ply += 1) {
    if (chess.isGameOver()) break;
    const ours = ply % 2 === 0;
    const analysis = await engine.analyse(chess.fen(), {
      depth: ours ? CONFIG.followDepth : CONFIG.followDepth - 4,
      movetime: CONFIG.verifyTimeCap,
      multipv: ours ? 2 : 1,
    });
    if (!analysis.lines.length) break;

    if (ours && ply > 0) {
      // Every one of our moves must stay forced, or the puzzle has branches.
      const a = cpFor(analysis.lines[0].score, solverColor);
      const b = analysis.lines[1] ? cpFor(analysis.lines[1].score, solverColor) : -10_000;
      if (a - b < CONFIG.followUniquenessCp) break;
    }

    const uci = analysis.lines[0].move;
    try {
      chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
    solution.push(uci);

    if (chess.isCheckmate()) break;
    // Stop once the win is obvious and the forcing sequence is over.
    if (!ours && solution.length >= 3) {
      const evalNow = cpFor(analysis.lines[0].score, solverColor);
      if (evalNow > 900) break;
    }
  }

  // Trim a trailing opponent move — a puzzle should end on the solver's move.
  if (solution.length % 2 === 0) solution.pop();
  if (!solution.length) return { reason: 'emptyLine' };

  const themes = detectThemes(fen, solution);
  const gapWinProb = winProbability(bestCp) - winProbability(secondCp);
  const rating = estimateRating(fen, solution, themes, { gapWinProb });
  const final = new Chess(fen);
  for (const uci of solution) {
    final.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
  }

  return {
    puzzle: {
      fen,
      solution,
      themes,
      rating,
      sideToMove: solverColor,
      finalEval: cpFor(first.lines[0].score, solverColor),
      mate: final.isCheckmate(),
    },
  };
}

// --- worker mode ------------------------------------------------------------

async function runWorker() {
  const engine = await createEngine();
  process.send?.({ type: 'ready' });

  process.on('message', async (message) => {
    if (message.type !== 'game') return;
    const random = makeRandom(message.seed);
    const stats = { plies: 0, candidates: 0, rejected: {} };
    try {
      const positions = await playGame(engine, random);
      stats.plies = positions.length - 1;
      const candidates = findCandidates(positions);
      stats.candidates = candidates.length;
      const puzzles = [];
      for (const candidate of candidates) {
        const { puzzle, reason } = await verifyCandidate(engine, candidate.fen);
        if (puzzle) puzzles.push(puzzle);
        else stats.rejected[reason] = (stats.rejected[reason] ?? 0) + 1;
      }
      process.send({ type: 'result', seed: message.seed, puzzles, stats });
    } catch (error) {
      process.send({ type: 'result', seed: message.seed, puzzles: [], stats, error: String(error) });
    }
  });
}

// --- coordinator ------------------------------------------------------------

async function runMain(args) {
  const started = Date.now();
  const existing = await readExisting(resolve(ROOT, args.out));
  const bySignature = new Map(existing.map((p) => [signature(p), p]));

  console.log(`Mining ${args.games} games across ${args.workers} workers…`);
  console.log(`Starting from ${existing.length} existing puzzles.\n`);

  const outPath = resolve(ROOT, args.out);
  await mkdir(dirname(outPath), { recursive: true });

  // Write after every game. A generation run takes half an hour; losing it to a
  // crashed worker at game 218 is not an acceptable failure mode.
  const flush = async () => {
    const puzzles = [...bySignature.values()].sort((a, b) => a.rating - b.rating);
    await writeFile(outPath, `${JSON.stringify({ generated: new Date().toISOString(), puzzles }, null, 1)}\n`);
    return puzzles;
  };

  let dispatched = 0;
  let finished = 0;

  await new Promise((resolveAll) => {
    const workers = Array.from({ length: args.workers }, () =>
      fork(fileURLToPath(import.meta.url), ['--worker'], { stdio: ['ignore', 'ignore', 'inherit', 'ipc'] }),
    );
    let alive = workers.length;

    const dispatch = (worker) => {
      if (dispatched >= args.games) {
        worker.kill();
        return;
      }
      worker.send({ type: 'game', seed: args.seed * 7919 + dispatched });
      dispatched += 1;
    };

    for (const worker of workers) {
      worker.on('message', (message) => {
        if (message.type === 'ready') {
          dispatch(worker);
          return;
        }
        finished += 1;
        let added = 0;
        for (const puzzle of message.puzzles) {
          const key = signature(puzzle);
          if (bySignature.has(key)) continue;
          bySignature.set(key, { id: makeId(puzzle), ...puzzle });
          added += 1;
        }
        const elapsed = ((Date.now() - started) / 1000).toFixed(0);
        const s = message.stats ?? {};
        const rejected = Object.entries(s.rejected ?? {})
          .map(([reason, count]) => `${reason}:${count}`)
          .join(' ');
        console.log(
          `[${finished}/${args.games}] ${s.plies ?? 0} plies · ${s.candidates ?? 0} candidates · ` +
            `+${added} puzzles (total ${bySignature.size}) · ${elapsed}s` +
            (rejected ? `\n   rejected: ${rejected}` : ''),
        );
        if (message.error) console.warn(`   worker error: ${message.error}`);
        flush().catch((error) => console.warn(`   could not write ${args.out}: ${error.message}`));
        dispatch(worker);
      });

      // Resolve when the pool is empty rather than when the counter reaches the
      // target: a worker whose engine dies never reports back, and waiting for a
      // count that can no longer be reached loses the entire run.
      worker.on('exit', () => {
        alive -= 1;
        if (alive === 0) resolveAll();
      });
    }
  });

  if (finished < args.games) {
    console.warn(`\nOnly ${finished}/${args.games} games completed — some workers exited early.`);
  }

  const puzzles = await flush();
  console.log(`\nWrote ${puzzles.length} puzzles to ${args.out}`);
  console.log(summarise(puzzles));
}

function signature(puzzle) {
  return `${puzzle.fen}|${puzzle.solution[0]}`;
}

function makeId(puzzle) {
  // Stable short id derived from the position, so re-runs keep SRS history valid.
  let hash = 2166136261;
  for (const ch of signature(puzzle)) {
    hash ^= ch.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return `p${(hash >>> 0).toString(36)}`;
}

async function readExisting(path) {
  try {
    return JSON.parse(await readFile(path, 'utf8')).puzzles ?? [];
  } catch {
    return [];
  }
}

function summarise(puzzles) {
  const buckets = new Map();
  for (const puzzle of puzzles) {
    const bucket = Math.floor(puzzle.rating / 200) * 200;
    buckets.set(bucket, (buckets.get(bucket) ?? 0) + 1);
  }
  const themeCounts = new Map();
  for (const puzzle of puzzles) {
    for (const theme of puzzle.themes) themeCounts.set(theme, (themeCounts.get(theme) ?? 0) + 1);
  }
  const lines = ['\nRating spread:'];
  for (const [bucket, count] of [...buckets].sort((a, b) => a[0] - b[0])) {
    lines.push(`  ${bucket}-${bucket + 199}: ${'█'.repeat(Math.ceil(count / 2))} ${count}`);
  }
  lines.push('Top themes:');
  for (const [theme, count] of [...themeCounts].sort((a, b) => b[1] - a[1]).slice(0, 12)) {
    lines.push(`  ${theme.padEnd(18)} ${count}`);
  }
  return lines.join('\n');
}

if (process.argv.includes('--worker')) {
  runWorker();
} else {
  runMain(parseArgs(process.argv.slice(2))).catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
