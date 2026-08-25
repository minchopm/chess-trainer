/**
 * Everything about the product that appears in more than one place.
 *
 * The website makes claims — puzzle counts, prices, licences — that must match
 * what the app actually ships, and a claim written twice is a claim that will
 * eventually disagree with itself. So they are written once, here, and the
 * pages read them.
 */

export const SITE = {
  name: 'Brass Pawn',
  tagline: 'The training half of getting good.',
  /**
   * What the thing is, for the home page's title tag.
   *
   * The old name, "Chess Trainer", carried the category and could never rank for
   * it; "Brass Pawn" is ownable and says nothing on its own, so the category has
   * to be said out loud somewhere a search engine reads first.
   */
  category: 'a chess trainer for iPhone and iPad',
  /** Where this site lives. Used for canonical URLs, sitemap and legal text. */
  origin: 'https://brasspawn.com',
  publisher: 'Mincho Milev',
  copyrightYear: 2026,
  /**
   * Named in Terms and Privacy as the support channel Apple requires.
   *
   * On the domain rather than a personal inbox — not for appearances, but
   * because this address is printed on two legal pages and handed to Apple,
   * and an address on a domain can be pointed somewhere else later without
   * reissuing either. There is no mailbox behind it: SES receives, a Lambda
   * rewrites the headers so the forward survives SPF and DKIM, and it lands in
   * a real inbox. See work/mail-forwarder.
   *
   * privacy@, legal@, security@, press@, hello@, postmaster@ and abuse@ all
   * answer to the same place. The last two because RFC 2142 expects any domain
   * that sends mail to answer on them.
   */
  contactEmail: 'support@brasspawn.com',
  /** The same mailbox, for the page whose subject it is. */
  privacyEmail: 'privacy@brasspawn.com',
  legalEmail: 'legal@brasspawn.com',
  /**
   * Still the old name, deliberately: this is the link the GPL obliges the app
   * to keep working, and the repository has not been renamed. If it ever is,
   * change it here too — GitHub redirects, but a licence should not lean on a
   * redirect.
   */
  repo: 'https://github.com/minchopm/chess-trainer',
  issues: 'https://github.com/minchopm/chess-trainer/issues',
  /**
   * Replace with the real numeric App Store id once the app is live. Empty
   * means "not published yet", and everything that depends on a real listing —
   * the Safari smart app banner, the download URLs in the structured data —
   * stays out of the page rather than pointing at a 404. A broken store link
   * in structured data is worse than no structured data.
   */
  appStoreId: '',
  appStore: 'https://apps.apple.com/app/brass-pawn/id0000000000',
  appStoreLive: false,
  bundleId: 'com.arte-soft.brasspawn',
  platforms: 'iPhone and iPad',
  minimumOs: 'iOS 17.0 or later',
  version: '1.0',
  /**
   * The licence of the app as a whole.
   *
   * Stockfish is GPLv3 and Reckless is AGPLv3. GPLv3 §13 permits the
   * combination, and what comes out the other side carries the Affero terms —
   * so the combined work is AGPLv3, which is what the App Store listing says
   * too. The Affero clause is about software offered over a network; nothing
   * here is, because both engines run on the device and the app makes no
   * network requests at all.
   */
  licence: 'GNU Affero General Public License v3',
  licenceShort: 'AGPLv3',
  licenceUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
  legalLastUpdated: '19 August 2026',
  /** ISO date the site went live; used as the publication date in schema. */
  published: '2026-08-19',
} as const;

/**
 * The locales the app ships in, as BCP-47 tags.
 *
 * Listed in the structured data because "works in your language" is a real
 * differentiator that no amount of prose on an English page can communicate to
 * somebody searching in Japanese.
 */
