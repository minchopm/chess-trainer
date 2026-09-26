// The Chess Olympiad as a team event, from every board of its official
// broadcast: each round's matches and their results, the table by match
// points, the round's upsets, and the event's numbers — for the reports
// (reports.mjs), which are about the Olympiad rather than one game in it.
//
// Everything here is counted from the relayed games, and says so: a match is
// counted only when all four of its boards were relayed and finished, and the
// order of teams level on match points is left to the official tiebreaks,
// which are not the broadcast's to give. The official standings are linked.
import { parsePgn, roundPgn, tour as readTour } from './lichess.mjs';

const RESULT = { '1-0': [1, 0], '0-1': [0, 1], '1/2-1/2': [0.5, 0.5] };

/**
 * One round of one section, from the games of every tour that relays part of
 * it — "Open | Matches 1-12", "Open | Matches 13-37" and so on, in that order,
 * so the first match is the top board's.
 */
function matchesOf(games) {
  const byPair = new Map();
  for (const game of games) {
    const t = game.tags;
    if (!t.WhiteTeam || !t.BlackTeam) continue;
    const pair = [t.WhiteTeam, t.BlackTeam].sort().join('\u0000');
    if (!byPair.has(pair)) byPair.set(pair, { home: t.WhiteTeam, away: t.BlackTeam, boards: [] });
    byPair.get(pair).boards.push(game);
  }
  return [...byPair.values()].map(({ home, away, boards }) => {
    const score = { [home]: 0, [away]: 0 };
    let finished = 0;
    for (const game of boards) {
      const points = RESULT[game.tags.Result];
      if (!points) continue;
      finished++;
      score[game.tags.WhiteTeam] += points[0];
      score[game.tags.BlackTeam] += points[1];
    }
    return {
      home,
      away,
      score: [score[home], score[away]],
      complete: boards.length === 4 && finished === 4,
      boards: boards.map((game) => ({
        white: player(game.tags, 'White'),
        black: player(game.tags, 'Black'),
        result: game.tags.Result,
        plies: game.sans.length,
        opening: game.tags.Opening ?? null,
        url: game.tags.GameURL ?? null,
      })),
    };
  });
}

function player(tags, side) {
  const [surname, given] = (tags[side] ?? '').split(',').map((s) => s.trim());
  return {
    name: given ? `${given} ${surname}` : surname,
    title: tags[`${side}Title`] ?? null,
    elo: Number(tags[`${side}Elo`]) || null,
    team: tags[`${side}Team`] ?? null,
  };
}

/** The table after a round: match points, then game points, from every complete match so far. */
export function standings(rounds, upTo) {
  const table = new Map();
  const row = (team) => {
    if (!table.has(team)) table.set(team, { team, mp: 0, gp: 0, played: 0 });
    return table.get(team);
  };
  for (const round of rounds.filter((r) => r.number <= upTo)) {
    for (const match of round.matches.filter((m) => m.complete)) {
      const [a, b] = match.score;
      const home = row(match.home);
      const away = row(match.away);
      home.gp += a;
      away.gp += b;
      home.played++;
      away.played++;
      if (a > b) home.mp += 2;
      else if (b > a) away.mp += 2;
      else {
        home.mp += 1;
        away.mp += 1;
      }
    }
  }
  return [...table.values()].sort((x, y) => y.mp - x.mp || y.gp - x.gp || x.team.localeCompare(y.team));
}

/** A round's numbers: its games by outcome, and its biggest upsets on the ratings. */
export function roundNumbers(round) {
  const games = round.matches.flatMap((m) => m.boards).filter((g) => RESULT[g.result] && g.plies > 1);
  const count = (result) => games.filter((g) => g.result === result).length;
  const upsets = games
    .filter((g) => g.result !== '1/2-1/2' && g.white.elo && g.black.elo)
    .map((g) => {
      const [winner, loser] = g.result === '1-0' ? [g.white, g.black] : [g.black, g.white];
      return { winner, loser, gap: loser.elo - winner.elo, url: g.url };
    })
    .filter((u) => u.gap >= 100)
    .sort((a, b) => b.gap - a.gap);
  return { games: games.length, white: count('1-0'), black: count('0-1'), draws: count('1/2-1/2'), upsets };
}

/**
 * The event's numbers, over every round so far. The longest game and not the
 * shortest win: a short defeat is a player's worst day, and nobody's to headline.
 */
export function eventNumbers(rounds) {
  const games = rounds.flatMap((r) => r.matches.flatMap((m) => m.boards)).filter((g) => RESULT[g.result] && g.plies > 1);
  const openings = new Map();
  for (const g of games) {
    const family = g.opening?.split(':')[0]?.trim();
    if (family) openings.set(family, (openings.get(family) ?? 0) + 1);
  }
  const longest = games.reduce((best, g) => (!best || g.plies > best.plies ? g : best), null);
  return {
    games: games.length,
    white: games.filter((g) => g.result === '1-0').length,
    black: games.filter((g) => g.result === '0-1').length,
    draws: games.filter((g) => g.result === '1/2-1/2').length,
    openings: [...openings.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([name, count]) => ({ name, count })),
    longest: longest && { ...longest, moves: Math.ceil(longest.plies / 2) },
  };
}

/**
 * The Olympiad's rounds, section by section, as far as they are finished — read
 * from Lichess, a round at a time, and only the rounds `known` does not have
 * yet: a finished round's games do not change, so each is read once.
 */
export async function readOlympiad(tourId, known = {}, log = console.error, outOfTime = () => false) {
  const main = await readTour(tourId);
  const info = main.tour.info ?? {};
  const sections = {};
  for (const t of main.group?.tours ?? [{ id: tourId, name: main.tour.name }]) {
    const name = t.name.split('|')[0].trim();
    (sections[name] ??= []).push(t.id);
  }
  const out = { name: main.group?.name ?? main.tour.name, info, dates: main.tour.dates ?? null, sections: {} };
  for (const [section, tourIds] of Object.entries(sections)) {
    const tours = [];
    for (const id of tourIds) tours.push(id === tourId ? main : await readTour(id));
    const numbers = [...new Set(tours.flatMap((t) => t.rounds.map((r) => Number(r.name.match(/\d+/)?.[0]))))]
      .filter(Boolean)
      .sort((a, b) => a - b);
    const rounds = [];
    for (const number of numbers) {
      const parts = tours.map((t) => t.rounds.find((r) => Number(r.name.match(/\d+/)?.[0]) === number)).filter(Boolean);
      if (!parts.length || !parts.every((r) => r.finished)) continue;
      const cached = known[section]?.find((r) => r.number === number);
      if (cached) {
        rounds.push(cached);
        continue;
      }
      // Out of time: the rounds read so far are kept, and the next run
      // carries on from here.
      if (outOfTime()) break;
      log(`  reading ${out.name} · ${section} · round ${number} (${parts.length} broadcasts)`);
      const games = [];
      for (const part of parts) games.push(...parsePgn(await roundPgn(part.id)));
      const startsAt = Math.min(...parts.map((r) => r.startsAt ?? Infinity));
      rounds.push({
        number,
        date: Number.isFinite(startsAt) ? new Date(startsAt).toISOString().slice(0, 10) : null,
        matches: matchesOf(games),
      });
    }
    out.sections[section] = rounds;
  }
  return out;
}
