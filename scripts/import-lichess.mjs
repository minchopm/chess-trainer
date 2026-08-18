#!/usr/bin/env node
// Optional importer for the Lichess puzzle database (CC0, ~5 million puzzles).
//
// The database is not bundled — it is a ~300 MB compressed download. Nothing
// here contacts the network unless you ask it to.
//
//   # 1. download once (about 300 MB compressed, 1 GB on disk)
//   curl -O https://database.lichess.org/lichess_db_puzzle.csv.zst
//
//   # 2. import a filtered slice
//   node scripts/import-lichess.mjs --file lichess_db_puzzle.csv.zst \
//        --min-rating 900 --max-rating 2600 --limit 20000
//
// Requires `zstd` on PATH for .zst input (brew install zstd). A plain .csv works
// with no extra tooling.
import { spawn } from 'node:child_process';
import { createReadStream } from 'node:fs';
import { writeFile, mkdir } from 'node:fs/promises';
import { createInterface } from 'node:readline';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Chess } from 'chess.js';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function parseArgs(argv) {
  const args = {
    file: null,
    out: 'data/tactics-lichess.json',
    'min-rating': 800,
    'max-rating': 2800,
    'min-plays': 100,
    limit: 40000,
    'per-band': 700,
    band: 100,
    seed: 7,
    themes: null,
  };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (!(key in args)) continue;
    const value = argv[i + 1];
    args[key] = ['file', 'out', 'themes'].includes(key) ? value : Number(value);
  }
  return args;
}

function openStream(path) {
  if (!path.endsWith('.zst')) return createReadStream(path);
  const child = spawn('zstd', ['-dc', path], { stdio: ['ignore', 'pipe', 'inherit'] });
  child.on('error', () => {
    console.error('Could not run `zstd`. Install it (brew install zstd) or decompress the file first.');
    process.exit(1);
  });
  return child.stdout;
}

/**
 * Lichess stores the position one ply *before* the puzzle starts: the first move
 * in the list is the opponent's blunder. Replay it so the stored position has
 * the solver to move, matching the format the trainer uses everywhere else.
 */
function normalise(fen, moves) {
  const chess = new Chess(fen);
  const [opponentMove, ...solution] = moves;
  if (!solution.length) return null;
  try {
    chess.move({
      from: opponentMove.slice(0, 2),
      to: opponentMove.slice(2, 4),
      promotion: opponentMove[4],
    });
  } catch {
    return null;
  }

  // Validate the whole line rather than trusting the file.
  const probe = new Chess(chess.fen());
  for (const uci of solution) {
    try {
      if (!probe.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] })) return null;
    } catch {
      return null;
    }
  }

  return { fen: chess.fen(), solution, mate: probe.isCheckmate() };
}

/** Split a CSV line, honouring quoted fields. */
function splitCsv(line) {
  const out = [];
  let current = '';
  let quoted = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (ch === '"') {
      if (quoted && line[i + 1] === '"') {
        current += '"';
        i += 1;
      } else quoted = !quoted;
    } else if (ch === ',' && !quoted) {
      out.push(current);
      current = '';
    } else current += ch;
  }
  out.push(current);
  return out;
}

/** Deterministic PRNG so the same file and seed always produce the same slice. */
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

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.file) {
    console.error('Usage: node scripts/import-lichess.mjs --file lichess_db_puzzle.csv.zst [--limit 20000]');
    console.error('Download it first:  curl -O https://database.lichess.org/lichess_db_puzzle.csv.zst');
    process.exit(1);
  }

  const wanted = args.themes ? new Set(args.themes.split(',')) : null;
  const random = makeRandom(args.seed);

  // Sample per rating band rather than taking the first N rows.
  //
  // Most Lichess puzzles sit between 1200 and 1800, so a plain first-N cut
  // leaves the top of the ladder almost empty — exactly the part you need once
  // you are strong. Reservoir sampling inside each band gives an even spread
  // across the whole range and stays representative of each band's contents.
  const bands = new Map(); // band floor -> { kept: [], seen: number }
  const bandOf = (rating) => Math.floor(rating / args.band) * args.band;

  let scanned = 0;
  let considered = 0;
  let header = true;
  const startedAt = Date.now();

  const rl = createInterface({ input: openStream(args.file), crlfDelay: Infinity });

  for await (const line of rl) {
    if (header) {
      header = false;
      if (line.startsWith('PuzzleId')) continue;
    }
    scanned += 1;

    const [id, fen, moves, rating, , , plays, themes] = splitCsv(line);
    if (!fen || !moves) continue;

    const ratingNumber = Number(rating);
    if (ratingNumber < args['min-rating'] || ratingNumber > args['max-rating']) continue;
    if (Number(plays) < args['min-plays']) continue;

    const themeList = (themes ?? '').split(' ').filter(Boolean);
    if (wanted && !themeList.some((theme) => wanted.has(theme))) continue;

    const floor = bandOf(ratingNumber);
    const band = bands.get(floor) ?? { kept: [], seen: 0 };
    if (!bands.has(floor)) bands.set(floor, band);
    band.seen += 1;

    // Decide whether to keep it *before* the expensive move validation.
    let slot = band.kept.length;
    if (slot >= args['per-band']) {
      const candidate = Math.floor(random() * band.seen);
      if (candidate >= args['per-band']) continue;
      slot = candidate;
    }

    const normalised = normalise(fen, moves.split(' '));
    if (!normalised) continue;
    considered += 1;

    const puzzle = {
      id: `l${id}`,
      fen: normalised.fen,
      solution: normalised.solution,
      themes: themeList,
      rating: ratingNumber,
      sideToMove: normalised.fen.split(' ')[1],
      mate: normalised.mate,
      source: 'lichess',
    };

    if (slot < band.kept.length) band.kept[slot] = puzzle;
    else band.kept.push(puzzle);

    if (scanned % 500_000 === 0) {
      const total = [...bands.values()].reduce((sum, b) => sum + b.kept.length, 0);
      console.log(`  scanned ${(scanned / 1000).toFixed(0)}k rows · holding ${total} · ${((Date.now() - startedAt) / 1000).toFixed(0)}s`);
    }
  }

  rl.close();

  const puzzles = [...bands.values()].flatMap((band) => band.kept).slice(0, args.limit);
  puzzles.sort((a, b) => a.rating - b.rating);
  const outPath = resolve(ROOT, args.out);
  await mkdir(dirname(outPath), { recursive: true });
  // One puzzle per line rather than pretty-printed: at 14,000 entries the
  // indentation is a third of the file, and the browser parses the whole thing
  // on every load.
  const body = puzzles.map((puzzle) => `  ${JSON.stringify(puzzle)}`).join(',\n');
  await writeFile(
    outPath,
    `{\n "generated": ${JSON.stringify(new Date().toISOString())},\n` +
      ` "source": "lichess.org puzzle database (CC0)",\n "puzzles": [\n${body}\n ]\n}\n`,
  );

  console.log(`\nKept ${puzzles.length} puzzles from ${scanned} rows (${considered} passed validation) → ${args.out}`);
  console.log('\nRating spread:');
  for (const floor of [...bands.keys()].sort((a, b) => a - b)) {
    const count = bands.get(floor).kept.length;
    if (count) console.log(`  ${String(floor).padStart(4)}-${floor + args.band - 1}: ${'█'.repeat(Math.ceil(count / 25))} ${count}`);
  }
  console.log('\nTo use them, either replace data/tactics.json with this file or merge the two.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
