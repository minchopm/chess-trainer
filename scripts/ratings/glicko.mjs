// Glicko, as the app has it (ios/Sources/ChessTraining/MatchProtocol.swift,
// `Glicko`): the same constants and the same arithmetic, so the number the
// referee settles on is the one a player's own device would have worked out.
// This copy is the one that counts.

export const STARTING = 1200;
/** No rating goes below this; there is no ceiling. */
export const FLOOR = 100;
/** A new player's deviation, and the most an idle one grows back to. */
export const NEW_DEVIATION = 350;
/** The narrowest a deviation gets, however many games. */
export const SETTLED_DEVIATION = 50;
/** How much uncertainty a day without a game adds: back to new after about a year. */
export const GROWTH_PER_DAY = Math.sqrt((NEW_DEVIATION ** 2 - SETTLED_DEVIATION ** 2) / 365);

const q = Math.log(10) / 400;

/** A deviation after time without a game. */
export function grown(deviation, idleMs) {
  const days = Math.max(idleMs, 0) / 86_400_000;
  return Math.min(Math.sqrt(deviation ** 2 + GROWTH_PER_DAY ** 2 * days), NEW_DEVIATION);
}

/** How much an opponent's result says: less, the less sure their rating is. */
const g = (deviation) => 1 / Math.sqrt(1 + (3 * q * q * deviation * deviation) / (Math.PI * Math.PI));

/** The score expected against this opponent, from 0 to 1. */
export function expected(rating, opponent, opponentDeviation) {
  return 1 / (1 + 10 ** ((-g(opponentDeviation) * (rating - opponent)) / 400));
}

/** The rating and deviation after one game; `score` is 1, ½ or 0. */
export function updated({ rating, deviation }, { rating: opponent, deviation: opponentDeviation }, score) {
  const impact = g(opponentDeviation);
  const e = expected(rating, opponent, opponentDeviation);
  const precision = 1 / deviation ** 2 + q * q * impact * impact * e * (1 - e);
  const next = rating + (q / precision) * impact * (score - e);
  return {
    rating: Math.max(Math.round(next), FLOOR),
    deviation: Math.max(Math.sqrt(1 / precision), SETTLED_DEVIATION),
  };
}
