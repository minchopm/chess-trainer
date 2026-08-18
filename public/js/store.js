// Progress tracking: puzzle rating, spaced repetition, per-theme accuracy.
// Everything lives in localStorage — no account, no server, no telemetry.

const KEY = 'chess-trainer:v1';
const DAY = 86_400_000;

const EMPTY = {
  ratings: { tactics: 1200, positional: 1200, endgame: 1200 },
  history: [], // { at, mode, puzzleId, correct, ratingAfter }
  themes: {}, // theme -> { seen, solved }
  cards: {}, // puzzleId -> { ease, interval, due, reps, lapses, lastResult }
  games: [], // { at, result, accuracy, blunders, opponentElo }
  streak: { current: 0, best: 0, lastDay: null },
};

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return structuredClone(EMPTY);
    return { ...structuredClone(EMPTY), ...JSON.parse(raw) };
  } catch {
    return structuredClone(EMPTY);
  }
}

let state = load();
const subscribers = new Set();

function persist() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    /* quota or private mode — training still works, it just won't be remembered */
  }
  for (const fn of subscribers) fn(state);
}

export function getState() {
  return state;
}

export function subscribe(fn) {
  subscribers.add(fn);
  fn(state);
  return () => subscribers.delete(fn);
}

export function resetProgress() {
  state = structuredClone(EMPTY);
  persist();
}

// --- rating -----------------------------------------------------------------

/** Standard Elo. K shrinks as the rating settles so early sessions converge fast. */
export function updateRating(mode, puzzleRating, correct) {
  const current = state.ratings[mode] ?? 1200;
  const played = state.history.filter((h) => h.mode === mode).length;
  const k = played < 20 ? 60 : played < 60 ? 32 : 20;
  const expected = 1 / (1 + 10 ** ((puzzleRating - current) / 400));
  const next = Math.round(current + k * ((correct ? 1 : 0) - expected));
  state.ratings[mode] = Math.max(400, next);
  return state.ratings[mode];
}

export function overallRating() {
  const { tactics, positional, endgame } = state.ratings;
  // Tactics dominates practical strength at club level, so weight it heaviest.
  return Math.round(tactics * 0.5 + positional * 0.25 + endgame * 0.25);
}

// --- spaced repetition ------------------------------------------------------

/**
 * SM-2, trimmed to the two outcomes a puzzle actually has. A missed puzzle comes
 * back tomorrow; a solved one is pushed out by its ease factor. Solving something
 * you were about to forget is what moves it into long-term memory.
 */
export function scheduleCard(puzzleId, correct, { hinted = false } = {}) {
  const now = Date.now();
  const card = state.cards[puzzleId] ?? { ease: 2.5, interval: 0, due: now, reps: 0, lapses: 0 };

  if (!correct) {
    card.ease = Math.max(1.3, card.ease - 0.2);
    card.interval = 0;
    card.due = now + DAY;
    card.lapses += 1;
  } else {
    const quality = hinted ? 3 : 5;
    card.ease = Math.max(1.3, card.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)));
    card.interval = card.reps === 0 ? 1 : card.reps === 1 ? 4 : Math.round(card.interval * card.ease);
    card.due = now + card.interval * DAY;
    card.reps += 1;
  }

  card.lastResult = correct ? 'solved' : 'missed';
  state.cards[puzzleId] = card;
  return card;
}

/**
 * Everything whose interval has elapsed — missed puzzles that come back the next
 * day, and solved ones resurfacing days or weeks later. Recalling something just
 * as you were about to forget it is what moves it into long-term memory, so
 * solved cards have to come back too, not only failed ones.
 */
export function dueCardIds() {
  const now = Date.now();
  return Object.entries(state.cards)
    .filter(([, card]) => card.due <= now)
    .map(([id]) => id);
}

export function isSeen(puzzleId) {
  return Boolean(state.cards[puzzleId]);
}

// --- recording results ------------------------------------------------------

/**
 * Themes that describe a puzzle rather than name a skill: which phase it is
 * from, how long the line is, how big the resulting advantage is, who played
 * the original game. They are useful for filtering a set, but counting them as
 * "weak spots" would bury the motifs you can actually train — every puzzle is
 * "short" or "long", so those columns say nothing about you.
 */
const NON_MOTIF_THEMES = new Set([
  'opening', 'middlegame', 'endgame',
  'oneMove', 'short', 'long', 'veryLong',
  'crushing', 'advantage', 'equality', 'mate',
  'master', 'masterVsMaster', 'superGM',
]);

export function isMotif(theme) {
  return !NON_MOTIF_THEMES.has(theme);
}


