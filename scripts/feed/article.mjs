// A story's words, in every language the app speaks — written by the collector
// the moment it picks a game, from the facts it has and nothing else.
//
// Written to be read: a headline chosen for the most striking fact the game
// has (a checkmate, an upset on the ratings, a move played with seconds on the
// clock, the move the engine wanted instead), and a few short paragraphs that
// put the reader on the move that decided it. A person may rewrite a story
// later and approve it (publish.mjs); until then, this is what is published.
//
// What keeps it safe to publish unread is what it is made of. Every sentence
// is a template filled with facts from the broadcast (players, ratings, teams,
// round, result, moves, clock) or with Stockfish's evaluation, and every
// evaluation is said to be Stockfish's. Nothing says what a player felt,
// meant, feared or failed at; nothing calls a move or a player anything; no
// sentence needs a pronoun, and in the languages whose verbs and adjectives
// take a person's gender the sentences are built so that they never do — the
// side (White, Black) or the move is the subject, never the player. `problems`
// checks the result, and the collector will not publish a story that fails.

/** The languages the app speaks, as the feed's folders are named. */
export const LANGS = [
  'en', 'ar', 'cs', 'da', 'de', 'el', 'es', 'fi', 'fr', 'he', 'hi', 'hu', 'id', 'it', 'ja',
  'ko', 'ms', 'nl', 'no', 'pl', 'pt-BR', 'ro', 'ru', 'sv', 'th', 'tr', 'vi', 'zh-Hans', 'zh-Hant',
  // The website speaks one language the app does not yet.
  'bg',
];

// ------------------------------------------------------------------- facts

export function moveLabel(ply, san) {
  const number = Math.ceil(ply / 2);
  return ply % 2 === 1 ? `${number}.${san}` : `${number}...${san}`;
}

function clockText(seconds) {
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}

/** Stockfish's score as a band, from White's side. */
function band(score) {
  if (score.mate != null) return { level: 'mate', side: score.mate > 0 ? 'white' : 'black' };
  const size = Math.abs(score.cp);
  const side = score.cp > 0 ? 'white' : 'black';
  if (size < 40) return { level: 'level', side };
  if (size < 120) return { level: 'small', side };
  if (size < 250) return { level: 'clear', side };
  return { level: 'winning', side };
}

function scoreText(score, lang) {
  if (score.mate != null) return `#${score.mate > 0 ? '' : '-'}${Math.abs(score.mate)}`;
  return new Intl.NumberFormat(`${lang}-u-nu-latn`, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
    signDisplay: 'exceptZero',
  }).format(score.cp / 100);
}

/** Everything a template may use, worked out once. */
function facts(story) {
  const sans = story.moves.split(' ');
  const moves = Math.ceil(sans.length / 2);
  const winnerSide = story.result === '1-0' ? 'white' : story.result === '0-1' ? 'black' : null;
  const loserSide = winnerSide === 'white' ? 'black' : winnerSide === 'black' ? 'white' : null;
  const winner = winnerSide ? story[winnerSide] : null;
  const loser = loserSide ? story[loserSide] : null;
  const gap = winner?.elo && loser?.elo ? loser.elo - winner.elo : 0;
  const key = story.key ?? null;
  const clock = key?.clock ?? null;
  const mate = story.ending === 'checkmate';

  // The headline goes to the most striking fact there is.
  let hook;
  if (mate && winnerSide) hook = 'mate';
  else if (winnerSide && gap >= 100) hook = 'upset';
  else if (key && clock != null && clock < 120) hook = 'clock';
  else if (key?.kind === 'mistake' && key.better) hook = 'challenge';
  else if (key?.kind === 'breakthrough') hook = 'decider';
  else if (key?.kind === 'swing') hook = 'chance';
  else hook = winnerSide ? 'win' : 'draw';

  return {
    story,
    moves,
    winnerSide,
    loserSide,
    winner,
    loser,
    gap,
    key,
    clock,
    mate,
    hook,
    score: story.result === '1-0' ? '1–0' : story.result === '0-1' ? '0–1' : '½–½',
    move: key ? moveLabel(key.ply, key.played) : null,
    better: key?.better ? moveLabel(key.ply, key.better) : null,
    reply: key?.reply && key.replyPlayed ? moveLabel(key.ply + 1, key.reply) : null,
  };
}

const full = (p) => `${p.title ? `${p.title} ` : ''}${p.name}${p.team ? ` (${p.team})` : ''}`;

// ------------------------------------------------------------------ words
//
// One table per language. `s` is always a side key, 'white' or 'black'; each
// language turns it into the form its sentence needs.

const EN = {
  side: { white: 'White', black: 'Black' },
  assess: {
    level: () => 'level',
    small: (s) => `a small edge for ${EN.side[s]}`,
    clear: (s) => `a clear advantage for ${EN.side[s]}`,
    winning: (s) => `winning for ${EN.side[s]}`,
    mate: (s) => `a forced mate for ${EN.side[s]}`,
  },
};

function english(f) {
  const { story, winner, loser } = f;
  const { white, black, event } = story;
  const a = (score) => `${EN.assess[band(score).level](band(score).side)} (${scoreText(score, 'en')})`;
  const round = event.round ? ` round ${event.round}` : '';
  const occasion = `${event.round ? `round ${event.round} of ` : ''}the ${event.name}${event.section ? ` (${event.section})` : ''}`;
  const n = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`;

  const headline = {
    mate: () => `Checkmate in ${n(f.moves, 'move')}: ${winner.short} beats ${loser.short}`,
    upset: () => `${winner.short} beats ${loser.short}, rated ${f.gap} points higher`,
    clock: () => winner
      ? `${winner.short} beats ${loser.short}: one move, with ${clockText(f.clock)} on the clock, decided it`
      : `${white.short}–${black.short}: one move, with ${clockText(f.clock)} on the clock, and a draw`,
    challenge: () => `${winner.short} beats ${loser.short}: can you find the move the engine wanted?`,
    decider: () => `${winner.short} beats ${loser.short}: the one move that decided it`,
    chance: () => `${white.short}–${black.short}: a win, by Stockfish's count, that came and went`,
    win: () => `${winner.short} beats ${loser.short} in ${event.short}${round}`,
    draw: () => `${white.short} and ${black.short} draw in ${event.short}${round}`,
  }[f.hook]();

  const lede = winner
    ? `${full(winner)} beat ${full(loser)} in ${occasion}, in ${n(f.moves, 'move')}.`
    : `${full(white)} and ${full(black)} drew in ${occasion}, after ${n(f.moves, 'move')}.`;

  const paragraphs = [lede];
  const key = f.key;
  if (key) {
    let moment;
    if (key.kind === 'breakthrough') {
      moment = `${f.move} was the move. Stockfish had the position as ${a(key.before)} before it and ${a(key.after)} after it, and it never swung back.`;
    } else if (key.kind === 'swing') {
      moment = `After ${f.move}, Stockfish had it as ${a(key.after)}. The game still ended in a draw.`;
    } else {
      moment = `The game turned on ${f.move}. Before it, Stockfish had the position as ${a(key.before)}; one move later, ${a(key.after)}.`;
    }
    if (f.clock != null && f.clock < 600) moment += ` It was played with ${clockText(f.clock)} left on the clock.`;
    paragraphs.push(moment);

    const question = [];
    if (f.better && key.kind !== 'breakthrough') question.push(`Stockfish wanted ${f.better} instead. Can you see why?`);
    if (key.kind === 'breakthrough') question.push('Can you see what Stockfish saw in it?');
    if (f.reply && key.kind === 'mistake') question.push(`And ${f.reply}, the engine's best reply, came straight back.`);
    if (question.length) paragraphs.push(question.join(' '));
  }

  const context = [];
  if (f.hook === 'upset') context.push(`The ratings said otherwise: ${winner.short} was ${f.gap} points lower.`);
  if (f.mate) context.push(`It ended in checkmate on move ${f.moves}.`);
  if (story.opening?.name) context.push(`It began as the ${story.opening.name}.`);
  if (context.length) paragraphs.push(context.join(' '));

  paragraphs.push('Replay it move by move, then take the key position on against the engine.');
  return { headline, lede, body: paragraphs.join('\n\n') };
}

/**
 * The other languages. The headline is the pairing and the score, then the
 * hook; the paragraphs are the result, the moment, the question, the context
 * and the invitation — the English story's shape, in sentences built for each
 * language rather than translated word for word from the English one.
 */
