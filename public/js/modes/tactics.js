// Tactics trainer: one position, one winning idea, immediate feedback.

import { Chess } from '/vendor/chess.mjs';
import { destinationsFor, checkSquare, formatPv } from '../coach.js';
import { analysePosition, describeMove } from '../features.js';
import { recordAttempt, getState, dueCardIds, isSeen, isMotif, trainingTargets } from '../store.js';
import { button, card, el, feedback, humanise, tags, fill } from '../ui.js';

export function createTacticsMode(context) {
  const { board, panel, controls, evalBar, data } = context;

  let puzzle = null;
  let chess = null;
  let step = 0;
  let mistakes = 0;
  let hintLevel = 0;
  let finished = false;
  let reason = null;

  /** How often a puzzle is chosen to attack a weakness rather than at random. */
  const TARGET_SHARE = 0.6;

  const sample = (list) => list[Math.floor(Math.random() * list.length)];

  /**
   * Choose the next puzzle, and say why it was chosen.
   *
   * Three mechanisms, in order of precedence:
   *   1. Spaced repetition — anything due comes back first.
   *   2. Weakness targeting — most of the rest are drawn from motifs you are
   *      measurably worse at than your own average.
   *   3. Difficulty tracking — everything stays near your rating, aimed slightly
   *      above it.
   *
   * Targeting is deliberately not applied every time. Drilling only your weak
   * motifs stops measuring the rest, and the rating would drift on stale data.
   */
  function pickPuzzle() {
    const puzzles = data.tactics;
    if (!puzzles?.length) return null;

    const due = new Set(dueCardIds());
    const dueOnes = puzzles.filter((p) => due.has(p.id));
    if (dueOnes.length) {
      return { puzzle: sample(dueOnes), reason: { kind: 'review' } };
    }

    const rating = getState().ratings.tactics;
    const target = rating + 60;

    const inRange = (window) =>
      puzzles.filter((p) => Math.abs(p.rating - target) <= window && !isSeen(p.id));

    const targets = trainingTargets();
    if (targets.length && Math.random() < TARGET_SHARE) {
      const wanted = new Set(targets.map((t) => t.name));
      for (const window of [250, 450, 800]) {
        const pool = inRange(window).filter((p) => p.themes.some((theme) => wanted.has(theme)));
        if (pool.length) {
          const chosen = sample(pool);
          const motif = targets.find((t) => chosen.themes.includes(t.name));
          return { puzzle: chosen, reason: { kind: 'weakness', motif } };
        }
      }
    }

    for (const window of [150, 300, 500, 1200]) {
      const pool = inRange(window);
      if (pool.length) return { puzzle: sample(pool), reason: { kind: 'level' } };
    }
    return { puzzle: sample(puzzles), reason: { kind: 'level' } };
  }

  function load(next) {
    puzzle = next?.puzzle ?? null;
    reason = next?.reason ?? null;
    if (!puzzle) {
      renderEmpty();
      return;
    }
    chess = new Chess(puzzle.fen);
    step = 0;
    mistakes = 0;
    hintLevel = 0;
    finished = false;

    board.clearShapes();
    board.setOrientation(chess.turn() === 'w' ? 'white' : 'black');
    board.setPosition(chess.fen(), { animate: false, check: checkSquare(chess) });
    board.setMovable(destinationsFor(chess));
    evalBar.hide();
    render();
  }

  function renderEmpty() {
    fill(panel, 
      card('No puzzles yet', [
        el('p', { class: 'subtle', html:
          'The puzzle file is empty. Generate a set with <code>npm run generate</code>, ' +
          'or import the Lichess database with <code>npm run import-lichess</code>.' }),
      ]),
    );
  }

  function whyThisPuzzle() {
    const text = explainChoice(reason);
    return text ? el('p', { class: 'subtle', text }) : null;
  }

  /** Always names the side that had to find the move, even after it is played. */
  function sideToMoveLabel() {
    const side = (puzzle.sideToMove ?? puzzle.fen.split(' ')[1]) === 'w' ? 'White' : 'Black';
    return finished ? `${side} to play — solution` : `${side} to play`;
  }

  function render(extra = null) {
    const objective = describeObjective(puzzle);

    fill(panel,
      card(null, [
        el('p', { class: 'prompt', text: sideToMoveLabel() }),
        el('p', { class: 'subtle', text: objective }),
        el('div', { class: 'tag-row' }, [
          el('span', { class: 'tag', text: `Rating ${puzzle.rating}` }),
          el('span', { class: 'tag', text: `${Math.ceil(puzzle.solution.length / 2)} move${puzzle.solution.length > 2 ? 's' : ''}` }),
          finished ? el('span', { class: 'tag', text: puzzle.id }) : null,
        ]),
        whyThisPuzzle(),
        extra,
      ]),
    );

    fill(controls, 
      button('Hint', onHint, { disabled: finished }),
      button('Show solution', onReveal, { disabled: finished }),
      button('Flip board', () => board.flip()),
      button(finished ? 'Next puzzle →' : 'Skip', () => next(), { primary: finished }),
    );
  }

  function onHint() {
    if (finished) return;
    hintLevel += 1;
    const uci = puzzle.solution[step];
    board.clearShapes();
    if (hintLevel === 1) {
      board.drawCircle(uci.slice(0, 2), '#5b9bd5');
      const piece = chess.get(uci.slice(0, 2));
      render(el('p', { class: 'subtle', text: `Move the ${pieceName(piece?.type)} on ${uci.slice(0, 2)}.` }));
    } else {
      board.drawArrow(uci.slice(0, 2), uci.slice(2, 4), '#ddb45a');
      render(el('p', { class: 'subtle', text: 'That is the move — play it on the board.' }));
    }
  }

  function onReveal() {
    if (finished) return;
    finish(false, { revealed: true });
  }

  async function handleMove(from, to, promotion) {
    if (finished || !puzzle) return;

    const expected = puzzle.solution[step];
    const attempted = `${from}${to}${promotion ?? ''}`;

    // Compare against the recorded move, tolerating a missing promotion suffix.
    if (attempted !== expected && `${from}${to}` !== expected.slice(0, 4)) {
      onWrong(from, to, promotion);
      return;
    }

    playMove(expected);
    step += 1;

    if (step >= puzzle.solution.length) {
      finish(true);
      return;
    }

    // The opponent's reply is part of the puzzle; play it after a beat so the
    // board reads as a sequence rather than a jump.
    board.setMovable(new Map());
    await wait(280);
    playMove(puzzle.solution[step]);
    step += 1;

    if (step >= puzzle.solution.length) {
      finish(true);
      return;
    }
    board.setMovable(destinationsFor(chess));
    render(el('p', { class: 'subtle', text: 'Good — keep going.' }));
  }

  function onWrong(from, to, promotion) {
    mistakes += 1;
    const probe = new Chess(chess.fen());
    let attempted = null;
    try {
      attempted = probe.move({ from, to, promotion });
    } catch {
      /* ignore — the board only offers legal moves */
    }

    board.setPosition(chess.fen(), { animate: true, check: checkSquare(chess) });
    board.setMovable(destinationsFor(chess));

    render(
      feedback('wrong', `${attempted?.san ?? 'That move'} is not the one`, [
        mistakes === 1
          ? 'There is a stronger move here. Look for the most forcing option — checks, captures and threats first.'
          : 'Still not it. Try a hint, or reveal the solution and study the idea.',
      ]),
    );
  }

  function playMove(uci) {
    chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    board.setPosition(chess.fen(), {
      lastMove: [uci.slice(0, 2), uci.slice(2, 4)],
      check: checkSquare(chess),
    });
  }

  function finish(success, { revealed = false } = {}) {
    finished = true;
    board.setMovable(new Map());
    board.clearShapes();

    // Play out the remainder so the whole idea is visible on the board.
    while (step < puzzle.solution.length) {
      playMove(puzzle.solution[step]);
      step += 1;
    }

    const counted = success && !revealed;
    recordAttempt({
      mode: 'tactics',
      puzzleId: puzzle.id,
      puzzleRating: puzzle.rating,
      correct: counted && mistakes === 0,
      themes: puzzle.themes,
      hinted: hintLevel > 0,
    });

    const heading = revealed
      ? 'Solution'
      : mistakes === 0
        ? 'Solved'
        : 'Solved, but not first time';

    render(
      el('div', {}, [
        feedback(counted && mistakes === 0 ? 'correct' : revealed ? 'wrong' : 'partial', heading, [
          el('p', { html: `<strong>${formatPv(puzzle.fen, puzzle.solution, 9)}</strong>` }),
          ...explain().map((line) => el('p', { text: line })),
        ]),
        tags([...puzzle.themes.filter(isMotif), ...puzzle.themes.filter((x) => !isMotif(x))].slice(0, 7)),
      ]),
    );
  }

  /** Narrate the solver's moves using the positional feature layer. */
  function explain() {
    const lines = [];
    const replay = new Chess(puzzle.fen);
    for (const [index, uci] of puzzle.solution.entries()) {
      const before = analysePosition(replay);
      const move = replay.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
      if (index % 2 !== 0) continue;
      const { notes } = describeMove(before, analysePosition(replay), move, replay);
      if (notes.length) lines.push(`${move.san} — ${notes.join(', ')}.`);
    }
    if (!lines.length && puzzle.mate) lines.push('The line ends in forced mate.');
    return lines;
  }

  function next() {
    load(pickPuzzle());
  }

  return {
    mount: () => next(),
    unmount: () => { evalBar.show(); },
    handleMove,
    next,
  };
}

