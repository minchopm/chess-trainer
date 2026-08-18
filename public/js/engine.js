// Stockfish 18 (single-threaded WASM build) behind a small promise API.
//
// The engine speaks UCI over a Worker. Commands are serialised through a queue
// because a UCI engine has exactly one position and one search at a time.

const ENGINE_URL = '/vendor/stockfish-18-lite-single.js';

/** Scores come out of UCI relative to the side to move; flip them to White's view. */
function toWhitePov(score, turn) {
  if (!score) return score;
  const sign = turn === 'w' ? 1 : -1;
  return score.mate == null
    ? { cp: score.cp * sign, mate: null }
    : { cp: null, mate: score.mate * sign };
}

export function formatScore(score, { signed = true } = {}) {
  if (!score) return '—';
  if (score.mate != null) return `${score.mate > 0 ? '#' : '#-'}${Math.abs(score.mate)}`;
  const pawns = score.cp / 100;
  const body = Math.abs(pawns).toFixed(Math.abs(pawns) >= 10 ? 1 : 2);
  if (!signed) return body;
  return `${pawns >= 0 ? '+' : '−'}${body}`;
}

/** Map a White-POV score onto a 0..1 "how much of the bar is white" value. */
export function scoreToBar(score) {
  if (!score) return 0.5;
  if (score.mate != null) return score.mate > 0 ? 1 : 0;
  return 1 / (1 + Math.exp(-score.cp / 320));
}

/** Win probability for the side the score favours, Lichess' logistic fit. */
export function winProbability(cp) {
  return 1 / (1 + Math.exp(-0.00368208 * Math.max(-1000, Math.min(1000, cp))));
}

export class Engine {
  #worker = null;
  #queue = Promise.resolve();
  #listeners = new Set();
  #booted = null;

  state = 'idle';
  onStateChange = null;

