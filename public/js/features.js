// Positional feature extraction.
//
// The engine tells you *which* move is best; these features are how the trainer
// explains *why*. They are deliberately the classical concepts a coach would
// name — open files, rook placement, outposts, pawn structure, king safety —
// because those are the handles a human can actually reuse over the board.

import { Chess } from '/vendor/chess.mjs';

const FILES = 'abcdefgh';
const PIECE_VALUE = { p: 1, n: 3, b: 3.25, r: 5, q: 9, k: 0 };

const fileIndex = (square) => FILES.indexOf(square[0]);
const rankOf = (square) => Number(square[1]);

/** Rank counted from a side's own back rank: a1 is rank 1 for White, a8 for Black. */
const relativeRank = (square, color) => (color === 'w' ? rankOf(square) : 9 - rankOf(square));

/** Collect { color, type, square } for every occupied square. */
function listPieces(chess) {
  const out = [];
  for (const row of chess.board()) {
    for (const cell of row) {
      if (cell) out.push({ color: cell.color, type: cell.type, square: cell.square });
    }
  }
  return out;
}

function pawnsByFile(pieces) {
  const map = { w: Array.from({ length: 8 }, () => []), b: Array.from({ length: 8 }, () => []) };
  for (const piece of pieces) {
    if (piece.type === 'p') map[piece.color][fileIndex(piece.square)].push(piece.square);
  }
  return map;
}

/** A pawn of `color` attacks these squares. */
function pawnAttacks(square, color) {
  const f = fileIndex(square);
  const r = rankOf(square) + (color === 'w' ? 1 : -1);
  if (r < 1 || r > 8) return [];
  return [f - 1, f + 1].filter((x) => x >= 0 && x < 8).map((x) => `${FILES[x]}${r}`);
}

export function analysePosition(chess) {
  const pieces = listPieces(chess);
  const pawns = pawnsByFile(pieces);
  const occupied = new Map(pieces.map((p) => [p.square, p]));

  const files = FILES.split('').map((name, index) => {
    const white = pawns.w[index].length;
    const black = pawns.b[index].length;
    return {
      name,
      index,
      whitePawns: white,
      blackPawns: black,
      open: white === 0 && black === 0,
      halfOpenFor: white === 0 && black > 0 ? 'w' : black === 0 && white > 0 ? 'b' : null,
    };
  });

  const rooks = pieces
    .filter((p) => p.type === 'r' || p.type === 'q')
    .map((p) => {
      const file = files[fileIndex(p.square)];
      return {
        ...p,
        onOpenFile: file.open,
        onHalfOpenFile: file.halfOpenFor === p.color,
        onSeventh: p.type === 'r' && relativeRank(p.square, p.color) === 7,
      };
    });

  const knights = pieces
    .filter((p) => p.type === 'n')
    .map((p) => ({ ...p, outpost: isOutpost(p.square, p.color, pieces) }));

  const structure = { w: pawnStructure('w', pawns, pieces), b: pawnStructure('b', pawns, pieces) };

  const bishops = { w: 0, b: 0 };
  for (const piece of pieces) if (piece.type === 'b') bishops[piece.color] += 1;

  const material = { w: 0, b: 0 };
  for (const piece of pieces) material[piece.color] += PIECE_VALUE[piece.type];

  return {
    files,
    rooks,
    knights,
    structure,
    bishopPair: { w: bishops.w >= 2, b: bishops.b >= 2 },
    material,
    materialBalance: material.w - material.b,
    kingSafety: { w: kingSafety(chess, 'w', pieces, files), b: kingSafety(chess, 'b', pieces, files) },
    mobility: { w: mobilityFor(chess, 'w'), b: mobilityFor(chess, 'b') },
    phase: gamePhase(pieces),
    occupied,
  };
}

/**
 * A knight sits on an outpost when it stands in enemy territory, a friendly pawn
 * defends it, and no enemy pawn can ever chase it away.
 */
function isOutpost(square, color, pieces) {
  const rank = relativeRank(square, color);
  if (rank < 4 || rank > 6) return false;

  const defended = pieces.some(
    (p) => p.type === 'p' && p.color === color && pawnAttacks(p.square, color).includes(square),
  );
  if (!defended) return false;

  // Any enemy pawn still on an adjacent file that has not yet passed the square
  // could advance to attack it.
  const enemy = color === 'w' ? 'b' : 'w';
  const f = fileIndex(square);
  const r = rankOf(square);
  const attackable = pieces.some((p) => {
    if (p.type !== 'p' || p.color !== enemy) return false;
    if (Math.abs(fileIndex(p.square) - f) !== 1) return false;
    return color === 'w' ? rankOf(p.square) > r : rankOf(p.square) < r;
  });
  return !attackable;
}