export const LOCALES: readonly string[] = [
  'en-US',
  'en-CA',
  'ar-SA',
  'cs',
  'da',
  'de-DE',
  'el',
  'es-ES',
  'fi',
  'fr-FR',
  'fr-CA',
  'he',
  'hi',
  'hu',
  'id',
  'it',
  'ja',
  'ko',
  'ms',
  'nl-NL',
  'no',
  'pl',
  'pt-BR',
  'ro',
  'ru',
  'sv',
  'th',
  'tr',
  'vi',
  'zh-Hans',
  'zh-Hant',
];

export interface EngineFact {
  readonly name: string;
  readonly version: string;
  readonly licence: string;
  readonly licenceUrl: string;
  readonly source: string;
  /** Can it be asked to play at a rating, or is it full strength or nothing? */
  readonly limitsStrength: boolean;
  readonly note: string;
}

/**
 * Both engines, and the one difference between them that a player will notice.
 *
 * They do not run at once and never play each other: one of them is chosen in
 * Settings and then it plays, grades and labels everything. That distinction
 * matters on a page, because "two engines" invites a reader to imagine a
 * feature that does not exist.
 */
export const ENGINES: readonly EngineFact[] = [
  {
    name: 'Stockfish',
    version: '18',
    licence: 'GPLv3',
    licenceUrl: 'https://www.gnu.org/licenses/gpl-3.0.html',
    source: 'https://github.com/official-stockfish/Stockfish',
    limitsStrength: true,
    note: 'The strongest engine there is, and the only one here that can play down to a rating.',
  },
  {
    name: 'Reckless',
    version: '0.10',
    licence: 'AGPLv3',
    licenceUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
    source: 'https://github.com/codedeliveryservice/Reckless',
    limitsStrength: false,
    note: 'A different opponent with its own taste in positions. It has no strength limiter, so it plays at full strength or not at all.',
  },
];

export const url = (path = ''): string => `${SITE.origin}${path === '/' ? '/' : path}`;

/** The bundled library, counted from the data files rather than remembered. */
export const LIBRARY = {
  tactics: 14_351,
  tacticsLichess: 14_185,
  tacticsMined: 166,
  ratingFloor: 760,
  ratingCeiling: 2_800,
  positional: 116,
  endgames: 15,
  games: 1_624,
  /** How many a free account gets of each gated activity, every day. */
  freeDaily: 5,
  /** The hour the allowance resets, local to the device. Not midnight. */
  freeResetHour: 9,
  /** The Watch library: published game scores, counted from data/classics.json. */
  classics: 900,
  gamesRatingFloor: 800,
  gamesRatingCeiling: 2_599,
  locales: 31,
  strings: 385,
} as const;

export const PRICING = {
  monthly: '$3.99',
  lifetime: '$49.99',
  currencyNote: 'Prices shown are US App Store prices. Your local price is set by the App Store.',
} as const;

/**
 * The title film.
 *
 * Shot in Google Flow and dropped into `public/film/`. Until the file is there
 * `src` stays null and the page shows the frame it will live in rather than a
 * broken player — a missing film should look deliberate, not broken.
 */
export const FILM = {
  src: null as string | null, // e.g. 'film/brass-pawn.mp4'
  poster: null as string | null, // e.g. 'film/poster.jpg'
  captions: null as string | null, // e.g. 'film/brass-pawn.en.vtt'
  runtime: '1:12',
  title: 'The Opening',
  synopsis:
    'A minute of chess, shot the way the game deserves: one warm light, a board in the dark, and the moment a knight settles on f7 and the game is already over.',
} as const;

export interface Mode {
  readonly slug: string;
  readonly act: string;
  readonly title: string;
  readonly lede: string;
  readonly body: readonly string[];
  readonly free: string;
  readonly stat?: { readonly value: string; readonly label: string };
}

/**
 * The eight things you can do in the app. Ordered the way a player meets them,
 * not the way the tab bar lists them.
 */