/**
 * What the puzzle is asking for, in one line. Reads both the theme vocabulary
 * the miner produces and Lichess', since a merged set contains both.
 */
/**
 * Say why this puzzle came up. The selection is doing real work on your history;
 * showing that turns it from an opaque shuffle into something you can trust and
 * argue with.
 */
function explainChoice(reason) {
  if (!reason) return null;
  if (reason.kind === 'review') return 'Review — you have seen this one before.';
  if (reason.kind === 'weakness' && reason.motif) {
    const percent = Math.round(reason.motif.accuracy * 100);
    return `Chosen for you: ${humanise(reason.motif.name).toLowerCase()} — ${percent}% of ${reason.motif.seen} so far.`;
  }
  return null;
}

function describeObjective(puzzle) {
  const themes = new Set(puzzle.themes);
  if (puzzle.mate || themes.has('mate')) {
    const inN = puzzle.themes.find((theme) => /^mateIn\d+$/.test(theme));
    return inN ? `Mate in ${inN.replace('mateIn', '')}.` : 'Find the forced mate.';
  }
  if (themes.has('defensiveMove') || themes.has('equality')) return 'Find the move that saves the position.';
  if (themes.has('crushing')) return 'Find the crushing blow.';
  if (themes.has('winsMaterial') || themes.has('hangingPiece')) return 'Win material.';
  if (themes.has('advantage')) return 'Find the move that wins a clear advantage.';
  return 'Find the strongest continuation.';
}

function pieceName(type) {
  return { p: 'pawn', n: 'knight', b: 'bishop', r: 'rook', q: 'queen', k: 'king' }[type] ?? 'piece';
}

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
