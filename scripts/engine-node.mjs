// Node-side Stockfish wrapper. Same idea as public/js/engine.js, but the Node
// build of stockfish.js exposes `listener` / `sendCommand` instead of a Worker.
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

export async function createEngine({ flavour = 'lite-single', hash = 64 } = {}) {
  const initEngine = require('stockfish');
  const engine = await initEngine(flavour);

  const listeners = new Set();
  engine.listener = (line) => {
    for (const fn of [...listeners]) fn(line);
  };

  const send = (command) => engine.sendCommand(command);

  const run = (command, isDone, onLine) =>
    new Promise((resolve, reject) => {
      const lines = [];
      const timer = setTimeout(() => {
        listeners.delete(listener);
        reject(new Error(`engine timeout: ${command}`));
      }, 180_000);
      const listener = (line) => {
        lines.push(line);
        onLine?.(line);
        if (isDone(line)) {
          clearTimeout(timer);
          listeners.delete(listener);
          resolve(lines);
        }
      };
      listeners.add(listener);
      send(command);
    });

  await run('uci', (l) => l === 'uciok');
  send(`setoption name Hash value ${hash}`);
  send('setoption name Threads value 1');
  await run('isready', (l) => l === 'readyok');

  let queue = Promise.resolve();
  const enqueue = (task) => {
    const next = queue.then(task, task);
    queue = next.catch(() => {});
    return next;
  };

  return {
    async newGame() {
      return enqueue(async () => {
        send('ucinewgame');
        await run('isready', (l) => l === 'readyok');
      });
    },

    /** @returns {Promise<{lines: Array, best: string|null, terminal: boolean}>} */
    async analyse(fen, { depth = null, movetime = null, multipv = 1 } = {}) {
      return enqueue(async () => {
        const turn = fen.split(' ')[1] ?? 'w';
        send('setoption name UCI_LimitStrength value false');
        send(`setoption name MultiPV value ${multipv}`);
        send(`position fen ${fen}`);
        const byRank = new Map();
        // depth and movetime together means "this deep, but never longer than
        // this". Some positions take minutes to reach even a modest depth, and
        // an unbounded depth search turns a batch job into an overnight one.
        const go = ['go', depth && `depth ${depth}`, movetime && `movetime ${movetime}`]
          .filter(Boolean)
          .join(' ');
        const output = await run(
          go === 'go' ? 'go depth 14' : go,
          (l) => l.startsWith('bestmove'),
          (line) => {
            const info = parseInfo(line);
            if (info) byRank.set(info.rank, { ...info, score: toWhitePov(info.score, turn) });
          },
        );
        const best = output.at(-1).split(/\s+/)[1];
        const lines = [...byRank.values()].sort((a, b) => a.rank - b.rank);
        return { lines, best: best === '(none)' ? null : best, terminal: lines.length === 0 };
      });
    },

    async pickMove(fen, { elo = null, depth = 8, movetime = null } = {}) {
      return enqueue(async () => {
        send('setoption name MultiPV value 1');
        if (elo) {
          send('setoption name UCI_LimitStrength value true');
          send(`setoption name UCI_Elo value ${Math.max(1320, Math.min(3190, Math.round(elo)))}`);
        } else {
          send('setoption name UCI_LimitStrength value false');
        }
        send(`position fen ${fen}`);
        const output = await run(
          movetime ? `go movetime ${movetime}` : `go depth ${depth}`,
          (l) => l.startsWith('bestmove'),
        );
        const best = output.at(-1).split(/\s+/)[1];
        return best === '(none)' ? null : best;
      });
    },
  };
}

function toWhitePov(score, turn) {
  const sign = turn === 'w' ? 1 : -1;
  return score.mate == null
    ? { cp: score.cp * sign, mate: null }
    : { cp: null, mate: score.mate * sign };
}

function parseInfo(line) {
  if (!line.startsWith('info ') || !line.includes(' pv ')) return null;
  const cp = /\bscore cp (-?\d+)/.exec(line);
  const mate = /\bscore mate (-?\d+)/.exec(line);
  if (!cp && !mate) return null;
  const pv = line.slice(line.indexOf(' pv ') + 4).trim().split(/\s+/);
  return {
    depth: Number(/\bdepth (\d+)/.exec(line)?.[1] ?? 0),
    rank: Number(/\bmultipv (\d+)/.exec(line)?.[1] ?? 1),
    score: mate ? { cp: null, mate: Number(mate[1]) } : { cp: Number(cp[1]), mate: null },
    move: pv[0],
    pv,
  };
}

/** Win probability for a centipawn score, from the perspective the score is in. */
export function winProbability(cp) {
  return 1 / (1 + Math.exp(-0.00368208 * Math.max(-1000, Math.min(1000, cp))));
}

/** Score in the given side's favour, with mate mapped to a large value. */
export function cpFor(score, color) {
  if (!score) return 0;
  const sign = color === 'w' ? 1 : -1;
  if (score.mate != null) return sign * score.mate > 0 ? 10_000 : -10_000;
  return score.cp * sign;
}
