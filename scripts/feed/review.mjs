#!/usr/bin/env node
// The day's drafts as one page to read and approve.
//
//   node scripts/feed/review.mjs 2026-09-26     → feed/drafts/2026-09-26.html
//
// A page rather than the JSON because a story is approved on what it says
// next to the board it is about — and a wrong move number is obvious on a
// diagram and invisible in a file.
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { diagramSvg, positionAt } from './diagram.mjs';
import { assessment, moveLabel } from './words.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const date = process.argv[2] ?? new Date().toISOString().slice(0, 10);

const pieces = {};
for (const colour of 'wb') {
  for (const kind of 'KQRBNP') {
    const code = colour + kind;
    const file = colour === 'w' ? `web/public/pieces/${code}.png` : `web/public/pieces/ebony/${code}.png`;
    const png = await readFile(resolve(ROOT, file));
    pieces[code] = `data:image/png;base64,${png.toString('base64')}`;
  }
}

const escape = (text) =>
  String(text ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

const score = (s) => (s.mate != null ? `mate in ${Math.abs(s.mate)} for ${s.mate > 0 ? 'White' : 'Black'}` : `${s.cp > 0 ? '+' : ''}${(s.cp / 100).toFixed(2)}`);

const drafts = JSON.parse(await readFile(resolve(ROOT, `feed/drafts/${date}.json`), 'utf8'));
const cards = drafts.stories.map((story, index) => {
  const sans = story.moves.split(' ');
  const ply = story.key?.ply ?? sans.length;
  const { fen, last } = positionAt(sans, ply);
  const board = diagramSvg(fen, { last, size: 320, flip: story.result === '0-1', piece: (c) => pieces[c] });
  const key = story.key;
  const facts = [
    ['Result', `${story.result} · ${Math.ceil(story.plies / 2)} moves${story.ending ? ` · ${story.ending}` : ''}`],
    ['Event', `${story.event.name}${story.event.section ? ` · ${story.event.section}` : ''}${story.event.round ? ` · round ${story.event.round}` : ''}`],
    ['White', `${story.white.title ?? ''} ${story.white.name} ${story.white.elo ?? ''} ${story.white.team ? `· ${story.white.team}` : ''}`],
    ['Black', `${story.black.title ?? ''} ${story.black.name} ${story.black.elo ?? ''} ${story.black.team ? `· ${story.black.team}` : ''}`],
    ['Opening', `${story.opening.eco ?? ''} ${story.opening.name ?? ''}`],
    key && ['Key move', `${moveLabel(key.ply, key.played)} (${key.kind}) · ${score(key.before)} → ${score(key.after)} · ${assessment(key.before)} → ${assessment(key.after)}`],
    key?.better && ['Engine instead', moveLabel(key.ply, key.better)],
    key?.reply && ['Best reply', `${moveLabel(key.ply + 1, key.reply)}${key.replyPlayed ? ' — played' : ' — not played'}`],
    key?.clock != null && ['Clock', `${Math.floor(key.clock / 60)}:${String(key.clock % 60).padStart(2, '0')} left after the key move`],
  ].filter(Boolean);
  return `
  <article class="${escape(story.status)}">
    <div class="board">${board}<p class="caption">${key ? `After ${escape(moveLabel(key.ply, key.played))}` : 'Final position'}</p></div>
    <div class="words">
      <p class="meta"><span class="n">${index + 1}</span><span class="status">${escape(story.status)}</span><code>${escape(story.id)}</code></p>
      <h2>${escape(story.headline)}</h2>
      <p class="body">${escape(story.body)}</p>
      <dl>${facts.map(([k, v]) => `<dt>${escape(k)}</dt><dd>${escape(v)}</dd>`).join('')}</dl>
      <p class="source"><a href="${escape(story.source.url)}">Game on Lichess</a></p>
    </div>
  </article>`;
});

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Feed drafts ${escape(date)}</title>
<style>
  :root { --ink: #05060A; --ink3: #10131B; --ivory: #E9E4D8; --dim: rgba(233,228,216,.66); --brass: #D6A95F; --deep: #8A6A2F; --good: #7FB069; }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--ink); color: var(--ivory); font: 15px/1.55 -apple-system, "Helvetica Neue", sans-serif; }
  main { max-width: 980px; margin: 0 auto; padding: 32px 16px 64px; }
  h1 { font: 600 28px/1.2 Georgia, serif; margin: 0 0 6px; }
  .lede { color: var(--dim); margin: 0 0 28px; }
  article { display: grid; grid-template-columns: 320px 1fr; gap: 24px; padding: 22px; margin: 0 0 18px; background: var(--ink3); border: 1px solid rgba(138,106,47,.45); border-radius: 10px; }
  article.approved { border-color: var(--good); }
  .board svg { width: 100%; height: auto; display: block; border-radius: 4px; }
  .caption { color: var(--dim); font-size: 12px; margin: 6px 0 0; text-align: center; }
  h2 { font: 600 21px/1.3 Georgia, serif; margin: 6px 0 10px; }
  .meta { display: flex; gap: 10px; align-items: center; margin: 0; font-size: 12px; color: var(--dim); }
  .n { background: var(--brass); color: var(--ink); font-weight: 700; border-radius: 50%; width: 24px; height: 24px; display: grid; place-items: center; }
  .status { text-transform: uppercase; letter-spacing: .12em; color: var(--brass); }
  .approved .status { color: var(--good); }
  code { font-size: 11px; opacity: .7; overflow-wrap: anywhere; }
  .body { margin: 0 0 14px; }
  dl { display: grid; grid-template-columns: max-content 1fr; gap: 3px 14px; font-size: 13px; margin: 0 0 10px; }
  dt { color: var(--dim); }
  dd { margin: 0; }
  a { color: var(--brass); }
  @media (max-width: 720px) { article { grid-template-columns: 1fr; } }
</style>
</head>
<body>
<main>
  <h1>Feed drafts · ${escape(date)}</h1>
  <p class="lede">${drafts.stories.length} stories. Nothing here is published until it is marked approved.</p>
  ${cards.join('\n')}
</main>
</body>
</html>
`;
const out = resolve(ROOT, `feed/drafts/${date}.html`);
await writeFile(out, html);
console.error(`Wrote ${out}`);
