import type { Player, Score, StorySummary } from './feed/types';

/** 41.Rxg7+ for White's move, 40...Rxb3 for Black's. */
export function moveLabel(ply: number, san: string): string {
  const number = Math.ceil(ply / 2);
  return ply % 2 === 1 ? `${number}.${san}` : `${number}...${san}`;
}

/** Stockfish's score, from White's side, as a number a reader knows. */
export function scoreText(score: Score): string {
  if (score.mate != null) return `#${score.mate > 0 ? '' : '−'}${Math.abs(score.mate)}`;
  const pawns = (score.cp ?? 0) / 100;
  return `${pawns > 0 ? '+' : pawns < 0 ? '−' : ''}${Math.abs(pawns).toFixed(2)}`;
}

export function resultText(result: StorySummary['result']): string {
  return result === '1/2-1/2' ? '½–½' : result.replace('-', '–');
}

export function playerText(p: Player): string {
  return [p.title, p.name].filter(Boolean).join(' ');
}

/** "Olympiad · Open · Round 9". */
export function occasion(s: StorySummary): string {
  return [s.event.short, s.event.section, s.event.round ? `Round ${s.event.round}` : null]
    .filter(Boolean)
    .join(' · ');
}

export function longDate(iso: string): string {
  return new Date(`${iso}T12:00:00Z`).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  });
}

/** The moves as they are printed: numbered pairs. */
export function movePairs(moves: string): { n: number; white: string; black: string | null }[] {
  const sans = moves.split(' ');
  const pairs = [];
  for (let i = 0; i < sans.length; i += 2) {
    pairs.push({ n: i / 2 + 1, white: sans[i], black: sans[i + 1] ?? null });
  }
  return pairs;
}
