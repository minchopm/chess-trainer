import type { Pages } from './types';

/**
 * The inner pages in English, lifted verbatim out of the templates.
 *
 * Introducing this layer changed where the words live and not one word itself,
 * so the English pages read today exactly as they read before. Every other
 * language is a translation of this file.
 */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Support',
      title: 'Ask a person',
      lede: 'There is no ticket system, no chatbot and no help centre with 400 articles in it. There is an email address and an issue tracker, and both reach the person who wrote the app.',
    },
    meta: {
      title: 'Support',
      description:
        'How to reach a human about Brass Pawn, what to include when reporting a wrong puzzle, and the questions that get asked most.',
    },
    email: {
      slug: 'Email',
      body: 'For anything: a bug, a wrong puzzle, a question about a purchase, or a disagreement with an evaluation. Write in English or Bulgarian.',
    },
    tracker: {
      slug: 'Issue tracker',
      name: 'GitHub issues',
      body: 'For anything you would rather were public — and for anything you want other people to be able to find later, which is most bug reports.',
    },
    report: {
      slug: 'If a puzzle is wrong',
      title: 'Send four things and it can be checked in a minute.',
      checklist: [
        'The FEN shown on the puzzle screen — tap and hold to copy it.',
        'The move you played, and the move the app said was right.',
        'Which mode you were in.',
        'The app version, from the About screen.',
      ],
      caveat:
        'Puzzles do occasionally disagree with a deeper search, and the disagreements cluster on long, quiet, highly rated positions whose point lies deeper than the verification searched. That is a limit of the check rather than a fault in the puzzle — but it is worth knowing which ones, and the only way to know is if you say.',
    },
    faq: { slug: 'Questions', title: 'Asked often enough to write down.' },
    more: {
      ratings: 'What a rating measures',
      tactics: 'The motifs',
      privacy: 'Privacy Policy',
      terms: 'Terms of Service',
      licences: 'Licences',
    },
  },
  pricing: {
    head: {
      slug: 'What it costs',
      title: 'Playing is free. The training is sold.',
      lede: 'Chess against the engine and chess against a person, unlimited, with no advertising anywhere in the app — that is free and it stays free. What is sold is the library, the drills, the exercises and the run.',
    },
    meta: {
      title: 'Pricing',
      description:
        'Playing is free and unlimited — the engine, a real opponent, and all 900 games. Pro lifts the five-a-day training limit: $3.99 a month or $49.99 once.',
    },
    free: {
      name: 'Free',
      note: 'No account. Nothing to sign up for.',
      items: [
        'Unlimited play against the engine, 1400 to full strength',
        'Unlimited online games over Game Center',
        'Move-by-move coaching in every game you play',
        'Five tactics puzzles a day',
        'Five Rush runs a day',
        'Five each: positional, endgame, Guess the Elo',
        'Ratings, streaks and spaced repetition, in full',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Monthly',
      per: 'per month',
      note: 'Cancel in your Apple Account settings, any time.',
      items: [
        'Every daily limit removed',
        'All {tactics} tactics puzzles',
        'All {positional} positional exercises',
        'All {endgames} endgame drills',
        'All {games} games to judge',
        'Unlimited Rush',
        'Everything in Free, unchanged',
      ],
    },
    lifetime: {
      name: 'One-off unlock',
      once: 'once',
      note: 'A non-consumable purchase. It does not renew.',
      items: [
        'Exactly the same as Pro monthly',
        'No renewal, no expiry, no reminder emails',
        'Restores on your other devices',
        'For people who would rather decide once',
      ],
    },
    table: {
      slug: 'The whole allowance',
      title: 'What the free tier actually gives you.',
      activity: 'Activity',
      freeCol: 'Free',
      proCol: 'Pro',
      unlimited: 'Unlimited',
      fiveADay: '5 a day',
      none: 'None',
      rows: [
        'Play against the engine',
        'Online games over Game Center',
        'Watch — the 900-game library',
        'Tactics puzzles',
        'Rush runs',
        'Positional exercises',
        'Endgame drills',
        'Guess the Elo',
        'Advertising',
      ],
      reset:
        'Daily allowances reset at nine in the morning, local time — not midnight, so an evening session is not cut in half by a date change.',
    },
    why: {
      slug: 'Why it is shaped this way',
      title: 'Three decisions, and the reason for each.',
      reasons: [
        {
          title: 'Metered, not locked',
          body: [
            'Nobody pays for a trainer they have not used, and a mode that refuses to open teaches nothing about what is behind it. So every mode opens, every day, and you get far enough in to feel the loop and watch the rating move.',
            'The paywall is never shown on launch. When the day’s allowance is spent the screen says so, and only a deliberate tap opens the purchase sheet.',
          ],
        },
        {
          title: 'Two prices, not three',
          body: [
            'There is no annual plan in between, because a third price is a third decision to make at the exact moment somebody wants to solve a puzzle. Monthly if you are not sure. One-off if you are.',
          ],
        },
        {
          title: 'Playing is never sold',
          body: [
            'Chess against the engine and chess against a person cost nothing to run and are the reason the app exists. Selling them would make this a chess app with a toll booth rather than a trainer.',
            'And there is no advertising — partly taste, partly licence. The app links two copyleft engines, Stockfish under the GPLv3 and Reckless under the AGPLv3, and a proprietary ad SDK in the same binary would make the whole thing undistributable. {link}',
          ],
        },
      ],
      licenceLink: 'The licence page explains it properly.',
    },
    answers: {
      slug: 'Buying, cancelling, refunds',
      title: 'The awkward questions, answered here rather than in an email.',
      items: [
        {
          q: 'How do I cancel?',
          a: 'Settings → your name → Subscriptions → Brass Pawn. We cannot cancel it for you, because the subscription is between you and Apple and we never had it. Cancelling stops future renewals and does not shorten the period you have paid for.',
        },
        {
          q: 'How do I get a refund?',
          a: 'Through Apple, at {link}. We cannot issue refunds for App Store purchases. If something is broken, write to us — we would rather fix it.',
        },
        {
          q: 'I bought the unlock and got a new phone.',
          a: 'Sign in with the same Apple Account and tap Restore purchases on the paywall screen. The app asks StoreKit what you own; nothing is stored on a server of ours because there is no server of ours.',
        },
        {
          q: 'Does Pro change my rating or unlock “better” puzzles?',
          a: 'No. The rating system is identical and every puzzle in the library is reachable on a free account — five a day at a time. Pro removes the counter, not a curtain.',
        },
        {
          q: 'Will the free allowance shrink later?',
          a: 'It may change in either direction as the library grows. Unlimited play against the engine and against a person will not become a paid feature; that is written into the {link} rather than only promised here.',
        },
      ],
      termsLink: 'Terms',
      more: 'More questions, and how to reach a human →',
    },
  },
  training: {
    head: {
      slug: 'The programme',
      title: 'Eight ways to be told the truth',
      lede: 'Three of these are free and unlimited forever — playing, playing somebody else, and the nine hundred games in Watch. The other five are five a day on a free account and unlimited with Pro. Every one of them grades you in words about the position rather than a number you have to interpret.',
    },
    meta: {
      title: 'Training',
      description:
        'Eight modes: tactics, positional judgement, endgames, Rush, Guess the Elo, Watch, coached play and online. How each one works, how the puzzles are mined and verified, and what the trainer does not do.',
    },
    modes: [
      {
        title: 'Tactics',
        lede: 'Positions with exactly one winning move, and a verdict the moment you play it.',
        body: [
          'Every puzzle has one answer and no branches. Play it on the board and the trainer tells you at once whether you found it; miss it and the position comes back tomorrow, then in four days, then in ten — for as long as it keeps catching you.',
          'Each puzzle is tagged with the motif it turns on — fork, pin, skewer, back-rank mate, deflection, the quiet move — so after a few hundred the trainer can tell you not that you are 1620, but that you are 1620 and you keep walking past deflections.',
        ],
        free: 'Five a day on a free account.',
        stat: 'puzzles, rated 760 to 2800',
      },
      {
        title: 'Positional judgement',
        lede: 'No forced win exists. Say who stands better, and then find the move that says why.',
        body: [
          'This is the mode built for the thing that separates strong players from good calculators. First you assess: clearly better, slightly better, balanced. Then you choose a move. Both answers are graded.',
          'The feedback names concrete features rather than moods — the open file and whether a rook is on it, the knight outpost no pawn can challenge, the pawn structure, king safety, the difference in piece activity. A position is not "nice for White"; it is better because of four things you can list.',
        ],
        free: 'Five a day on a free account.',
        stat: 'quiet positions, engine-screened',
      },
      {
        title: 'Endgames',
        lede: 'Canonical positions, played out against an engine that defends properly.',
        body: [
          'Knowing the idea is not the same as converting it, so here you have to actually achieve the result. Stockfish takes the other side and puts up the best defence there is.',
          'After every move the trainer re-checks whether the result is still reachable — and if it is not, it tells you the exact move where it stopped being. That is the sentence that teaches: not "you drew", but "you drew here".',
        ],
        free: 'Five a day on a free account.',
        stat: 'drills, every label engine-verified',
      },
      {
        title: 'Rush',
        lede: 'A timed run. Solve as many as you can before the clock takes the rest.',
        body: [
          'The same puzzles, against a clock, with the difficulty climbing as you keep getting them right. It trains a different muscle from a puzzle you can stare at: the one that has to see it now.',
          'Runs are scored and kept, so the number goes up over months rather than over an evening.',
        ],
        free: 'Five runs a day on a free account.',
      },
      {
        title: 'Guess the Elo',
        lede: 'A real rated game, played out move by move. How strong were these two?',
        body: [
          'Reading a game’s level is the same skill as judging your own moves: both come down to noticing which mistakes are being made and which are not. So the game runs, you watch, and at some point you commit to a number.',
          'The games are real, from the Lichess archives, with both players within 150 points of each other — a guess about "the players" only means something when there is one level to guess.',
        ],
        free: 'Five a day on a free account.',
        stat: 'rated games, 800 to 2599',
      },
      {
        title: 'Watch',
        lede: 'Nine hundred games worth watching — and the moment you would have played differently, take it over.',
        body: [
          'Every game in the library is decisive, between two named players, and either finished inside twenty-five moves or is famous enough to have a name of its own. Nobody learns anything from a ninety-move draw between people they have never heard of, and a library that includes them is a library nobody opens twice.',
          'Look a player up, or an event, or a year. Then play the game through at your own pace. The point is not the highlight reel: it is that at some move you will think <em>I would have taken there</em> — and at that moment you can. Take the position over and carry on against the engine from exactly the square where you disagreed. Finding out what your idea was actually worth is the whole exercise.',
        ],
        free: 'Free, unlimited, always.',
        stat: 'games, every one decisive',
      },
      {
        title: 'Play & coach',
        lede: 'A full game at a strength you choose, with every move of yours graded as you play.',
        body: [
          'Set the engine anywhere from 1400 to full strength and play it out. Each of your moves is graded while the game is still going, and the coach explains what the better move would have achieved — in words about the position, not a number.',
          'At the end you get accuracy, blunder count, and the single moment that cost you most.',
        ],
        free: 'Free, unlimited, always.',
      },
      {
        title: 'Online',
        lede: 'Two people, one clock, no engine anywhere near it.',
        body: [
          'Game Center finds you somebody who chose the same time control — 3, 5, 10, 15 or 30 minutes. It is the one mode with no engine in it: no hint, no move values, no coaching, because help that only one side gets is not a game.',
          'There is no server. The two devices talk to each other and both run the rules, so a move is played only if it is legal in the position the receiving device already holds. A peer that lies produces a dropped packet, not an illegal board.',
        ],
        free: 'Free, unlimited, always.',
      },
    ],
    watchLink: 'What got into the library, and what did not →',
    pipeline: {
      slug: 'How a puzzle is made',
      title: 'Mined, not transcribed.',
      lede: 'Writing positions down from memory risks shipping a puzzle whose “solution” is wrong or not unique, which trains exactly the wrong instinct. So none of them are written down from memory. They are found, and then they are attacked until they either survive or are thrown away.',
      steps: [
        {
          title: 'Play, at human strength',
          body: 'Stockfish plays itself at deliberately human-like strength — 1320 to 2500 Elo — opening with a random pick among its top few shallow choices, so the games vary instead of repeating one line forever.',
        },
        {
          title: 'Screen for the property, not the blunder',
          body: 'Every position is searched at depth 12 with two candidate lines. The signal is not “somebody blundered” but the thing a puzzle actually needs: one move is far better than every alternative.',
        },
        {
          title: 'Re-search deep, with a margin',
          body: 'Survivors are searched again at depth 20 with MultiPV. A candidate is kept only if the best move beats the runner-up by at least 140 centipawns and actually achieves something.',
        },
        {
          title: 'Extend until it branches',
          body: 'The solution is extended move by move for as long as every one of the solver’s moves stays uniquely best. The moment there are two good answers, the puzzle ends there — so it never has a branch you could be marked wrong for taking.',
        },
        {
          title: 'Verify with a fresh engine',
          body: 'The whole set is re-checked at a higher depth by a separate script with a new engine instance. On the bundled mined set that rejected 6 of 172 puzzles whose solutions stopped being unique two plies deeper. Those were dropped rather than shipped.',
        },
      ],
    },
    honest: {
      title: 'And the same suspicion applied to the endgames',
      body: [
        'Every endgame drill’s stated result is checked against a deep search rather than taken on trust. A mislabelled drill fails the check instead of quietly teaching you something false.',
        'The verifier also catches something the usual chess libraries will not tell you: whether the side not to move is in check. Such a position is illegal — no game can reach it — but a library will happily accept it, and the engine answers with bestmove (none), which reads like an engine failure rather than a bad position. Three hand-written drills were wrong in exactly this way. The check now catches it.',
      ],
    },
    limits: {
      slug: 'Honest limitations',
      title: 'What this does not do.',
      items: [
        {
          title: 'The set mixes two rating scales.',
          body: 'The {lichess} Lichess puzzles carry ratings calibrated against millions of human attempts. The {mined} locally mined ones carry estimates derived from solution depth and motif. Both order sensibly, but a mined 1600 and a Lichess 1600 are not measured the same way.',
        },
        {
          title: 'Puzzle ratings are not over-the-board ratings.',
          body: 'They run several hundred points higher, and they always will. They measure progress against yourself, not strength against a field of humans on a clock — {link}, because the gap is structural rather than a sign you are bad at converting.',
        },
        {
          title: 'There is no opening training.',
          body: 'Deliberately. Opening study is memorisation against a repertoire you choose, which is a different tool with a different shape. The positional mode covers the transition out of the opening, which is the part that actually generalises.',
        },
        {
          title: 'This will not make you a grandmaster.',
          body: 'Nothing will, on its own. Titles come from thousands of hours plus rated tournament play against humans. What this gives you is the training half of that, structured, with an honest measure of where you actually are.',
        },
      ],
      ratingsLink: 'which is worth understanding properly',
    },
    more: {
      motifs: 'The twenty motifs, defined and counted →',
      engine: 'How the engine is used →',
    },
  },
  tactics: {
    head: {
      slug: 'Glossary',
      title: 'The twenty motifs',
      lede: 'Every tactic in chess is one of a small number of shapes, and once you can name them you start seeing them a move earlier. These are the ones Brass Pawn tags its puzzles with — each one followed by how many positions in the bundled library actually turn on it.',
      meta: 'Counted from the bundled set of 14,351 puzzles · Last reviewed 19 August 2026',
    },
    meta: {
      title: 'The twenty motifs',
      description:
        'Every tactical motif Brass Pawn tags its puzzles with, defined, and counted against the bundled library so you can tell which ones you can actually practise.',
    },
    indexLabel: 'The motifs',
    puzzles: 'puzzles',
    motifs: [
      {
        name: 'Fork',
        short: 'One piece attacks two things at once, and only one of them can be saved.',
        body: 'The knight is the famous forker because it attacks squares no other piece defends the same way, but every piece forks: a pawn hitting two minor pieces, a queen hitting a rook and a loose bishop, a king in the endgame stepping between two pawns. The test is not "am I attacking two things" but "can both of them get out".',
      },
      {
        name: 'Pin',
        short: 'A piece cannot move because something more valuable is behind it.',
        body: 'Absolute when the king is behind it — moving is illegal, not merely bad. Relative when it is a queen or a rook behind, where moving is legal and simply loses material. The follow-up is what wins: a pinned piece is a piece that cannot defend, so pile more attackers onto it, or hit it with a pawn.',
      },
      {
        name: 'Skewer',
        short: 'A pin the other way round: the valuable piece is in front and has to move.',
        body: 'Check the king along a line with a rook, bishop or queen, and whatever stood behind it is yours when the king steps aside. Skewers are rarer than pins because they need the two pieces already lined up with the valuable one in front — which is why they usually appear after a check has forced the king onto the line.',
      },
      {
        name: 'Discovered attack',
        short: 'Moving one piece unmasks an attack from the piece behind it.',
        body: 'The strongest tactic in chess by a distance, because the piece that moves is free to do something of its own while the attack it uncovers does the work. Two threats appear in one move and neither of them can be answered by capturing the moving piece.',
      },
      {
        name: 'Discovered check',
        short: 'The unmasked attack is a check, so the opponent has no time for anything else.',
        body: 'A discovered attack where the piece behind gives check. Whatever the moving piece does — take a queen, walk to a mating square, put itself en prise — the reply must deal with the check first, so it happens for free.',
      },
      {
        name: 'Double check',
        short: 'Two pieces give check at once, so the king must move. No block, no capture.',
        body: 'The only tactic against which there is exactly one legal class of reply. Capturing one checker leaves the other; blocking one line leaves the other. This is why double check delivers mates that look impossible — the defender may have five ways to stop each check separately and none that stops both.',
      },
      {
        name: 'Deflection',
        short: 'Force a defender away from the job it is doing.',
        body: 'A piece is holding a mating square, a back rank or another piece. Attack something it values more, or simply take something it must recapture, and the defence it was providing disappears with it. Often the sacrifice looks absurd until you notice what the recapturing piece stops covering.',
      },
      {
        name: 'Attraction',
        short: 'Lure a piece — usually the king — onto a square where it can be hit.',
        body: 'Also called the decoy. A sacrifice that the opponent is obliged to accept, played not to win material but to put a piece somewhere fatal: a king dragged onto a fork square, a queen pulled onto a line with a rook. The material comes back with interest a move later.',
      },
      {
        name: 'Clearance',
        short: 'Get your own piece out of the way of your own attack.',
        body: 'The line or the square is right and your own man is standing on it. Clearance moves it with tempo — usually with a check or a capture, so the opponent has no time to reorganise while the road opens.',
      },
      {
        name: 'Interference',
        short: 'Cut the line between a defender and the thing it defends.',
        body: 'Put a piece — often a sacrificed one — squarely between a rook and the square it is guarding. The defender is still on the board, still notionally defending, and no longer able to. Rare, and one of the hardest patterns to see, because the interfering piece usually looks like a blunder.',
      },
      {
        name: 'X-ray',
        short: 'A piece acts through another piece, along the line it will occupy later.',
        body: 'A rook defending its own piece through an enemy piece, or attacking through one. Nothing is happening yet; what matters is what happens the moment the piece in between moves or is taken. Recognising an x-ray is usually what makes a capture that "loses material" not lose it.',
      },
      {
        name: 'Zwischenzug',
        short: 'The in-between move: before recapturing, do something more forcing.',
        body: 'German for "intermediate move", and the single most common reason a calculated line turns out to be wrong. You expect a recapture; instead comes a check, or a bigger threat, and by the time the recapture happens the position has changed. Look for one every time a sequence seems forced.',
      },
      {
        name: 'Zugzwang',
        short: 'Having to move is itself the problem.',
        body: 'Every legal move makes the position worse, and passing is not allowed. Mostly an endgame idea — king and pawn endings are decided by it — and the reason "the opposition" matters: whoever is obliged to step aside first loses the square. Almost the only situation in chess where the right of a move is a liability.',
      },
      {
        name: 'Back-rank mate',
        short: 'A king boxed in by its own pawns, mated along the first rank.',
        body: 'The most common mate between players who have castled and left the pawns alone. It rarely appears as a mate on the board — it appears as a threat that wins material, because every defensive move has to keep guarding the rank. The whole family of deflection tactics exists to remove that guard.',
      },
      {
        name: 'Smothered mate',
        short: 'A knight mates a king that its own pieces have hemmed in.',
        body: 'The finish of Philidor’s Legacy: queen sacrifice on g8, rook recaptures, knight on f7 delivers mate with the king surrounded by its own men. Rare in real games and worth knowing anyway, because the pattern is what makes you look at a corner and count escape squares.',
      },
      {
        name: 'Hanging piece',
        short: 'Something is simply undefended and can be taken.',
        body: 'Not glamorous, and it decides more games than every other item on this list combined. Most losses under 1800 are one player taking a free piece the other stopped watching. The habit that fixes it is checking what is loose — both colours — before every move.',
      },
      {
        name: 'Trapped piece',
        short: 'A piece has no safe square, and can be hunted down at leisure.',
        body: 'Usually a bishop that took a pawn it should have left, or a knight that went raiding. The tactic is not a single blow but a squeeze: take away the squares one at a time and the piece falls with no sacrifice needed.',
      },
      {
        name: 'Quiet move',
        short: 'The winning move is not a check, not a capture, and not a threat.',
        body: 'The reason strong players find combinations that others miss. After a forcing sequence the answer is a modest move that takes away the last escape square, and it is invisible to anyone who only calculates checks and captures. If a position looks winning and nothing forcing works, look for the quiet one.',
      },
      {
        name: 'Sacrifice',
        short: 'Give material for something worth more than material.',
        body: 'Time, lines, squares, or the position of the enemy king. A real sacrifice is not a gamble; it is a calculation whose end is concrete. What separates one that works from one that does not is almost always whether the defending pieces can come back in time.',
      },
      {
        name: 'Advanced pawn',
        short: 'A pawn near promotion changes what every other piece is worth.',
        body: 'A pawn on the seventh is not a pawn; it is a queen that has to be watched by something, and that something is no longer free. Most endgame tactics are really about the tension between stopping a pawn and doing anything else.',
      },
    ],
    after: {
      slug: 'Why the numbers are here',
      title: 'A glossary tells you what a fork is. A number tells you whether you can practise it.',
      body: [
        'Knowing the name of a pattern and being able to find it under a clock are different skills, and only the second one wins games. Every count above is the real number of positions in the bundled library tagged with that motif — not an estimate, and not rounded up. Sixty x-ray puzzles is sixty; if that is the thing you keep missing, it is worth knowing you will not run out in an evening.',
        'The trainer tracks which motifs you get wrong, so after a few hundred puzzles it can tell you not that you are 1620, but that you are 1620 and you keep walking past deflections.',
      ],
      more: 'How the puzzles are mined and verified →',
    },
  },
};