export const MODES: readonly Mode[] = [
  {
    slug: 'tactics',
    act: 'I',
    title: 'Tactics',
    lede: 'Positions with exactly one winning move, and a verdict the moment you play it.',
    body: [
      'Every puzzle has one answer and no branches. Play it on the board and the trainer tells you at once whether you found it; miss it and the position comes back tomorrow, then in four days, then in ten — for as long as it keeps catching you.',
      'Each puzzle is tagged with the motif it turns on — fork, pin, skewer, back-rank mate, deflection, the quiet move — so after a few hundred the trainer can tell you not that you are 1620, but that you are 1620 and you keep walking past deflections.',
    ],
    free: 'Five a day on a free account.',
    stat: { value: '14,351', label: 'puzzles, rated 760 to 2800' },
  },
  {
    slug: 'positional',
    act: 'II',
    title: 'Positional judgement',
    lede: 'No forced win exists. Say who stands better, and then find the move that says why.',
    body: [
      'This is the mode built for the thing that separates strong players from good calculators. First you assess: clearly better, slightly better, balanced. Then you choose a move. Both answers are graded.',
      'The feedback names concrete features rather than moods — the open file and whether a rook is on it, the knight outpost no pawn can challenge, the pawn structure, king safety, the difference in piece activity. A position is not "nice for White"; it is better because of four things you can list.',
    ],
    free: 'Five a day on a free account.',
    stat: { value: '116', label: 'quiet positions, engine-screened' },
  },
  {
    slug: 'endgames',
    act: 'III',
    title: 'Endgames',
    lede: 'Canonical positions, played out against an engine that defends properly.',
    body: [
      'Knowing the idea is not the same as converting it, so here you have to actually achieve the result. Stockfish takes the other side and puts up the best defence there is.',
      'After every move the trainer re-checks whether the result is still reachable — and if it is not, it tells you the exact move where it stopped being. That is the sentence that teaches: not "you drew", but "you drew here".',
    ],
    free: 'Five a day on a free account.',
    stat: { value: '15', label: 'drills, every label engine-verified' },
  },
  {
    slug: 'rush',
    act: 'IV',
    title: 'Rush',
    lede: 'A timed run. Solve as many as you can before the clock takes the rest.',
    body: [
      'The same puzzles, against a clock, with the difficulty climbing as you keep getting them right. It trains a different muscle from a puzzle you can stare at: the one that has to see it now.',
      'Runs are scored and kept, so the number goes up over months rather than over an evening.',
    ],
    free: 'Five runs a day on a free account.',
  },
  {
    slug: 'guess-the-elo',
    act: 'V',
    title: 'Guess the Elo',
    lede: 'A real rated game, played out move by move. How strong were these two?',
    body: [
      'Reading a game’s level is the same skill as judging your own moves: both come down to noticing which mistakes are being made and which are not. So the game runs, you watch, and at some point you commit to a number.',
      'The games are real, from the Lichess archives, with both players within 150 points of each other — a guess about "the players" only means something when there is one level to guess.',
    ],
    free: 'Five a day on a free account.',
    stat: { value: '1,624', label: 'rated games, 800 to 2599' },
  },
  {
    slug: 'watch',
    act: 'VI',
    title: 'Watch',
    lede: 'Nine hundred games worth watching — and the moment you would have played differently, take it over.',
    body: [
      'Every game in the library is decisive, between two named players, and either finished inside twenty-five moves or is famous enough to have a name of its own. Nobody learns anything from a ninety-move draw between people they have never heard of, and a library that includes them is a library nobody opens twice.',
      'Look a player up, or an event, or a year. Then play the game through at your own pace. The point is not the highlight reel: it is that at some move you will think <em>I would have taken there</em> — and at that moment you can. Take the position over and carry on against the engine from exactly the square where you disagreed. Finding out what your idea was actually worth is the whole exercise.',
    ],
    free: 'Free, unlimited, always.',
    stat: { value: '900', label: 'games, every one decisive' },
  },
  {
    slug: 'play',
    act: 'VII',
    title: 'Play & coach',
    lede: 'A full game at a strength you choose, with every move of yours graded as you play.',
    body: [
      'Set the engine anywhere from 1400 to full strength and play it out. Each of your moves is graded while the game is still going, and the coach explains what the better move would have achieved — in words about the position, not a number.',
      'At the end you get accuracy, blunder count, and the single moment that cost you most.',
    ],
    free: 'Free, unlimited, always.',
  },
  {
    slug: 'online',
    act: 'VIII',
    title: 'Online',
    lede: 'Two people, one clock, no engine anywhere near it.',
    body: [
      'Game Center finds you somebody who chose the same time control — 3, 5, 10, 15 or 30 minutes. It is the one mode with no engine in it: no hint, no move values, no coaching, because help that only one side gets is not a game.',
      'There is no server. The two devices talk to each other and both run the rules, so a move is played only if it is legal in the position the receiving device already holds. A peer that lies produces a dropped packet, not an illegal board.',
    ],
    free: 'Free, unlimited, always.',
  },
];