function pawnStructure(color, pawns, pieces) {
  const own = pawns[color];
  const enemy = pawns[color === 'w' ? 'b' : 'w'];
  const isolated = [];
  const doubled = [];
  const passed = [];
  const backward = [];

  for (let f = 0; f < 8; f += 1) {
    if (!own[f].length) continue;
    const neighbours = (own[f - 1]?.length ?? 0) + (own[f + 1]?.length ?? 0);
    if (neighbours === 0) isolated.push(...own[f]);
    if (own[f].length > 1) doubled.push(...own[f]);

    for (const square of own[f]) {
      const r = rankOf(square);
      const ahead = (list) =>
        list.some((sq) => (color === 'w' ? rankOf(sq) > r : rankOf(sq) < r));
      const blocked = ahead(enemy[f] ?? []) || ahead(enemy[f - 1] ?? []) || ahead(enemy[f + 1] ?? []);
      if (!blocked) passed.push(square);

      // Backward: no friendly pawn on an adjacent file is level with or behind it,
      // and the square in front is covered by an enemy pawn.
      const supported = [own[f - 1] ?? [], own[f + 1] ?? []].some((list) =>
        list.some((sq) => (color === 'w' ? rankOf(sq) <= r : rankOf(sq) >= r)),
      );
      const front = `${FILES[f]}${color === 'w' ? r + 1 : r - 1}`;
      const contested = pieces.some(
        (p) =>
          p.type === 'p' &&
          p.color !== color &&
          pawnAttacks(p.square, p.color).includes(front),
      );
      if (!supported && contested) backward.push(square);
    }
  }

  return { isolated, doubled, passed, backward, count: own.flat().length };
}

function kingSafety(chess, color, pieces, files) {
  const king = pieces.find((p) => p.type === 'k' && p.color === color);
  if (!king) return { square: null, shield: 0, openFilesNearby: 0, castled: false };

  const f = fileIndex(king.square);
  const r = rankOf(king.square);
  let shield = 0;
  for (let df = -1; df <= 1; df += 1) {
    const nf = f + df;
    if (nf < 0 || nf > 7) continue;
    for (let step = 1; step <= 2; step += 1) {
      const nr = color === 'w' ? r + step : r - step;
      if (nr < 1 || nr > 8) continue;
      const piece = pieces.find((p) => p.square === `${FILES[nf]}${nr}`);
      if (piece?.type === 'p' && piece.color === color) {
        shield += step === 1 ? 1 : 0.5;
        break;
      }
    }
  }

  let openFilesNearby = 0;
  for (let df = -1; df <= 1; df += 1) {
    const file = files[f + df];
    if (file && (file.open || file.halfOpenFor === (color === 'w' ? 'b' : 'w'))) openFilesNearby += 1;
  }

  return {
    square: king.square,
    shield,
    openFilesNearby,
    castled: relativeRank(king.square, color) === 1 && (f <= 2 || f >= 6),
  };
}

/** Pseudo-mobility: legal moves for `color`, obtained by handing the side the move. */
function mobilityFor(chess, color) {
  if (chess.turn() === color) return chess.moves().length;
  const parts = chess.fen().split(' ');
  parts[1] = color;
  parts[3] = '-'; // an en-passant square is illegal for the other side to inherit
  try {
    return new Chess(parts.join(' ')).moves().length;
  } catch {
    return 0; // e.g. the side to move is already giving check — no legal probe position
  }
}

function gamePhase(pieces) {
  const heavy = pieces.filter((p) => 'qrbn'.includes(p.type)).length;
  if (heavy >= 12) return 'opening';
  if (heavy >= 6) return 'middlegame';
  return 'endgame';
}

// --- explaining a move ------------------------------------------------------

/**
 * Compare the position before and after a move and name what it achieved.
 * Returns short clauses meant to be joined into a sentence.
 */