  #setState(state) {
    this.state = state;
    this.onStateChange?.(state);
  }

  #ensureWorker() {
    if (this.#worker) return this.#worker;
    this.#worker = new Worker(ENGINE_URL);
    this.#worker.addEventListener('message', (event) => {
      const line = typeof event.data === 'string' ? event.data : event.data?.data;
      if (typeof line !== 'string') return;
      for (const listener of this.#listeners) listener(line);
    });
    this.#worker.addEventListener('error', (event) => this.#handleCrash(event));
    return this.#worker;
  }

  /**
   * A WASM engine can die (it aborts rather than throwing when it runs out of
   * memory). Tear the worker down so the next request boots a fresh one instead
   * of hanging forever on a dead one.
   */
  #handleCrash(event) {
    // Deliberately not swallowed: if the engine dies, that should be visible.
    console.error('Stockfish worker died:', event?.message ?? event);
    this.#setState('error');
    try {
      this.#worker?.terminate();
    } catch {
      /* already gone */
    }
    this.#worker = null;
    this.#booted = null;
    this.#queue = Promise.resolve();
    for (const listener of [...this.#listeners]) listener('bestmove (none)');
    this.#listeners.clear();
  }

  #send(command) {
    this.#ensureWorker().postMessage(command);
  }

  /** Run `command`, collecting output until `isDone(line)` returns true. */
  #run(command, isDone, { onLine, timeout = 120000 } = {}) {
    return new Promise((resolve, reject) => {
      const lines = [];
      const timer = setTimeout(() => {
        this.#listeners.delete(listener);
        reject(new Error(`Engine timed out on: ${command}`));
      }, timeout);

      const listener = (line) => {
        lines.push(line);
        onLine?.(line);
        if (isDone(line)) {
          clearTimeout(timer);
          this.#listeners.delete(listener);
          resolve(lines);
        }
      };

      this.#listeners.add(listener);
      this.#send(command);
    });
  }

  /**
   * Let the engine finish unwinding before sending it anything else.
   *
   * `bestmove` is emitted from inside the search, before the Asyncify unwind has
   * completed. The worker build defers its own queue drain by a timer for
   * exactly this reason — but it only queues `go` and `setoption`; `position`
   * runs immediately, re-enters the module mid-unwind, and traps with
   * "unreachable", killing the engine. Yielding two macrotasks lets the module
   * settle first. Sending `stop`/`isready` here would not help: those are
   * immediate calls too, and re-entering is the thing being avoided.
   */
  async #settle() {
    await new Promise((resolve) => setTimeout(resolve, 0));
    await new Promise((resolve) => setTimeout(resolve, 4));
  }

  /** Serialise everything so two searches can never overlap. */
  #enqueue(task) {
    const next = this.#queue.then(task, task);
    this.#queue = next.catch(() => {});
    return next;
  }

  boot() {
    this.#booted ??= (async () => {
      this.#setState('booting');
      await this.#run('uci', (line) => line === 'uciok');
      // Keep the hash table small. This runs in a browser tab beside whatever
      // else the machine is doing, and a big table buys little at these depths.
      this.#send('setoption name Hash value 16');
      await this.#run('isready', (line) => line === 'readyok');
      this.#setState('ready');
    })();
    return this.#booted;
  }

  async setOption(name, value) {
    await this.boot();
    this.#send(`setoption name ${name} value ${value}`);
  }

  async newGame() {
    await this.boot();
    return this.#enqueue(async () => {
      this.#send('ucinewgame');
      await this.#run('isready', (line) => line === 'readyok');
    });
  }

  /**
   * Analyse a position.
   * Returns { lines: [{ rank, score, move, pv }], best } with scores in White POV.
   */
  async analyse(fen, { depth = 16, multipv = 1, movetime = null, onProgress = null } = {}) {
    await this.boot();
    const turn = fen.split(' ')[1] ?? 'w';

    return this.#enqueue(async () => {
      this.#setState('thinking');
      await this.#settle();
      this.#send(`setoption name MultiPV value ${multipv}`);
      this.#send(`position fen ${fen}`);

      const byRank = new Map();
      const go = movetime ? `go movetime ${movetime}` : `go depth ${depth}`;

      const output = await this.#run(go, (line) => line.startsWith('bestmove'), {
        onLine: (line) => {
          const parsed = parseInfo(line);
          if (!parsed) return;
          byRank.set(parsed.rank, { ...parsed, score: toWhitePov(parsed.score, turn) });
          onProgress?.({ depth: parsed.depth, lines: sortLines(byRank) });
        },
      });

      this.#setState('ready');
      const bestLine = output.find((line) => line.startsWith('bestmove'));
      const best = bestLine?.split(/\s+/)[1] ?? null;
      const lines = sortLines(byRank);

      // A mated/stalemated position emits no info lines at all.
      if (!lines.length) return { lines: [], best: best === '(none)' ? null : best, terminal: true };
      return { lines, best, terminal: false };
    });
  }

  /**
   * Pick a move at a limited strength. `elo` uses Stockfish's own strength
   * limiter, which plays far more human-like than simply reducing depth.
   */
  async pickMove(fen, { elo = null, depth = 12, movetime = null } = {}) {
    await this.boot();
    return this.#enqueue(async () => {
      this.#setState('thinking');
      await this.#settle();
      this.#send('setoption name MultiPV value 1');
      if (elo) {
        this.#send('setoption name UCI_LimitStrength value true');
        this.#send(`setoption name UCI_Elo value ${Math.max(1320, Math.min(3190, Math.round(elo)))}`);
      } else {
        this.#send('setoption name UCI_LimitStrength value false');
      }
      this.#send(`position fen ${fen}`);
      const go = movetime ? `go movetime ${movetime}` : `go depth ${depth}`;
      const output = await this.#run(go, (line) => line.startsWith('bestmove'));
      this.#setState('ready');
      const best = output.at(-1).split(/\s+/)[1];
      return best === '(none)' ? null : best;
    });
  }

  stop() {
    if (this.#worker) this.#send('stop');
  }
}

function sortLines(byRank) {
  return [...byRank.values()].sort((a, b) => a.rank - b.rank);
}

function parseInfo(line) {
  if (!line.startsWith('info ') || !line.includes(' pv ')) return null;
  const depth = Number(/\bdepth (\d+)/.exec(line)?.[1] ?? 0);
  const rank = Number(/\bmultipv (\d+)/.exec(line)?.[1] ?? 1);
  const cp = /\bscore cp (-?\d+)/.exec(line);
  const mate = /\bscore mate (-?\d+)/.exec(line);
  if (!cp && !mate) return null;
  const pv = line.slice(line.indexOf(' pv ') + 4).trim().split(/\s+/);
  return {
    depth,
    rank,
    score: mate ? { cp: null, mate: Number(mate[1]) } : { cp: Number(cp[1]), mate: null },
    move: pv[0],
    pv,
  };
}