export function recordAttempt({ mode, puzzleId, puzzleRating, correct, themes = [], hinted = false }) {
  const ratingAfter = updateRating(mode, puzzleRating, correct && !hinted);
  scheduleCard(puzzleId, correct, { hinted });

  for (const theme of themes.filter(isMotif)) {
    const entry = (state.themes[theme] ??= { seen: 0, solved: 0 });
    entry.seen += 1;
    if (correct) entry.solved += 1;
  }

  state.history.push({ at: Date.now(), mode, puzzleId, correct, ratingAfter });
  if (state.history.length > 2000) state.history = state.history.slice(-2000);

  bumpStreak();
  persist();
  return ratingAfter;
}

export function recordGame(summary) {
  state.games.push({ at: Date.now(), ...summary });
  if (state.games.length > 200) state.games = state.games.slice(-200);
  bumpStreak();
  persist();
}

function bumpStreak() {
  const today = new Date().toDateString();
  if (state.streak.lastDay === today) return;
  const yesterday = new Date(Date.now() - DAY).toDateString();
  state.streak.current = state.streak.lastDay === yesterday ? state.streak.current + 1 : 1;
  state.streak.best = Math.max(state.streak.best, state.streak.current);
  state.streak.lastDay = today;
}

// --- reporting --------------------------------------------------------------

export function sessionStats(mode) {
  const today = new Date().setHours(0, 0, 0, 0);
  const todays = state.history.filter((h) => h.at >= today && (!mode || h.mode === mode));
  const solved = todays.filter((h) => h.correct).length;
  return {
    attempted: todays.length,
    solved,
    accuracy: todays.length ? solved / todays.length : 0,
  };
}

/**
 * Upper end of a Wilson confidence interval for an accuracy.
 *
 * Ranking motifs by raw accuracy makes small samples shout: one missed puzzle
 * reads as "0% — your worst weakness". The upper bound asks the more useful
 * question — how good could you plausibly be at this? — so a motif only rises to
 * the top once there is enough evidence that you are genuinely worse at it.
 */
function wilsonUpper(solved, seen, z = 1.0) {
  if (!seen) return 1;
  const p = solved / seen;
  const denominator = 1 + (z * z) / seen;
  const centre = p + (z * z) / (2 * seen);
  const margin = z * Math.sqrt((p * (1 - p) + (z * z) / (4 * seen)) / seen);
  return Math.min(1, (centre + margin) / denominator);
}

/** Motifs sorted worst-first, with the confidence-adjusted score used to rank them. */
export function weakestThemes(limit = 6, { minSeen = 3 } = {}) {
  return Object.entries(state.themes)
    .filter(([, t]) => t.seen >= minSeen)
    .map(([name, t]) => ({
      name,
      ...t,
      accuracy: t.solved / t.seen,
      ceiling: wilsonUpper(t.solved, t.seen),
    }))
    .sort((a, b) => a.ceiling - b.ceiling)
    .slice(0, limit);
}

/**
 * The motifs worth aiming puzzles at: ones you are measurably worse at than your
 * own average. Compared against your own baseline rather than a fixed number,
 * because a 60% overall solver and an 85% solver need different thresholds.
 */
export function trainingTargets({ minSeen = 4, margin = 0.05, limit = 6 } = {}) {
  const entries = Object.entries(state.themes).filter(([, t]) => t.seen >= minSeen);
  if (entries.length < 3) return []; // too early to know anything

  let solved = 0;
  let seen = 0;
  for (const [, t] of entries) {
    solved += t.solved;
    seen += t.seen;
  }
  const baseline = solved / seen;

  return entries
    .map(([name, t]) => ({
      name,
      ...t,
      accuracy: t.solved / t.seen,
      ceiling: wilsonUpper(t.solved, t.seen),
    }))
    .filter((t) => t.ceiling < baseline - margin)
    .sort((a, b) => a.ceiling - b.ceiling)
    .slice(0, limit);
}

/**
 * The ladder. These are honest labels for what a puzzle rating means in practice —
 * a puzzle rating is not an OTB rating, it runs several hundred points higher.
 */
export const LADDER = [
  { min: 0, max: 1000, name: 'Beginner', focus: 'Piece safety, one-move threats, basic mates' },
  { min: 1000, max: 1400, name: 'Club player', focus: 'Forks, pins, back rank, king-and-pawn endings' },
  { min: 1400, max: 1750, name: 'Strong club', focus: 'Two-move combinations, rook activity, opposition' },
  { min: 1750, max: 2050, name: 'Expert', focus: 'Deflection, interference, prophylaxis, Lucena/Philidor' },
  { min: 2050, max: 2300, name: 'Candidate master', focus: 'Quiet moves, long forcing lines, minor-piece endings' },
  { min: 2300, max: 2500, name: 'Master', focus: 'Positional sacrifices, defensive resources, technique' },
  { min: 2500, max: Infinity, name: 'Grandmaster range', focus: 'Deep calculation, imbalance evaluation, endgame precision' },
];

export function ladderState(rating) {
  return LADDER.map((rung) => ({
    ...rung,
    state: rating >= rung.max ? 'done' : rating >= rung.min ? 'current' : 'locked',
  }));
}