export function describeMove(before, after, move, chessAfter) {
  const notes = [];
  const color = move.color;
  const them = color === 'w' ? 'b' : 'w';
  const side = color === 'w' ? 'White' : 'Black';

  // Checkmate ends the game, so nothing else about the move matters. Listing
  // pawn structure next to "delivers checkmate" reads as noise.
  if (move.san.includes('#')) {
    return {
      side,
      notes: move.captured
        ? [`delivers checkmate, capturing the ${pieceName(move.captured)}`]
        : ['delivers checkmate'],
    };
  }

  if (move.flags.includes('k')) notes.push('castles kingside, tucking the king away');
  if (move.flags.includes('q')) notes.push('castles queenside');
  if (move.san.includes('+')) notes.push('gives check');

  if (move.captured) {
    const gained = PIECE_VALUE[move.captured];
    const risked = PIECE_VALUE[move.piece];
    if (gained > risked + 0.5) notes.push(`wins material — takes the ${pieceName(move.captured)}`);
    else notes.push(`captures the ${pieceName(move.captured)}`);
  }

  if (move.promotion) notes.push(`promotes to a ${pieceName(move.promotion)}`);

  // Rook activity
  if (move.piece === 'r') {
    const landed = after.rooks.find((r) => r.square === move.to);
    const departed = before.rooks.find((r) => r.square === move.from);
    if (landed?.onOpenFile && !departed?.onOpenFile) {
      notes.push(`takes the open ${move.to[0]}-file`);
    } else if (landed?.onHalfOpenFile && !departed?.onHalfOpenFile) {
      notes.push(`puts the rook on the half-open ${move.to[0]}-file`);
    }
    if (landed?.onSeventh && !departed?.onSeventh) {
      notes.push('lands the rook on the seventh rank');
    }
    const stacked = after.rooks.filter(
      (r) => r.color === color && r.type === 'r' && fileIndex(r.square) === fileIndex(move.to),
    );
    if (stacked.length > 1) notes.push('doubles the rooks');
  }

  // Knight play
  if (move.piece === 'n') {
    const landed = after.knights.find((n) => n.square === move.to);
    if (landed?.outpost) notes.push(`plants the knight on the ${move.to} outpost, where no pawn can dislodge it`);
  }

  // Structural consequences
  const passedBefore = before.structure[color].passed.length;
  const passedAfter = after.structure[color].passed.length;
  if (passedAfter > passedBefore) notes.push('creates a passed pawn');

  const theirIsolatedBefore = before.structure[them].isolated.length;
  const theirIsolatedAfter = after.structure[them].isolated.length;
  if (theirIsolatedAfter > theirIsolatedBefore) notes.push("leaves the opponent with an isolated pawn");

  if (before.bishopPair[them] && !after.bishopPair[them]) {
    notes.push('breaks up the enemy bishop pair');
  }

  // File opening
  const openedFiles = after.files.filter((f, i) => f.open && !before.files[i].open);
  for (const file of openedFiles) notes.push(`opens the ${file.name}-file`);

  // Activity swing
  const gain = after.mobility[color] - before.mobility[color];
  if (gain >= 6) notes.push('sharply increases the activity of the pieces');

  const enemyKing = after.kingSafety[them];
  if (enemyKing.openFilesNearby > before.kingSafety[them].openFilesNearby) {
    notes.push('pries open lines toward the enemy king');
  }

  if (chessAfter?.isStalemate?.()) notes.push('stalemates the opponent');

  return { side, notes };
}

function pieceName(type) {
  return { p: 'pawn', n: 'knight', b: 'bishop', r: 'rook', q: 'queen', k: 'king' }[type] ?? type;
}

/** A short, static read of the position — used for the positional-judgement mode. */
export function summarisePosition(features) {
  const points = [];

  const openFiles = features.files.filter((f) => f.open).map((f) => f.name);
  if (openFiles.length) {
    points.push(`Open file${openFiles.length > 1 ? 's' : ''}: ${openFiles.join(', ')}.`);
  }

  for (const color of ['w', 'b']) {
    const side = color === 'w' ? 'White' : 'Black';
    const rooksOnFiles = features.rooks.filter(
      (r) => r.color === color && r.type === 'r' && (r.onOpenFile || r.onHalfOpenFile),
    );
    if (rooksOnFiles.length) {
      points.push(`${side} rook${rooksOnFiles.length > 1 ? 's' : ''} on ${rooksOnFiles.map((r) => r.square).join(' and ')} control open lines.`);
    }
    const outposts = features.knights.filter((n) => n.color === color && n.outpost);
    if (outposts.length) {
      points.push(`${side} has a secure knight on ${outposts.map((n) => n.square).join(', ')}.`);
    }
    const { passed, isolated, backward } = features.structure[color];
    if (passed.length) points.push(`${side} has a passed pawn on ${passed.join(', ')}.`);
    if (isolated.length) points.push(`${side}'s pawn${isolated.length > 1 ? 's' : ''} on ${isolated.join(', ')} ${isolated.length > 1 ? 'are' : 'is'} isolated.`);
    if (backward.length) points.push(`${side} has a backward pawn on ${backward.join(', ')}.`);
  }

  if (features.bishopPair.w !== features.bishopPair.b) {
    points.push(`${features.bishopPair.w ? 'White' : 'Black'} holds the bishop pair.`);
  }

  const balance = features.materialBalance;
  if (Math.abs(balance) >= 0.75) {
    points.push(`Material: ${balance > 0 ? 'White' : 'Black'} is up roughly ${Math.abs(balance).toFixed(2).replace(/\.?0+$/, '')} points.`);
  } else {
    points.push('Material is level.');
  }

  const activity = features.mobility.w - features.mobility.b;
  if (Math.abs(activity) >= 6) {
    points.push(`${activity > 0 ? 'White' : 'Black'} has noticeably more active pieces (${features.mobility.w} vs ${features.mobility.b} legal moves).`);
  }

  return points;
}
