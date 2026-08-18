// Application shell: owns the board, the engine and the evaluation bar, and
// hands them to whichever training mode is active.

import { Board } from './board.js';
import { Engine, formatScore, scoreToBar } from './engine.js';
import { subscribe, overallRating, getState } from './store.js';
import { clear, el } from './ui.js';

import { createTacticsMode } from './modes/tactics.js';
import { createPositionalMode } from './modes/positional.js';
import { createEndgameMode } from './modes/endgame.js';
import { createPlayMode } from './modes/play.js';
import { createProgressMode } from './modes/progress.js';

const MODES = [
  { id: 'tactics', label: 'Tactics', create: createTacticsMode },
  { id: 'positional', label: 'Positional', create: createPositionalMode },
  { id: 'endgame', label: 'Endgames', create: createEndgameMode },
  { id: 'play', label: 'Play & coach', create: createPlayMode },
  { id: 'progress', label: 'Progress', create: createProgressMode },
];

const engine = new Engine();
const boardEl = document.getElementById('board');
const panelEl = document.getElementById('panel');
const controlsEl = document.getElementById('board-controls');
const statusEl = document.getElementById('engine-status');
const ratingChip = document.getElementById('rating-chip');
const evalBarEl = document.getElementById('evalbar');
const evalFill = document.getElementById('evalbar-white');
const evalText = document.getElementById('evalbar-text');

const board = new Board(boardEl, { onMove: (...args) => active?.handleMove?.(...args) });

const evalBar = {
  set(score) {
    if (!score) {
      evalBarEl.hidden = false;
      evalFill.style.height = '50%';
      evalText.textContent = '—';
      return;
    }
    const share = scoreToBar(score);
    evalFill.style.height = `${share * 100}%`;
    evalText.textContent = formatScore(score, { signed: false });
    evalBarEl.dataset.lead = share >= 0.5 ? 'white' : 'black';
  },
  hide() {
    evalBarEl.hidden = true;
  },
  show() {
    evalBarEl.hidden = false;
  },
};

engine.onStateChange = (state) => {
  statusEl.dataset.state = state;
  statusEl.textContent = { booting: 'engine loading', ready: 'engine ready', thinking: 'thinking…', error: 'engine failed' }[state] ?? state;
};

subscribe(() => {
  ratingChip.innerHTML = `rating <strong>${overallRating()}</strong>`;
});

const context = {
  board,
  engine,
  evalBar,
  panel: panelEl,
  controls: controlsEl,
  data: {},
  setMode: (id) => selectMode(id),
};

let active = null;

async function loadData() {
  const [tactics, endgames, positions] = await Promise.all([
    fetchJson('/data/tactics.json'),
    fetchJson('/data/endgames.json'),
    fetchJson('/data/positions.json'),
  ]);
  context.data.tactics = tactics?.puzzles ?? [];
  context.data.endgames = endgames?.drills ?? [];
  context.data.positions = positions?.exercises ?? [];
}

async function fetchJson(url) {
  try {
    const response = await fetch(url);
    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null;
  }
}

const nav = document.getElementById('modes');
for (const mode of MODES) {
  nav.append(
    el('button', {
      type: 'button',
      'data-mode': mode.id,
      onClick: () => selectMode(mode.id),
    }, [mode.label]),
  );
}

function selectMode(id) {
  const mode = MODES.find((m) => m.id === id) ?? MODES[0];
  active?.unmount?.();
  board.clearShapes();
  board.setMovable(new Map());
  clear(controlsEl);
  clear(panelEl);
  evalBar.show();

  for (const btn of nav.children) {
    btn.setAttribute('aria-selected', String(btn.dataset.mode === mode.id));
  }
  location.hash = mode.id;

  active = mode.create(context);
  active.mount();
}

(async function start() {
  panelEl.replaceChildren(el('div', { class: 'loading', text: 'Loading engine and puzzles…' }));
  await loadData();
  engine.boot().catch(() => {});
  selectMode(location.hash.slice(1) || 'tactics');
})();

// Keyboard: F flips the board, N asks the active mode for the next item.
window.addEventListener('keydown', (event) => {
  if (event.target.matches('input, textarea, select')) return;
  if (event.key === 'f') board.flip();
  if (event.key === 'n') active?.next?.();
});

export { context, getState };