export interface Faq {
  readonly q: string;
  readonly a: string;
}

export const FAQ: readonly Faq[] = [
  {
    q: 'Does it need an internet connection?',
    a: 'No. The engine, the puzzles and your progress are all on the device. The single exception is online play, which needs Game Center to reach the other person.',
  },
  {
    q: 'Is there an account?',
    a: 'There is none to create. Your ratings and history live in the app’s own container on your device, and deleting the app deletes them.',
  },
  {
    q: 'What is free?',
    a: 'Playing is free and stays free — against the engine, against a person over Game Center, and the nine hundred games in Watch — all unlimited. On top of that a free account gets five a day of each kind of training: five tactics puzzles, five Rush runs, five positional exercises, five endgame drills and five games to judge. The allowance resets at nine in the morning, local time.',
  },
  {
    q: 'Why is there no advertising?',
    a: 'Partly taste and partly licence. The app links two engines — Stockfish under the GPLv3 and Reckless under the AGPLv3 — and compiling a proprietary advertising SDK into the same binary would make the combined work undistributable under either. Selling the app is fine; copyleft has never forbidden charging. Bolting a closed SDK onto it is not.',
  },
  {
    q: 'Are my puzzle ratings the same as a FIDE rating?',
    a: 'No, and they run several hundred points higher. They measure progress against yourself, not strength against a field.',
  },
  {
    q: 'Where do the puzzles come from?',
    a: 'Most are from the Lichess puzzle database, released into the public domain under CC0, carrying ratings calibrated against millions of real solving attempts. The rest were mined locally by having Stockfish play itself and keeping only positions where one move is far better than every alternative.',
  },
  {
    q: 'Can I see the source code?',
    a: 'Yes. The app carries the GNU Affero General Public License version 3 — the terms Reckless brings with it, which the GPLv3 of Stockfish permits combining with — and the complete corresponding source is published on GitHub.',
  },
  {
    q: 'Which engine am I playing?',
    a: 'Whichever you chose in Settings. Stockfish and Reckless are both compiled into the app, and one of them plays, grades and labels everything. They are not equivalent: Stockfish can be asked to play anywhere from about 1400 to full strength, while Reckless has no strength limiter and plays at full strength or not at all.',
  },
];

export interface Motif {
  readonly slug: string;
  readonly name: string;
  /** What it is, in one sentence a beginner can act on. */
  readonly short: string;
  readonly body: string;
  /** How many of the bundled puzzles turn on it. Counted, not estimated. */
  readonly count: number;
}

/**
 * The tactical vocabulary the trainer tags puzzles with.
 *
 * The counts are real — taken from the bundled set, not rounded for effect —
 * because the number is the honest answer to "how much practice is there of
 * this?", which is the only question that makes a glossary worth reading twice.
 *
 * Ordered by how early a player meets them rather than by frequency.
 */
