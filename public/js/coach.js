// The coaching layer: turns raw engine output into a judgement and an
// explanation a human can act on.

import { Chess } from '/vendor/chess.mjs';
import { winProbability, formatScore } from './engine.js';
import { analysePosition, describeMove } from './features.js';

/** Convert a UCI move string into a chess.js move object without mutating `chess`. */
export function uciToMove(fen, uci) {
  if (!uci || uci.length < 4) return null;
  const probe = new Chess(fen);
  try {
    return probe.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
  } catch {
    return null;
  }
}

export function moveToUci(move) {
  return `${move.from}${move.to}${move.promotion ?? ''}`;
}

/** Render a UCI principal variation as SAN, e.g. "1.Rd1 Qc7 2.Rd7". */
export function pvToSan(fen, pv, limit = 8) {
  const probe = new Chess(fen);
  const out = [];
  for (const uci of pv.slice(0, limit)) {
    const number = probe.moveNumber(); // read before the move, which increments it
    let move;
    try {
      move = probe.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
    if (!move) break;
    out.push({ san: move.san, color: move.color, number });
  }
  return out;
}

export function formatPv(fen, pv, limit = 8) {
  const moves = pvToSan(fen, pv, limit);
  let text = '';
  for (const [index, move] of moves.entries()) {
    if (move.color === 'w') text += `${move.number}.${move.san} `;
    else text += index === 0 ? `${move.number}...${move.san} ` : `${move.san} `;
  }
  return text.trim();
}

const GRADES = [
  { id: 'best', label: 'Best move', maxLoss: 0.005 },
  { id: 'excellent', label: 'Excellent', maxLoss: 0.02 },
  { id: 'good', label: 'Good', maxLoss: 0.05 },
  { id: 'inaccuracy', label: 'Inaccuracy', maxLoss: 0.1 },
  { id: 'mistake', label: 'Mistake', maxLoss: 0.2 },
  { id: 'blunder', label: 'Blunder', maxLoss: Infinity },
];

/**
 * Grade a move by how much win probability it threw away, not by raw centipawns.
 * Losing 100cp when you are already winning by a queen barely matters; losing it
 * in a level position is decisive. Win probability captures that; centipawns don't.
 */
export function gradeMove({ scoreBefore, scoreAfter, moverColor, wasEngineTop }) {
  const before = perspectiveCp(scoreBefore, moverColor);
  const after = perspectiveCp(scoreAfter, moverColor);
  const loss = Math.max(0, winProbability(before) - winProbability(after));
  const grade = wasEngineTop ? GRADES[0] : GRADES.find((g) => loss <= g.maxLoss);
  return {
    id: grade.id,
    label: grade.label,
    winProbLoss: loss,
    cpLoss: Math.max(0, before - after),
  };
}

/** Score from the mover's point of view, with mates mapped onto a large centipawn value. */
function perspectiveCp(score, color) {
  if (!score) return 0;
  const sign = color === 'w' ? 1 : -1;
  if (score.mate != null) return sign * score.mate > 0 ? 10000 : -10000;
  return score.cp * sign;
}

/**
 * Full review of one move: what it was worth, what the engine preferred, and a
 * plain-language reason drawn from the positional features.
 */
export async function reviewMove(engine, fenBefore, move, { depth = 14, multipv = 2 } = {}) {
  const chessBefore = new Chess(fenBefore);
  const before = analysePosition(chessBefore);

  const analysisBefore = await engine.analyse(fenBefore, { depth, multipv });
  const bestUci = analysisBefore.lines[0]?.move ?? analysisBefore.best;
  const scoreBefore = analysisBefore.lines[0]?.score ?? null;

  const chessAfter = new Chess(fenBefore);
  const played = chessAfter.move({ from: move.from, to: move.to, promotion: move.promotion });
  const fenAfter = chessAfter.fen();
  const after = analysePosition(chessAfter);

  const wasEngineTop = bestUci === moveToUci(played);

  let scoreAfter = scoreBefore;
  if (!wasEngineTop) {
    const analysisAfter = await engine.analyse(fenAfter, { depth, multipv: 1 });
    scoreAfter = analysisAfter.terminal
      ? terminalScore(chessAfter)
      : analysisAfter.lines[0]?.score ?? scoreBefore;
  }

  const grade = gradeMove({
    scoreBefore,
    scoreAfter,
    moverColor: played.color,
    wasEngineTop,
  });

  const { notes } = describeMove(before, after, played, chessAfter);
  const bestMove = wasEngineTop ? null : uciToMove(fenBefore, bestUci);
  let bestReason = null;
  if (bestMove) {
    const chessBest = new Chess(fenBefore);
    chessBest.move({ from: bestMove.from, to: bestMove.to, promotion: bestMove.promotion });
    bestReason = describeMove(before, analysePosition(chessBest), bestMove, chessBest).notes;
  }

  return {
    played,
    grade,
    scoreBefore,
    scoreAfter,
    bestUci,
    bestSan: bestMove?.san ?? played.san,
    bestPv: analysisBefore.lines[0]?.pv ?? [],
    notes,
    bestReason,
    text: buildExplanation({ played, grade, notes, bestSan: bestMove?.san, bestReason, scoreAfter }),
  };
}

function terminalScore(chess) {
  if (chess.isCheckmate()) return { cp: null, mate: chess.turn() === 'w' ? -1 : 1 };
  return { cp: 0, mate: null };
}

function joinClauses(clauses) {
  if (!clauses.length) return '';
  if (clauses.length === 1) return clauses[0];
  return `${clauses.slice(0, -1).join(', ')} and ${clauses.at(-1)}`;
}

function buildExplanation({ played, grade, notes, bestSan, bestReason, scoreAfter }) {
  const parts = [];

  if (notes.length) {
    parts.push(`${played.san} ${joinClauses(notes)}.`);
  }

  if (grade.id === 'best' || grade.id === 'excellent') {
    if (!notes.length) parts.push(`${played.san} is what the engine plays too.`);
  } else if (bestSan) {
    const why = bestReason?.length ? ` — it ${joinClauses(bestReason)}` : '';
    const cost =
      grade.cpLoss >= 9000
        ? 'and it throws away a forced mate'
        : `costing about ${(grade.cpLoss / 100).toFixed(2)} pawns`;
    // The grade itself is shown as the heading; don't repeat it in the sentence.
    parts.push(`${bestSan} was stronger${why}, ${cost}.`);
  }

  parts.push(`Evaluation after the move: ${formatScore(scoreAfter)}.`);
  return parts.join(' ');
}

/** Legal-destination map for the board, in the shape Board#setMovable wants. */
export function destinationsFor(chess, color = null) {
  const dests = new Map();
  if (color && chess.turn() !== color) return dests;
  for (const move of chess.moves({ verbose: true })) {
    if (!dests.has(move.from)) dests.set(move.from, []);
    dests.get(move.from).push(move.to);
  }
  return dests;
}

/** The square of the king in check, or null. */
export function checkSquare(chess) {
  if (!chess.isCheck()) return null;
  const turn = chess.turn();
  for (const row of chess.board()) {
    for (const cell of row) {
      if (cell?.type === 'k' && cell.color === turn) return cell.square;
    }
  }
  return null;
}
