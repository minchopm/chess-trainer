// Engines for the collector, one per child process.
//
// The npm build of Stockfish will not start a second engine in one process —
// the second looks for a file the first has already claimed and aborts — and
// in a worker thread it mistakes itself for a browser worker and exports
// nothing. A child process is neither, so each extra engine gets one, running
// the same wrapper everything else uses. What comes back has the same two
// methods the analysis calls, so it cannot tell the difference.
import { fork } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { createEngine } from '../engine-node.mjs';

if (process.env.FEED_ENGINE_CHILD === '1' && process.send) {
  const engine = await createEngine({ hash: Number(process.env.FEED_ENGINE_HASH ?? 128) });
  process.on('message', async ({ id, method, args }) => {
    try {
      process.send({ id, result: await engine[method](...args) });
    } catch (error) {
      process.send({ id, error: error.message });
    }
  });
  process.send({ ready: true });
}

export async function createEngines(count, { hash = 128 } = {}) {
  // One engine needs no child: it is the Lambda's case, and the plainest.
  if (count <= 1) return [await createEngine({ hash })];
  return Promise.all(Array.from({ length: count }, () => childEngine(hash)));
}

function childEngine(hash) {
  const child = fork(fileURLToPath(import.meta.url), [], {
    env: { ...process.env, FEED_ENGINE_CHILD: '1', FEED_ENGINE_HASH: String(hash) },
    stdio: ['ignore', 'ignore', 'inherit', 'ipc'],
  });
  const pending = new Map();
  let next = 0;

  function call(method, args) {
    return new Promise((resolve, reject) => {
      const id = next++;
      pending.set(id, { resolve, reject });
      child.send({ id, method, args });
    });
  }

  return new Promise((resolveReady, rejectReady) => {
    child.once('error', rejectReady);
    child.once('exit', (code) => rejectReady(new Error(`engine process exited with ${code}`)));
    child.on('message', (message) => {
      if (message.ready) {
        resolveReady({
          newGame: () => call('newGame', []),
          analyse: (fen, options) => call('analyse', [fen, options]),
          close: () => child.kill(),
        });
        return;
      }
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) reject(new Error(message.error));
      else resolve(message.result);
    });
  });
}
