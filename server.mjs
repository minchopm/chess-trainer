// Minimal static server for the trainer.
//
// The engine is the single-threaded Stockfish build, so no SharedArrayBuffer and
// therefore no cross-origin-isolation headers are required. We still send them
// when available since they cost nothing and let you swap in the threaded build.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(fileURLToPath(new URL('./public', import.meta.url)));
const DATA = resolve(fileURLToPath(new URL('./data', import.meta.url)));
const PORT = Number(process.env.PORT) || 5173;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

async function resolveFile(urlPath) {
  // /data/* is served from the repo's data directory, everything else from public/.
  if (urlPath.startsWith('/data/')) {
    const p = join(DATA, normalize(urlPath.slice('/data/'.length)).replace(/^(\.\.[/\\])+/, ''));
    return p.startsWith(DATA) ? p : null;
  }
  let p = join(ROOT, normalize(urlPath).replace(/^(\.\.[/\\])+/, ''));
  if (!p.startsWith(ROOT)) return null;
  try {
    if ((await stat(p)).isDirectory()) p = join(p, 'index.html');
  } catch {
    return null;
  }
  return p;
}

const server = createServer(async (req, res) => {
  const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const file = await resolveFile(urlPath === '/' ? '/index.html' : urlPath);

  if (!file) {
    res.writeHead(404).end('Not found');
    return;
  }

  try {
    const body = await readFile(file);
    res.writeHead(200, {
      'Content-Type': TYPES[extname(file)] ?? 'application/octet-stream',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Resource-Policy': 'same-origin',
      'Cache-Control': extname(file) === '.wasm' ? 'public, max-age=604800' : 'no-cache',
    });
    res.end(body);
  } catch {
    res.writeHead(404).end('Not found');
  }
});

server.listen(PORT, () => {
  console.log(`Chess trainer running at http://localhost:${PORT}`);
});
