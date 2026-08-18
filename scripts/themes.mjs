// Tactical motif detection. Runs over a solved puzzle line and names what the
// combination actually is, so the trainer can report "you keep missing pins"
// rather than just "you got 6 of 10 wrong".
import { Chess } from 'chess.js';

const FILES = 'abcdefgh';
const VALUE = { p: 1, n: 3, b: 3, r: 5, q: 9, k: 100 };

const RAYS = {
  r: [[1, 0], [-1, 0], [0, 1], [0, -1]],
  b: [[1, 1], [1, -1], [-1, 1], [-1, -1]],
};
RAYS.q = [...RAYS.r, ...RAYS.b];

const LEAPS = {
  n: [[1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2]],
  k: [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]],
};

const toXY = (square) => [FILES.indexOf(square[0]), Number(square[1]) - 1];
const toSquare = (x, y) => `${FILES[x]}${y + 1}`;
const onBoard = (x, y) => x >= 0 && x < 8 && y >= 0 && y < 8;

function boardMap(chess) {
  const map = new Map();
  for (const row of chess.board()) {
    for (const cell of row) if (cell) map.set(cell.square, cell);
  }
  return map;
}

/** Squares the piece standing on `square` attacks (ignoring pins and legality). */
export function attacksFrom(board, square) {
  const piece = board.get(square);
  if (!piece) return [];
  const [x, y] = toXY(square);
  const out = [];

  if (piece.type === 'p') {
    const dy = piece.color === 'w' ? 1 : -1;
    for (const dx of [-1, 1]) if (onBoard(x + dx, y + dy)) out.push(toSquare(x + dx, y + dy));
    return out;
  }

  if (LEAPS[piece.type]) {
    for (const [dx, dy] of LEAPS[piece.type]) {
      if (onBoard(x + dx, y + dy)) out.push(toSquare(x + dx, y + dy));
    }
    return out;
  }

  for (const [dx, dy] of RAYS[piece.type] ?? []) {
    let nx = x + dx;
    let ny = y + dy;
    while (onBoard(nx, ny)) {
      const sq = toSquare(nx, ny);
      out.push(sq);
      if (board.has(sq)) break;
      nx += dx;
      ny += dy;
    }
  }
  return out;
}

/** Enemy pieces the piece on `square` currently hits. */
function targetsOf(board, square) {
  const piece = board.get(square);
  if (!piece) return [];
  return attacksFrom(board, square)
    .map((sq) => board.get(sq))
    .filter((target) => target && target.color !== piece.color);
}

/** Is `square` attacked by any piece of `color`? */
function attackedBy(board, square, color) {
  for (const [from, piece] of board) {
    if (piece.color !== color) continue;
    if (attacksFrom(board, from).includes(square)) return true;
  }
  return false;
}

/**
 * Walk the ray from a line piece and return the first two enemy pieces on it —
 * that pattern is a pin (valuable one behind) or a skewer (valuable one in front).
 */
function alignedPair(board, square, direction) {
  const piece = board.get(square);
  let [x, y] = toXY(square);
  const found = [];
  x += direction[0];
  y += direction[1];
  while (onBoard(x, y)) {
    const sq = toSquare(x, y);
    const occupant = board.get(sq);
    if (occupant) {
      if (occupant.color === piece.color) break;
      found.push({ square: sq, piece: occupant });
      if (found.length === 2) break;
    }
    x += direction[0];
    y += direction[1];
  }
  return found.length === 2 ? found : null;
}

/**
 * @param {string} fen puzzle start position (solver to move)
 * @param {string[]} solution UCI moves, alternating solver / opponent
 */
