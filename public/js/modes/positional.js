// Positional judgement: no forced win, no single tactical shot. First you say
// who stands better and by how much, then you choose a plan. This is the skill
// that separates players who can calculate from players who know what to
// calculate.

import { Chess } from '/vendor/chess.mjs';
import { destinationsFor, checkSquare, formatPv } from '../coach.js';
import { analysePosition, summarisePosition, describeMove } from '../features.js';
import { formatScore, winProbability } from '../engine.js';
import { recordAttempt, getState, isSeen } from '../store.js';
import { append, button, card, el, feedback, fill, tags } from '../ui.js';

const JUDGEMENTS = [
  { id: 'white-clear', label: 'White is clearly better', min: 120, max: Infinity },
  { id: 'white-slight', label: 'White is slightly better', min: 35, max: 120 },
  { id: 'equal', label: 'Balanced', min: -35, max: 35 },
  { id: 'black-slight', label: 'Black is slightly better', min: -120, max: -35 },
  { id: 'black-clear', label: 'Black is clearly better', min: -Infinity, max: -120 },
];

function correctJudgement(cp) {
  return JUDGEMENTS.find((j) => cp >= j.min && cp < j.max) ?? JUDGEMENTS[2];
}

export function createPositionalMode(context) {
  const { board, panel, controls, evalBar, engine, data } = context;

  let exercise = null;
  let chess = null;
  let phase = 'judge'; // judge -> move -> done
  let judgementCorrect = false;
  let moveGrade = null;

  function pick() {
    const pool = data.positions;
    if (!pool?.length) return null;
    const rating = getState().ratings.positional;
    for (const window of [200, 400, 700, 2000]) {
      const near = pool.filter((p) => Math.abs(p.rating - rating) <= window && !isSeen(p.id));
      if (near.length) return near[Math.floor(Math.random() * near.length)];
    }
    return pool[Math.floor(Math.random() * pool.length)];
  }

  function load(next) {
    exercise = next;
    if (!exercise) {
      fill(panel, 
        card('No positional exercises yet', [
          el('p', { class: 'subtle', html:
            'Generate them with <code>npm run generate:positions</code>. They are mined from the ' +
            'same self-play games as the tactics, but filtered for the opposite property: ' +
            'positions where several moves are reasonable and judgement decides.' }),
        ]),
      );
      return;
    }

    chess = new Chess(exercise.fen);
    phase = 'judge';
    judgementCorrect = false;
    moveGrade = null;

    board.clearShapes();
    board.setOrientation(chess.turn() === 'w' ? 'white' : 'black');
    board.setPosition(exercise.fen, { animate: false, check: checkSquare(chess) });
    board.setMovable(new Map());
    evalBar.hide();
    renderJudge();
  }

  function renderJudge() {
    fill(panel, 
      card(null, [
        el('p', { class: 'prompt', text: `${chess.turn() === 'w' ? 'White' : 'Black'} to move — how do you assess this?` }),
        el('p', { class: 'subtle', text: 'No tactics here. Weigh structure, activity, king safety and space.' }),
        el('div', { class: 'choice-list' }, JUDGEMENTS.map((judgement) =>
          el('button', {
            class: 'choice',
            'data-id': judgement.id,
            onClick: () => onJudge(judgement),
          }, [judgement.label]),
        )),
      ]),
    );

    fill(controls, 
      button('Flip board', () => board.flip()),
      button('Skip', () => next()),
    );
  }

  function onJudge(chosen) {
    const truth = correctJudgement(exercise.cp);
    judgementCorrect = chosen.id === truth.id;

    for (const node of panel.querySelectorAll('.choice')) {
      node.disabled = true;
      if (node.dataset.id === truth.id) node.dataset.state = 'correct';
      else if (node.dataset.id === chosen.id) node.dataset.state = 'wrong';
    }

    phase = 'move';
    board.setMovable(destinationsFor(chess));

    const features = analysePosition(chess);
    panel.append(
      feedback(judgementCorrect ? 'correct' : 'partial',
        judgementCorrect ? 'Right read' : `Engine says: ${truth.label.toLowerCase()} (${formatScore({ cp: exercise.cp, mate: null })})`,
        summarisePosition(features).map((line) => el('p', { text: line })),
      ),
      el('p', { class: 'prompt', text: 'Now play the move you would choose.' }),
    );
  }

  async function handleMove(from, to, promotion) {
    if (phase !== 'move') return;

    const probe = new Chess(exercise.fen);
    let move;
    try {
      move = probe.move({ from, to, promotion });
    } catch {
      return;
    }
    if (!move) return;

    board.setPosition(probe.fen(), { lastMove: [from, to], check: checkSquare(probe) });
    board.setMovable(new Map());
    phase = 'done';

    const uci = `${from}${to}${promotion ?? ''}`;
    const known = [exercise.best, ...exercise.alternatives].find((line) => line.uci === uci);

    let playedCp;
    if (known) {
      playedCp = known.cp;
    } else {
      // Not one of the precomputed lines — ask the engine directly.
      const pending = el('p', { class: 'subtle', text: 'Checking your move with the engine…' });
      panel.append(pending);
      const analysis = await engine.analyse(probe.fen(), { depth: 14, multipv: 1 });
      pending.remove();
      const mover = chess.turn();
      const score = analysis.lines[0]?.score;
      playedCp = score
        ? (score.mate != null ? (score.mate > 0 ? 10000 : -10000) : score.cp) * (mover === 'w' ? 1 : -1)
        : 0;
    }

    const bestCp = exercise.best.cp;
    const loss = Math.max(0, winProbability(bestCp) - winProbability(playedCp));
    moveGrade = loss <= 0.02 ? 'correct' : loss <= 0.06 ? 'partial' : 'wrong';

    recordAttempt({
      mode: 'positional',
      puzzleId: exercise.id,
      puzzleRating: exercise.rating,
      correct: judgementCorrect && moveGrade !== 'wrong',
      themes: exercise.themes ?? [],
    });

    renderResult(move, playedCp, loss);
  }

  function renderResult(move, playedCp, loss) {
    const bestMove = new Chess(exercise.fen).move({
      from: exercise.best.uci.slice(0, 2),
      to: exercise.best.uci.slice(2, 4),
      promotion: exercise.best.uci[4],
    });

    const before = analysePosition(new Chess(exercise.fen));
    const afterBest = new Chess(exercise.fen);
    afterBest.move({ from: bestMove.from, to: bestMove.to, promotion: bestMove.promotion });
    const bestNotes = describeMove(before, analysePosition(afterBest), bestMove, afterBest).notes;

    board.clearShapes();
    board.drawArrow(exercise.best.uci.slice(0, 2), exercise.best.uci.slice(2, 4), '#6cbf73');

    const heading =
      moveGrade === 'correct'
        ? `${move.san} — the engine's choice too`
        : moveGrade === 'partial'
          ? `${move.san} is playable`
          : `${move.san} makes it worse`;

    append(panel,
      feedback(moveGrade, heading, [
        moveGrade === 'correct'
          ? null
          : el('p', { html: `Engine prefers <strong>${bestMove.san}</strong>${bestNotes.length ? ` — it ${bestNotes.join(', ')}` : ''}.` }),
        el('p', { text: `Your move: ${(playedCp / 100).toFixed(2)}  ·  best: ${(exercise.best.cp / 100).toFixed(2)}  ·  cost: ${(loss * 100).toFixed(1)}% win probability.` }),
        el('p', { class: 'subtle', text: `Main line: ${formatPv(exercise.fen, exercise.best.pv ?? [exercise.best.uci], 8)}` }),
      ].filter(Boolean)),
      exercise.themes?.length ? tags(exercise.themes) : null,
    );

    fill(controls, 
      button('Next position →', () => next(), { primary: true }),
      button('Flip board', () => board.flip()),
    );
  }

  function next() {
    load(pick());
  }

  return {
    mount: () => next(),
    unmount: () => evalBar.show(),
    handleMove,
    next,
  };
}
