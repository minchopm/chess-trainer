#!/usr/bin/env node
// Mines *quiet* positions for the positional-judgement mode.
//
// This is the mirror image of the tactics miner. There, a position is worth
// keeping when exactly one move works. Here it is worth keeping when several
// moves are playable and the best one is not a capture or a check — because
// then the exercise tests judgement instead of calculation.
//
//   node scripts/generate-positions.mjs --games 40 --workers 8
import { fork } from 'node:child_process';
import { cpus } from 'node:os';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';
import { createEngine, cpFor } from './engine-node.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..');

const CONFIG = {
  playElo: [1900, 2600], // stronger play keeps the positions sensible
  gameMoveTime: 70,
  maxGameLength: 70,
  sampleEvery: 3, // don't take three near-identical positions in a row
  minPly: 14,
  studyDepth: 18,
  maxAbsEval: 300, // still a game, not a decided one
  minAlternatives: 3,
  // Several moves must be reasonable, or it is a tactic in disguise.
  maxTopGapCp: 90,
  perGame: 3,
};

function parseArgs(argv) {
  const args = { games: 40, workers: Math.max(1, cpus().length - 2), out: 'data/positions.json', seed: 5 };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (key in args) args[key] = key === 'out' ? argv[i + 1] : Number(argv[i + 1]);
  }
  return args;
}

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