export const MOTIFS: readonly Motif[] = [
  {
    slug: 'fork',
    name: 'Fork',
    short: 'One piece attacks two things at once, and only one of them can be saved.',
    body: 'The knight is the famous forker because it attacks squares no other piece defends the same way, but every piece forks: a pawn hitting two minor pieces, a queen hitting a rook and a loose bishop, a king in the endgame stepping between two pawns. The test is not "am I attacking two things" but "can both of them get out".',
    count: 1799,
  },
  {
    slug: 'pin',
    name: 'Pin',
    short: 'A piece cannot move because something more valuable is behind it.',
    body: 'Absolute when the king is behind it — moving is illegal, not merely bad. Relative when it is a queen or a rook behind, where moving is legal and simply loses material. The follow-up is what wins: a pinned piece is a piece that cannot defend, so pile more attackers onto it, or hit it with a pawn.',
    count: 1074,
  },
  {
    slug: 'skewer',
    name: 'Skewer',
    short: 'A pin the other way round: the valuable piece is in front and has to move.',
    body: 'Check the king along a line with a rook, bishop or queen, and whatever stood behind it is yours when the king steps aside. Skewers are rarer than pins because they need the two pieces already lined up with the valuable one in front — which is why they usually appear after a check has forced the king onto the line.',
    count: 308,
  },
  {
    slug: 'discovered-attack',
    name: 'Discovered attack',
    short: 'Moving one piece unmasks an attack from the piece behind it.',
    body: 'The strongest tactic in chess by a distance, because the piece that moves is free to do something of its own while the attack it uncovers does the work. Two threats appear in one move and neither of them can be answered by capturing the moving piece.',
    count: 798,
  },
  {
    slug: 'discovered-check',
    name: 'Discovered check',
    short: 'The unmasked attack is a check, so the opponent has no time for anything else.',
    body: 'A discovered attack where the piece behind gives check. Whatever the moving piece does — take a queen, walk to a mating square, put itself en prise — the reply must deal with the check first, so it happens for free.',
    count: 351,
  },
  {
    slug: 'double-check',
    name: 'Double check',
    short: 'Two pieces give check at once, so the king must move. No block, no capture.',
    body: 'The only tactic against which there is exactly one legal class of reply. Capturing one checker leaves the other; blocking one line leaves the other. This is why double check delivers mates that look impossible — the defender may have five ways to stop each check separately and none that stops both.',
    count: 107,
  },
  {
    slug: 'deflection',
    name: 'Deflection',
    short: 'Force a defender away from the job it is doing.',
    body: 'A piece is holding a mating square, a back rank or another piece. Attack something it values more, or simply take something it must recapture, and the defence it was providing disappears with it. Often the sacrifice looks absurd until you notice what the recapturing piece stops covering.',
    count: 646,
  },
  {
    slug: 'attraction',
    name: 'Attraction',
    short: 'Lure a piece — usually the king — onto a square where it can be hit.',
    body: 'Also called the decoy. A sacrifice that the opponent is obliged to accept, played not to win material but to put a piece somewhere fatal: a king dragged onto a fork square, a queen pulled onto a line with a rook. The material comes back with interest a move later.',
    count: 675,
  },
  {
    slug: 'clearance',
    name: 'Clearance',
    short: 'Get your own piece out of the way of your own attack.',
    body: 'The line or the square is right and your own man is standing on it. Clearance moves it with tempo — usually with a check or a capture, so the opponent has no time to reorganise while the road opens.',
    count: 265,
  },
  {
    slug: 'interference',
    name: 'Interference',
    short: 'Cut the line between a defender and the thing it defends.',
    body: 'Put a piece — often a sacrificed one — squarely between a rook and the square it is guarding. The defender is still on the board, still notionally defending, and no longer able to. Rare, and one of the hardest patterns to see, because the interfering piece usually looks like a blunder.',
    count: 65,
  },
  {
    slug: 'x-ray',
    name: 'X-ray',
    short: 'A piece acts through another piece, along the line it will occupy later.',
    body: 'A rook defending its own piece through an enemy piece, or attacking through one. Nothing is happening yet; what matters is what happens the moment the piece in between moves or is taken. Recognising an x-ray is usually what makes a capture that "loses material" not lose it.',
    count: 60,
  },
  {
    slug: 'zwischenzug',
    name: 'Zwischenzug',
    short: 'The in-between move: before recapturing, do something more forcing.',
    body: 'German for "intermediate move", and the single most common reason a calculated line turns out to be wrong. You expect a recapture; instead comes a check, or a bigger threat, and by the time the recapture happens the position has changed. Look for one every time a sequence seems forced.',
    count: 200,
  },
  {
    slug: 'zugzwang',
    name: 'Zugzwang',
    short: 'Having to move is itself the problem.',
    body: 'Every legal move makes the position worse, and passing is not allowed. Mostly an endgame idea — king and pawn endings are decided by it — and the reason "the opposition" matters: whoever is obliged to step aside first loses the square. Almost the only situation in chess where the right of a move is a liability.',
    count: 241,
  },
  {
    slug: 'back-rank-mate',
    name: 'Back-rank mate',
    short: 'A king boxed in by its own pawns, mated along the first rank.',
    body: 'The most common mate between players who have castled and left the pawns alone. It rarely appears as a mate on the board — it appears as a threat that wins material, because every defensive move has to keep guarding the rank. The whole family of deflection tactics exists to remove that guard.',
    count: 168,
  },
  {
    slug: 'smothered-mate',
    name: 'Smothered mate',
    short: 'A knight mates a king that its own pieces have hemmed in.',
    body: 'The finish of Philidor’s Legacy: queen sacrifice on g8, rook recaptures, knight on f7 delivers mate with the king surrounded by its own men. Rare in real games and worth knowing anyway, because the pattern is what makes you look at a corner and count escape squares.',
    count: 41,
  },
  {
    slug: 'hanging-piece',
    name: 'Hanging piece',
    short: 'Something is simply undefended and can be taken.',
    body: 'Not glamorous, and it decides more games than every other item on this list combined. Most losses under 1800 are one player taking a free piece the other stopped watching. The habit that fixes it is checking what is loose — both colours — before every move.',
    count: 503,
  },
  {
    slug: 'trapped-piece',
    name: 'Trapped piece',
    short: 'A piece has no safe square, and can be hunted down at leisure.',
    body: 'Usually a bishop that took a pawn it should have left, or a knight that went raiding. The tactic is not a single blow but a squeeze: take away the squares one at a time and the piece falls with no sacrifice needed.',
    count: 196,
  },
  {
    slug: 'quiet-move',
    name: 'Quiet move',
    short: 'The winning move is not a check, not a capture, and not a threat.',
    body: 'The reason strong players find combinations that others miss. After a forcing sequence the answer is a modest move that takes away the last escape square, and it is invisible to anyone who only calculates checks and captures. If a position looks winning and nothing forcing works, look for the quiet one.',
    count: 1101,
  },
  {
    slug: 'sacrifice',
    name: 'Sacrifice',
    short: 'Give material for something worth more than material.',
    body: 'Time, lines, squares, or the position of the enemy king. A real sacrifice is not a gamble; it is a calculation whose end is concrete. What separates one that works from one that does not is almost always whether the defending pieces can come back in time.',
    count: 1318,
  },
  {
    slug: 'advanced-pawn',
    name: 'Advanced pawn',
    short: 'A pawn near promotion changes what every other piece is worth.',
    body: 'A pawn on the seventh is not a pawn; it is a queen that has to be watched by something, and that something is no longer free. Most endgame tactics are really about the tension between stopping a pawn and doing anything else.',
    count: 1129,
  },
];
