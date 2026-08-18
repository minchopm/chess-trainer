// Endgame drills. You play the position out against Stockfish and must actually
// achieve the result — the engine defends properly, so knowing the idea is not
// the same as executing it. After every move the trainer checks whether the
// result is still reachable and tells you the moment it stops being.

import { Chess } from '/vendor/chess.mjs';
import { destinationsFor, checkSquare, uciToMove } from '../coach.js';
import { formatScore } from '../engine.js';
import { recordAttempt, getState } from '../store.js';
import { button, card, el, feedback, fill, tags } from '../ui.js';

const ENGINE_DEPTH = 16;

export function createEndgameMode(context) {
  const { board, panel, controls, evalBar, engine, data } = context;

  let drill = null;
  let chess = null;
  let userColor = 'w';
  let finished = false;
  let thinking = false;
  let plies = 0;
  let lostAt = null;

  function pick() {
    const pool = data.endgames;
    if (!pool?.length) return null;
    const rating = getState().ratings.endgame;
    const sorted = [...pool].sort(
      (a, b) => Math.abs(a.rating - rating) - Math.abs(b.rating - rating),
    );
    // Pick randomly from the five closest so the same drill doesn't repeat.
    return sorted[Math.floor(Math.random() * Math.min(5, sorted.length))];
  }

  function load(next) {
    drill = next;
    if (!drill) {
      fill(panel, card('No drills found', [el('p', { class: 'subtle', text: 'data/endgames.json is missing or empty.' })]));
      return;
    }

    chess = new Chess(drill.fen);
    userColor = chess.turn();
    finished = false;
    thinking = false;
    plies = 0;
    lostAt = null;

    board.clearShapes();
    board.setOrientation(userColor === 'w' ? 'white' : 'black');
    board.setPosition(chess.fen(), { animate: false, check: checkSquare(chess) });
    board.setMovable(destinationsFor(chess, userColor));
    evalBar.show();
    evalBar.set({ cp: 0, mate: null });
    render();
    updateEval();
  }

  function goalText() {
    return drill.goal === 'win'
      ? `Win as ${userColor === 'w' ? 'White' : 'Black'}.`
      : `Hold the draw as ${userColor === 'w' ? 'White' : 'Black'}.`;
  }

  function render(extra = null) {
    fill(panel, 
      card(null, [
        el('p', { class: 'prompt', text: drill.name }),
        el('p', { class: 'subtle', text: goalText() }),
        el('div', { class: 'tag-row' }, [
          el('span', { class: 'tag', text: `Rating ${drill.rating}` }),
          el('span', { class: 'tag', text: drill.goal === 'win' ? 'Must win' : 'Must draw' }),
          el('span', { class: 'tag', text: `${Math.ceil(plies / 2)} move${Math.ceil(plies / 2) === 1 ? '' : 's'} played` }),
        ]),
        extra,
      ]),
      card('The idea', [el('p', { class: 'subtle', text: drill.idea })]),
      drill.themes?.length ? tags(drill.themes) : null,
    );

    fill(controls, 
      button('Restart drill', () => load(drill), { disabled: thinking }),
      button('Flip board', () => board.flip()),
      button('Next drill →', () => next(), { primary: finished }),
    );
  }

  async function updateEval() {
    if (chess.isGameOver()) {
      evalBar.set(chess.isCheckmate() ? { cp: null, mate: chess.turn() === 'w' ? -1 : 1 } : { cp: 0, mate: null });
      return null;
    }
    const analysis = await engine.analyse(chess.fen(), { depth: 12, multipv: 1 });
    const score = analysis.lines[0]?.score ?? null;
    evalBar.set(score);
    return score;
  }

  /** Score from the trainee's point of view, mates flattened to a big number. */
  function userCp(score) {
    if (!score) return 0;
    const sign = userColor === 'w' ? 1 : -1;
    if (score.mate != null) return sign * score.mate > 0 ? 10_000 : -10_000;
    return score.cp * sign;
  }

  async function handleMove(from, to, promotion) {
    if (finished || thinking || chess.turn() !== userColor) return;

    let move;
    try {
      move = chess.move({ from, to, promotion });
    } catch {
      return;
    }
    if (!move) return;
    plies += 1;
    board.setPosition(chess.fen(), { lastMove: [from, to], check: checkSquare(chess) });
    board.setMovable(new Map());

    if (checkOutcome()) return;

    thinking = true;
    render(el('p', { class: 'subtle', text: 'Engine is thinking…' }));

    const score = await updateEval();
    const cp = userCp(score);

    // Has the goal just become unreachable?
    if (!lostAt) {
      if (drill.goal === 'win' && cp < 180) lostAt = { move: move.san, cp, reason: 'the win is gone' };
      if (drill.goal === 'draw' && cp < -300) lostAt = { move: move.san, cp, reason: 'the draw is gone' };
    }

    const reply = await engine.pickMove(chess.fen(), { depth: ENGINE_DEPTH });
    if (reply) {
      const replyMove = uciToMove(chess.fen(), reply);
      chess.move({ from: reply.slice(0, 2), to: reply.slice(2, 4), promotion: reply[4] });
      plies += 1;
      board.setPosition(chess.fen(), {
        lastMove: [reply.slice(0, 2), reply.slice(2, 4)],
        check: checkSquare(chess),
      });
      void replyMove;
    }

    thinking = false;
    await updateEval();

    if (checkOutcome()) return;

    board.setMovable(destinationsFor(chess, userColor));

    if (plies > 160) {
      conclude(drill.goal === 'draw', 'The 80-move limit ran out.');
      return;
    }

    render(
      lostAt
        ? feedback('wrong', `${lostAt.move} threw it away`, [
            `After that move ${lostAt.reason} — the evaluation is now ${(lostAt.cp / 100).toFixed(2)} from your side. ` +
              'Play on if you like, or restart and try the correct plan.',
          ])
        : null,
    );
  }

  /** @returns true when the drill has ended. */
  function checkOutcome() {
    if (!chess.isGameOver()) return false;

    if (chess.isCheckmate()) {
      const winner = chess.turn() === 'w' ? 'b' : 'w';
      conclude(winner === userColor && drill.goal === 'win',
        winner === userColor ? 'Checkmate — you delivered it.' : 'You were checkmated.');
      return true;
    }

    const how = chess.isStalemate()
      ? 'Stalemate.'
      : chess.isInsufficientMaterial()
        ? 'Insufficient material.'
        : chess.isThreefoldRepetition()
          ? 'Threefold repetition.'
          : 'Fifty-move rule.';
    conclude(drill.goal === 'draw', how);
    return true;
  }

  function conclude(success, how) {
    finished = true;
    thinking = false;
    board.setMovable(new Map());

    recordAttempt({
      mode: 'endgame',
      puzzleId: drill.id,
      puzzleRating: drill.rating,
      correct: success,
      themes: drill.themes ?? [],
    });

    render(
      feedback(success ? 'correct' : 'wrong', success ? 'Drill passed' : 'Drill failed', [
        `${how} ${success ? 'That is the result you needed.' : `You needed to ${drill.goal === 'win' ? 'win' : 'draw'} this.`}`,
        lostAt && !success ? `It went wrong at ${lostAt.move}.` : null,
        drill.idea,
      ].filter(Boolean)),
    );
  }

  function next() {
    load(pick());
  }

  return {
    mount: () => next(),
    unmount: () => {},
    handleMove,
    next,
  };
}
