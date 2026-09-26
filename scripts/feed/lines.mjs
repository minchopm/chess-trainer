#!/usr/bin/env node
// What the engine sees at each draft's key moment, for whoever rewrites the
// words: the line it wanted, the line after the move that was played, and what
// the players actually did next.
//
//   node scripts/feed/lines.mjs 2026-09-26
import { readFile } from 'node:fs/promises';
import { Chess } from 'chess.js';
import { createEngine } from '../engine-node.mjs';
const d = JSON.parse(await readFile(new URL(`../../feed/drafts/${process.argv[2] ?? new Date().toISOString().slice(0, 10)}.json`, import.meta.url), 'utf8'));
const engine = await createEngine({ hash: 128 });
const toSan = (fen, pv) => { const c = new Chess(fen); const out = []; for (const u of pv.slice(0, 8)) { try { out.push(c.move({ from: u.slice(0,2), to: u.slice(2,4), promotion: u[4] }).san); } catch { break; } } return out.join(' '); };
const material = (fen) => { const v = { p:1,n:3,b:3,r:5,q:9,k:0 }; let w=0,b=0; for (const ch of fen.split(' ')[0]) { const l = ch.toLowerCase(); if (v[l]==null) continue; if (ch===l) b+=v[l]; else w+=v[l]; } return `W${w} B${b}`; };
for (const s of d.stories) {
  const sans = s.moves.split(' ');
  const k = s.key; if (!k) { console.log(s.id, 'no key; last moves:', sans.slice(-10).join(' ')); continue; }
  const c = new Chess(); for (const x of sans.slice(0, k.ply - 1)) c.move(x);
  const before = c.fen(); c.move(sans[k.ply - 1]); const after = c.fen();
  const a = await engine.analyse(before, { depth: 20, movetime: 3000 });
  const b = await engine.analyse(after, { depth: 20, movetime: 3000 });
  console.log(`\n${s.id}  key ${k.ply} ${k.played}  material ${material(after)}`);
  console.log('  before FEN', before);
  console.log('  engine line before:', toSan(before, a.lines[0].pv));
  console.log('  engine line after :', toSan(after, b.lines[0].pv));
  console.log('  game continued    :', sans.slice(k.ply, k.ply + 10).join(' '));
  console.log('  game end          :', sans.slice(-6).join(' '), s.result);
}
process.exit(0);