const T = {
  de: {
    round: (r) => `Runde ${r}`, women: 'Frauen',
    side: { white: 'Weiß', black: 'Schwarz' },
    assess: { level: () => 'ausgeglichen', small: (s) => `leichter Vorteil für ${T.de.side[s]}`, clear: (s) => `klarer Vorteil für ${T.de.side[s]}`, winning: (s) => `Gewinnstellung für ${T.de.side[s]}`, mate: (s) => `forciertes Matt für ${T.de.side[s]}` },
    win: (s) => `Sieg für ${T.de.side[s]}`, draw: 'Remis',
    moves: (n) => `nach ${n} ${n === 1 ? 'Zug' : 'Zügen'}`,
    head: { mate: (n) => `Matt im ${n}. Zug`, upset: (g) => `Überraschung bei ${g} Elo-Punkten Unterschied`, clock: (t) => `ein Zug mit ${t} auf der Uhr entschied`, challenge: 'Welchen Zug wollte die Engine?', decider: 'der Zug, der alles entschied', chance: 'eine Gewinnchance laut Stockfish, die verstrich' },
    mistake: (m, b, a) => `Stockfish vor ${m}: ${b}. Danach: ${a}.`,
    breakthrough: (m, b, a) => `${m} entschied die Partie. Stockfish davor: ${b}; danach: ${a} – und dabei blieb es.`,
    swing: (m, a) => `Nach ${m} sah Stockfish ${a} – und doch endete die Partie remis.`,
    clock: (t) => `Der Zug fiel mit ${t} auf der Uhr.`,
    better: (mv) => `Stockfish wollte stattdessen ${mv}. Warum?`,
    liked: 'Was sah Stockfish in diesem Zug?',
    reply: (mv) => `Und die beste Antwort, ${mv}, kam sofort.`,
    upset: (s, g) => `Die Elo-Zahlen sagten etwas anderes: ${T.de.side[s]} lag ${g} Punkte darunter.`,
    mate: (n) => `Die Partie endete mit Matt im ${n}. Zug.`,
    cta: 'Zug für Zug nachspielen – und die Schlüsselstellung selbst gegen die Engine weiterspielen.',
  },
  fr: {
    round: (r) => `ronde ${r}`, women: 'féminin',
    side: { white: 'Blancs', black: 'Noirs' },
    assess: { level: () => 'égalité', small: (s) => `léger avantage aux ${T.fr.side[s]}`, clear: (s) => `net avantage aux ${T.fr.side[s]}`, winning: (s) => `position gagnante pour les ${T.fr.side[s]}`, mate: (s) => `mat forcé pour les ${T.fr.side[s]}` },
    win: (s) => `victoire des ${T.fr.side[s]}`, draw: 'nulle',
    moves: (n) => `en ${n} coup${n === 1 ? '' : 's'}`,
    head: { mate: (n) => `mat au ${n}e coup`, upset: (g) => `la surprise, à ${g} points Elo d’écart`, clock: (t) => `un coup, avec ${t} à la pendule, a tout décidé`, challenge: 'quel coup voulait le moteur ?', decider: 'le coup qui a tout décidé', chance: 'une occasion de gain, selon Stockfish, qui est passée' },
    mistake: (m, b, a) => `Stockfish avant ${m} : ${b}. Après : ${a}.`,
    breakthrough: (m, b, a) => `${m} a décidé la partie. Stockfish avant : ${b} ; après : ${a} — et l’évaluation n’est plus revenue.`,
    swing: (m, a) => `Après ${m}, Stockfish voyait ${a} — et pourtant, la partie s’est terminée par la nulle.`,
    clock: (t) => `Le coup a été joué avec ${t} à la pendule.`,
    better: (mv) => `Le choix de Stockfish était ${mv}. Pourquoi ?`,
    liked: 'Qu’a vu Stockfish dans ce coup ?',
    reply: (mv) => `Et la meilleure réponse, ${mv}, est arrivée aussitôt.`,
    upset: (s, g) => `Le classement disait l’inverse : les ${T.fr.side[s]} avaient ${g} points Elo de moins.`,
    mate: (n) => `La partie s’est terminée par un mat au ${n}e coup.`,
    cta: 'Rejouez-la coup par coup, puis reprenez la position clé contre le moteur.',
  },
  es: {
    round: (r) => `ronda ${r}`, women: 'femenino',
    side: { white: 'blancas', black: 'negras' },
    assess: { level: () => 'igualdad', small: (s) => `ligera ventaja de las ${T.es.side[s]}`, clear: (s) => `clara ventaja de las ${T.es.side[s]}`, winning: (s) => `posición ganadora para las ${T.es.side[s]}`, mate: (s) => `mate forzado para las ${T.es.side[s]}` },
    win: (s) => `victoria de las ${T.es.side[s]}`, draw: 'tablas',
    moves: (n) => `en ${n} jugada${n === 1 ? '' : 's'}`,
    head: { mate: (n) => `mate en la jugada ${n}`, upset: (g) => `la sorpresa, con ${g} puntos Elo de diferencia`, clock: (t) => `una jugada, con ${t} en el reloj, lo decidió todo`, challenge: '¿qué jugada quería el motor?', decider: 'la jugada que lo decidió todo', chance: 'una ocasión de ganar, según Stockfish, que se escapó' },
    mistake: (m, b, a) => `Stockfish antes de ${m}: ${b}. Después: ${a}.`,
    breakthrough: (m, b, a) => `${m} decidió la partida. Stockfish antes: ${b}; después: ${a}, y la valoración ya no volvió atrás.`,
    swing: (m, a) => `Tras ${m}, Stockfish veía ${a}, y aun así la partida terminó en tablas.`,
    clock: (t) => `La jugada se hizo con ${t} en el reloj.`,
    better: (mv) => `La elección de Stockfish era ${mv}. ¿Por qué?`,
    liked: '¿Qué vio Stockfish en esa jugada?',
    reply: (mv) => `Y la mejor respuesta, ${mv}, llegó enseguida.`,
    upset: (s, g) => `El Elo decía lo contrario: las ${T.es.side[s]} tenían ${g} puntos menos.`,
    mate: (n) => `La partida terminó con mate en la jugada ${n}.`,
    cta: 'Reprodúcela jugada a jugada y sigue la posición clave contra el motor.',
  },
  it: {
    round: (r) => `turno ${r}`, women: 'femminile',
    side: { white: 'Bianco', black: 'Nero' },
    assess: { level: () => 'parità', small: (s) => `leggero vantaggio del ${T.it.side[s]}`, clear: (s) => `netto vantaggio del ${T.it.side[s]}`, winning: (s) => `posizione vinta per il ${T.it.side[s]}`, mate: (s) => `matto forzato per il ${T.it.side[s]}` },
    win: (s) => `vittoria del ${T.it.side[s]}`, draw: 'patta',
    moves: (n) => `in ${n} moss${n === 1 ? 'a' : 'e'}`,
    head: { mate: (n) => `scacco matto alla mossa ${n}`, upset: (g) => `la sorpresa, con ${g} punti Elo di differenza`, clock: (t) => `una mossa, con ${t} sull’orologio, ha deciso tutto`, challenge: 'quale mossa voleva il motore?', decider: 'la mossa che ha deciso tutto', chance: 'un’occasione di vittoria, secondo Stockfish, sfumata' },
    mistake: (m, b, a) => `Stockfish prima di ${m}: ${b}. Dopo: ${a}.`,
    breakthrough: (m, b, a) => `${m} ha deciso la partita. Stockfish prima: ${b}; dopo: ${a}, e la valutazione non è più tornata indietro.`,
    swing: (m, a) => `Dopo ${m} Stockfish vedeva ${a}, eppure la partita è finita patta.`,
    clock: (t) => `La mossa è stata giocata con ${t} sull’orologio.`,
    better: (mv) => `La scelta di Stockfish era ${mv}. Perché?`,
    liked: 'Che cosa ha visto Stockfish in quella mossa?',
    reply: (mv) => `E la risposta migliore, ${mv}, è arrivata subito.`,
    upset: (s, g) => `L’Elo diceva il contrario: il ${T.it.side[s]} aveva ${g} punti in meno.`,
    mate: (n) => `La partita è finita con lo scacco matto alla mossa ${n}.`,
    cta: 'Rivedila mossa per mossa e prosegui la posizione chiave contro il motore.',
  },
  'pt-BR': {
    round: (r) => `rodada ${r}`, women: 'feminino',
    side: { white: 'brancas', black: 'pretas' },
    assess: { level: () => 'igualdade', small: (s) => `leve vantagem das ${T['pt-BR'].side[s]}`, clear: (s) => `clara vantagem das ${T['pt-BR'].side[s]}`, winning: (s) => `posição vencedora para as ${T['pt-BR'].side[s]}`, mate: (s) => `mate forçado para as ${T['pt-BR'].side[s]}` },
    win: (s) => `vitória das ${T['pt-BR'].side[s]}`, draw: 'empate',
    moves: (n) => `em ${n} lance${n === 1 ? '' : 's'}`,
    head: { mate: (n) => `xeque-mate no lance ${n}`, upset: (g) => `a zebra, com ${g} pontos de rating de diferença`, clock: (t) => `um lance, com ${t} no relógio, decidiu tudo`, challenge: 'qual lance o motor queria?', decider: 'o lance que decidiu tudo', chance: 'uma chance de vitória, segundo o Stockfish, que passou' },
    mistake: (m, b, a) => `Stockfish antes de ${m}: ${b}. Depois: ${a}.`,
    breakthrough: (m, b, a) => `${m} decidiu a partida. Stockfish antes: ${b}; depois: ${a} — e a avaliação não voltou mais.`,
    swing: (m, a) => `Depois de ${m}, o Stockfish via ${a} — e mesmo assim a partida terminou empatada.`,
    clock: (t) => `O lance foi jogado com ${t} no relógio.`,
    better: (mv) => `A escolha do Stockfish era ${mv}. Por quê?`,
    liked: 'O que o Stockfish viu nesse lance?',
    reply: (mv) => `E a melhor resposta, ${mv}, veio na hora.`,
    upset: (s, g) => `O rating dizia o contrário: as ${T['pt-BR'].side[s]} tinham ${g} pontos a menos.`,
    mate: (n) => `A partida terminou em xeque-mate no lance ${n}.`,
    cta: 'Reveja lance a lance e continue a posição-chave contra o motor.',
  },
  ru: {
    round: (r) => `тур ${r}`, women: 'женский турнир',
    side: { white: 'белых', black: 'чёрных' },
    assess: { level: () => 'равенство', small: (s) => `небольшой перевес ${T.ru.side[s]}`, clear: (s) => `явный перевес ${T.ru.side[s]}`, winning: (s) => `выигранная позиция у ${T.ru.side[s]}`, mate: (s) => `форсированный мат в пользу ${T.ru.side[s]}` },
    win: (s) => `победа ${T.ru.side[s]}`, draw: 'ничья',
    moves: (n) => `за ${n} ${plural('ru', n, { one: 'ход', few: 'хода', many: 'ходов', other: 'хода' })}`,
    head: { mate: (n) => `мат на ${n}-м ходу`, upset: (g) => `сенсация при разнице в ${g} ${plural('ru', g, { one: 'пункт', few: 'пункта', many: 'пунктов', other: 'пункта' })} рейтинга`, clock: (t) => `всё решил один ход при ${t} на часах`, challenge: 'какой ход хотел движок?', decider: 'ход, который всё решил', chance: 'шанс на победу по оценке Stockfish, который не реализовался' },
    mistake: (m, b, a) => `Stockfish до хода ${m}: ${b}. После: ${a}.`,
    breakthrough: (m, b, a) => `Ход ${m} решил партию. Stockfish до него: ${b}; после: ${a} — и оценка уже не вернулась.`,
    swing: (m, a) => `После хода ${m} у Stockfish было ${a} — и всё же партия закончилась вничью.`,
    clock: (t) => `Ход был сделан при ${t} на часах.`,
    better: (mv) => `Выбор Stockfish — ${mv}. Почему?`,
    liked: 'Что Stockfish увидел в этом ходе?',
    reply: (mv) => `А лучший ответ, ${mv}, последовал сразу.`,
    upset: (s, g) => `Рейтинг говорил обратное: у ${T.ru.side[s]} было на ${g} ${plural('ru', g, { one: 'пункт', few: 'пункта', many: 'пунктов', other: 'пункта' })} меньше.`,
    mate: (n) => `Партия закончилась матом на ${n}-м ходу.`,
    cta: 'Посмотрите партию ход за ходом и продолжите ключевую позицию против движка.',
  },
  pl: {
    round: (r) => `runda ${r}`, women: 'kobiety',
    side: { white: 'białych', black: 'czarnych' },
    nom: { white: 'białe', black: 'czarne' },
    assess: { level: () => 'równowaga', small: (s) => `lekka przewaga ${T.pl.side[s]}`, clear: (s) => `wyraźna przewaga ${T.pl.side[s]}`, winning: (s) => `wygrana pozycja ${T.pl.side[s]}`, mate: (s) => `wymuszony mat dla ${T.pl.side[s]}` },
    win: (s) => `wygrana ${T.pl.side[s]}`, draw: 'remis',
    moves: (n) => `w ${n}. ruchu`,
    head: { mate: (n) => `mat w ${n}. ruchu`, upset: (g) => `sensacja przy ${g} ${plural('pl', g, { one: 'punkcie', few: 'punktach', many: 'punktach', other: 'punktach' })} różnicy rankingu`, clock: (t) => `jeden ruch przy ${t} na zegarze przesądził wszystko`, challenge: 'jaki ruch chciał silnik?', decider: 'ruch, który przesądził partię', chance: 'szansa na wygraną według Stockfisha, która przepadła' },
    mistake: (m, b, a) => `Stockfish przed ${m}: ${b}. Po nim: ${a}.`,
    breakthrough: (m, b, a) => `${m} przesądził partię. Stockfish przed nim: ${b}; po nim: ${a} — i ocena już nie wróciła.`,
    swing: (m, a) => `Po ${m} Stockfish widział ${a}, a jednak partia zakończyła się remisem.`,
    clock: (t) => `Ruch padł przy ${t} na zegarze.`,
    better: (mv) => `Wybór Stockfisha: ${mv}. Dlaczego?`,
    liked: 'Co Stockfish zobaczył w tym ruchu?',
    reply: (mv) => `A najlepsza odpowiedź, ${mv}, padła od razu.`,
    upset: (s, g) => `Ranking mówił co innego: ${T.pl.nom[s]} miały o ${g} ${plural('pl', g, { one: 'punkt', few: 'punkty', many: 'punktów', other: 'punktu' })} mniej.`,
    mate: (n) => `Partia zakończyła się matem w ${n}. ruchu.`,
    cta: 'Odtwórz ją ruch po ruchu i zagraj kluczową pozycję przeciw silnikowi.',
  },
  cs: {
    round: (r) => `${r}. kolo`, women: 'ženy',
    side: { white: 'bílého', black: 'černého' },
    nom: { white: 'Bílý', black: 'Černý' },
    assess: { level: () => 'vyrovnaná pozice', small: (s) => `malá výhoda ${T.cs.side[s]}`, clear: (s) => `jasná výhoda ${T.cs.side[s]}`, winning: (s) => `vyhraná pozice ${T.cs.side[s]}`, mate: (s) => `vynucený mat pro ${T.cs.side[s]}` },
    win: (s) => `výhra ${T.cs.side[s]}`, draw: 'remíza',
    moves: (n) => `v ${n}. tahu`,
    head: { mate: (n) => `mat v ${n}. tahu`, upset: (g) => `překvapení při rozdílu ${g} ${g === 1 ? 'bodu' : 'bodů'} Elo`, clock: (t) => `jeden tah s ${t} na hodinách rozhodl`, challenge: 'jaký tah chtěl engine?', decider: 'tah, který rozhodl', chance: 'šance na výhru podle Stockfishe, která nevyšla' },
    mistake: (m, b, a) => `Stockfish před tahem ${m}: ${b}. Po něm: ${a}.`,
    breakthrough: (m, b, a) => `Tah ${m} rozhodl partii. Stockfish předtím: ${b}; potom: ${a} – a hodnocení se už nevrátilo.`,
    swing: (m, a) => `Po tahu ${m} viděl Stockfish ${a}, a přesto partie skončila remízou.`,
    clock: (t) => `Tah padl s ${t} na hodinách.`,
    better: (mv) => `Volba Stockfishe: ${mv}. Proč?`,
    liked: 'Co Stockfish v tom tahu viděl?',
    reply: (mv) => `A nejlepší odpověď, ${mv}, přišla hned.`,
    upset: (s, g) => `Elo tvrdilo opak: ${T.cs.nom[s]} měl o ${g} ${g === 1 ? 'bod' : g < 5 ? 'body' : 'bodů'} méně.`,
    mate: (n) => `Partie skončila matem v ${n}. tahu.`,
    cta: 'Přehrajte si ji tah po tahu a pokračujte v klíčové pozici proti enginu.',
  },
  nl: {
    round: (r) => `ronde ${r}`, women: 'vrouwen',
    side: { white: 'wit', black: 'zwart' },
    assess: { level: () => 'gelijk', small: (s) => `licht voordeel voor ${T.nl.side[s]}`, clear: (s) => `duidelijk voordeel voor ${T.nl.side[s]}`, winning: (s) => `gewonnen stelling voor ${T.nl.side[s]}`, mate: (s) => `geforceerd mat voor ${T.nl.side[s]}` },
    win: (s) => `winst voor ${T.nl.side[s]}`, draw: 'remise',
    moves: (n) => `in ${n} ${n === 1 ? 'zet' : 'zetten'}`,
    head: { mate: (n) => `mat in de ${n}e zet`, upset: (g) => `de verrassing bij ${g} Elo-punten verschil`, clock: (t) => `één zet met ${t} op de klok besliste alles`, challenge: 'welke zet wilde de engine?', decider: 'de zet die alles besliste', chance: 'een winstkans volgens Stockfish die voorbijging' },
    mistake: (m, b, a) => `Stockfish vóór ${m}: ${b}. Daarna: ${a}.`,
    breakthrough: (m, b, a) => `${m} besliste de partij. Stockfish ervoor: ${b}; erna: ${a} – en de evaluatie kwam niet meer terug.`,
    swing: (m, a) => `Na ${m} zag Stockfish ${a}, en toch eindigde de partij in remise.`,
    clock: (t) => `De zet werd gespeeld met ${t} op de klok.`,
    better: (mv) => `De keuze van Stockfish was ${mv}. Waarom?`,
    liked: 'Wat zag Stockfish in die zet?',
    reply: (mv) => `En het beste antwoord, ${mv}, kwam meteen.`,
    upset: (s, g) => `De ratings zeiden iets anders: ${T.nl.side[s]} stond ${g} punten lager.`,
    mate: (n) => `De partij eindigde met mat in de ${n}e zet.`,
    cta: 'Speel de partij zet voor zet na en speel de sleutelstelling verder tegen de engine.',
  },
  sv: {
    round: (r) => `rond ${r}`, women: 'damer',
    side: { white: 'vit', black: 'svart' },
    assess: { level: () => 'jämnt', small: (s) => `liten fördel för ${T.sv.side[s]}`, clear: (s) => `klar fördel för ${T.sv.side[s]}`, winning: (s) => `vunnen ställning för ${T.sv.side[s]}`, mate: (s) => `forcerad matt för ${T.sv.side[s]}` },
    win: (s) => `vinst för ${T.sv.side[s]}`, draw: 'remi',
    moves: (n) => `på ${n} drag`,
    head: { mate: (n) => `matt i drag ${n}`, upset: (g) => `skrällen vid ${g} ratingpoängs skillnad`, clock: (t) => `ett drag med ${t} kvar på klockan avgjorde`, challenge: 'vilket drag ville motorn ha?', decider: 'draget som avgjorde allt', chance: 'en vinstchans enligt Stockfish som gick förlorad' },
    mistake: (m, b, a) => `Stockfish före ${m}: ${b}. Efter: ${a}.`,
    breakthrough: (m, b, a) => `${m} avgjorde partiet. Stockfish före: ${b}; efter: ${a} – och värderingen vände aldrig tillbaka.`,
    swing: (m, a) => `Efter ${m} såg Stockfish ${a}, och ändå slutade partiet remi.`,
    clock: (t) => `Draget spelades med ${t} kvar på klockan.`,
    better: (mv) => `Stockfish ville spela ${mv}. Varför?`,
    liked: 'Vad såg Stockfish i det draget?',
    reply: (mv) => `Och det bästa svaret, ${mv}, kom direkt.`,
    upset: (s, g) => `Ratingen sa något annat: ${T.sv.side[s]} låg ${g} poäng lägre.`,
    mate: (n) => `Partiet slutade med matt i drag ${n}.`,
    cta: 'Spela upp partiet drag för drag och spela vidare från nyckelställningen mot motorn.',
  },
  da: {
    round: (r) => `runde ${r}`, women: 'damer',
    side: { white: 'hvid', black: 'sort' },
    assess: { level: () => 'lige', small: (s) => `lille fordel til ${T.da.side[s]}`, clear: (s) => `klar fordel til ${T.da.side[s]}`, winning: (s) => `vundet stilling til ${T.da.side[s]}`, mate: (s) => `tvunget mat til ${T.da.side[s]}` },
    win: (s) => `sejr til ${T.da.side[s]}`, draw: 'remis',
    moves: (n) => `på ${n} træk`,
    head: { mate: (n) => `mat i træk ${n}`, upset: (g) => `overraskelsen ved ${g} ratingpoints forskel`, clock: (t) => `ét træk med ${t} på uret afgjorde det`, challenge: 'hvilket træk ville motoren have?', decider: 'trækket, der afgjorde det hele', chance: 'en gevinstchance ifølge Stockfish, der gled væk' },
    mistake: (m, b, a) => `Stockfish før ${m}: ${b}. Efter: ${a}.`,
    breakthrough: (m, b, a) => `${m} afgjorde partiet. Stockfish før: ${b}; efter: ${a} – og vurderingen vendte aldrig tilbage.`,
    swing: (m, a) => `Efter ${m} så Stockfish ${a}, og alligevel endte partiet remis.`,
    clock: (t) => `Trækket blev spillet med ${t} tilbage på uret.`,
    better: (mv) => `Stockfish ville spille ${mv}. Hvorfor?`,
    liked: 'Hvad så Stockfish i det træk?',
    reply: (mv) => `Og det bedste svar, ${mv}, kom med det samme.`,
    upset: (s, g) => `Ratingen sagde noget andet: ${T.da.side[s]} lå ${g} point lavere.`,
    mate: (n) => `Partiet sluttede med mat i træk ${n}.`,
    cta: 'Gennemspil partiet træk for træk, og spil videre fra nøglestillingen mod motoren.',
  },
  no: {
    round: (r) => `runde ${r}`, women: 'kvinner',
    side: { white: 'hvit', black: 'svart' },
    assess: { level: () => 'likt', small: (s) => `liten fordel til ${T.no.side[s]}`, clear: (s) => `klar fordel til ${T.no.side[s]}`, winning: (s) => `vunnet stilling for ${T.no.side[s]}`, mate: (s) => `tvunget matt for ${T.no.side[s]}` },
    win: (s) => `seier til ${T.no.side[s]}`, draw: 'remis',
    moves: (n) => `på ${n} trekk`,
    head: { mate: (n) => `matt i trekk ${n}`, upset: (g) => `overraskelsen ved ${g} ratingpoengs forskjell`, clock: (t) => `ett trekk med ${t} på klokken avgjorde`, challenge: 'hvilket trekk ville motoren ha?', decider: 'trekket som avgjorde alt', chance: 'en vinstsjanse ifølge Stockfish som gled unna' },
    mistake: (m, b, a) => `Stockfish før ${m}: ${b}. Etter: ${a}.`,
    breakthrough: (m, b, a) => `${m} avgjorde partiet. Stockfish før: ${b}; etter: ${a} – og vurderingen snudde aldri tilbake.`,
    swing: (m, a) => `Etter ${m} så Stockfish ${a}, og likevel endte partiet remis.`,
    clock: (t) => `Trekket ble spilt med ${t} igjen på klokken.`,
    better: (mv) => `Stockfish ville spille ${mv}. Hvorfor?`,
    liked: 'Hva så Stockfish i det trekket?',
    reply: (mv) => `Og det beste svaret, ${mv}, kom med en gang.`,
    upset: (s, g) => `Ratingen sa noe annet: ${T.no.side[s]} lå ${g} poeng lavere.`,
    mate: (n) => `Partiet endte med matt i trekk ${n}.`,
    cta: 'Spill partiet av trekk for trekk, og spill videre fra nøkkelstillingen mot motoren.',
  },
  fi: {
    round: (r) => `${r}. kierros`, women: 'naiset',
    side: { white: 'valkean', black: 'mustan' },
    to: { white: 'valkealle', black: 'mustalle' },
    nom: { white: 'valkea', black: 'musta' },
    assess: { level: () => 'tasainen', small: (s) => `pieni etu ${T.fi.to[s]}`, clear: (s) => `selvä etu ${T.fi.to[s]}`, winning: (s) => `voittoasema ${T.fi.to[s]}`, mate: (s) => `pakotettu matti ${T.fi.to[s]}` },
    win: (s) => `${T.fi.side[s]} voitto`, draw: 'tasapeli',
    moves: (n) => `${n} siirrossa`,
    head: { mate: (n) => `matti siirrolla ${n}`, upset: (g) => `yllätys ${g} Elo-pisteen erolla`, clock: (t) => `yksi siirto ratkaisi, kellossa ${t}`, challenge: 'minkä siirron moottori olisi halunnut?', decider: 'siirto, joka ratkaisi kaiken', chance: 'Stockfishin mukaan voittomahdollisuus, joka meni ohi' },
    mistake: (m, b, a) => `Stockfish ennen siirtoa ${m}: ${b}. Sen jälkeen: ${a}.`,
    breakthrough: (m, b, a) => `${m} ratkaisi pelin. Stockfish ennen: ${b}; jälkeen: ${a} – eikä arvio enää kääntynyt.`,
    swing: (m, a) => `Siirron ${m} jälkeen Stockfish näki: ${a}. Silti peli päättyi tasapeliin.`,
    clock: (t) => `Siirto tehtiin, kun kellossa oli ${t}.`,
    better: (mv) => `Stockfishin valinta oli ${mv}. Miksi?`,
    liked: 'Mitä Stockfish näki siinä siirrossa?',
    reply: (mv) => `Ja paras vastaus, ${mv}, tuli heti.`,
    upset: (s, g) => `Elo-luvut kertoivat muuta: ${T.fi.nom[s]} oli ${g} pistettä alempana.`,
    mate: (n) => `Peli päättyi mattiin siirrolla ${n}.`,
    cta: 'Katso peli siirto siirrolta ja jatka avainasemasta moottoria vastaan.',
  },
  hu: {
    round: (r) => `${r}. forduló`, women: 'női',
    side: { white: 'világos', black: 'sötét' },
    assess: { level: () => 'kiegyenlített állás', small: (s) => `${T.hu.side[s]} kis előnye`, clear: (s) => `${T.hu.side[s]} egyértelmű előnye`, winning: (s) => `${T.hu.side[s]} nyerő állása`, mate: (s) => `${T.hu.side[s]} kikényszerített mattja` },
    win: (s) => `${T.hu.side[s]} győzelme`, draw: 'döntetlen',
    moves: (n) => `${n} lépésben`,
    head: { mate: (n) => `matt (${n}. lépés)`, upset: (g) => `meglepetés ${g} Élő-pont különbséggel`, clock: (t) => `egyetlen lépés döntött, ${t} volt az órán`, challenge: 'melyik lépést akarta a motor?', decider: 'a lépés, amely mindent eldöntött', chance: 'a Stockfish szerinti nyerési esély, amely elszállt' },
    mistake: (m, b, a) => `Stockfish értékelése ${m} előtt: ${b}. Utána: ${a}.`,
    breakthrough: (m, b, a) => `${m} döntötte el a játszmát. Stockfish előtte: ${b}; utána: ${a} – és az értékelés már nem fordult vissza.`,
    swing: (m, a) => `${m} után a Stockfish értékelése: ${a}. A játszma mégis döntetlen lett.`,
    clock: (t) => `A lépés akkor született, amikor ${t} volt hátra az órán.`,
    better: (mv) => `A Stockfish választása ${mv} lett volna. Miért?`,
    liked: 'Mit látott a Stockfish ebben a lépésben?',
    reply: (mv) => `A legjobb válasz, ${mv}, azonnal érkezett.`,
    upset: (s, g) => `Az Élő-pontszám mást mondott: ${T.hu.side[s]} ${g} ponttal alacsonyabban állt.`,
    mate: (n) => `A játszma mattal ért véget (${n}. lépés).`,
    cta: 'Játszd végig lépésről lépésre, és folytasd a kulcsállást a motor ellen.',
  },
  tr: {
    round: (r) => `${r}. tur`, women: 'kadınlar',
    side: { white: 'Beyazın', black: 'Siyahın' },
    nom: { white: 'Beyaz', black: 'Siyah' },
    assess: { level: () => 'eşitlik', small: (s) => `${T.tr.side[s]} hafif üstünlüğü`, clear: (s) => `${T.tr.side[s]} açık üstünlüğü`, winning: (s) => `${T.tr.side[s]} kazanan konumu`, mate: (s) => `${T.tr.side[s]} zorlamalı matı` },
    win: (s) => `${T.tr.side[s]} galibiyeti`, draw: 'beraberlik',
    moves: (n) => `${n} hamlede`,
    head: { mate: (n) => `${n}. hamlede mat`, upset: (g) => `${g} Elo puanı farkla sürpriz`, clock: (t) => `saatte ${t} kala tek hamle belirledi`, challenge: 'motor hangi hamleyi istiyordu?', decider: 'her şeyi belirleyen hamle', chance: 'Stockfish’e göre kaçan bir galibiyet şansı' },
    mistake: (m, b, a) => `Stockfish, ${m} öncesi: ${b}. Sonrası: ${a}.`,
    breakthrough: (m, b, a) => `Oyunu ${m} belirledi. Stockfish öncesinde: ${b}; sonrasında: ${a} — ve değerlendirme bir daha geri dönmedi.`,
    swing: (m, a) => `${m} sonrasında Stockfish’in değerlendirmesi: ${a}. Yine de oyun berabere bitti.`,
    clock: (t) => `Hamle saatte ${t} kala yapıldı.`,
    better: (mv) => `Stockfish’in tercihi ${mv} idi. Neden?`,
    liked: 'Stockfish bu hamlede ne gördü?',
    reply: (mv) => `En iyi yanıt, ${mv}, hemen geldi.`,
    upset: (s, g) => `Reytingler başka şey söylüyordu: ${T.tr.nom[s]} ${g} puan gerideydi.`,
    mate: (n) => `Oyun ${n}. hamlede matla bitti.`,
    cta: 'Oyunu hamle hamle izle ve kilit konumdan motora karşı devam et.',
  },
  el: {
    round: (r) => `γύρος ${r}`, women: 'γυναικών',
    side: { white: 'των λευκών', black: 'των μαύρων' },
    nom: { white: 'τα λευκά', black: 'τα μαύρα' },
    assess: { level: () => 'ισορροπία', small: (s) => `μικρό πλεονέκτημα ${T.el.side[s]}`, clear: (s) => `σαφές πλεονέκτημα ${T.el.side[s]}`, winning: (s) => `κερδισμένη θέση ${T.el.side[s]}`, mate: (s) => `αναγκαστικό ματ υπέρ ${T.el.side[s]}` },
    win: (s) => `νίκη ${T.el.side[s]}`, draw: 'ισοπαλία',
    moves: (n) => `σε ${n} ${n === 1 ? 'κίνηση' : 'κινήσεις'}`,
    head: { mate: (n) => `ματ στην κίνηση ${n}`, upset: (g) => `έκπληξη με διαφορά ${g} βαθμών Elo`, clock: (t) => `μία κίνηση με ${t} στο ρολόι τα έκρινε όλα`, challenge: 'ποια κίνηση ήθελε η μηχανή;', decider: 'η κίνηση που τα έκρινε όλα', chance: 'μια ευκαιρία νίκης, κατά το Stockfish, που χάθηκε' },
    mistake: (m, b, a) => `Stockfish πριν από την ${m}: ${b}. Μετά: ${a}.`,
    breakthrough: (m, b, a) => `Η ${m} έκρινε την παρτίδα. Stockfish πριν: ${b}· μετά: ${a} — και η εκτίμηση δεν γύρισε ποτέ πίσω.`,
    swing: (m, a) => `Μετά την ${m} το Stockfish έβλεπε ${a}, κι όμως η παρτίδα έληξε ισόπαλη.`,
    clock: (t) => `Η κίνηση παίχτηκε με ${t} στο ρολόι.`,
    better: (mv) => `Η επιλογή του Stockfish ήταν ${mv}. Γιατί;`,
    liked: 'Τι είδε το Stockfish σε αυτή την κίνηση;',
    reply: (mv) => `Και η καλύτερη απάντηση, ${mv}, ήρθε αμέσως.`,
    upset: (s, g) => `Η βαθμολογία έλεγε άλλα: ${T.el.nom[s]} είχαν ${g} βαθμούς λιγότερους.`,
    mate: (n) => `Η παρτίδα έληξε με ματ στην κίνηση ${n}.`,
    cta: 'Δείτε την κίνηση προς κίνηση και συνεχίστε τη θέση-κλειδί απέναντι στη μηχανή.',
  },
  he: {
    rtl: true,
    round: (r) => `סיבוב ${r}`, women: 'נשים',
    side: { white: 'לבן', black: 'שחור' },
    assess: { level: () => 'שוויון', small: (s) => `יתרון קל ל${T.he.side[s]}`, clear: (s) => `יתרון ברור ל${T.he.side[s]}`, winning: (s) => `עמדה מנצחת ל${T.he.side[s]}`, mate: (s) => `מט כפוי ל${T.he.side[s]}` },
    win: (s) => `ניצחון ל${T.he.side[s]}`, draw: 'תיקו',
    moves: (n) => `ב־${n} מסעים`,
    head: { mate: (n) => `מט במסע ${n}`, upset: (g) => `הפתעה בפער של ${g} נקודות דירוג`, clock: (t) => `מסע אחד, עם ${t} על השעון, הכריע`, challenge: 'איזה מסע רצה המנוע?', decider: 'המסע שהכריע הכול', chance: 'הזדמנות לניצחון, לפי Stockfish, שחלפה' },
    mistake: (m, b, a) => `Stockfish לפני ${m}: ${b}. אחריו: ${a}.`,
    breakthrough: (m, b, a) => `${m} הכריע את המשחק. Stockfish לפני: ${b}; אחרי: ${a} — וההערכה לא חזרה עוד.`,
    swing: (m, a) => `אחרי ${m} ההערכה של Stockfish: ${a}. ובכל זאת המשחק הסתיים בתיקו.`,
    clock: (t) => `המסע שוחק עם ${t} על השעון.`,
    better: (mv) => `הבחירה של Stockfish: ${mv}. למה?`,
    liked: 'מה ראה Stockfish במסע הזה?',
    reply: (mv) => `והתשובה הטובה ביותר, ${mv}, הגיעה מיד.`,
    upset: (s, g) => `הדירוג אמר אחרת: ל${T.he.side[s]} היו ${g} נקודות פחות.`,
    mate: (n) => `המשחק הסתיים במט במסע ${n}.`,
    cta: 'צפו במשחק מסע אחר מסע, והמשיכו את עמדת המפתח מול המנוע.',
  },
  ar: {
    rtl: true,
    round: (r) => `الجولة ${r}`, women: 'السيدات',
    side: { white: 'الأبيض', black: 'الأسود' },
    to: { white: 'للأبيض', black: 'للأسود' },
    assess: { level: () => 'توازن', small: (s) => `أفضلية طفيفة ${T.ar.to[s]}`, clear: (s) => `أفضلية واضحة ${T.ar.to[s]}`, winning: (s) => `موقف فائز ${T.ar.to[s]}`, mate: (s) => `كش مات إجباري ${T.ar.to[s]}` },
    win: (s) => `فوز ${T.ar.side[s]}`, draw: 'تعادل',
    moves: (n) => `في ${n} نقلة`,
    head: { mate: (n) => `كش مات في النقلة ${n}`, upset: (g) => `مفاجأة بفارق ${g} نقطة في التصنيف`, clock: (t) => `نقلة واحدة، و${t} على الساعة، حسمت كل شيء`, challenge: 'ما النقلة التي أرادها المحرك؟', decider: 'النقلة التي حسمت كل شيء', chance: 'فرصة فوز، بحسب Stockfish، لم تتحقق' },
    mistake: (m, b, a) => `تقييم Stockfish قبل ${m}: ${b}. بعدها: ${a}.`,
    breakthrough: (m, b, a) => `حسمت ${m} المباراة. Stockfish قبلها: ${b}؛ بعدها: ${a} — ولم يعد التقييم إلى الوراء.`,
    swing: (m, a) => `بعد ${m} كان تقييم Stockfish: ${a}. ومع ذلك انتهت المباراة بالتعادل.`,
    clock: (t) => `لُعبت النقلة و${t} على الساعة.`,
    better: (mv) => `اختيار Stockfish كان ${mv}. لماذا؟`,
    liked: 'ماذا رأى Stockfish في هذه النقلة؟',
    reply: (mv) => `وجاء أفضل رد، ${mv}، على الفور.`,
    upset: (s, g) => `التصنيف قال غير ذلك: كان ${T.ar.side[s]} أقل بـ${g} نقطة.`,
    mate: (n) => `انتهت المباراة بكش مات في النقلة ${n}.`,
    cta: 'أعد مشاهدة المباراة نقلة بنقلة، وتابع اللعب من الموقف الحاسم ضد المحرك.',
  },
  hi: {
    round: (r) => `राउंड ${r}`, women: 'महिला',
    side: { white: 'सफ़ेद', black: 'काले' },
    assess: { level: () => 'बराबरी', small: (s) => `${T.hi.side[s]} को हल्की बढ़त`, clear: (s) => `${T.hi.side[s]} को साफ़ बढ़त`, winning: (s) => `${T.hi.side[s]} के लिए जीती हुई स्थिति`, mate: (s) => `${T.hi.side[s]} के लिए ज़बरन मात` },
    win: (s) => `${T.hi.side[s]} की जीत`, draw: 'ड्रॉ',
    moves: (n) => `${n} चालों में`,
    head: { mate: (n) => `चाल ${n} पर मात`, upset: (g) => `रेटिंग में ${g} अंकों के अंतर के साथ उलटफेर`, clock: (t) => `घड़ी पर ${t} रहते एक चाल ने फ़ैसला किया`, challenge: 'इंजन कौन-सी चाल चाहता था?', decider: 'वह चाल जिसने सब तय कर दिया', chance: 'Stockfish के अनुसार जीत का एक मौका, जो निकल गया' },
    mistake: (m, b, a) => `${m} से पहले Stockfish: ${b}। उसके बाद: ${a}।`,
    breakthrough: (m, b, a) => `${m} ने बाज़ी का फ़ैसला किया। Stockfish पहले: ${b}; बाद में: ${a} — और आकलन फिर नहीं पलटा।`,
    swing: (m, a) => `${m} के बाद Stockfish का आकलन: ${a}। फिर भी बाज़ी ड्रॉ रही।`,
    clock: (t) => `यह चाल घड़ी पर ${t} रहते चली गई।`,
    better: (mv) => `Stockfish की पसंद ${mv} थी। क्यों?`,
    liked: 'Stockfish ने इस चाल में क्या देखा?',
    reply: (mv) => `और सबसे अच्छा जवाब, ${mv}, तुरंत आया।`,
    upset: (s, g) => `रेटिंग कुछ और कहती थी: ${T.hi.side[s]} की रेटिंग ${g} अंक कम थी।`,
    mate: (n) => `बाज़ी चाल ${n} पर मात के साथ ख़त्म हुई।`,
    cta: 'बाज़ी को चाल-दर-चाल देखें, और अहम स्थिति से इंजन के ख़िलाफ़ खेल जारी रखें।',
  },
  ja: {
    round: (r) => `第${r}ラウンド`, women: '女子',
    side: { white: '白', black: '黒' },
    assess: { level: () => '互角', small: (s) => `${T.ja.side[s]}がやや優勢`, clear: (s) => `${T.ja.side[s]}が優勢`, winning: (s) => `${T.ja.side[s]}が勝勢`, mate: (s) => `${T.ja.side[s]}の強制メイト` },
    win: (s) => `${T.ja.side[s]}の勝ち`, draw: '引き分け',
    moves: (n) => `（${n}手）`,
    head: { mate: (n) => `${n}手目でチェックメイト`, upset: (g) => `レーティング差${g}の番狂わせ`, clock: (t) => `残り${t}の一手が勝負を決めた`, challenge: 'エンジンが求めた手は？', decider: '勝負を決めた一手', chance: 'Stockfishの評価では勝ちのチャンスがあったが、引き分けに' },
    mistake: (m, b, a) => `${m}の前のStockfish評価：${b}。その後：${a}。`,
    breakthrough: (m, b, a) => `${m}が勝負を決めた。Stockfish評価は前が${b}、後が${a}。評価はその後戻らなかった。`,
    swing: (m, a) => `${m}の後のStockfish評価は${a}。それでも対局は引き分けに終わった。`,
    clock: (t) => `この手は残り時間${t}で指された。`,
    better: (mv) => `Stockfishの選択は${mv}。なぜか？`,
    liked: 'Stockfishはこの手に何を見たのか？',
    reply: (mv) => `そして最善の応手${mv}がすぐに返ってきた。`,
    upset: (s, g) => `レーティングは逆を示していた。${T.ja.side[s]}のレーティングは${g}低かった。`,
    mate: (n) => `対局は${n}手目のチェックメイトで終わった。`,
    cta: '一手ずつ再生し、重要な局面からエンジンと対戦してみよう。',
    join: '',
  },
  ko: {
    round: (r) => `${r}라운드`, women: '여자부',
    side: { white: '백', black: '흑' },
    assess: { level: () => '균형', small: (s) => `${T.ko.side[s]} 약간 우세`, clear: (s) => `${T.ko.side[s]} 확실한 우세`, winning: (s) => `${T.ko.side[s]} 승리 국면`, mate: (s) => `${T.ko.side[s]} 강제 체크메이트` },
    win: (s) => `${T.ko.side[s]} 승리`, draw: '무승부',
    moves: (n) => `(${n}수)`,
    head: { mate: (n) => `${n}수째 체크메이트`, upset: (g) => `레이팅 차이 ${g}점의 이변`, clock: (t) => `시계에 ${t} 남기고 둔 한 수가 승부를 갈랐다`, challenge: '엔진이 원한 수는?', decider: '승부를 가른 한 수', chance: 'Stockfish가 본 승리 기회, 이어지지 않았다' },
    mistake: (m, b, a) => `${m} 이전 Stockfish 평가: ${b}. 이후: ${a}.`,
    breakthrough: (m, b, a) => `승부를 결정한 수는 ${m}. Stockfish 평가 이전: ${b}, 이후: ${a} — 평가는 다시 돌아오지 않았다.`,
    swing: (m, a) => `${m} 이후 Stockfish 평가: ${a}. 그래도 대국은 무승부로 끝났다.`,
    clock: (t) => `이 수를 둘 때 남은 시간: ${t}.`,
    better: (mv) => `Stockfish의 선택은 ${mv}. 왜일까?`,
    liked: 'Stockfish는 이 수에서 무엇을 봤을까?',
    reply: (mv) => `그리고 최선의 응수(${mv})가 곧바로 나왔다.`,
    upset: (s, g) => `레이팅은 반대였다: ${T.ko.side[s]}의 레이팅이 ${g}점 낮았다.`,
    mate: (n) => `대국은 ${n}수째 체크메이트로 끝났다.`,
    cta: '한 수씩 다시 보고, 핵심 국면부터 엔진과 이어서 둬 보세요.',
  },
  'zh-Hans': {
    round: (r) => `第${r}轮`, women: '女子组',
    side: { white: '白方', black: '黑方' },
    assess: { level: () => '均势', small: (s) => `${T['zh-Hans'].side[s]}略优`, clear: (s) => `${T['zh-Hans'].side[s]}明显占优`, winning: (s) => `${T['zh-Hans'].side[s]}胜势`, mate: (s) => `${T['zh-Hans'].side[s]}有强制将杀` },
    win: (s) => `${T['zh-Hans'].side[s]}胜`, draw: '和棋',
    moves: (n) => `，共${n}回合`,
    head: { mate: (n) => `第${n}回合将杀`, upset: (g) => `等级分相差${g}分的爆冷`, clock: (t) => `钟上仅剩${t}，一步定乾坤`, challenge: '引擎想走哪一步？', decider: '决定胜负的一步', chance: '按Stockfish评估的胜机，最终未能兑现' },
    mistake: (m, b, a) => `${m}之前Stockfish评估：${b}。之后：${a}。`,
    breakthrough: (m, b, a) => `${m}决定了这盘棋。Stockfish评估，之前：${b}；之后：${a}，此后再未回摆。`,
    swing: (m, a) => `${m}之后，Stockfish评估为${a}，但这盘棋仍以和棋告终。`,
    clock: (t) => `这步棋走出时，钟上剩${t}。`,
    better: (mv) => `Stockfish的选择是${mv}。为什么？`,
    liked: 'Stockfish在这步棋里看到了什么？',
    reply: (mv) => `而最佳应着${mv}随即出现。`,
    upset: (s, g) => `等级分却相反：${T['zh-Hans'].side[s]}低了${g}分。`,
    mate: (n) => `对局在第${n}回合以将杀结束。`,
    cta: '逐步回放这盘棋，再从关键局面与引擎继续对弈。',
    join: '',
  },
  'zh-Hant': {
    round: (r) => `第${r}輪`, women: '女子組',
    side: { white: '白方', black: '黑方' },
    assess: { level: () => '均勢', small: (s) => `${T['zh-Hant'].side[s]}略優`, clear: (s) => `${T['zh-Hant'].side[s]}明顯佔優`, winning: (s) => `${T['zh-Hant'].side[s]}勝勢`, mate: (s) => `${T['zh-Hant'].side[s]}有強制將殺` },
    win: (s) => `${T['zh-Hant'].side[s]}勝`, draw: '和棋',
    moves: (n) => `，共${n}回合`,
    head: { mate: (n) => `第${n}回合將殺`, upset: (g) => `等級分相差${g}分的爆冷`, clock: (t) => `鐘上僅剩${t}，一步定乾坤`, challenge: '引擎想走哪一步？', decider: '決定勝負的一步', chance: '按Stockfish評估的勝機，最終未能兌現' },
    mistake: (m, b, a) => `${m}之前Stockfish評估：${b}。之後：${a}。`,
    breakthrough: (m, b, a) => `${m}決定了這盤棋。Stockfish評估，之前：${b}；之後：${a}，此後再未回擺。`,
    swing: (m, a) => `${m}之後，Stockfish評估為${a}，但這盤棋仍以和棋告終。`,
    clock: (t) => `這步棋走出時，鐘上剩${t}。`,
    better: (mv) => `Stockfish的選擇是${mv}。為什麼？`,
    liked: 'Stockfish在這步棋裡看到了什麼？',
    reply: (mv) => `而最佳應著${mv}隨即出現。`,
    upset: (s, g) => `等級分卻相反：${T['zh-Hant'].side[s]}低了${g}分。`,
    mate: (n) => `對局在第${n}回合以將殺結束。`,
    cta: '逐步回放這盤棋，再從關鍵局面與引擎繼續對弈。',
    join: '',
  },
  th: {
    round: (r) => `รอบที่ ${r}`, women: 'หญิง',
    side: { white: 'ฝ่ายขาว', black: 'ฝ่ายดำ' },
    assess: { level: () => 'สมดุล', small: (s) => `${T.th.side[s]}ได้เปรียบเล็กน้อย`, clear: (s) => `${T.th.side[s]}ได้เปรียบชัดเจน`, winning: (s) => `${T.th.side[s]}อยู่ในตำแหน่งชนะ`, mate: (s) => `${T.th.side[s]}มีรุกจนบังคับ` },
    win: (s) => `${T.th.side[s]}ชนะ`, draw: 'เสมอ',
    moves: (n) => `ใน ${n} ตา`,
    head: { mate: (n) => `รุกจนในตาที่ ${n}`, upset: (g) => `พลิกล็อกเมื่อเรตติ้งต่างกัน ${g} คะแนน`, clock: (t) => `ตาเดียวตอนเหลือเวลา ${t} ตัดสินทุกอย่าง`, challenge: 'เอนจินอยากเดินตาไหน?', decider: 'ตาที่ตัดสินทุกอย่าง', chance: 'โอกาสชนะตามการประเมินของ Stockfish ที่ไม่ได้เกิดขึ้น' },
    mistake: (m, b, a) => `Stockfish ก่อน ${m}: ${b} หลังจากนั้น: ${a}`,
    breakthrough: (m, b, a) => `${m} คือตาที่ตัดสินเกม Stockfish ก่อนหน้า: ${b} หลังจากนั้น: ${a} และการประเมินไม่ย้อนกลับอีกเลย`,
    swing: (m, a) => `หลัง ${m} การประเมินของ Stockfish คือ ${a} แต่เกมก็ยังจบลงด้วยการเสมอ`,
    clock: (t) => `ตานี้เดินตอนเหลือเวลา ${t}`,
    better: (mv) => `ตาที่ Stockfish เลือกคือ ${mv} ทำไม?`,
    liked: 'Stockfish เห็นอะไรในตานี้?',
    reply: (mv) => `และการตอบโต้ที่ดีที่สุด ${mv} ก็ตามมาทันที`,
    upset: (s, g) => `เรตติ้งบอกตรงข้าม: ${T.th.side[s]}มีเรตติ้งต่ำกว่า ${g} คะแนน`,
    mate: (n) => `เกมจบด้วยการรุกจนในตาที่ ${n}`,
    cta: 'ดูเกมย้อนหลังทีละตา แล้วเล่นต่อจากตำแหน่งสำคัญกับเอนจิน',
  },
  vi: {
    round: (r) => `vòng ${r}`, women: 'nữ',
    side: { white: 'Trắng', black: 'Đen' },
    assess: { level: () => 'cân bằng', small: (s) => `${T.vi.side[s]} hơi ưu thế`, clear: (s) => `${T.vi.side[s]} ưu thế rõ`, winning: (s) => `${T.vi.side[s]} ở thế thắng`, mate: (s) => `${T.vi.side[s]} có đòn chiếu hết bắt buộc` },
    win: (s) => `${T.vi.side[s]} thắng`, draw: 'hòa',
    moves: (n) => `sau ${n} nước`,
    head: { mate: (n) => `chiếu hết ở nước ${n}`, upset: (g) => `bất ngờ với chênh lệch ${g} điểm Elo`, clock: (t) => `một nước đi khi đồng hồ còn ${t} đã quyết định tất cả`, challenge: 'engine muốn đi nước nào?', decider: 'nước đi quyết định tất cả', chance: 'cơ hội thắng theo Stockfish đã trôi qua' },
    mistake: (m, b, a) => `Stockfish trước ${m}: ${b}. Sau đó: ${a}.`,
    breakthrough: (m, b, a) => `${m} quyết định ván đấu. Stockfish trước: ${b}; sau: ${a} — và đánh giá không bao giờ quay lại.`,
    swing: (m, a) => `Sau ${m}, Stockfish đánh giá ${a}, nhưng ván đấu vẫn kết thúc hòa.`,
    clock: (t) => `Nước đi được thực hiện khi đồng hồ còn ${t}.`,
    better: (mv) => `Lựa chọn của Stockfish là ${mv}. Vì sao?`,
    liked: 'Stockfish đã thấy gì trong nước đi này?',
    reply: (mv) => `Và nước đáp trả tốt nhất, ${mv}, đến ngay lập tức.`,
    upset: (s, g) => `Hệ số Elo nói điều ngược lại: ${T.vi.side[s]} thấp hơn ${g} điểm.`,
    mate: (n) => `Ván đấu kết thúc bằng chiếu hết ở nước ${n}.`,
    cta: 'Xem lại từng nước và chơi tiếp từ thế cờ then chốt với engine.',
  },
  id: {
    round: (r) => `babak ${r}`, women: 'putri',
    side: { white: 'Putih', black: 'Hitam' },
    assess: { level: () => 'seimbang', small: (s) => `${T.id.side[s]} sedikit unggul`, clear: (s) => `${T.id.side[s]} unggul jelas`, winning: (s) => `posisi menang untuk ${T.id.side[s]}`, mate: (s) => `skakmat paksa untuk ${T.id.side[s]}` },
    win: (s) => `kemenangan ${T.id.side[s]}`, draw: 'remis',
    moves: (n) => `dalam ${n} langkah`,
    head: { mate: (n) => `skakmat di langkah ${n}`, upset: (g) => `kejutan dengan selisih ${g} poin rating`, clock: (t) => `satu langkah dengan sisa ${t} di jam menentukan segalanya`, challenge: 'langkah apa yang diinginkan mesin?', decider: 'langkah yang menentukan segalanya', chance: 'peluang menang menurut Stockfish yang terlewat' },
    mistake: (m, b, a) => `Stockfish sebelum ${m}: ${b}. Sesudahnya: ${a}.`,
    breakthrough: (m, b, a) => `${m} menentukan permainan. Stockfish sebelumnya: ${b}; sesudahnya: ${a} — dan penilaian itu tak pernah berbalik.`,
    swing: (m, a) => `Setelah ${m}, penilaian Stockfish: ${a}. Namun permainan tetap berakhir remis.`,
    clock: (t) => `Langkah itu dimainkan dengan sisa ${t} di jam.`,
    better: (mv) => `Pilihan Stockfish adalah ${mv}. Mengapa?`,
    liked: 'Apa yang dilihat Stockfish dalam langkah ini?',
    reply: (mv) => `Dan jawaban terbaik, ${mv}, datang seketika.`,
    upset: (s, g) => `Rating berkata lain: ${T.id.side[s]} ${g} poin lebih rendah.`,
    mate: (n) => `Permainan berakhir dengan skakmat di langkah ${n}.`,
    cta: 'Putar ulang langkah demi langkah, lalu lanjutkan posisi kunci melawan mesin.',
  },
  ms: {
    round: (r) => `pusingan ${r}`, women: 'wanita',
    side: { white: 'Putih', black: 'Hitam' },
    assess: { level: () => 'seimbang', small: (s) => `${T.ms.side[s]} sedikit mendahului`, clear: (s) => `${T.ms.side[s]} jelas mendahului`, winning: (s) => `kedudukan menang untuk ${T.ms.side[s]}`, mate: (s) => `mat paksa untuk ${T.ms.side[s]}` },
    win: (s) => `kemenangan ${T.ms.side[s]}`, draw: 'seri',
    moves: (n) => `dalam ${n} langkah`,
    head: { mate: (n) => `mat pada langkah ${n}`, upset: (g) => `kejutan dengan beza ${g} mata penarafan`, clock: (t) => `satu langkah dengan baki ${t} pada jam menentukan segalanya`, challenge: 'langkah apakah yang dikehendaki enjin?', decider: 'langkah yang menentukan segalanya', chance: 'peluang menang menurut Stockfish yang terlepas' },
    mistake: (m, b, a) => `Stockfish sebelum ${m}: ${b}. Selepas itu: ${a}.`,
    breakthrough: (m, b, a) => `${m} menentukan permainan. Stockfish sebelumnya: ${b}; selepasnya: ${a} — dan penilaian itu tidak berpatah balik.`,
    swing: (m, a) => `Selepas ${m}, penilaian Stockfish: ${a}. Namun permainan tetap berakhir seri.`,
    clock: (t) => `Langkah itu dimainkan dengan baki ${t} pada jam.`,
    better: (mv) => `Pilihan Stockfish ialah ${mv}. Mengapa?`,
    liked: 'Apakah yang dilihat Stockfish dalam langkah ini?',
    reply: (mv) => `Dan jawapan terbaik, ${mv}, datang serta-merta.`,
    upset: (s, g) => `Penarafan berkata lain: ${T.ms.side[s]} ${g} mata lebih rendah.`,
    mate: (n) => `Permainan berakhir dengan mat pada langkah ${n}.`,
    cta: 'Main semula langkah demi langkah, kemudian teruskan kedudukan penting menentang enjin.',
  },
  bg: {
    round: (r) => `${r}. кръг`, women: 'жени',
    side: { white: 'белите', black: 'черните' },
    assess: { level: () => 'равенство', small: (s) => `леко предимство за ${T.bg.side[s]}`, clear: (s) => `ясно предимство за ${T.bg.side[s]}`, winning: (s) => `спечелена позиция за ${T.bg.side[s]}`, mate: (s) => `форсиран мат за ${T.bg.side[s]}` },
    win: (s) => `победа за ${T.bg.side[s]}`, draw: 'реми',
    moves: (n) => `за ${n} ${n === 1 ? 'ход' : 'хода'}`,
    head: { mate: (n) => `мат на ${n}-ия ход`, upset: (g) => `изненада при ${g} точки разлика в рейтинга`, clock: (t) => `един ход при ${t} на часовника реши всичко`, challenge: 'кой ход искаше енджинът?', decider: 'ходът, който реши всичко', chance: 'шанс за победа според Stockfish, който отмина' },
    mistake: (m, b, a) => `Stockfish преди ${m}: ${b}. След него: ${a}.`,
    breakthrough: (m, b, a) => `${m} реши партията. Stockfish преди това: ${b}; след това: ${a} — и оценката повече не се върна.`,
    swing: (m, a) => `След ${m} Stockfish даваше ${a} — и въпреки това партията завърши реми.`,
    clock: (t) => `Ходът е изигран при ${t} на часовника.`,
    better: (mv) => `Изборът на Stockfish беше ${mv}. Защо?`,
    liked: 'Какво видя Stockfish в този ход?',
    reply: (mv) => `А най-добрият отговор, ${mv}, дойде веднага.`,
    upset: (s, g) => `Рейтингът казваше друго: ${T.bg.side[s]} бяха с ${g} точки по-ниско.`,
    mate: (n) => `Партията завърши с мат на ${n}-ия ход.`,
    cta: 'Разгледайте партията ход по ход и продължете ключовата позиция срещу енджина.',
  },
  ro: {
    round: (r) => `runda ${r}`, women: 'feminin',
    side: { white: 'albului', black: 'negrului' },
    short: { white: 'alb', black: 'negru' },
    nom: { white: 'Albul', black: 'Negrul' },
    assess: { level: () => 'egalitate', small: (s) => `ușor avantaj pentru ${T.ro.short[s]}`, clear: (s) => `avantaj clar pentru ${T.ro.short[s]}`, winning: (s) => `poziție câștigată pentru ${T.ro.short[s]}`, mate: (s) => `mat forțat pentru ${T.ro.short[s]}` },
    win: (s) => `victoria ${T.ro.side[s]}`, draw: 'remiză',
    moves: (n) => `în ${n} ${n === 1 ? 'mutare' : `${roDe(n)}mutări`}`,
    head: { mate: (n) => `mat la mutarea ${n}`, upset: (g) => `surpriza la ${g} ${roDe(g)}puncte Elo diferență`, clock: (t) => `o singură mutare, cu ${t} pe ceas, a decis totul`, challenge: 'ce mutare voia motorul?', decider: 'mutarea care a decis totul', chance: 'o șansă de câștig, după Stockfish, care s-a dus' },
    mistake: (m, b, a) => `Stockfish înainte de ${m}: ${b}. După: ${a}.`,
    breakthrough: (m, b, a) => `${m} a decis partida. Stockfish înainte: ${b}; după: ${a} — iar evaluarea nu s-a mai întors.`,
    swing: (m, a) => `După ${m}, Stockfish vedea ${a}, și totuși partida s-a încheiat remiză.`,
    clock: (t) => `Mutarea a fost făcută cu ${t} pe ceas.`,
    better: (mv) => `Alegerea lui Stockfish era ${mv}. De ce?`,
    liked: 'Ce a văzut Stockfish în această mutare?',
    reply: (mv) => `Iar cel mai bun răspuns, ${mv}, a venit imediat.`,
    upset: (s, g) => `Ratingul spunea altceva: ${T.ro.nom[s]} avea cu ${g} ${roDe(g)}puncte mai puțin.`,
    mate: (n) => `Partida s-a încheiat cu mat la mutarea ${n}.`,
    cta: 'Revezi-o mutare cu mutare și continuă poziția-cheie împotriva motorului.',
  },
};

