#!/usr/bin/env node
// Importer for whole games from the Lichess database (CC0), for the
// Guess the Elo mode.
//
// The archives are not bundled — they are large downloads. Nothing here
// contacts the network unless you ask it to.
//
//   # 1. download one or more monthly archives
//   curl -O https://database.lichess.org/standard/lichess_db_standard_rated_2014-07.pgn.zst
//
//   # 2. sample an even spread of games across the rating ladder
//   node scripts/import-games.mjs --files lichess_db_standard_rated_2014-07.pgn.zst
//
// Requires `zstd` on PATH for .zst input. A plain .pgn works with no extra
// tooling.
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
    files: null,
    out: 'data/games.json',
    'min-rating': 800,
    'max-rating': 2600,
    // A guess about "the players" only means something when the two players
    // are at a similar level. Lichess pairs by rating, so most games qualify.
    'max-gap': 150,
    'min-moves': 18,
    'max-moves': 70,
    'per-band': 90,
    band: 100,
    seed: 11,
  };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (!(key in args)) continue;
    const value = argv[i + 1];
    args[key] = ['files', 'out'].includes(key) ? value : Number(value);
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

/** Deterministic PRNG, so the same archives and seed give the same slice. */
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

/**
 * Replay the movetext and return the line in UCI.
 *
 * Validating every move here rather than trusting the archive means the app
 * never has to defend itself against a line that does not play: a game that
 * stops halfway through would be a film that freezes, with no way for the
 * viewer to tell whose fault it was.
 */
function toUci(movetext) {
  const chess = new Chess();
  const cleaned = movetext
    .replace(/\{[^}]*\}/g, ' ')      // comments
    .replace(/\$\d+/g, ' ')          // numeric annotation glyphs
    .replace(/\d+\.(\.\.)?/g, ' ')   // move numbers
    .replace(/[?!]+/g, ' ')
    .trim();

  const uci = [];
  for (const token of cleaned.split(/\s+/)) {
    if (!token || token === '1-0' || token === '0-1' || token === '1/2-1/2' || token === '*') continue;
    let move;
    try {
      move = chess.move(token, { strict: false });
    } catch {
      return null;
    }
    if (!move) return null;
    uci.push(`${move.from}${move.to}${move.promotion ?? ''}`);
  }
  return uci;
}

/** "Rated Blitz game" -> "Blitz"; tournament games carry a URL after the name. */
function speedOf(event) {
  const match = /(Bullet|Blitz|Classical|Correspondence)/.exec(event ?? '');
  return match ? match[1] : null;
}

async function importFile(path, args, bands, random, stats) {
  const rl = createInterface({ input: openStream(path), crlfDelay: Infinity });
  let headers = {};

  for await (const line of rl) {
    if (line.startsWith('[')) {
      const match = /^\[(\w+) "(.*)"\]$/.exec(line);
      if (match) headers[match[1]] = match[2];
      continue;
    }
    if (!line.trim() || !line.trim().match(/^[1*]/)) continue;

    // A movetext line: this is the end of one game's record.
    const game = headers;
    headers = {};
    stats.scanned += 1;

    const white = Number(game.WhiteElo);
    const black = Number(game.BlackElo);
    if (!white || !black) continue;
    if (Math.abs(white - black) > args['max-gap']) continue;

    const average = Math.round((white + black) / 2);
    if (average < args['min-rating'] || average > args['max-rating']) continue;

    // Bullet is not a game you can read: the moves are a product of the clock
    // as much as of the players, which is exactly what the guess is about.
    const speed = speedOf(game.Event);
    if (speed !== 'Blitz' && speed !== 'Classical') continue;
    if (game.Termination && game.Termination !== 'Normal' && game.Termination !== 'Time forfeit') continue;

    const floor = Math.floor(average / args.band) * args.band;
    const band = bands.get(floor) ?? { kept: [], seen: 0 };
    if (!bands.has(floor)) bands.set(floor, band);
    band.seen += 1;

    // Decide whether to keep it *before* replaying the moves, which is by far
    // the expensive part.
    let slot = band.kept.length;
    if (slot >= args['per-band']) {
      const candidate = Math.floor(random() * band.seen);
      if (candidate >= args['per-band']) continue;
      slot = candidate;
    }

    const moves = toUci(line.trim());
    if (!moves) {
      stats.unplayable += 1;
      continue;
    }
    const fullMoves = Math.ceil(moves.length / 2);
    if (fullMoves < args['min-moves'] || fullMoves > args['max-moves']) continue;

    const id = (game.Site ?? '').split('/').pop();
    if (!id) continue;

    const record = {
      id: `g${id}`,
      white,
      black,
      result: game.Result,
      speed,
      timeControl: game.TimeControl ?? null,
      termination: game.Termination ?? null,
      eco: game.ECO || null,
      opening: game.Opening || null,
      date: game.UTCDate ?? null,
      moves: moves.join(' '),
    };

    if (slot < band.kept.length) band.kept[slot] = record;
    else band.kept.push(record);
    stats.kept += 1;

    if (stats.scanned % 200_000 === 0) {
      const held = [...bands.values()].reduce((sum, b) => sum + b.kept.length, 0);
      console.log(`  scanned ${(stats.scanned / 1000).toFixed(0)}k games · holding ${held}`);
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.files) {
    console.error('Usage: node scripts/import-games.mjs --files a.pgn.zst[,b.pgn.zst]');
    console.error('Download one first:');
    console.error('  curl -O https://database.lichess.org/standard/lichess_db_standard_rated_2014-07.pgn.zst');
    process.exit(1);
  }

  const random = makeRandom(args.seed);
  const bands = new Map();
  const stats = { scanned: 0, kept: 0, unplayable: 0 };
  const startedAt = Date.now();

  for (const path of args.files.split(',')) {
    console.log(`Reading ${path}`);
    await importFile(path.trim(), args, bands, random, stats);
  }

  const games = [...bands.entries()]
    .sort((a, b) => a[0] - b[0])
    .flatMap(([, band]) => band.kept)
    .sort((a, b) => (a.white + a.black) - (b.white + b.black));

  const out = resolve(ROOT, args.out);
  await mkdir(dirname(out), { recursive: true });

  const body = games.map((game) => JSON.stringify(game)).join(',\n  ');
  await writeFile(out, `{
 "note": "Rated human games from the Lichess database (CC0), sampled evenly across rating bands. Ratings are Lichess ratings, not FIDE. Moves are UCI, space separated.",
 "games": [
  ${body}
 ]
}
`);

  console.log(`\nScanned ${stats.scanned} games, kept ${games.length}, ${stats.unplayable} unplayable`);
  for (const [floor, band] of [...bands.entries()].sort((a, b) => a[0] - b[0])) {
    console.log(`  ${floor}–${floor + args.band - 1}: ${band.kept.length} of ${band.seen} seen`);
  }
  console.log(`Wrote ${args.out} in ${((Date.now() - startedAt) / 1000).toFixed(0)}s`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
