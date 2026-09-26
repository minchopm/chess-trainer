// The first draft of a story's words.
//
// A draft, and it reads like one. Its job is to put every fact the story may
// use in one place, in plain sentences, so that rewriting it is editing rather
// than research. It never guesses: where the relay does not say how a game
// ended, the draft does not say either.

/** A player as the feed writes them. */
export function person(tags, side, lookup) {
  const name = tags[side] ?? '';
  const known = lookup(name, tags[`${side}FideId`]);
  const [surname, given] = name.split(',').map((s) => s.trim());
  return {
    name: known?.display ?? (given ? `${given} ${surname}` : surname),
    short: known?.short ?? surname,
    title: tags[`${side}Title`] ?? null,
    elo: Number(tags[`${side}Elo`]) || null,
    team: tags[`${side}Team`] ?? null,
    fed: tags[`${side}Fed`] ?? null,
    fideId: Number(tags[`${side}FideId`]) || null,
  };
}

/**
 * An event's long and short names.
 *
 * "46th FIDE Chess Olympiad Samarkand 2026 | Open | Matches 1-12" is three
 * things: the event, the section and which boards this tour relays. The last
 * is the relay's business, not the reader's.
 */
export function eventNames(t) {
  const group = t.group?.name;
  const parts = t.tour.name.split('|').map((s) => s.trim());
  const name = group ?? parts[0];
  const rest = group ? parts : parts.slice(1);
  const section = rest.find((p) => !/^Matches\b/i.test(p) && p !== name) ?? null;
  const short = name
    .replace(/\b(19|20)\d\d\b/g, '')
    .replace(/^\d+(st|nd|rd|th)\s+/i, '')
    .replace(/\bFIDE\s+Chess\s+/i, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
  return { name, short: /Olympiad/i.test(short) ? 'Olympiad' : short, section };
}

export function moveLabel(ply, san) {
  const number = Math.ceil(ply / 2);
  return ply % 2 === 1 ? `${number}.${san}` : `${number}...${san}`;
}

/** An engine score, from White's side, in the words a reader would use. */
export function assessment(score) {
  if (score.mate != null) return `a forced mate for ${score.mate > 0 ? 'White' : 'Black'}`;
  const cp = score.cp;
  const side = cp > 0 ? 'White' : 'Black';
  const size = Math.abs(cp);
  if (size < 40) return 'about level';
  if (size < 120) return `a small edge for ${side}`;
  if (size < 250) return `a clear advantage for ${side}`;
  return `a winning position for ${side}`;
}

function who(p) {
  return p.team ? `${p.name} (${p.team})` : p.name;
}

export function draftWords(story) {
  const { white, black, result, event, key } = story;
  const decisive = result !== '1/2-1/2';
  const winner = result === '1-0' ? white : black;
  const loser = result === '1-0' ? black : white;
  const colour = result === '1-0' ? 'White' : 'Black';
  const round = event.round ? `round ${event.round} of ` : '';
  const occasion = `${round}the ${event.name}${event.section ? ` (${event.section})` : ''}`;
  const moves = Math.ceil(story.plies / 2);

  const headline = decisive
    ? `${winner.short} beats ${loser.short}${event.round ? ` in ${event.short} round ${event.round}` : ''}`
    : `${white.short} and ${black.short} draw${event.round ? ` in ${event.short} round ${event.round}` : ''}`;

  const sentences = [];
  sentences.push(
    decisive
      ? `${who(winner)} beat ${who(loser)} with the ${colour} pieces in ${occasion}.`
      : `${who(white)} and ${who(black)} drew in ${occasion}.`,
  );
  if (story.opening.name) sentences.push(`The opening was the ${story.opening.name}.`);
  if (key) {
    const label = moveLabel(key.ply, key.played);
    if (key.kind === 'breakthrough') {
      sentences.push(`The engine's assessment tipped with ${label}, from ${assessment(key.before)} to ${assessment(key.after)}, and stayed there.`);
    } else if (key.kind === 'swing') {
      sentences.push(`The biggest swing came with ${label}, from ${assessment(key.before)} to ${assessment(key.after)} by the engine's count, and it was not converted.`);
    } else {
      sentences.push(`The game turned on ${label}: the engine's assessment went from ${assessment(key.before)} to ${assessment(key.after)}.`);
    }
    if (key.better) sentences.push(`The engine preferred ${moveLabel(key.ply, key.better)}.`);
    if (key.clock != null && key.clock < 600) {
      const minutes = Math.max(1, Math.round(key.clock / 60));
      sentences.push(`It was played with ${minutes} minute${minutes === 1 ? '' : 's'} left on the clock.`);
    }
  }
  if (story.ending === 'checkmate') sentences.push(`It ended in checkmate on move ${moves}.`);
  else if (story.ending === 'repetition') sentences.push(`It ended in a repetition on move ${moves}.`);
  else if (story.ending === 'stalemate') sentences.push(`It ended in stalemate on move ${moves}.`);
  else sentences.push(decisive ? `${winner.short} won in ${moves} moves.` : `The draw came on move ${moves}.`);

  return { headline, body: sentences.join(' ') };
}