/** Romanian puts "de" before a counted noun from twenty on. */
function roDe(n) {
  const rest = n % 100;
  return rest >= 20 || (rest === 0 && n > 0) ? 'de ' : '';
}

function plural(lang, n, forms) {
  const category = new Intl.PluralRules(lang).select(n);
  return forms[category] ?? forms.other;
}

/** Latin names, moves and scores inside a right-to-left sentence, each kept in one piece. */
const isolate = (text) => `⁨${text}⁩`;

function translated(f, lang) {
  const L = T[lang];
  const { story, winnerSide } = f;
  const { white, black, event } = story;
  const x = L.rtl ? isolate : (text) => text;
  const a = (score) => `${L.assess[band(score).level](band(score).side)} (${x(scoreText(score, lang))})`;
  const section = event.section === 'Women' ? L.women : event.section;
  const occasion = `${x(event.name)}${event.round ? `, ${L.round(event.round)}` : ''}${section ? ` (${x(section)})` : ''}`;
  const pairing = `${x(white.short)} – ${x(black.short)} ${x(f.score)}`;
  const move = f.move && x(f.move);
  const time = f.clock != null ? x(clockText(f.clock)) : null;

  const hook = f.hook === 'win' ? L.win(winnerSide) : f.hook === 'draw' ? L.draw
    : f.hook === 'mate' ? L.head.mate(f.moves) : f.hook === 'upset' ? L.head.upset(f.gap)
    : f.hook === 'clock' ? L.head.clock(time) : L.head[f.hook];
  const headline = `${pairing}${lang === 'ja' || lang.startsWith('zh') ? '：' : ': '}${hook}`;

  const outcome = winnerSide ? L.win(winnerSide) : L.draw;
  // Chinese and Japanese close up to their own punctuation; Hindi ends a
  // sentence with a danda, and Thai with nothing at all.
  const cjk = lang === 'ja' || lang.startsWith('zh');
  const colon = cjk ? '：' : ': ';
  const stop = cjk ? '。' : lang === 'hi' ? '।' : lang === 'th' ? '' : '.';
  const tail = L.moves(f.moves);
  const lede = `${occasion}${colon}${x(full(white))} – ${x(full(black))}${lang === 'ja' ? '、' : cjk ? '，' : ', '}${outcome}${/^[（，]/.test(tail) ? '' : ' '}${tail}${stop}`;

  const join = (parts) => parts.join(L.join ?? ' ');
  const paragraphs = [lede];
  const key = f.key;
  if (key) {
    let moment = key.kind === 'breakthrough' ? L.breakthrough(move, a(key.before), a(key.after))
      : key.kind === 'swing' ? L.swing(move, a(key.after))
      : L.mistake(move, a(key.before), a(key.after));
    if (f.clock != null && f.clock < 600) moment = join([moment, L.clock(time)]);
    paragraphs.push(moment);
    const question = [];
    if (f.better && key.kind !== 'breakthrough') question.push(L.better(x(f.better)));
    if (key.kind === 'breakthrough') question.push(L.liked);
    if (f.reply && key.kind === 'mistake') question.push(L.reply(x(f.reply)));
    if (question.length) paragraphs.push(join(question));
  }
  const context = [];
  if (f.hook === 'upset') context.push(L.upset(winnerSide, f.gap));
  if (f.mate) context.push(L.mate(f.moves));
  if (context.length) paragraphs.push(join(context));
  paragraphs.push(L.cta);
  return { headline, lede, body: paragraphs.join('\n\n') };
}

