// Progress dashboard: where you actually stand, and what to work on next.

import {
  getState, overallRating, sessionStats, weakestThemes, ladderState, resetProgress, dueCardIds,
  trainingTargets,
} from '../store.js';
import { button, card, el, stat, fill, humanise } from '../ui.js';

export function createProgressMode(context) {
  const { panel, controls, board, evalBar, data } = context;

  function render() {
    const state = getState();
    const rating = overallRating();
    const today = sessionStats();
    const due = dueCardIds().length;

    fill(panel, 
      card('Where you are', [
        el('div', { class: 'stat-grid' }, [
          stat('Overall', rating),
          stat('Tactics', state.ratings.tactics),
          stat('Positional', state.ratings.positional),
          stat('Endgames', state.ratings.endgame),
        ]),
        el('p', { class: 'subtle', text:
          'Puzzle ratings run a few hundred points above over-the-board ratings — treat them as a ' +
          'measure of progress against yourself, not as a FIDE equivalent.' }),
      ]),

      card('Today', [
        el('div', { class: 'stat-grid' }, [
          stat('Attempted', today.attempted),
          stat('Solved', today.solved),
          stat('Accuracy', `${Math.round(today.accuracy * 100)}%`),
          stat('Day streak', state.streak.current, `best ${state.streak.best}`),
        ]),
        due
          ? el('p', { class: 'subtle', text: `${due} puzzle${due === 1 ? '' : 's'} due for review — they come up first in Tactics.` })
          : el('p', { class: 'subtle', text: 'Nothing queued for review. Missed puzzles come back tomorrow; solved ones at growing intervals.' }),
      ]),

      card('The ladder', [
        el('div', { class: 'ladder' }, ladderState(rating).map((rung) =>
          el('div', { class: 'rung', 'data-state': rung.state }, [
            el('span', { class: 'range', text: rung.max === Infinity ? `${rung.min}+` : `${rung.min}` }),
            el('span', {}, [el('strong', { text: rung.name }), el('div', { class: 'subtle', text: rung.focus })]),
            el('span', { class: 'subtle', text: rung.state === 'done' ? '✓' : rung.state === 'current' ? 'here' : '' }),
          ]),
        )),
      ]),

      weaknessCard(),
      libraryCard(),
      recentGamesCard(state),
    );

    fill(controls, 
      button('Reset all progress', () => {
        if (confirm('Delete all ratings, statistics and review scheduling? This cannot be undone.')) {
          resetProgress();
          render();
        }
      }),
    );
  }

  function weaknessCard() {
    const weak = weakestThemes();
    if (!weak.length) {
      return card('Weak spots', [
        el('p', { class: 'subtle', text: 'Solve a few dozen puzzles and the motifs you struggle with will be listed here — and the trainer will start aiming puzzles at them.' }),
      ]);
    }

    const targeted = new Set(trainingTargets().map((t) => t.name));

    return card('Weak spots', [
      el('table', { class: 'themes' }, weak.map((theme) =>
        el('tr', {}, [
          el('td', {}, [
            humanise(theme.name),
            targeted.has(theme.name) ? el('span', { class: 'tag', text: 'targeting' }) : null,
            el('div', { class: 'bar' }, [el('span', { style: `width:${Math.round(theme.accuracy * 100)}%` })]),
          ].filter(Boolean)),
          el('td', { text: `${Math.round(theme.accuracy * 100)}% of ${theme.seen}` }),
        ]),
      )),
      targeted.size
        ? el('p', { class: 'subtle', text: `About 60% of new puzzles are now drawn from ${targeted.size === 1 ? 'this motif' : 'these motifs'}. The rest stay varied, so the rating keeps measuring everything.` })
        : el('p', { class: 'subtle', text: 'Nothing is clearly below your own average yet, so puzzles are still chosen purely by rating. Targeting starts once a motif has at least four attempts and stands out.' }),
    ]);
  }

  function libraryCard() {
    const tactics = data.tactics?.length ?? 0;
    const positions = data.positions?.length ?? 0;
    const endgames = data.endgames?.length ?? 0;
    const seen = Object.keys(getState().cards).length;

    return card('Library', [
      el('div', { class: 'stat-grid' }, [
        stat('Tactics', tactics),
        stat('Positional', positions),
        stat('Endgames', endgames),
        stat('Seen', seen),
      ]),
      el('p', { class: 'subtle', html:
        'Add more with <code>npm run generate</code> (tactics), <code>npm run generate:positions</code> ' +
        '(positional) or <code>npm run import-lichess</code> (the 5-million-puzzle Lichess database).' }),
    ]);
  }

  function recentGamesCard(state) {
    if (!state.games.length) return null;
    const recent = state.games.slice(-10).reverse();
    const wins = state.games.filter((g) => g.result === 'win').length;
    const avgAccuracy = Math.round(
      state.games.reduce((sum, g) => sum + (g.accuracy ?? 0), 0) / state.games.length,
    );

    return card('Games played', [
      el('div', { class: 'stat-grid' }, [
        stat('Played', state.games.length),
        stat('Won', wins),
        stat('Avg accuracy', `${avgAccuracy}%`),
      ]),
      el('table', { class: 'themes' }, recent.map((game) =>
        el('tr', {}, [
          el('td', { text: `${game.result} vs ${game.opponentElo}` }),
          el('td', { text: `${game.accuracy}% · ${game.blunders} blunder${game.blunders === 1 ? '' : 's'}` }),
        ]),
      )),
    ]);
  }

  return {
    mount: () => {
      board.setMovable(new Map());
      evalBar.hide();
      render();
    },
    unmount: () => evalBar.show(),
    next: render,
  };
}
