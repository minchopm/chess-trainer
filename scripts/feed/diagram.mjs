// A position as an SVG diagram, on the app's walnut squares with the app's
// own pieces — for the review page, which is read once and thrown away. The
// site draws its boards in the browser instead (web/src/app/board).
import { Chess } from 'chess.js';

export const LIGHT = '#CB9B66';
export const DARK = '#6C432C';
export const MARK = 'rgba(255, 214, 92, 0.5)';

/** The position after `ply` half-moves of the game, and the move that led there. */
export function positionAt(sans, ply) {
  const chess = new Chess();
  let last = null;
  for (const san of sans.slice(0, ply)) last = chess.move(san);
  return { fen: chess.fen(), last: last && { from: last.from, to: last.to } };
}

function xy(square, flip, cell) {
  const file = square.charCodeAt(0) - 97;
  const rank = Number(square[1]) - 1;
  const x = (flip ? 7 - file : file) * cell;
  const y = (flip ? rank : 7 - rank) * cell;
  return [x, y];
}

export function diagramSvg(fen, { last = null, size = 400, flip = false, piece = (code) => `/pieces/${code}.png` } = {}) {
  const cell = size / 8;
  const parts = [`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size} ${size}" width="${size}" height="${size}" role="img">`];
  for (let r = 0; r < 8; r++) {
    for (let f = 0; f < 8; f++) {
      const fill = (r + f) % 2 === 0 ? LIGHT : DARK;
      parts.push(`<rect x="${f * cell}" y="${r * cell}" width="${cell}" height="${cell}" fill="${fill}"/>`);
    }
  }
  if (last) {
    for (const sq of [last.from, last.to]) {
      const [x, y] = xy(sq, flip, cell);
      parts.push(`<rect x="${x}" y="${y}" width="${cell}" height="${cell}" fill="${MARK}"/>`);
    }
  }
  const rows = fen.split(' ')[0].split('/');
  rows.forEach((row, r) => {
    let f = 0;
    for (const ch of row) {
      if (/\d/.test(ch)) {
        f += Number(ch);
        continue;
      }
      const code = (ch === ch.toUpperCase() ? 'w' : 'b') + ch.toUpperCase();
      const square = String.fromCharCode(97 + f) + (8 - r);
      const [x, y] = xy(square, flip, cell);
      parts.push(`<image href="${piece(code)}" x="${x}" y="${y}" width="${cell}" height="${cell}"/>`);
      f++;
    }
  });
  parts.push('</svg>');
  return parts.join('');
}