// ------------------------------------------------------------------ public

/** One language's words for a story. */
export function article(story, lang = 'en') {
  const f = facts(story);
  return lang === 'en' ? english(f) : translated(f, lang);
}

/** Every language's words for a story, checked; throws rather than publish words that fail. */
export function articles(story) {
  const out = {};
  for (const lang of LANGS) {
    const words = article(story, lang);
    const wrong = problems(`${words.headline}\n${words.body}`, lang);
    if (wrong.length) throw new Error(`${story.id} (${lang}): ${wrong.join('; ')}`);
    out[lang] = words;
  }
  return out;
}

/**
 * What would make a story unsafe or broken to publish. Every language: a
 * template left unfilled. English — the one language whose sentences are
 * free enough to say something they should not — also: a gendered pronoun,
 * or a word that judges a person or reports a feeling nobody reported.
 */
export function problems(text, lang) {
  const found = [];
  if (/\$\{|\bundefined\b|\bNaN\b|\bnull\b|\[object /.test(text)) found.push('a template left unfilled');
  if (lang === 'en') {
    if (/\b(he|she|him|his|her|hers|himself|herself)\b/i.test(text)) found.push('a gendered pronoun');
    const judged = text.match(/\b(blunder\w*|chok\w*|collaps\w*|panic\w*|nerv\w*|disaster\w*|humiliat\w*|shock\w*|stun\w*|crush\w*|destroy\w*|brillian\w*|genius|shame\w*|terribl\w*|awful|embarrass\w*|meltdown|cracked|clueless)\b/i);
    if (judged) found.push(`a judgement ("${judged[0]}")`);
  }
  return found;
}
