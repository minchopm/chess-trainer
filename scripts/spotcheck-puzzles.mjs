#!/usr/bin/env node
// Spot-check a large puzzle set.
//
// `verify-puzzles.mjs` checks every puzzle, which is right for a few hundred
// mined ones but takes over a day for an imported Lichess set of 14,000. This
// takes an evenly spaced sample across the rating range instead and asks the
// only question that matters for an import: does the engine agree that the
// recorded first move is the best one?
//
// A systematic import bug — most obviously getting Lichess' one-ply offset
// wrong — shows up as near-total disagreement, which a sample of forty catches
// just as reliably as a full pass.
//
//   node scripts/spotcheck-puzzles.mjs [--file data/tactics.json] [--sample 40]
//                                      [--depth 18] [--source lichess]
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';
import { createEngine, cpFor } from './engine-node.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const argv = process.argv.slice(2);
const opt = (name, fallback) => {
  const index = argv.indexOf(`--${name}`);
  return index === -1 ? fallback : argv[index + 1];
};

const FILE = opt('file', 'data/tactics.json');
const SAMPLE = Number(opt('sample', 40));
const DEPTH = Number(opt('depth', 18));
const TIME_CAP = Number(opt('time-cap', 4000));
const SOURCE = opt('source', null);

/** The side not to move being in check is an illegal position no game can reach. */
function opponentInCheck(fen) {
  const parts = fen.split(' ');
  parts[1] = parts[1] === 'w' ? 'b' : 'w';
  parts[3] = '-';
  try {
    return new Chess(parts.join(' ')).isCheck();
  } catch {
    return true;
  }
}

const all = JSON.parse(readFileSync(resolve(ROOT, FILE), 'utf8')).puzzles ?? [];
const pool = SOURCE ? all.filter((p) => p.source === SOURCE) : all;

if (!pool.length) {
  console.error(`No puzzles in ${FILE}${SOURCE ? ` with source "${SOURCE}"` : ''}.`);
  process.exit(1);
}

// Evenly spaced through the rating-sorted set, so the sample spans the range
// rather than clustering wherever the puzzles happen to be dense.
const sorted = [...pool].sort((a, b) => a.rating - b.rating);
const step = Math.max(1, Math.floor(sorted.length / SAMPLE));
const sample = [];
for (let i = 0; i < sorted.length && sample.length < SAMPLE; i += step) sample.push(sorted[i]);

console.log(`Spot-checking ${sample.length} of ${pool.length} puzzles at depth ${DEPTH}…\n`);

const engine = await createEngine({ hash: 64 });
let agree = 0;
const problems = [];

for (const puzzle of sample) {
  if (opponentInCheck(puzzle.fen)) {
    problems.push({ id: puzzle.id, why: 'illegal: side not to move is in check' });
    console.log(`  ✗ ${puzzle.id} illegal position`);
    continue;
  }

  const side = puzzle.fen.split(' ')[1];
  let lines = [];
  try {
    ({ lines } = await engine.analyse(puzzle.fen, { depth: DEPTH, movetime: TIME_CAP, multipv: 2 }));
  } catch (error) {
    problems.push({ id: puzzle.id, why: `engine failed: ${error.message}` });
    continue;
  }
  if (!lines.length) {
    problems.push({ id: puzzle.id, why: 'engine returned no evaluation' });
    continue;
  }

  const best = cpFor(lines[0].score, side);
  const second = lines[1] ? cpFor(lines[1].score, side) : -10_000;
  const match = lines[0].move === puzzle.solution[0];
  if (match) agree += 1;
  else problems.push({ id: puzzle.id, why: `engine prefers ${lines[0].move} over ${puzzle.solution[0]}` });

  console.log(
    `  ${match ? '✓' : '✗'} r${String(puzzle.rating).padStart(4)}  ` +
      `recorded ${puzzle.solution[0]}  engine ${lines[0].move}  ` +
      `eval ${(best / 100).toFixed(2)}  gap ${((best - second) / 100).toFixed(2)}`,
  );
}

const rate = ((agree / sample.length) * 100).toFixed(0);
console.log(`\nEngine agrees on ${agree}/${sample.length} first moves (${rate}%).`);
console.log(
  'A few disagreements are normal and concentrate on long, quiet, highly rated\n' +
  'puzzles: the point of those lies deeper than this check searches. Raise\n' +
  '--depth before suspecting the data. Widespread disagreement is the real signal.',
);

// Puzzle sets are allowed the odd disagreement — a deeper search sometimes finds
// an equally good alternative. A systematic import bug looks nothing like that.
if (agree / sample.length < 0.85) {
  console.error('\nThat is too low. Something is wrong with the set, not with individual puzzles.');
  for (const problem of problems) console.error(`  ${problem.id}: ${problem.why}`);
  process.exit(1);
}
process.exit(0);