export function detectThemes(fen, solution) {
  const themes = new Set();
  const chess = new Chess(fen);
  const solverColor = chess.turn();

  const startBoard = boardMap(chess);
  const startMaterial = materialFor(startBoard, solverColor) - materialFor(startBoard, other(solverColor));

  let ourMoveCount = 0;

  for (const [index, uci] of solution.entries()) {
    const boardBefore = boardMap(chess);
    const move = chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    if (!move) break;
    const boardAfter = boardMap(chess);
    const isOurs = index % 2 === 0;
    if (!isOurs) continue;
    ourMoveCount += 1;

    if (move.promotion) themes.add(move.promotion === 'q' ? 'promotion' : 'underpromotion');
    if (move.flags.includes('e')) themes.add('enPassant');

    // Fork: the piece that just moved hits two or more meaningful targets.
    const hits = targetsOf(boardAfter, move.to).filter((t) => VALUE[t.type] >= 3);
    if (hits.length >= 2) themes.add(move.piece === 'n' ? 'knightFork' : 'fork');

    // Pin / skewer created by a line piece.
    if ('rbq'.includes(move.piece)) {
      for (const direction of RAYS[move.piece]) {
        const pair = alignedPair(boardAfter, move.to, direction);
        if (!pair) continue;
        const [front, back] = pair;
        if (VALUE[back.piece.type] > VALUE[front.piece.type]) themes.add('pin');
        else if (VALUE[front.piece.type] > VALUE[back.piece.type] && VALUE[front.piece.type] >= 5) {
          themes.add('skewer');
        }
      }
    }

    // Discovered attack: some other friendly piece gained a target through the vacated square.
    for (const [square, piece] of boardAfter) {
      if (piece.color !== move.color || square === move.to) continue;
      if (!'rbq'.includes(piece.type)) continue;
      const before = new Set(targetsOf(boardBefore, square).map((t) => t.type + t.color));
      const gained = targetsOf(boardAfter, square).filter(
        (t) => VALUE[t.type] >= 5 && !before.has(t.type + t.color),
      );
      if (gained.length && attacksFrom(boardBefore, square).includes(move.from)) {
        themes.add(chess.isCheck() ? 'discoveredCheck' : 'discoveredAttack');
      }
    }

    // Capturing something the opponent left undefended.
    if (index === 0 && move.captured) {
      if (!attackedBy(boardBefore, move.to, other(move.color))) themes.add('hangingPiece');
    }

    // A quiet first move that still wins is a different skill entirely.
    if (index === 0 && !move.captured && !move.san.includes('+') && !move.promotion) {
      themes.add('quietMove');
    }

    if (chess.isCheckmate()) {
      themes.add(`mateIn${ourMoveCount}`);
      themes.add('mate');
      classifyMate(boardAfter, move, other(move.color), themes);
    }
  }

  // Sacrifice: at some point in the line we were down material relative to the start.
  const finalBoard = boardMap(chess);
  const finalMaterial = materialFor(finalBoard, solverColor) - materialFor(finalBoard, other(solverColor));
  if (finalMaterial < startMaterial - 0.5 && !themes.has('mate')) themes.add('sacrifice');
  if (finalMaterial > startMaterial + 0.5) themes.add('winsMaterial');

  const pieceCount = finalBoard.size;
  themes.add(pieceCount <= 10 ? 'endgame' : pieceCount <= 24 ? 'middlegame' : 'opening');
  themes.add(solution.length <= 1 ? 'oneMove' : solution.length <= 3 ? 'short' : 'long');

  return [...themes];
}

function classifyMate(board, move, matedColor, themes) {
  const kingSquare = [...board].find(([, p]) => p.type === 'k' && p.color === matedColor)?.[0];
  if (!kingSquare) return;
  const [kx, ky] = toXY(kingSquare);
  const backRank = matedColor === 'w' ? 0 : 7;

  if (ky === backRank && 'rq'.includes(move.piece)) {
    // Blocked in by its own pawns on the second rank?
    const shield = [-1, 0, 1].filter((dx) => {
      const ny = matedColor === 'w' ? ky + 1 : ky - 1;
      if (!onBoard(kx + dx, ny)) return false;
      const occupant = board.get(toSquare(kx + dx, ny));
      return occupant?.color === matedColor && occupant.type === 'p';
    }).length;
    if (shield >= 2) themes.add('backRankMate');
  }

  if (move.piece === 'n') {
    const escapes = LEAPS.k
      .map(([dx, dy]) => [kx + dx, ky + dy])
      .filter(([x, y]) => onBoard(x, y))
      .filter(([x, y]) => board.get(toSquare(x, y))?.color !== matedColor);
    if (escapes.length === 0) themes.add('smotheredMate');
  }
}

function materialFor(board, color) {
  let total = 0;
  for (const piece of board.values()) {
    if (piece.color === color && piece.type !== 'k') total += VALUE[piece.type];
  }
  return total;
}

const other = (color) => (color === 'w' ? 'b' : 'w');

/**
 * Estimate a puzzle rating. Puzzle ratings are not playing ratings — a 1500
 * puzzle is roughly what a 1500-rated player solves half the time.
 */
export function estimateRating(fen, solution, themes, { gapWinProb = 0.5 } = {}) {
  let rating = 1100;

  const ourMoves = Math.ceil(solution.length / 2);
  rating += (ourMoves - 1) * 220; // depth of calculation dominates difficulty

  const chess = new Chess(fen);
  const first = chess.move({
    from: solution[0].slice(0, 2),
    to: solution[0].slice(2, 4),
    promotion: solution[0][4],
  });

  if (themes.includes('quietMove')) rating += 260; // no check, no capture — hardest to spot
  if (themes.includes('sacrifice')) rating += 180;
  if (themes.includes('underpromotion')) rating += 300;
  if (themes.includes('mateIn1')) rating -= 350;
  if (themes.includes('hangingPiece') && ourMoves === 1) rating -= 200;
  if (themes.includes('backRankMate')) rating -= 80;
  if (themes.includes('knightFork')) rating -= 40;
  if (themes.includes('endgame')) rating += 60;
  if (first?.san.includes('+')) rating -= 90; // checks narrow the search for the solver

  // A wide margin over the second-best move makes the right idea stand out.
  rating -= Math.round((gapWinProb - 0.3) * 300);

  return Math.max(600, Math.min(2900, Math.round(rating / 10) * 10));
}
