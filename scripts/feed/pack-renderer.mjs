#!/usr/bin/env node
// The site's renderer, as the collector carries it.
//
//   node scripts/feed/pack-renderer.mjs web/dist/brass-pawn/server <out>
//
// The Angular server bundle a site build leaves (web/src/server.ts), less what
// only a server that serves the prerendered site would use. The build folds
// every prerendered page into it as an asset, and lists every story it
// prerendered as a route of its own — and with those in, asking it for a story
// the build had hands back the page as it was prerendered, or nothing. The
// collector asks precisely when that page is out of date: a story approved in
// new words (publish.mjs). So the pages go, the stories' own routes go, and
// every story falls to the /today/* route, which renders it. What is kept is
// the code, the two HTML shells and the stylesheet the renderer inlines from —
// a fifth of the size.
import { copyFile, mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const [from, to] = process.argv.slice(2).map((path) => resolve(path));
if (!from || !to) {
  console.error('usage: pack-renderer.mjs <server dir> <out dir>');
  process.exit(2);
}

await mkdir(join(to, 'assets-chunks'), { recursive: true });
for (const name of await readdir(from)) {
  if (name.endsWith('.mjs') && name !== 'angular-app-manifest.mjs') await copyFile(join(from, name), join(to, name));
}
const kept = ['index_server_html.mjs', 'index_csr_html.mjs'];
for (const name of await readdir(join(from, 'assets-chunks'))) {
  if (kept.includes(name) || /^styles-.*_css\.mjs$/.test(name)) {
    await copyFile(join(from, 'assets-chunks', name), join(to, 'assets-chunks', name));
  }
}

let manifest = await readFile(join(from, 'angular-app-manifest.mjs'), 'utf8');

// The routes are JSON between `routes: [` and the `],` that closes it.
const open = manifest.indexOf('routes: [');
if (open < 0) throw new Error('pack-renderer: no routes in the manifest');
const start = open + 'routes: '.length;
let depth = 0;
let end = start;
for (; end < manifest.length; end++) {
  if (manifest[end] === '[') depth++;
  else if (manifest[end] === ']' && --depth === 0) break;
}
const routes = JSON.parse(manifest.slice(start, end + 1));
const story = /^\/today\/(?!story$)[^/*]+$/;
if (!routes.some((route) => route.route === '/today/*')) throw new Error('pack-renderer: no /today/* route to fall back to');
const left = routes.filter((route) => !story.test(route.route));
manifest = manifest.slice(0, start) + JSON.stringify(left, null, 2) + manifest.slice(end + 1);

// One asset per line; the prerendered pages are the ones named …index.html.
manifest = manifest
  .split('\n')
  .filter((line) => !/^\s*'([^']*\/)?index\.html': \{/.test(line))
  .join('\n');
await writeFile(join(to, 'angular-app-manifest.mjs'), manifest);
console.error(`pack-renderer: ${routes.length - left.length} story routes and the prerendered pages left out`);
