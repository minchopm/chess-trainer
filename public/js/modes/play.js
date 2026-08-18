// Play a full game against Stockfish with a coach looking over your shoulder.
// Every move you make is graded straight away, so the feedback arrives while you
// still remember what you were thinking.

import { Chess } from '/vendor/chess.mjs';
import { destinationsFor, checkSquare, reviewMove, uciToMove, formatPv } from '../coach.js';
import { recordGame } from '../store.js';
import { button, card, el, feedback, fill } from '../ui.js';

const LEVELS = [
  { label: 'Casual', elo: 1400 },
  { label: 'Club', elo: 1800 },
  { label: 'Strong club', elo: 2100 },
  { label: 'Expert', elo: 2400 },
  { label: 'Master', elo: 2700 },
  { label: 'Full strength', elo: null },
];

export function createPlayMode(context) {
  const { board, panel, controls, evalBar, engine } = context;

  let chess = new Chess();
  let userColor = 'w';
  let level = LEVELS[1];
  let coaching = true;
  let busy = false;
  let started = false;
  let reviews = []; // one entry per user move
  let lastReview = null;

  function renderSetup() {
    fill(panel, 
      card('New game', [
        el('p', { class: 'subtle', text: 'The engine plays at the strength you choose. Coaching grades each of your moves as you go.' }),
        el('div', { class: 'level-row' }, [
          el('span', { text: 'Strength' }),
          el('select', {
            onChange: (event) => { level = LEVELS[Number(event.target.value)]; },
          }, LEVELS.map((option, index) =>
            el('option', { value: index, selected: option === level }, [
              option.elo ? `${option.label} (${option.elo})` : option.label,
            ]),
          )),
        ]),
        el('div', { class: 'level-row' }, [
          el('span', { text: 'You play' }),
          el('select', {
            onChange: (event) => { userColor = event.target.value; },
          }, [
            el('option', { value: 'w', selected: true }, ['White']),
            el('option', { value: 'b' }, ['Black']),
          ]),
        ]),
        el('div', { class: 'level-row' }, [
          el('label', {}, [
            el('input', {
              type: 'checkbox',
              checked: coaching,
              onChange: (event) => { coaching = event.target.checked; },
            }),
            ' Coach me after every move',
          ]),
        ]),
        el('div', { class: 'controls' }, [button('Start game', startGame, { primary: true })]),
      ]),
    );
    fill(controls, button('Flip board', () => board.flip()));
  }

  async function startGame() {
    chess = new Chess();
    reviews = [];
    lastReview = null;
    started = true;
    busy = false;

    board.clearShapes();
    board.setOrientation(userColor === 'w' ? 'white' : 'black');
    board.setPosition(chess.fen(), { animate: false });
    evalBar.show();
    evalBar.set({ cp: 20, mate: null });

    await engine.newGame();
    render();

    if (userColor === 'b') await engineMove();
    else board.setMovable(destinationsFor(chess, userColor));
  }

  function render(extra = null) {
    fill(panel, 
      card(null, [
        el('p', { class: 'prompt', text: statusLine() }),
        el('p', { class: 'subtle', text: `Opponent: ${level.elo ? `${level.label} — ${level.elo} Elo` : 'Stockfish, full strength'}` }),
        extra,
      ]),
      lastReview ? reviewCard(lastReview) : null,
      card('Moves', [movelist()]),
    );

    fill(controls, 
      button('Takeback', takeback, { disabled: busy || reviews.length === 0 || chess.isGameOver() }),
      button('Hint', hint, { disabled: busy || chess.isGameOver() }),
      button('Flip board', () => board.flip()),
      button('Resign / new game', () => { started = false; renderSetup(); board.setMovable(new Map()); }),
    );
  }

  function statusLine() {
    if (chess.isCheckmate()) return chess.turn() === userColor ? 'Checkmate — you lost.' : 'Checkmate — you won.';
    if (chess.isDraw()) return 'Draw.';
    if (busy) return 'Engine is thinking…';
    return chess.turn() === userColor ? 'Your move.' : 'Engine to move.';
  }

  function reviewCard(review) {
    const verdict =
      review.grade.id === 'best' || review.grade.id === 'excellent' || review.grade.id === 'good'
        ? 'correct'
        : review.grade.id === 'inaccuracy'
          ? 'partial'
          : 'wrong';
    return card('Coach', [
      feedback(verdict, `${review.played.san} — ${review.grade.label}`, [review.text]),
      review.bestUci && review.grade.id !== 'best'
        ? el('p', { class: 'subtle', text: `Main line: ${formatPv(review.fenBefore, review.bestPv, 6)}` })
        : null,
    ].filter(Boolean));
  }

  function movelist() {
    const history = chess.history({ verbose: true });
    const grid = el('div', { class: 'movelist' });
    for (let i = 0; i < history.length; i += 2) {
      grid.append(el('span', { class: 'num', text: `${i / 2 + 1}.` }));
      for (const ply of [i, i + 1]) {
        const move = history[ply];
        if (!move) {
          grid.append(el('span'));
          continue;
        }
        const review = reviews.find((r) => r.index === ply);
        grid.append(el('span', {
          class: 'mv',
          'data-quality': review?.grade.id ?? '',
          title: review?.text ?? '',
        }, [move.san]));
      }
    }
    return grid;
  }

  async function handleMove(from, to, promotion) {
    if (!started || busy || chess.turn() !== userColor || chess.isGameOver()) return;

    const fenBefore = chess.fen();
    const index = chess.history().length;

    // Claim the turn before mutating, so a duplicated event can't play twice.
    busy = true;
    let move;
    try {
      move = chess.move({ from, to, promotion });
    } catch {
      move = null;
    }
    if (!move) {
      busy = false;
      return;
    }

    board.setPosition(chess.fen(), { lastMove: [from, to], check: checkSquare(chess) });
    board.setMovable(new Map());
    board.clearShapes();
    render();

    if (coaching) {
      try {
        const review = await reviewMove(engine, fenBefore, move, { depth: 14, multipv: 2 });
        review.index = index;
        review.fenBefore = fenBefore;
        reviews.push(review);
        lastReview = review;
        evalBar.set(review.scoreAfter);
      } catch {
        /* a failed review must not break the game */
      }
    }

    if (chess.isGameOver()) {
      busy = false;
      endGame();
      return;
    }

    try {
      await engineMove();
    } catch {
      // Never leave the board frozen on "thinking" if the engine dies.
      busy = false;
      board.setMovable(destinationsFor(chess, userColor));
      render(el('p', { class: 'subtle', text: 'The engine stopped responding. Play your move again, or start a new game.' }));
    }
  }

  async function engineMove() {
    busy = true;
    render();
    const uci = await engine.pickMove(chess.fen(), {
      elo: level.elo,
      depth: level.elo ? 12 : 16,
      movetime: level.elo ? 300 : null,
    });
    if (uci) {
      chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
      board.setPosition(chess.fen(), {
        lastMove: [uci.slice(0, 2), uci.slice(2, 4)],
        check: checkSquare(chess),
      });
    }
    busy = false;

    if (chess.isGameOver()) {
      endGame();
      return;
    }
    board.setMovable(destinationsFor(chess, userColor));
    render();
  }

  async function hint() {
    if (busy || chess.turn() !== userColor) return;
    busy = true;
    render(el('p', { class: 'subtle', text: 'Asking the engine…' }));
    const analysis = await engine.analyse(chess.fen(), { depth: 13, multipv: 1 });
    busy = false;
    const uci = analysis.lines[0]?.move;
    if (uci) {
      board.clearShapes();
      board.drawArrow(uci.slice(0, 2), uci.slice(2, 4), '#5b9bd5', 0.7);
      const move = uciToMove(chess.fen(), uci);
      render(el('p', { class: 'subtle', text: `Engine suggests ${move?.san ?? uci}. Using a hint doesn't count against you — understanding it does.` }));
    } else {
      render();
    }
  }

  function takeback() {
    if (busy || !reviews.length) return;
    chess.undo(); // engine reply
    chess.undo(); // your move
    reviews.pop();
    lastReview = reviews.at(-1) ?? null;
    board.setPosition(chess.fen(), { animate: true, check: checkSquare(chess) });
    board.setMovable(destinationsFor(chess, userColor));
    render();
  }

  function endGame() {
    board.setMovable(new Map());
    const graded = reviews.filter((r) => r.grade);
    const blunders = graded.filter((r) => r.grade.id === 'blunder').length;
    const mistakes = graded.filter((r) => r.grade.id === 'mistake').length;
    const inaccuracies = graded.filter((r) => r.grade.id === 'inaccuracy').length;
    const avgLoss = graded.length
      ? graded.reduce((sum, r) => sum + Math.min(300, r.grade.cpLoss), 0) / graded.length
      : 0;
    // Accuracy in the usual sense: how close the whole game was to engine play.
    const accuracy = Math.round(Math.max(0, 100 - avgLoss / 3));

    const result = chess.isCheckmate()
      ? chess.turn() === userColor ? 'loss' : 'win'
      : 'draw';

    recordGame({ result, accuracy, blunders, opponentElo: level.elo ?? 3190 });

    render(
      feedback(result === 'win' ? 'correct' : result === 'draw' ? 'partial' : 'wrong',
        `Game over — ${result === 'win' ? 'you won' : result === 'draw' ? 'draw' : 'you lost'}`,
        [
          `Accuracy ${accuracy}% · ${blunders} blunder${blunders === 1 ? '' : 's'}, ${mistakes} mistake${mistakes === 1 ? '' : 's'}, ${inaccuracies} inaccurac${inaccuracies === 1 ? 'y' : 'ies'}.`,
          worstMoveLine(graded),
        ].filter(Boolean)),
    );
  }

  function worstMoveLine(graded) {
    if (!graded.length) return null;
    const worst = graded.reduce((a, b) => (b.grade.cpLoss > a.grade.cpLoss ? b : a));
    if (worst.grade.cpLoss < 60) return 'No serious errors — that is the game to build on.';
    return `Costliest moment: ${worst.played.san}. ${worst.text}`;
  }

  return {
    mount: () => {
      evalBar.show();
      evalBar.set({ cp: 20, mate: null });
      // Show the starting position while the options are being chosen, rather
      // than leaving whatever the previous mode had on the board.
      chess = new Chess();
      board.setOrientation('white');
      board.setPosition(chess.fen(), { animate: false });
      renderSetup();
    },
    unmount: () => { started = false; },
    handleMove,
    next: () => { if (!started) renderSetup(); },
  };
}
