import { SITE } from '../../core/site';

/**
 * Search-facing <title> overrides (50–59 chars) for the 39 guides whose full
 * <h1> exceeds 60 characters on its own.
 */
export const GUIDE_SEO_TITLES: Readonly<Record<string, string>> = {
  'checks-captures-threats-chess': 'Checks, Captures & Threats: Practical Chess Calculation',
  'centipawns-vs-win-probability': 'Centipawns vs Win Probability & Accuracy in Chess',
  'review-lost-chess-games': 'How to Review Lost Chess Games Beyond the Last Blunder',
  'offline-chess-app-checklist': 'Offline Chess App for iPhone: What Works Without Wi-Fi',
  'pin-versus-skewer-training': 'Pin vs Skewer in Chess: How to Spot & Calculate Both',
  'double-check-legal-defences': 'Double Check in Chess: Why the King Must Always Move',
  'deflection-versus-decoy': 'Deflection vs Decoy in Chess: Key Tactical Differences',
  'back-rank-weakness-safety-check': 'Back-Rank Mate & Weakness: Escape-Square Safety Check',
  'clearance-tactics-lines-and-squares': 'Clearance Tactics in Chess: Freeing Squares & Lines',
  'interference-tactics-defensive-lines': 'Interference Tactics in Chess: Cutting Defensive Lines',
  'hanging-piece-check-before-every-move': 'Counting Attackers & Defenders: Loose-Piece Chess Check',
  'queen-forks-checks-and-loose-targets': 'Queen Forks in Chess: Checks & Loose-Piece Targets',
  'attraction-sacrifice-mating-square': 'Attraction Sacrifices in Chess: Forcing Mating Nets',
  'double-attack-versus-fork': 'Double Attack vs Fork in Chess: How to Spot Both',
  'defensive-tactics-find-the-saving-move': 'Defensive Chess Tactics: Finding the Saving Resource',
  'find-opponents-best-defence': "Chess Calculation: Find Your Opponent's Best Defence",
  'chess-board-visualization-calculation': 'Chess Board Visualization: Track Moves Without Guessing',
  'evaluate-material-imbalances': 'Material Imbalances in Chess Beyond Simple Point Counts',
  'bishop-versus-knight-trade-decision': 'Bishop vs Knight in Chess: When to Trade or Keep',
  'weak-pawns-attackable-targets': 'Weak Pawns in Chess: Structural Flaw vs Real Target',
  'king-safety-versus-piece-activity': 'King Safety vs Piece Activity: Choosing Priorities',
  'improve-your-worst-piece': 'Improve Your Worst Piece: Practical Chess Strategy',
  'positional-exercise-or-forced-tactic': 'Positional Chess Exercises vs Forced Tactical Puzzles',
  'wrong-bishop-rook-pawn': 'Wrong Bishop & Rook Pawn Endgame: Draw Fortress Guide',
  'rook-behind-passed-pawn': 'Rook Behind Passed Pawns: Tarrasch Rule & Exceptions',
  'active-king-endgame': 'Active King in Chess Endgames: Safe Centralisation',
  'queen-versus-pawn-ending': 'Queen vs Pawn on the 7th Rank: Winning & Drawing Zones',
  'bishop-versus-knight-endgames': 'Bishop vs Knight Endgames: One-Wing vs Two-Wing Play',
  'opposite-coloured-bishops': 'Opposite-Coloured Bishop Endgames: Blockade & Drawing',
  'dead-position-insufficient-material': 'Insufficient Material & Dead Positions in Chess Rules',
  'fifty-move-rule': 'The 50-Move Rule in Chess: Counting, Resets & Claims',
  'threefold-repetition': 'Threefold Repetition in Chess: Exact Rules & Claims',
  'convert-extra-pawn': 'How to Convert an Extra Pawn in Chess Endgames',
  'save-worse-endgame': 'How to Defend & Save a Worse Endgame in Chess',
  'opening-development-principles': 'Chess Opening Development Principles & Early Threats',
  'chess-center-control': 'Chess Centre Control: Occupation, Influence & Breaks',
  'opening-memorization-vs-ideas': 'Chess Opening Ideas vs Memorisation: Practical Guide',
  'chess-engine-assistance-fair-play': 'Chess Engine Fair Play: Training Review vs Live Help',
  'online-chess-connection-planning': 'Online Chess Connection Drops: Pre-Game Device Check',
};

export function guideSeoTitle(slug: string, title: string): string {
  if (slug in GUIDE_SEO_TITLES) return GUIDE_SEO_TITLES[slug];
  const withBrand = `${title} — ${SITE.name}`;
  return withBrand.length <= 60 ? withBrand : title;
}
