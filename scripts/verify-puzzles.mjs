#!/usr/bin/env node
// Independent verification pass.
//
// Generated puzzles were checked at depth 20 during mining; this re-checks them
// at a higher depth with a fresh engine, and separately confirms that every
// hand-written endgame drill really has the result its label claims. Anything
// that fails is reported and, with --fix, removed from the data files.
//
//   node scripts/verify-puzzles.mjs [--depth 24] [--endgame-movetime 4000] [--fix]
import { readFile, writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';
import { createEngine, cpFor } from './engine-node.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const args = process.argv.slice(2);
const flag = (name, fallback) => {
  const index = args.indexOf(`--${name}`);
  return index === -1 ? fallback : Number(args[index + 1]);
};

// Two plies deeper than the generator searched, which is enough to catch a
// solution that flips under a harder look. Going deeper still is exponentially
// slower for very little extra signal.
const DEPTH = flag('depth', 22);
// Ceiling per position. A handful of positions never reach depth 22 in any
// reasonable time; without a cap they turn a 20-minute check into hours.
const TIME_CAP = flag('time-cap', 6000);
// Endgames get a time budget rather than a depth. A fixed depth is unusable
// here: depth 28 in a rook-versus-king position is instant, while depth 28 with
// two bishops explores for minutes and times the engine out.
const ENDGAME_MOVETIME = flag('endgame-movetime', 4000);
const FIX = args.includes('--fix');

async function verifyTactics(engine) {
  const path = resolve(ROOT, 'data/tactics.json');
  let file;
  try {
    file = JSON.parse(await readFile(path, 'utf8'));
  } catch {
    console.log('No data/tactics.json yet — run `npm run generate` first.\n');
    return { failures: [] };
  }

  const puzzles = file.puzzles ?? [];
  const failures = [];
  const startedAt = Date.now();
  console.log(`Verifying ${puzzles.length} tactics puzzles at depth ${DEPTH}…`);

  for (const [index, puzzle] of puzzles.entries()) {
    const problems = [];

    if (opponentInCheck(puzzle.fen)) problems.push('illegal: the side not to move is in check');

    // The recorded line must be legal from the recorded position.
    const chess = new Chess(puzzle.fen);
    for (const uci of puzzle.solution) {
      try {
        const move = chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
        if (!move) throw new Error('illegal');
      } catch {
        problems.push(`illegal move ${uci} in solution`);
        break;
      }
    }

    if (!problems.length) {
      const solverColor = puzzle.fen.split(' ')[1];
      let lines = [];
      try {
        ({ lines } = await engine.analyse(puzzle.fen, {
          depth: DEPTH,
          movetime: TIME_CAP,
          multipv: 2,
        }));
      } catch (error) {
        problems.push(`engine failed: ${error.message}`);
      }

      if (problems.length) {
        // fall through to the failure report below
      } else if (lines.length < 2) {
        problems.push('only one legal move');
      } else {
        if (lines[0].move !== puzzle.solution[0]) {
          problems.push(`deeper search prefers ${lines[0].move} over ${puzzle.solution[0]}`);
        }
        const gap = cpFor(lines[0].score, solverColor) - cpFor(lines[1].score, solverColor);
        if (gap < 100) problems.push(`solution is not unique (gap ${gap}cp)`);
      }
    }

    if (problems.length) failures.push({ id: puzzle.id, fen: puzzle.fen, problems });
    if ((index + 1) % 10 === 0) {
      const elapsed = ((Date.now() - startedAt) / 1000).toFixed(0);
      console.log(`  ${index + 1}/${puzzles.length} · ${failures.length} unsound so far · ${elapsed}s`);
    }
  }

  console.log(`Tactics: ${puzzles.length - failures.length}/${puzzles.length} sound.`);
  for (const failure of failures) {
    console.log(`  ✗ ${failure.id}: ${failure.problems.join('; ')}`);
    console.log(`    ${failure.fen}`);
  }

  if (FIX && failures.length) {
    const bad = new Set(failures.map((f) => f.id));
    file.puzzles = puzzles.filter((p) => !bad.has(p.id));
    await writeFile(path, `${JSON.stringify(file, null, 1)}\n`);
    console.log(`  removed ${bad.size} unsound puzzles from data/tactics.json`);
  }

  return { failures };
}

async function verifyEndgames(engine) {
  const path = resolve(ROOT, 'data/endgames.json');
  const file = JSON.parse(await readFile(path, 'utf8'));
  const drills = file.drills ?? [];
  const failures = [];

  console.log(`\nVerifying ${drills.length} endgame drills at ${ENDGAME_MOVETIME}ms each…`);

  for (const drill of drills) {
    const problems = [];
    let chess;
    try {
      chess = new Chess(drill.fen);
    } catch (error) {
      console.log(`  ✗ ${drill.id.padEnd(30)} invalid FEN: ${error.message}`);
      failures.push({ id: drill.id, problems: [`invalid FEN: ${error.message}`] });
      continue;
    }

    if (chess.isGameOver()) problems.push('position is already over');

    if (opponentInCheck(drill.fen)) {
      console.log(`  ✗ ${drill.id.padEnd(30)} illegal: the side not to move is in check`);
      failures.push({ id: drill.id, problems: ['illegal: the side not to move is in check'] });
      continue;
    }

    const side = chess.turn();
    let lines = [];
    try {
      ({ lines } = await engine.analyse(drill.fen, { movetime: ENDGAME_MOVETIME, multipv: 1 }));
    } catch (error) {
      console.log(`  ✗ ${drill.id.padEnd(30)} engine failed: ${error.message}`);
      failures.push({ id: drill.id, problems: [`engine failed: ${error.message}`] });
      continue;
    }

    if (!lines.length) {
      console.log(`  ✗ ${drill.id.padEnd(30)} engine returned no evaluation`);
      failures.push({ id: drill.id, problems: ['engine returned no evaluation'] });
      continue;
    }

    const cp = cpFor(lines[0].score, side);
    const mate = lines[0].score?.mate ?? null;

    // "win" must be decisive for the side to move; "draw" must be near zero.
    if (drill.goal === 'win' && cp < 400) {
      problems.push(`labelled win but engine gives ${describe(cp, mate)} for ${side}`);
    }
    if (drill.goal === 'draw' && Math.abs(cp) > 150) {
      problems.push(`labelled draw but engine gives ${describe(cp, mate)} for ${side}`);
    }

    if (problems.length) failures.push({ id: drill.id, fen: drill.fen, problems, cp });
    console.log(
      `  ${problems.length ? '✗' : '✓'} ${drill.id.padEnd(30)} ${drill.goal.padEnd(5)} ${describe(cp, mate)}`,
    );
    for (const problem of problems) console.log(`      ${problem}`);
  }

  if (FIX && failures.length) {
    const bad = new Set(failures.map((f) => f.id));
    file.drills = drills.filter((d) => !bad.has(d.id));
    await writeFile(path, `${JSON.stringify(file, null, 1)}\n`);
    console.log(`  removed ${bad.size} mislabelled drills from data/endgames.json`);
  }

  console.log(`Endgames: ${drills.length - failures.length}/${drills.length} correctly labelled.`);
  return { failures };
}

/**
 * True when the side *not* to move is in check — an illegal position that no
 * game can reach. chess.js happily accepts these, and Stockfish responds to them
 * with "bestmove (none)", which is easy to misread as an engine failure. Worth
 * checking explicitly: it is the single easiest mistake to make when writing a
 * position by hand.
 */
function opponentInCheck(fen) {
  const parts = fen.split(' ');
  parts[1] = parts[1] === 'w' ? 'b' : 'w';
  parts[3] = '-';
  try {
    return new Chess(parts.join(' ')).isCheck();
  } catch {
    return false;
  }
}

function describe(cp, mate) {
  if (mate != null) return `mate in ${Math.abs(mate)}`;
  return `${cp >= 0 ? '+' : ''}${(cp / 100).toFixed(2)}`;
}

const engine = await createEngine({ hash: 128 });
const tactics = await verifyTactics(engine);
const endgames = await verifyEndgames(engine);

const total = tactics.failures.length + endgames.failures.length;
console.log(`\n${total === 0 ? 'All checks passed.' : `${total} problem(s) found.`}`);
process.exit(total && !FIX ? 1 : 0);