async function mineGame(engine, random) {
  const chess = new Chess();
  await engine.newGame();

  const base = CONFIG.playElo[0] + random() * (CONFIG.playElo[1] - CONFIG.playElo[0]);
  const openingPlies = 6 + Math.floor(random() * 8);
  for (let i = 0; i < openingPlies; i += 1) {
    if (chess.isGameOver()) break;
    const { lines } = await engine.analyse(chess.fen(), { depth: 6, multipv: 4 });
    const choices = lines.map((l) => l.move).filter(Boolean);
    if (!choices.length) break;
    const uci = choices[Math.floor(random() * choices.length)];
    chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
  }

  const found = [];
  let ply = chess.history().length;

  while (!chess.isGameOver() && ply < CONFIG.maxGameLength && found.length < CONFIG.perGame) {
    if (ply >= CONFIG.minPly && ply % CONFIG.sampleEvery === 0 && !chess.isCheck()) {
      const exercise = await study(engine, chess.fen());
      if (exercise) found.push(exercise);
    }
    const uci = await engine.pickMove(chess.fen(), { elo: base, movetime: CONFIG.gameMoveTime });
    if (!uci) break;
    try {
      chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
    ply += 1;
  }

  return found;
}

/** Deep-analyse one position and keep it only if it is genuinely a judgement call. */
async function study(engine, fen) {
  const chess = new Chess(fen);
  const mover = chess.turn();
  const { lines } = await engine.analyse(fen, { depth: CONFIG.studyDepth, multipv: 4 });
  if (lines.length < CONFIG.minAlternatives + 1) return null;

  const scored = lines.map((line) => ({
    uci: line.move,
    cp: cpFor(line.score, mover),
    pv: line.pv.slice(0, 8),
  }));

  const best = scored[0];
  if (Math.abs(best.cp) > CONFIG.maxAbsEval) return null;
  if (best.cp - scored[scored.length - 1].cp > CONFIG.maxTopGapCp) return null;

  // The best move must be quiet: no capture, no check, no promotion. Otherwise
  // this is a tactics puzzle wearing a positional hat.
  const probe = new Chess(fen);
  const bestMove = probe.move({
    from: best.uci.slice(0, 2),
    to: best.uci.slice(2, 4),
    promotion: best.uci[4],
  });
  if (!bestMove || bestMove.captured || bestMove.promotion || bestMove.san.includes('+')) return null;

  const pieces = [...fen.split(' ')[0]].filter((ch) => /[a-zA-Z]/.test(ch)).length;
  const whiteCp = mover === 'w' ? best.cp : -best.cp;
  const gapToSecond = best.cp - scored[1].cp;

  return {
    fen,
    cp: whiteCp,
    sideToMove: mover,
    best,
    alternatives: scored.slice(1),
    rating: rate({ gapToSecond, pieces, absEval: Math.abs(whiteCp) }),
    themes: [pieces > 24 ? 'middlegame' : pieces > 12 ? 'lateMiddlegame' : 'endgame', 'judgement'],
  };
}

/**
 * Harder when the candidate moves are close together (nothing stands out) and
 * when the evaluation is near zero (no material clue to anchor the judgement).
 */
function rate({ gapToSecond, pieces, absEval }) {
  let rating = 1350;
  rating += Math.round((60 - Math.min(60, gapToSecond)) * 6);
  if (absEval < 30) rating += 120;
  if (pieces > 26) rating += 90;
  if (pieces < 14) rating -= 80;
  return Math.max(900, Math.min(2600, Math.round(rating / 10) * 10));
}

async function runWorker() {
  const engine = await createEngine();
  process.send?.({ type: 'ready' });
  process.on('message', async (message) => {
    if (message.type !== 'game') return;
    try {
      const exercises = await mineGame(engine, makeRandom(message.seed));
      process.send({ type: 'result', exercises });
    } catch (error) {
      process.send({ type: 'result', exercises: [], error: String(error) });
    }
  });
}

async function runMain(args) {
  const started = Date.now();
  const outPath = resolve(ROOT, args.out);
  const existing = await readExisting(outPath);
  const byFen = new Map(existing.map((e) => [e.fen, e]));

  console.log(`Mining quiet positions from ${args.games} games across ${args.workers} workers…`);

  await mkdir(dirname(outPath), { recursive: true });

  // Write after every game so a crashed worker can never cost the whole run.
  const flush = async () => {
    const exercises = [...byFen.values()].sort((a, b) => a.rating - b.rating);
    await writeFile(outPath, `${JSON.stringify({ generated: new Date().toISOString(), exercises }, null, 1)}\n`);
    return exercises;
  };

  let dispatched = 0;
  let finished = 0;

  await new Promise((done) => {
    const workers = Array.from({ length: args.workers }, () =>
      fork(fileURLToPath(import.meta.url), ['--worker'], { stdio: ['ignore', 'ignore', 'inherit', 'ipc'] }),
    );
    let alive = workers.length;

    const dispatch = (worker) => {
      if (dispatched >= args.games) {
        worker.kill();
        return;
      }
      worker.send({ type: 'game', seed: args.seed * 104729 + dispatched });
      dispatched += 1;
    };

    for (const worker of workers) {
      worker.on('message', (message) => {
        if (message.type === 'ready') return dispatch(worker);
        finished += 1;
        let added = 0;
        for (const exercise of message.exercises) {
          if (byFen.has(exercise.fen)) continue;
          byFen.set(exercise.fen, { id: makeId(exercise.fen), ...exercise });
          added += 1;
        }
        console.log(
          `[${finished}/${args.games}] +${added} (total ${byFen.size}) · ${((Date.now() - started) / 1000).toFixed(0)}s`,
        );
        if (message.error) console.warn(`   worker error: ${message.error}`);
        flush().catch((error) => console.warn(`   could not write ${args.out}: ${error.message}`));
        dispatch(worker);
      });

      // Resolve on an empty pool, not on a target count a dead worker can make
      // unreachable.
      worker.on('exit', () => {
        alive -= 1;
        if (alive === 0) done();
      });
    }
  });

  const exercises = await flush();
  console.log(`\nWrote ${exercises.length} positional exercises to ${args.out}`);
}

function makeId(fen) {
  let hash = 2166136261;
  for (const ch of fen) {
    hash ^= ch.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return `q${(hash >>> 0).toString(36)}`;
}

async function readExisting(path) {
  try {
    return JSON.parse(await readFile(path, 'utf8')).exercises ?? [];
  } catch {
    return [];
  }
}

if (process.argv.includes('--worker')) {
  runWorker();
} else {
  runMain(parseArgs(process.argv.slice(2))).catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
