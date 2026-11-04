import type { ComparePageContent } from '../types';

export const COMPARE_BATCH_1: readonly ComparePageContent[] = [
  {
    slug: 'brass-pawn-vs-chess-com',
    tldr:
      'Brass Pawn is a native iPhone, iPad and Mac chess trainer with Stockfish 18 and Reckless 0.10 compiled into the app, zero ads, no account sign-up and an optional $39.99 one-off Pro unlock. Chess.com is the largest commercial online chess server, built around global matchmaking, clubs, video courses and recurring Gold, Platinum and Diamond subscriptions. Pick Brass Pawn for distraction-free offline training and coached engine games; pick Chess.com for large rated player pools, titled events and community clubs.',
    tables: [
      {
        id: 'architecture',
        heading: 'Platform, engine and privacy architecture',
        caption: 'Core technical comparison between Brass Pawn and Chess.com',
        headers: ['Dimension', 'Brass Pawn', 'Chess.com'],
        rows: [
          [
            'Supported platforms',
            'Native SwiftUI app for iPhone, iPad and Mac (iOS/iPadOS 17+, macOS 14+)',
            'Web browser, iOS and Android apps',
          ],
          [
            'Engine execution',
            'On-device Stockfish 18 (1400–full) and Reckless 0.10 (full strength), 100% offline',
            'Browser/cloud Game Review plus personality bots; internet required for server review',
          ],
          [
            'Move evaluation scale',
            'Win-probability drop per move with position-feature coaching sentences',
            'Accuracy score, centipawn/CAPS classification and cloud Coach callouts',
          ],
          [
            'Account & data model',
            'No Brass Pawn account; offline history stays on device; Game Center for multiplayer',
            'Mandatory account for rated play, puzzle history and cross-device sync',
          ],
          [
            'Advertising & tracking',
            'Zero ads and zero third-party analytics/ad SDKs (AGPLv3 copyleft binary)',
            'Banner/display ads on Free tier; ad-free requires paid membership',
          ],
          [
            'In-game chat',
            'None — MatchProtocol transmits moves, resignations and draw offers only',
            'Live game chat, direct messages, forums and club feeds (configurable)',
          ],
        ],
      },
      {
        id: 'training-pricing',
        heading: 'Training modes, daily limits and multi-year cost',
        caption: 'Training library access and pricing structure in Brass Pawn vs Chess.com',
        headers: ['Feature / Cost', 'Brass Pawn', 'Chess.com'],
        rows: [
          [
            'Free computer & human play',
            'Unlimited coached engine games and unlimited Game Center matches ($0)',
            'Unlimited online games; deep post-game Coach review metered on Free tier',
          ],
          [
            'Free daily training',
            '5 each per day: Tactics, Rush, Positional, Endgames and Guess the Elo (resets 9 AM)',
            'Limited daily puzzles, Puzzle Rush runs and Game Reviews on Free tier',
          ],
          [
            'Bundled puzzle & game counts',
            '14,351 tactics (20 motifs), 116 positional, 15 endgame drills, 900 Watch games',
            'Large server puzzle pool, video lessons, opening explorer and master archive',
          ],
          [
            'Opening repertoire courses',
            'Not included — focuses on tactics, quiet middlegame judgement and endgames',
            'Included via interactive lessons, Opening Explorer and partner links',
          ],
          [
            'Paid training unlock',
            '$3.99/month or $39.99 one-off non-consumable App Store unlock',
            'Recurring Gold, Platinum and Diamond monthly or annual subscriptions (no lifetime tier)',
          ],
          [
            '3-year total cost for full training',
            '$39.99 total with the one-off unlock (restores across your Apple devices)',
            'Three annual renewals of Gold, Platinum or Diamond membership',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Which app fits your chess routine?',
        caption: 'Scenario-by-scenario recommendation between Brass Pawn and Chess.com',
        headers: ['Player scenario', 'Better fit', 'Reason'],
        rows: [
          [
            'Subway commute or long flight without reliable Wi-Fi',
            'Brass Pawn',
            'Stockfish 18, Reckless 0.10, all 14,351 puzzles and 900 Watch games live inside the app bundle.',
          ],
          [
            'Instant 3+0 or 10+0 pairing at 2 AM against thousands of rated humans',
            'Chess.com',
            'Massive global concurrency pairs any rating band within seconds across all time controls.',
          ],
          [
            'Avoiding recurring subscriptions while unlocking unlimited daily tactics',
            'Brass Pawn',
            'Offers a $39.99 one-off unlock alongside unlimited free coached play and zero ads.',
          ],
          [
            'Following Titled Tuesday, clubs, leagues and video lesson libraries',
            'Chess.com',
            'Built as a full community broadcast, tournament and video content hub.',
          ],
          [
            'Family iPad or focus session with zero chat and zero ad banners',
            'Brass Pawn',
            'No text chat field exists in the app, and Screen Time can disable Game Center multiplayer.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Local coaching while you play vs server Game Review afterward',
        paragraphs: [
          'Online servers separate playing from reviewing because live engine feedback cannot exist inside a rated human game. When you practise against Stockfish 18 in Brass Pawn (adjustable from roughly 1400 up to full strength), every move you make is graded immediately using win probability rather than raw centipawns, and the coach explains what changed on the board — an unchallenged outpost on e5, a surrendered open file, or an exposed king diagonal.',
          'Because both Stockfish 18 and Reckless 0.10 run locally on your iPhone, iPad or Mac, there is no server queue and no per-day cap on coached computer games. You can also take over any position from the 900 decisive master games in Watch and test your own continuation against the engine.',
        ],
      },
      {
        heading: 'How many players combine both tools',
        paragraphs: [
          'Choosing Brass Pawn does not require deleting an online tournament account. Many club players keep an online account strictly for scheduled rapid games or friends leagues, while moving daily puzzles, endgame technique and blunder-check sparring into Brass Pawn so training happens without ads, social notifications or blitz tilt.',
        ],
      },
    ],
    honestTradeoffs: [
      'Chess.com has orders-of-magnitude larger live multiplayer pools, variants (Bughouse, Chess960, Crazyhouse), clubs and daily correspondence tournaments; Brass Pawn multiplayer is standard chess on 3, 5, 10, 15 or 30-minute clocks over Apple Game Center.',
      'Chess.com runs on Android, Windows browsers and Linux; Brass Pawn’s native app requires iPhone, iPad or Mac.',
      'Chess.com includes opening explorer trees and video lessons; Brass Pawn intentionally omits memorised opening courses.',
    ],
    faqs: [
      {
        q: 'Can I play unlimited games in Brass Pawn without paying?',
        a: 'Yes. Playing against the on-device engine (with live move-by-move coaching), playing real opponents over Game Center, and replaying or taking over all 900 decisive master games in Watch are free and unlimited forever, with zero ads.',
      },
      {
        q: 'How does Brass Pawn grade blunders differently from centipawn thresholds?',
        a: 'Brass Pawn converts engine evaluations into win probability before grading a move. Dropping 100 centipawns when you are already up a queen barely alters your winning chances (~1%), whereas dropping 100 centipawns in a level position swings win probability by ~24%. Grading win-probability loss avoids false blunder alarms in already-won games.',
      },
      {
        q: 'Does Brass Pawn import my Chess.com game archive automatically?',
        a: 'No. Brass Pawn has no cloud account sync or third-party API login. You can paste a game or position onto the analysis board or read a physical board from a photo on device, while keeping training ratings local.',
      },
      {
        q: 'Does the $39.99 Brass Pawn Pro unlock cover iPhone, iPad and Mac?',
        a: 'Yes. Brass Pawn Pro is an App Store purchase tied to your Apple Account, so tapping Restore purchases unlocks unlimited daily training across your iPhone, iPad and Mac.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-lichess',
      'ad-free-chess-training-vs-diamond-subscriptions',
      'structured-chess-bot-sparring-vs-blitz-tilt',
    ],
    relatedGuides: [
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
      { slug: 'centipawns-vs-win-probability', title: 'Centipawns, winning chances and accuracy: read chess scores carefully' },
      { slug: 'chess-training-vs-online-play', title: 'Chess training or online play: give each session a job' },
    ],
  },
  {
    slug: 'brass-pawn-vs-lichess',
    tldr:
      'Lichess is a completely free, donor-funded open-source chess server with fast global matchmaking, tournaments, studies and an opening explorer. Brass Pawn is an AGPLv3 native trainer for iPhone, iPad and Mac built around offline Stockfish 18 and Reckless 0.10 coaching, 2D and 3D boards, 116 positional judgement exercises, 15 engine-verified endgame drills and 14,351 spaced-repetition tactics puzzles. Use Lichess for free global online play and shared studies; use Brass Pawn for native Apple offline coaching and structured solo practice.',
    tables: [
      {
        id: 'architecture',
        heading: 'Native offline trainer vs open-source online server',
        caption: 'Technical and product comparison between Brass Pawn and Lichess',
        headers: ['Dimension', 'Brass Pawn', 'Lichess'],
        rows: [
          [
            'Primary focus',
            'Solo offline training, live move coaching & curated game takeover on Apple devices',
            'Global live human matchmaking, arenas, studies, broadcasts & analysis server',
          ],
          [
            'Native platforms',
            'SwiftUI app for iPhone, iPad and Mac (2D & carved/bronze 3D boards)',
            'Web application plus iOS and Android mobile apps',
          ],
          [
            'Bundled chess engines',
            'Stockfish 18 (rating-limited or full) + Reckless 0.10 compiled into the app',
            'Browser/mobile Stockfish (WASM/native) plus cloud server analysis',
          ],
          [
            'Software licence',
            'GNU AGPLv3 (complete source on GitHub)',
            'GNU AGPLv3 (complete server & client source on GitHub)',
          ],
          [
            'Advertising & tracking',
            'Zero ads, zero trackers, no account creation',
            'Zero ads, zero trackers, optional free account',
          ],
          [
            'Puzzle provenance',
            '14,185 CC0 Lichess puzzles (even per-rating-band slice) + 166 depth-20 mined puzzles',
            'Full multi-million CC0 community puzzle database generated from Lichess games',
          ],
        ],
      },
      {
        id: 'modes-pricing',
        heading: 'Training modes and cost structure',
        caption: 'Mode-by-mode training comparison between Brass Pawn and Lichess',
        headers: ['Capability', 'Brass Pawn', 'Lichess'],
        rows: [
          [
            'Coached engine sparring',
            'Every player move graded live by win probability with plain-English feature notes',
            'Play against Stockfish levels 1–8; post-game centipawn/win-chance computer review',
          ],
          [
            'Spaced-repetition tactics',
            'Missed puzzles automatically return at 1, 4 and 10+ day intervals; tracks 20 motifs',
            'Theme filtering, Puzzle Storm, Puzzle Streak and Puzzle Racer (manual replay of misses)',
          ],
          [
            'Positional judgement mode',
            '116 quiet positions: grade the evaluation first, then find the move and feature reason',
            'Not a separate built-in mode (available only via user-created Studies)',
          ],
          [
            'Guess the Elo mode',
            '1,624 archived rated games (800–2599, within 150 Elo) built into the app offline',
            'Not a native mode',
          ],
          [
            'Master game library',
            '900 decisive short/famous games offline with instant one-tap engine takeover',
            'Millions of searchable master/user games & live tournament broadcasts online',
          ],
          [
            'Price',
            'Free unlimited play + 5/day drills; Pro $3.99/mo or $39.99 once supports development',
            '$0 free for every feature; funded by voluntary Patron donations',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to use Brass Pawn vs Lichess',
        caption: 'Practical decision guide for players choosing or combining Brass Pawn and Lichess',
        headers: ['Goal', 'Recommended tool', 'Why'],
        rows: [
          [
            'Free 24/7 rapid, blitz, classical or Chess960 games against humans worldwide',
            'Lichess',
            'Instant global matchmaking, Swiss/Arena tournaments and zero paywalls.',
          ],
          [
            'Playing a 1500-strength engine offline while getting plain-English feedback after each move',
            'Brass Pawn',
            'Play & Coach explains positional features changed by your move while the game is still live.',
          ],
          [
            'Building and sharing collaborative PGN opening studies with a coach or club',
            'Lichess',
            'Lichess Studies and the Masters/Lichess Opening Explorer are purpose-built for repertoire sharing.',
          ],
          [
            'Practising quiet positional assessments and spaced-repetition tactical misses on Mac or iPad',
            'Brass Pawn',
            'Dedicated Positional judgement mode, automatic review scheduling and native Apple ergonomics.',
          ],
          [
            'Switching between Stockfish 18 and Reckless 0.10 offline for a second engine opinion',
            'Brass Pawn',
            'Both engines ship inside the binary and run locally with one switch in Settings.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Shared open-source DNA, different daily jobs',
        paragraphs: [
          'Brass Pawn owes a direct debt to Lichess and credits it openly: 14,185 of Brass Pawn’s 14,351 tactics puzzles and the 1,624 games in Guess the Elo come from Lichess’s CC0 public-domain archives, sampled evenly across 100-point rating bands from 760 to 2800 so high-rated bands stay just as populated as 1400. Both projects are licensed under GNU AGPLv3 and carry zero advertising.',
          'Where they diverge is product shape. Lichess is an online commons for playing humans, running tournaments and collaborating on PGN studies. Brass Pawn is a native iPhone, iPad and Mac practice room designed for the hours when you want a coach on every move, automatic spaced repetition on missed puzzles, 116 quiet positional tests, and 2D or carved 3D boards with zero network dependency.',
        ],
      },
      {
        heading: 'Why Brass Pawn charges for unlimited training while keeping play free',
        paragraphs: [
          'Lichess funds its servers through charitable Patron donations and makes every puzzle unlimited at $0. Brass Pawn keeps engine play, Game Center multiplayer and its 900-game Watch library free forever, and sells unlimited daily training ($3.99/month or $39.99 once) to fund native Apple development — while publishing the complete AGPLv3 source code on GitHub.',
        ],
      },
    ],
    honestTradeoffs: [
      'Lichess is 100% free with zero daily counters on puzzles, Storm or analysis; Brass Pawn meters its five training modes to 5/day on the free tier.',
      'Lichess offers massive global human matchmaking, variants, correspondence play, Opening Explorer and interactive Studies that Brass Pawn does not attempt to replicate.',
      'Lichess works on Android, Windows, Linux and any modern browser; Brass Pawn’s native app targets iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Why use Brass Pawn if Lichess puzzles are already free?',
        a: 'If you want unlimited browser puzzles at $0, Lichess is unbeatable. Players install Brass Pawn for live move-by-move coaching during engine games, automatic spaced-repetition scheduling on missed puzzles, 116 quiet positional judgement exercises, Guess the Elo, Reckless 0.10 as a second local engine, and native 2D/3D SwiftUI polish offline on iPhone, iPad and Mac.',
      },
      {
        q: 'Are Brass Pawn puzzle ratings identical to Lichess puzzle ratings?',
        a: 'The 14,185 imported Lichess puzzles start from their human-calibrated Lichess ratings, while the 166 locally mined puzzles use depth-and-motif estimates. As on Lichess, your puzzle rating tracks training progress against the set and runs several hundred points higher than over-the-board Elo.',
      },
      {
        q: 'Does Brass Pawn connect to my Lichess account to play online?',
        a: 'No. Brass Pawn has no Lichess login integration; its online human matches run device-to-device through Apple Game Center on 3, 5, 10, 15 or 30-minute clocks.',
      },
      {
        q: 'Is Brass Pawn really open source like Lichess?',
        a: 'Yes. Because Brass Pawn links Stockfish 18 (GPLv3) and Reckless 0.10 (AGPLv3), the entire application is distributed under GNU AGPLv3 with complete source code at github.com/minchopm/chess-trainer.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chess-com',
      'offline-chess-app-vs-online-chess-servers',
      'brass-pawn-vs-en-croissant',
    ],
    relatedGuides: [
      { slug: 'puzzle-rating-vs-chess-rating', title: 'Why puzzle rating and playing rating are different' },
      { slug: 'spaced-repetition-chess', title: 'Spaced repetition for chess: remember ideas, not clicks' },
      { slug: 'offline-chess-app-checklist', title: 'Choosing an offline chess app: what should work without internet?' },
    ],
  },
  {
    slug: 'brass-pawn-vs-chessable',
    tldr:
      'Chessable is a course marketplace built around MoveTrainer spaced repetition for memorising opening repertoires, strategy books and author video courses. Brass Pawn is a native iPhone, iPad and Mac board trainer focused on live Stockfish 18 / Reckless sparring, 14,351 tactical puzzles, 116 quiet positional assessments and 15 active endgame drills against full-strength engine defence. Use Chessable to memorise an opening repertoire; use Brass Pawn to train calculation, positional judgement and practical game conversion.',
    tables: [
      {
        id: 'focus-matrix',
        heading: 'Course memorisation marketplace vs live board trainer',
        caption: 'Structural comparison between Brass Pawn and Chessable',
        headers: ['Dimension', 'Brass Pawn', 'Chessable'],
        rows: [
          [
            'Core pedagogy',
            'Active calculation, positional assessment, coached engine play & live endgame conversion',
            'MoveTrainer spaced-repetition recall of book variations & author opening courses',
          ],
          [
            'Opening repertoire courses',
            'Deliberately excluded — positional mode trains the transition out of the opening',
            'Flagship strength — hundreds of Short & Sweet and Lifetime Repertoire courses',
          ],
          [
            'Live engine sparring',
            'Unlimited free coached games against Stockfish 18 (1400–full) or Reckless 0.10',
            'Not an engine sparring app; focused on drilling pre-authored move trees',
          ],
          [
            'Endgame practice',
            '15 canonical drills played out move-by-move against Stockfish’s best defence',
            'Endgame book courses (e.g., 100 Endgames You Must Know) drilled as fixed variations',
          ],
          [
            'Offline access',
            '100% of engines, puzzles, drills and 900 Watch games work offline out of the box',
            'Offline course downloading requires an active Chessable Pro membership',
          ],
          [
            'Platforms',
            'Native SwiftUI app for iPhone, iPad and Mac',
            'Web browser plus iOS and Android companion apps',
          ],
        ],
      },
      {
        id: 'pricing-comparison',
        heading: 'Pricing model: one library vs per-course marketplace',
        caption: 'Cost comparison between Brass Pawn and Chessable courses/memberships',
        headers: ['Cost element', 'Brass Pawn', 'Chessable'],
        rows: [
          [
            'Base download & free tier',
            '$0 — unlimited coached play, Game Center play, 900 Watch games + 5/day per drill mode',
            '$0 — free account with limited course slots and free Short & Sweet samples',
          ],
          [
            'Subscription option',
            '$3.99/month removes all daily training limits',
            'Recurring Chessable Pro monthly/annual plan for study features & offline mode',
          ],
          [
            'Permanent ownership option',
            '$39.99 one-off unlock covers the entire app and all bundled libraries forever',
            'Individual Lifetime Repertoire text/video courses sold separately per opening',
          ],
          [
            'Typical multi-repertoire spend',
            '$39.99 maximum one-off spend across the whole app',
            'Often $50–$300+ across 1.e4/1.d4 and Black defence courses ( especially with video)',
          ],
          [
            'Account & tracking',
            'No account, no analytics SDK, zero ads',
            'Account required to store purchased courses and review queues',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Which tool solves your current bottleneck?',
        caption: 'Choosing between Brass Pawn and Chessable based on how you lose games',
        headers: ['Why you are losing games', 'Better tool', 'Why'],
        rows: [
          [
            'Missing forks, deflections or quiet moves after move 12',
            'Brass Pawn',
            '14,351 tactics tagged by 20 motifs with spaced repetition directly target tactical blindness.',
          ],
          [
            'Forgetting main-line Marshall Attack or Najdorf theory before move 18 in FIDE events',
            'Chessable',
            'MoveTrainer is built specifically to drill exact book move orders until automatic.',
          ],
          [
            'Reaching equal middlegames with no plan and drifting into worse pawn structures',
            'Brass Pawn',
            '116 positional judgement exercises and coached engine games grade plans in plain words.',
          ],
          [
            'Knowing rook-and-pawn endgame theory on paper but failing to convert against resistance',
            'Brass Pawn',
            'You play the position out against Stockfish 18, which pinpoints the exact move a win became a draw.',
          ],
          [
            'Studying grandmaster annotated prose and multi-hour video lectures on one opening',
            'Chessable',
            'Author-led text and video courses provide deep thematic repertoire commentary.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Memorising a branch vs playing against resistance',
        paragraphs: [
          'Spaced repetition works differently on an opening tree than on a tactic or endgame. In an opening course, there is a curated variation to recall. In an endgame over the board, your opponent does not follow a single scripted variation — they look for the stubbornest defence available. That is why Brass Pawn’s 15 endgame drills pit you directly against Stockfish 18 rather than replaying a fixed PGN line, checking after every move whether the win or draw still holds.',
          'For tactics, Brass Pawn uses spaced repetition where it shines: miss one of the 14,351 single-solution puzzles and it returns tomorrow, in four days, and in ten days until you spot the motif cleanly.',
        ],
      },
      {
        heading: 'Why Brass Pawn leaves opening courses to dedicated tools',
        paragraphs: [
          'Brass Pawn states on its Training page that it includes no opening memorisation trainer on purpose. Below 1800–2000, far more games turn on loose pieces, missed intermediate moves and mishandled transitions into the middlegame than on move-14 novelty recall. If you play classical tournaments and want a repertoire book alongside Brass Pawn, pairing one focused opening reference with Brass Pawn’s tactical and positional routines covers both halves without overlap.',
        ],
      },
    ],
    honestTradeoffs: [
      'Chessable offers deep opening repertoires, grandmaster video lectures and digitised chess classics that Brass Pawn does not sell or include.',
      'Brass Pawn’s endgame set is 15 foundational engine-verified drills rather than a 400-position theoretical endgame manual.',
      'Chessable syncs review queues across web, Android and iOS; Brass Pawn stores progress locally on iPhone, iPad or Mac.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn use spaced repetition like Chessable?',
        a: 'Yes, for tactical puzzles. Whenever you miss a puzzle in Brass Pawn, it is scheduled to return at expanding intervals (1 day, 4 days, 10 days and beyond) and logged against its tactical motif until you solve it reliably.',
      },
      {
        q: 'Can I buy extra puzzle packs or courses inside Brass Pawn?',
        a: 'No. There are no add-on course fees or DLC packs. Every puzzle, positional exercise, endgame drill and Watch game ships inside the app; Free meters training to 5/day per mode, and Pro ($3.99/mo or $39.99 once) unlocks unlimited daily runs.',
      },
      {
        q: 'How does Brass Pawn teach the transition out of the opening without repertoire courses?',
        a: 'Through its 116 quiet Positional judgement positions and Play & Coach mode, where you evaluate open files, knight outposts, king safety, bishop pairs and pawn breaks rather than reciting memorised book moves.',
      },
      {
        q: 'Does Brass Pawn require Pro to work offline?',
        a: 'No. Offline play and your daily free training allowance work completely offline on the free tier with zero internet connection.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-ct-art-chess-king',
      'ad-free-chess-training-vs-diamond-subscriptions',
      'brass-pawn-vs-lichess',
    ],
    relatedGuides: [
      { slug: 'opening-memorization-vs-ideas', title: 'Opening memorisation versus ideas: build a repertoire you can explain' },
      { slug: 'opening-vs-endgame-study', title: 'Should you study chess openings or endgames first?' },
      { slug: 'positional-exercise-or-forced-tactic', title: 'Positional exercise or forced tactic? Change how you judge the answer' },
    ],
  },
  {
    slug: 'brass-pawn-vs-dr-wolf',
    tldr:
      'Learn Chess with Dr. Wolf is a scripted conversational coaching app aimed primarily at beginners and early intermediates learning foundational concepts. Brass Pawn is a native iPhone, iPad and Mac chess trainer powered by local Stockfish 18 and Reckless 0.10 engines, scaling from 760-rated tactics and 1400-strength sparring all the way to 2800 puzzles and full grandmaster-plus engine play — with unlimited free coached games and a $39.99 one-off Pro option.',
    tables: [
      {
        id: 'coaching-comparison',
        heading: 'Engine-backed coaching vs scripted beginner tutor',
        caption: 'Comparison of coaching mechanics and ceiling between Brass Pawn and Dr. Wolf',
        headers: ['Dimension', 'Brass Pawn', 'Learn Chess with Dr. Wolf'],
        rows: [
          [
            'Target skill range',
            'Beginners who know the rules up to strong club players (puzzles 760–2800; engine 1400–full)',
            'Complete beginners to early intermediates (~400–1400)',
          ],
          [
            'How coaching text is generated',
            'Deterministic feature extraction from real Stockfish 18 / Reckless evaluations + win-probability drop',
            'Friendly conversational character prompts, guided lessons and mistake hints',
          ],
          [
            'Top engine ceiling',
            'Full-strength Stockfish 18 and Reckless 0.10 running natively on device',
            'Capped friendly coach personalities rather than full-strength dual UCI engines',
          ],
          [
            'Tactics & training breadth',
            '14,351 tactics, 116 positional exercises, 15 endgame drills, Rush, 1,624 Guess the Elo games',
            'Short guided concept lessons, basic drills and coached practice games',
          ],
          [
            'Platforms',
            'Native iPhone, iPad and Mac',
            'iOS and Android mobile apps',
          ],
          [
            'Privacy & accounts',
            'No account sign-up, zero analytics, zero ad SDKs, AGPLv3 open source',
            'Proprietary commercial app (Chess.com family) with subscription tracking',
          ],
        ],
      },
      {
        id: 'pricing-free-tier',
        heading: 'Free play vs paywalled coaching games',
        caption: 'Free allowance and long-term cost in Brass Pawn vs Learn Chess with Dr. Wolf',
        headers: ['Access / Cost', 'Brass Pawn', 'Learn Chess with Dr. Wolf'],
        rows: [
          [
            'Free coached games',
            'Unlimited coached games against the engine, forever ($0)',
            'A handful of introductory coached games free before subscription paywall',
          ],
          [
            'Free human multiplayer',
            'Unlimited real-time Game Center matches on 3/5/10/15/30-min clocks ($0)',
            'No human multiplayer mode (solo coach app)',
          ],
          [
            'Free master game study',
            'All 900 decisive master games in Watch with position takeover ($0)',
            'Not included',
          ],
          [
            'Paid plans',
            '$3.99/month or $39.99 one-off unlock (for unlimited daily puzzles/drills)',
            'Recurring monthly or annual coaching subscription (no one-off lifetime unlock)',
          ],
          [
            'Paywall behaviour',
            'Never shown on launch; appears only after spending 5 free daily attempts in a drill mode',
            'Subscription required to continue full coached games and lessons past trial',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Who should pick Brass Pawn vs Dr. Wolf?',
        caption: 'Player-fit matrix comparing Brass Pawn and Learn Chess with Dr. Wolf',
        headers: ['Player profile', 'Better fit', 'Reason'],
        rows: [
          [
            'Learning how the knight moves and basic checkmate rules on day one',
            'Learn Chess with Dr. Wolf',
            'Step-by-step interactive onboarding lessons teach the absolute rules from zero.',
          ],
          [
            'Already know the rules and want unlimited free coached practice games on iPhone, iPad or Mac',
            'Brass Pawn',
            'Play & Coach never meters or paywalls computer games and grades every move by win probability.',
          ],
          [
            'Climbing from 1000 to 1800+ without outgrowing your training app',
            'Brass Pawn',
            '14,351 puzzles reach 2800 and Stockfish 18 scales smoothly up to full strength.',
          ],
          [
            'Preferring a one-time purchase over another annual mobile subscription',
            'Brass Pawn',
            '$39.99 buys Pro outright, and coached play is free even without Pro.',
          ],
          [
            'Playing on an Android phone',
            'Learn Chess with Dr. Wolf',
            'Dr. Wolf ships an Android build; Brass Pawn is built natively for Apple platforms.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Position facts vs conversational chat bubbles',
        paragraphs: [
          'Dr. Wolf wraps hints in a gentle tutor persona (“Let’s look at your bishop…”), which reassures brand-new players during their first week at the board. Once you know the rules, however, chatty Filler slows down a 20-minute study session and tops out quickly in tactical depth.',
          'Brass Pawn explicitly avoids pretending the engine is a conversational human tutor. Instead, it searches the position locally with Stockfish 18 or Reckless 0.10, measures the exact win-probability swing of your move, and states the concrete board change in one crisp sentence — such as seizing the open d-file, planting an unassailable knight on e5, or leaving an isolated pawn.',
        ],
      },
      {
        heading: 'Never paywalling the chessboard itself',
        paragraphs: [
          'A coaching app that locks coached games after three introductory matches forces you to subscribe before you have built a habit. Brass Pawn keeps Play & Coach 100% free and unlimited forever, reserving Brass Pawn Pro strictly for removing the five-a-day counter on its bundled puzzle and drill modes.',
        ],
      },
    ],
    honestTradeoffs: [
      'Dr. Wolf includes interactive rules tutorials for someone who has never played a legal game of chess; Brass Pawn assumes you already know how pieces move.',
      'Dr. Wolf offers spoken/chatty step-by-step beginner lessons on both iOS and Android; Brass Pawn is Apple-only (iPhone, iPad, Mac).',
      'Brass Pawn intentionally omits opening lessons, whereas Dr. Wolf walks beginners through basic opening setups.',
    ],
    faqs: [
      {
        q: 'Is Brass Pawn suitable for beginners who just learned the rules?',
        a: 'Yes, once you know legal piece movement. Tactics puzzles begin at 760, Guess the Elo begins at 800, Stockfish plays down to club/novice levels with two-step hints and take-backs, and every coached move explains positional ideas in plain words.',
      },
      {
        q: 'Does Brass Pawn use a cloud LLM to write its coaching sentences?',
        a: 'No. Brass Pawn uses zero cloud AI or language models. Its coaching layer inspects the real board features along Stockfish 18 or Reckless 0.10’s principal variation locally on your device, so it works offline and never hallucinates illegal moves.',
      },
      {
        q: 'How much do coached games cost in Brass Pawn?',
        a: '$0. Coached games against the engine are completely free and unlimited without an account or subscription.',
      },
      {
        q: 'Can I also play real people once I finish practising with the coach?',
        a: 'Yes. Brass Pawn includes free unlimited Game Center multiplayer on 3, 5, 10, 15 and 30-minute clocks, with all engine hints strictly disabled so human matches stay fair.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-duolingo-chess',
      'brass-pawn-vs-magnus-trainer',
      'brass-pawn-vs-decodechess',
    ],
    relatedGuides: [
      { slug: 'chess-coach-vs-engine', title: 'Chess coach or engine: what kind of feedback do you need?' },
      { slug: 'beginner-chess-study-plan', title: 'A beginner chess study plan built around real mistakes' },
      { slug: 'choose-chess-computer-strength', title: 'Choosing a chess computer strength for useful practice' },
    ],
  },
  {
    slug: 'brass-pawn-vs-magnus-trainer',
    tldr:
      'Magnus Trainer (from the Play Magnus series) teaches chess concepts through themed arcade mini-games and short gamified drills. Brass Pawn trains you on a real 8x8 chessboard using bundled Stockfish 18 and Reckless 0.10 engines, 14,351 single-solution tactics, 116 quiet positional exercises, 15 endgame drills and 900 decisive master games you can take over at any move. Pick Magnus Trainer for casual mini-games; pick Brass Pawn for transferable over-the-board calculation.',
    tables: [
      {
        id: 'board-vs-minigames',
        heading: 'Classical 8x8 calculation vs themed chess mini-games',
        caption: 'Training design comparison between Brass Pawn and Magnus Trainer',
        headers: ['Aspect', 'Brass Pawn', 'Magnus Trainer'],
        rows: [
          [
            'Training medium',
            'Full legal 8x8 chess positions, complete games and real endgame conversions',
            'Arcade mini-games, piece-coordination challenges and short thematic lessons',
          ],
          [
            'On-device engines',
            'Stockfish 18 (1400–full) and Reckless 0.10 compiled locally',
            'Lightweight lesson verification rather than dual top-ranked UCI engines',
          ],
          [
            'Tactical training',
            '14,351 verified single-answer puzzles rated 760–2800 + timed Rush mode',
            'Gamified tactical stages with points, stars and arcade mechanics',
          ],
          [
            'Master game study',
            '900 decisive master games in Watch + daily Today top-board turning points',
            'Curated themed snippets rather than a searchable 900-game takeover library',
          ],
          [
            'Apple platforms',
            'Native iPhone, iPad and Mac app',
            'Mobile-focused app (legacy Play Magnus app suite consolidated over time)',
          ],
          [
            'Visual environment',
            'Quiet dark theatre palette with 2D & carved/bronze 3D sets, zero ads',
            'Bright arcade UI with badges, streaks and gamified progression',
          ],
        ],
      },
      {
        id: 'modes-pricing',
        heading: 'Content depth and pricing comparison',
        caption: 'Free tier and purchase model in Brass Pawn vs Magnus Trainer',
        headers: ['Feature / Pricing', 'Brass Pawn', 'Magnus Trainer'],
        rows: [
          [
            'Free unlimited play',
            'Coached engine games, Game Center multiplayer & 900 Watch games ($0)',
            'Selected introductory mini-games and basic stages',
          ],
          [
            'Daily free drills',
            '5 attempts per day in each of 5 training modes (25 total exercises/day free)',
            'Subscription gates full curriculum tracks and advanced mini-game levels',
          ],
          [
            'Pro cost',
            '$3.99/month or $39.99 one-off permanent unlock',
            'Recurring monthly/annual membership model',
          ],
          [
            'Endgame verification',
            '15 canonical endgames played live against Stockfish best defence',
            'Short scripted endgame mini-lessons',
          ],
          [
            'Open source & privacy',
            'AGPLv3 source on GitHub, no account, no analytics or ad SDKs',
            'Closed-source commercial app with user accounts and telemetry',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When mini-games help vs when real positions win',
        caption: 'Player-fit guide for Brass Pawn vs Magnus Trainer',
        headers: ['Situation', 'Recommended app', 'Why'],
        rows: [
          [
            'Younger casual player who wants arcade-style piece movement games',
            'Magnus Trainer',
            'Mini-games break piece movement into short, game-like visual challenges.',
          ],
          [
            'Translating puzzle practice into real 10-minute or 15-minute games',
            'Brass Pawn',
            'Every puzzle, positional test and endgame happens on a real legal board with full piece interaction.',
          ],
          [
            'Studying famous decisive master games and testing “what if I captured?”',
            'Brass Pawn',
            'Watch lets you take over any position among 900 decisive classics against Stockfish 18.',
          ],
          [
            'Practising offline on Mac, iPad and iPhone under one one-off purchase',
            'Brass Pawn',
            'Native macOS, iPadOS and iOS support with a $39.99 lifetime Pro option.',
          ],
          [
            'Building observation skills by estimating player strength from real moves',
            'Brass Pawn',
            'Includes 1,624 real blitz/classical games in Guess the Elo (800–2599).',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why transfer to real games requires the whole board',
        paragraphs: [
          'Mini-games isolate a single mechanic — such as guiding a knight around lava squares — which feels snappy on a phone screen. The catch is that blunders in real games almost always come from overlooking a defender on the far side of the board: an x-ray along the e-file, a pinned g7-pawn or an intermediate check.',
          'Brass Pawn keeps all eight modes on a real legal chessboard. Whether you are solving one of 1,101 quiet-move puzzles, judging a balanced middlegame in Positional mode, or defending rook-and-pawn against Stockfish 18, your eyes practise scanning the exact geometry you face in real matches.',
        ],
      },
      {
        heading: 'Take over master games instead of passively reading snippets',
        paragraphs: [
          'In Brass Pawn’s free 900-game Watch library, every game is decisive and either finishes inside 25 moves or is a named classic. The moment you wonder why a master declined a sacrifice, tap Play on from here and play your idea out against the local engine with move-by-move coaching.',
        ],
      },
    ],
    honestTradeoffs: [
      'Magnus Trainer’s arcade mini-games appeal to players who find standard chess positions intimidating at first.',
      'Magnus Trainer includes beginner-oriented thematic concept tracks, whereas Brass Pawn expects you to learn by solving, judging and playing real positions.',
      'Brass Pawn runs exclusively on Apple platforms (iPhone, iPad, Mac), whereas Play Magnus apps targeted both iOS and Android.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn have timed arcade modes if I want speed practice?',
        a: 'Yes — Rush gives you a timed tactical run where puzzle difficulty climbs as you solve, tracking your personal high scores over time without changing the rules of chess into a mini-game.',
      },
      {
        q: 'Are the 900 master games in Brass Pawn locked behind Pro?',
        a: 'No. The entire 900-game Watch library — including searching by player, event or year and taking over any position against the engine — is 100% free and unlimited.',
      },
      {
        q: 'How does Guess the Elo work in Brass Pawn?',
        a: 'You step through one of 1,624 real Lichess blitz or classical games where both players were rated within 150 points of each other (between 800 and 2599, usernames removed) and commit to a rating estimate based on the quality of their moves.',
      },
      {
        q: 'Is Play Magnus still maintained separately from Magnus Trainer?',
        a: 'Several legacy Play Magnus mobile apps have changed availability following corporate consolidation, whereas Brass Pawn is actively shipped as version 1.4 on iOS, iPadOS and macOS with full AGPLv3 source code on GitHub.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-duolingo-chess',
      'brass-pawn-vs-dr-wolf',
      'brass-pawn-vs-chess-universe',
    ],
    relatedGuides: [
      { slug: 'study-master-games-with-takeover', title: 'Study a master game by taking over the position' },
      { slug: 'guess-the-elo-chess-exercise', title: 'Guess the Elo as a chess observation exercise' },
      { slug: 'ten-minute-chess-routine', title: 'A ten-minute chess routine with a clear stopping point' },
    ],
  },
  {
    slug: 'brass-pawn-vs-shredder-chess',
    tldr:
      'Shredder Chess is a respected long-running commercial chess program known for Stefan Meyer-Kahlen’s Shredder engine, adaptive Elo play and classic paid iOS/desktop apps. Brass Pawn brings a modern native SwiftUI dark-theatre interface to iPhone, iPad and Mac with two bundled engines (Stockfish 18 and Reckless 0.10), win-probability move coaching, 14,351 tactics puzzles, 116 positional exercises, 900 Watch games and free Game Center multiplayer.',
    tables: [
      {
        id: 'engine-ui',
        heading: 'Modern SwiftUI dual-engine studio vs classic Shredder Chess',
        caption: 'Technical comparison between Brass Pawn and Shredder Chess on Apple devices',
        headers: ['Feature', 'Brass Pawn', 'Shredder Chess (iOS / Mac)'],
        rows: [
          [
            'Bundled engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 (full strength) compiled locally',
            'Proprietary Shredder engine (human-like adaptive rating levels)',
          ],
          [
            'Interface generation',
            'Modern native SwiftUI across iPhone, iPad and Mac with 2D & carved/bronze 3D sets',
            'Classic utilitarian mobile/desktop chess interface',
          ],
          [
            'Tactics library',
            '14,351 puzzles (760–2800) across 20 motifs + spaced repetition + Rush',
            'Roughly 1,000 built-in tactical puzzles on mobile',
          ],
          [
            'Positional & endgame modes',
            '116 quiet positional exercises + 15 engine-verified endgame drills',
            'Endgame tablebase lookups (online) and standard position play; no separate positional quiz mode',
          ],
          [
            'Move coaching',
            'Win-probability grading + plain-English sentences naming changed board features',
            'Numeric/bar evaluation, tutor blunder warning before/after moves and principal variations',
          ],
          [
            'Human multiplayer',
            'Real-time Game Center matches (3, 5, 10, 15, 30 min) with zero engine help',
            'Primarily solo play and analysis against Shredder',
          ],
        ],
      },
      {
        id: 'licensing-cost',
        heading: 'Pricing, cross-device ownership and licensing',
        caption: 'Purchase and licensing comparison between Brass Pawn and Shredder Chess',
        headers: ['Dimension', 'Brass Pawn', 'Shredder Chess'],
        rows: [
          [
            'Try before paying',
            'Free download: unlimited engine play, Game Center & 900 Watch games + 5/day drills',
            'Upfront paid App Store download on iOS; separate trial/license on desktop',
          ],
          [
            'iPhone, iPad & Mac unified purchase',
            'Single Apple Account unlocks iPhone, iPad and Mac ($3.99/mo or $39.99 once)',
            'Mobile iOS app and Classic/Deep Shredder Mac desktop licenses sold separately',
          ],
          [
            'Desktop Shredder cost',
            'Mac app included in the same App Store listing at $0 play / $39.99 Pro',
            'Classic Shredder / Deep Shredder Mac desktop editions cost ~$29.95–$99.95+',
          ],
          [
            'Source code & ads',
            'GNU AGPLv3 open source, zero ads, zero analytics',
            'Proprietary closed source, zero ads',
          ],
          [
            'Localisation',
            '31 languages with translated chess motif terminology',
            'Selected European/major interface languages',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Choosing between Brass Pawn and Shredder Chess',
        caption: 'Player-fit comparison for Apple chess players considering Shredder or Brass Pawn',
        headers: ['What you value most', 'Better choice', 'Why'],
        rows: [
          [
            'Playing offline against Stockfish 18 for free on iPhone, iPad and Mac',
            'Brass Pawn',
            'Computer play with live coaching is $0 forever across all three Apple platforms.',
          ],
          [
            'Specifically playing against the classic commercial Shredder engine style',
            'Shredder Chess',
            'Only official Shredder apps ship Meyer-Kahlen’s proprietary Shredder engine.',
          ],
          [
            'Large 14,351-puzzle library with spaced repetition plus 900 master games',
            'Brass Pawn',
            'More than 14× the mobile puzzle volume plus Watch, Guess the Elo and Positional drills.',
          ],
          [
            'Desktop PGN opening book editing and online 6-piece Shredderbase queries',
            'Shredder Chess (Desktop)',
            'Desktop Deep Shredder includes traditional opening book trees and tablebase probes.',
          ],
          [
            'Switching between two distinct engines offline for a second positional verdict',
            'Brass Pawn',
            'Ships both Stockfish 18 and Reckless 0.10 inside the same app.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Two generations of offline Apple chess apps',
        paragraphs: [
          'For years, Shredder on iPhone and iPad was the standard answer whenever someone asked for a serious offline chess app without free-to-play clutter. It earned that reputation by shipping a real engine and charging an honest price with zero ads.',
          'Brass Pawn carries that same offline, zero-ad ethic forward into modern SwiftUI across iPhone, iPad and Apple Silicon Mac. Where Shredder centres on one classic engine and a 1,000-puzzle pack, Brass Pawn compiles both Stockfish 18 and Reckless 0.10 locally, expands the tactics set to 14,351 motif-tagged positions, adds 116 quiet positional exercises and 900 decisive master games, and explains mistakes using win probability rather than raw centipawn swings.',
        ],
      },
      {
        heading: 'Free play vs paid-upfront download',
        paragraphs: [
          'With Shredder iOS, you pay upfront before playing your first game, and desktop Shredder for macOS is a separate purchase. Brass Pawn lets you install on iPhone, iPad and Mac for $0, play unlimited coached engine games and Game Center matches forever, and pay $3.99/month or $39.99 once only if you want unlimited daily training drills.',
        ],
      },
    ],
    honestTradeoffs: [
      'Shredder’s mobile app is a lower single upfront price (~$7.99–$9.99 on iOS alone) if you only want basic mobile play and 1,000 puzzles without Mac sync or 14,351 tactics — though playing against the engine in Brass Pawn is $0.',
      'Desktop Deep Shredder supports external UCI engines, opening book editing and PGN file databases that Brass Pawn does not target.',
      'Shredder also ships Android and Windows versions; Brass Pawn is Apple-native.',
    ],
    faqs: [
      {
        q: 'Is Stockfish 18 in Brass Pawn stronger than mobile Shredder?',
        a: 'At full strength, Stockfish 18 is the top-rated chess engine in the world and stronger than any human or classic commercial mobile engine. More importantly for training, Brass Pawn uses Stockfish’s UCI_Elo search-depth limiting so you can set human-scaled opposition from roughly 1400 upward.',
      },
      {
        q: 'Why does Brass Pawn include Reckless 0.10 alongside Stockfish 18?',
        a: 'Even elite engines evaluate imbalanced positions differently. Including Reckless 0.10 gives you an instant offline second opinion in Settings when analysing a sharp sacrifice or fortress, though Reckless plays at full strength only.',
      },
      {
        q: 'Does Brass Pawn work on Airplane Mode like Shredder?',
        a: 'Yes. Both engines, all 14,351 tactics puzzles, 116 positional exercises, 15 endgame drills, 1,624 Guess the Elo games and 900 Watch games are bundled locally and need zero internet access.',
      },
      {
        q: 'Does Brass Pawn support Mac as well as iPhone and iPad?',
        a: 'Yes. Brass Pawn ships natively for iOS 17+, iPadOS 17+ and macOS 14+ under a single App Store listing.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-hiarcs-chess-explorer',
      'brass-pawn-vs-smallfish-stockfish-ios',
      'native-mac-ipad-chess-app-vs-browser-tabs',
    ],
    relatedGuides: [
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
      { slug: 'choose-chess-computer-strength', title: 'Choosing a chess computer strength for useful practice' },
      { slug: 'offline-chess-app-checklist', title: 'Choosing an offline chess app: what should work without internet?' },
    ],
  },
  {
    slug: 'brass-pawn-vs-aimchess',
    tldr:
      'Aimchess is a cloud analytics subscription that imports your recent Chess.com or Lichess games to generate scouting reports and personalized drill queues. Brass Pawn is a self-contained native iPhone, iPad and Mac chess trainer that requires no online chess account, runs Stockfish 18 and Reckless 0.10 locally offline, and grades your moves live while you play — with free unlimited sparring and a $39.99 one-off Pro unlock.',
    tables: [
      {
        id: 'workflow-architecture',
        heading: 'On-device standalone trainer vs cloud account analytics',
        caption: 'Architectural and workflow comparison between Brass Pawn and Aimchess',
        headers: ['Dimension', 'Brass Pawn', 'Aimchess'],
        rows: [
          [
            'Data input needed',
            'Zero setup — start playing or solving immediately with no external account',
            'Requires linking an active Chess.com or Lichess username with recent rated games',
          ],
          [
            'Where engines run',
            'Locally on your iPhone, iPad or Mac (Stockfish 18 + Reckless 0.10)',
            'On Aimchess cloud servers over an internet connection',
          ],
          [
            'Live game playing',
            'Unlimited free coached engine games + unlimited Game Center human matches',
            'Analytics and drill companion; you still play your games on external servers',
          ],
          [
            'Weakness detection',
            'Tracks your accuracy across 20 tactical motifs and resurfaces missed puzzles via spaced repetition',
            'Aggregates opening win rates, time-management stats and blunder positions from imported games',
          ],
          [
            'Privacy posture',
            'No account, no analytics SDK, training history stored locally on device',
            'Email/social login, cloud profile storage and third-party web analytics',
          ],
          [
            'Offline capability',
            'Full training library, engines and 900 Watch games work offline',
            'Requires internet to fetch scouting reports, sync games and run lessons',
          ],
        ],
      },
      {
        id: 'modes-pricing',
        heading: 'Training modes and pricing comparison',
        caption: 'Feature coverage and subscription math in Brass Pawn vs Aimchess',
        headers: ['Feature / Cost', 'Brass Pawn', 'Aimchess'],
        rows: [
          [
            'Tactics & timed runs',
            '14,351 verified puzzles (760–2800) + timed Rush mode',
            'Blunder-retry puzzles generated from your imported games + themed drills',
          ],
          [
            'Positional & observation modes',
            '116 quiet positional judgement tests + 1,624 Guess the Elo games',
            'Advantage capitalization, defender and intuition mini-drills',
          ],
          [
            'Endgame practice',
            '15 canonical endgames played to completion against Stockfish 18',
            'Endgame drills surfaced from positions similar to your online games',
          ],
          [
            'Free tier',
            'Unlimited coached & online play, 900 Watch games + 5/day per training mode',
            'Limited scouting report preview and a small daily sample of lessons',
          ],
          [
            'Paid pricing',
            '$3.99/month or $39.99 one-off permanent unlock',
            'Recurring monthly or annual SaaS subscription (no lifetime unlock)',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to choose Brass Pawn vs Aimchess',
        caption: 'Decision guide matching player habits to Brass Pawn or Aimchess',
        headers: ['Your chess habit', 'Better choice', 'Why'],
        rows: [
          [
            'You play 200+ blitz/rapid games a month on Lichess or Chess.com and want opening win-rate charts',
            'Aimchess',
            'Built specifically to crunch bulk online game histories into statistical scouting reports.',
          ],
          [
            'You want one quiet native app on iPhone, iPad or Mac to play, get coached and solve puzzles offline',
            'Brass Pawn',
            'Includes the chessboard, two engines, Game Center play and 14,351 puzzles in one offline app.',
          ],
          [
            'You avoid cloud logins or do not maintain a high-volume public online blitz account',
            'Brass Pawn',
            'Works 100% standalone without scraping an external username.',
          ],
          [
            'You want to stop paying annual SaaS renewals for chess drills',
            'Brass Pawn',
            '$39.99 unlocks Brass Pawn Pro permanently across your Apple devices.',
          ],
          [
            'You want immediate win-probability coaching during a practice game rather than a batch report later',
            'Brass Pawn',
            'Play & Coach grades every move on the spot and explains positional features in words.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Real-time feedback in the position vs retrospective dashboards',
        paragraphs: [
          'Aggregate percentages (“You score 43% against the French”) tell you where results leaked last month, which helps if you already play high-volume online blitz. They are less helpful when you want to sit down on an iPad for twenty minutes without opening a browser or feeding an online blitz habit first.',
          'Brass Pawn closes the loop inside the session itself: play a coached game at your target strength, see immediately which move dropped win probability and which board feature changed, or work through missed tactical motifs that automatically return on your local spaced-repetition schedule.',
        ],
      },
      {
        heading: 'No external account required',
        paragraphs: [
          'If you take a break from online rating pools — or prefer playing friends over Game Center and over the board — Aimchess has no new games to ingest. Brass Pawn’s bundled 14,351 tactics, 116 positional positions, 15 endgame drills and 900 Watch games remain ready offline at any time.',
        ],
      },
    ],
    honestTradeoffs: [
      'Aimchess automatically pulls hundreds of your Chess.com/Lichess games to calculate opening-specific win rates and clock usage statistics; Brass Pawn does not connect to external accounts.',
      'Aimchess generates custom retry puzzles from your own past online blunders; Brass Pawn uses its curated 14,351-puzzle library and live Play & Coach feedback.',
      'Aimchess runs in any desktop browser and on Android; Brass Pawn is native to iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn track which tactical themes I miss without an online account?',
        a: 'Yes. Every puzzle in Brass Pawn is tagged across 20 tactical motifs — such as forks, pins, deflections, quiet moves and zwischenzugs — and your per-motif history and spaced-repetition queue are stored locally on your device.',
      },
      {
        q: 'Can I review a single OTB or online game in Brass Pawn?',
        a: 'You can paste a game or position onto Brass Pawn’s board or scan a physical diagram using the on-device photo reader, then analyse with Stockfish 18 or Reckless 0.10 offline.',
      },
      {
        q: 'Does Brass Pawn charge a recurring fee to see my mistake statistics?',
        a: 'No. Ratings per discipline, streaks, motif tracking and post-game accuracy/blunder summaries in Play & Coach are included on the free tier.',
      },
      {
        q: 'Is Aimchess still separate from Chess.com?',
        a: 'Aimchess joined the Play Magnus / Chess.com group while continuing as a dedicated web/mobile analytics subscription, whereas Brass Pawn is an independent AGPLv3 Apple app.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chess-com',
      'brass-pawn-vs-decodechess',
      'structured-chess-bot-sparring-vs-blitz-tilt',
    ],
    relatedGuides: [
      { slug: 'review-lost-chess-games', title: 'How to review a lost chess game without stopping at the last blunder' },
      { slug: 'weekly-chess-training-plan', title: 'Build a weekly chess training plan from your own games' },
      { slug: 'centipawns-vs-win-probability', title: 'Centipawns, winning chances and accuracy: read chess scores carefully' },
    ],
  },
  {
    slug: 'brass-pawn-vs-chess-tempo',
    tldr:
      'Chess Tempo is a veteran browser-focused tactics and opening-repertoire workbench prized by serious tournament players for custom problem filters and community move comments. Brass Pawn is a native iPhone, iPad and Mac offline chess trainer combining 14,351 motif-tagged tactics with live coached Stockfish 18 sparring, Reckless 0.10, 116 positional judgement tests, 900 Watch games and 2D/3D boards. Choose Chess Tempo for granular web database queries; choose Brass Pawn for native offline Apple ergonomics and coached play.',
    tables: [
      {
        id: 'ux-architecture',
        heading: 'Native Apple offline studio vs browser tactics workbench',
        caption: 'Interface, platform and engine comparison between Brass Pawn and Chess Tempo',
        headers: ['Dimension', 'Brass Pawn', 'Chess Tempo'],
        rows: [
          [
            'Interface & platform',
            'Native SwiftUI app for iPhone, iPad and Mac with 2D & carved/bronze 3D sets',
            'Dense web application with mobile web/wrapper apps across platforms',
          ],
          [
            'Offline capability',
            '100% offline engines, 14,351 tactics, drills and 900 games bundled locally',
            'Online server database; requires internet connection for problem sets and stats',
          ],
          [
            'Puzzle curation',
            '14,185 CC0 Lichess + 166 depth-20 mined puzzles; strictly single-solution, zero branches',
            'Large master-game problem set with standard, blitz and mixed (defensive/non-winning) modes',
          ],
          [
            'Coached full games',
            'Stockfish 18 (1400–full) grades every move by win probability in plain English',
            'Online play and cloud engine analysis; not built around live plain-English move coaching',
          ],
          [
            'Opening repertoire tool',
            'Deliberately excluded (positional mode covers post-opening plans)',
            'Full spaced-repetition opening tree trainer with PGN import/export',
          ],
          [
            'Account & privacy',
            'No account needed, zero analytics, AGPLv3 open source',
            'Account required for ratings, custom problem sets and repertoire storage',
          ],
        ],
      },
      {
        id: 'training-pricing',
        heading: 'Training features and membership comparison',
        caption: 'Feature set and cost comparison between Brass Pawn and Chess Tempo',
        headers: ['Feature / Cost', 'Brass Pawn', 'Chess Tempo'],
        rows: [
          [
            'Spaced repetition',
            'Automatic review queue on missed tactics (1, 4, 10+ days) included in Free & Pro',
            'Custom spaced-repetition problem sets gated to paid membership tiers',
          ],
          [
            'Positional & endgame modes',
            '116 engine-screened quiet positions + 15 Stockfish-verified endgame drills',
            'Mixed mode (find non-losing moves) + theoretical endgame benchmark mode',
          ],
          [
            'Guess the Elo',
            '1,624 real rated games built in + Chess Tempo also offers Guess the Move on master games',
            'Guess-the-Move master game training (paid feature depth)',
          ],
          [
            'Free tier',
            'Unlimited engine & Game Center play, 900 Watch games + 5/day per training mode',
            'Free standard/blitz tactics and basic opening trees with tier caps',
          ],
          [
            'Paid tiers',
            '$3.99/month or $39.99 one-off permanent unlock',
            'Recurring Silver, Gold and Diamond annual/monthly memberships',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Who gets more from Brass Pawn vs Chess Tempo?',
        caption: 'Scenario guide comparing Brass Pawn and Chess Tempo',
        headers: ['Use case', 'Better fit', 'Why'],
        rows: [
          [
            'Solving tactics and playing coached games on an iPhone or iPad on a train or plane',
            'Brass Pawn',
            'Native touch response, zero browser chrome and complete offline bundling.',
          ],
          [
            'Building custom Boolean puzzle queries (e.g., “mates in 4 rated 1900–2100 missed twice”)',
            'Chess Tempo',
            'Diamond custom problem sets offer unmatched database query granularity.',
          ],
          [
            'Reading community debates on why an alternative sacrifice fails in a master tactic',
            'Chess Tempo',
            'Years of user-contributed move comments under individual problems.',
          ],
          [
            'Testing alternative ideas directly against Stockfish 18 or Reckless 0.10 offline',
            'Brass Pawn',
            'Instant local engine evaluation and master-game takeover with zero network round trip.',
          ],
          [
            'One-time payment instead of another annual chess website renewal',
            'Brass Pawn',
            '$39.99 one-off unlock covers iPhone, iPad and Mac permanently.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Touch-first clarity vs dense database controls',
        paragraphs: [
          'Chess Tempo was designed by and for players who love tables of percentiles, custom tag filters and PGN repertoire trees in a desktop browser. On a phone screen, that density can turn a quick ten-minute tactical session into squinting at menus and waiting on network requests.',
          'Brass Pawn strips away configuration overhead on iPhone, iPad and Mac. Open Tactics and solve immediately with spaced repetition already wired in; open Positional judgement to assess quiet structures; or open Watch to take over one of 900 decisive master games against Stockfish 18.',
        ],
      },
      {
        heading: 'Why Brass Pawn puzzles never branch ambiguously',
        paragraphs: [
          'Nothing erodes trust in a puzzle trainer faster than playing a winning move that happens not to be the author’s pet line. Brass Pawn’s puzzle pipeline extends each line only while the solver’s best move stays uniquely best (with a ≥140 centipawn margin at depth 20 on mined positions), stopping the puzzle the instant two moves are equally good.',
        ],
      },
    ],
    honestTradeoffs: [
      'Chess Tempo supports custom Boolean problem sets, community problem comments and full opening repertoire trees that Brass Pawn does not offer.',
      'Chess Tempo works on Windows, Linux and Android browsers; Brass Pawn’s native app is for iPhone, iPad and Mac.',
      'Chess Tempo’s mixed mode mixes defensive non-losing positions directly into tactics, whereas Brass Pawn separates forced wins (Tactics) from quiet evaluations (Positional judgement).',
    ],
    faqs: [
      {
        q: 'How many tactical motifs does Brass Pawn track compared with Chess Tempo tags?',
        a: 'Brass Pawn tags its 14,351 puzzles across 20 core tactical motifs — including fork (1,799), sacrifice (1,318), advanced pawn (1,129), quiet move (1,101), pin (1,074), discovered attack (798), attraction (675) and deflection (646) — so weakness reports stay actionable rather than split across hundreds of micro-tags.',
      },
      {
        q: 'Does Brass Pawn have an equivalent to Chess Tempo’s Guess the Move?',
        a: 'Brass Pawn approaches game study from two angles: Watch lets you step through 900 decisive master games and take over any position against Stockfish 18 when you disagree with a move, while Guess the Elo tests your ability to read playing strength across 1,624 rated games.',
      },
      {
        q: 'Can I use Brass Pawn offline without a paid subscription?',
        a: 'Yes. Free-tier engine games, Watch games and your 5 daily attempts per training mode all run offline on your device.',
      },
      {
        q: 'Is spaced repetition locked behind Pro in Brass Pawn?',
        a: 'No. Spaced repetition and per-discipline ratings work identically on the free tier; Pro simply removes the 5-a-day counter.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-lichess',
      'brass-pawn-vs-ct-art-chess-king',
      'native-mac-ipad-chess-app-vs-browser-tabs',
    ],
    relatedGuides: [
      { slug: 'spaced-repetition-chess', title: 'Spaced repetition for chess: remember ideas, not clicks' },
      { slug: 'positional-exercise-or-forced-tactic', title: 'Positional exercise or forced tactic? Change how you judge the answer' },
      { slug: 'calculate-forcing-lines-without-tunnel-vision', title: 'Calculate forcing lines without following checks blindly' },
    ],
  },
  {
    slug: 'brass-pawn-vs-hiarcs-chess-explorer',
    tldr:
      'HIARCS Chess Explorer Pro is a deep macOS/Windows PGN database and opening-book workbench (with separate paid iOS apps) built around Mark Uniacke’s HIARCS engine. Brass Pawn is a unified native iPhone, iPad and Mac training studio with Stockfish 18 and Reckless 0.10 compiled in, 14,351 tactics puzzles, 116 positional exercises, 15 endgame drills, 900 Watch games and Game Center play. Pick HIARCS for multi-million-game PGN database prep on Mac; pick Brass Pawn for zero-setup daily training across all your Apple devices.',
    tables: [
      {
        id: 'workbench-vs-trainer',
        heading: 'Daily Apple training studio vs desktop PGN database workbench',
        caption: 'Technical comparison between Brass Pawn and HIARCS Chess Explorer',
        headers: ['Capability', 'Brass Pawn', 'HIARCS Chess Explorer / iOS'],
        rows: [
          [
            'Core mission',
            'Structured daily training (tactics, positional, endgames, Rush, coached play)',
            'PGN database management, opening tree exploration & human-style HIARCS engine prep',
          ],
          [
            'Cross-device Apple app',
            'Single App Store app & entitlement across iPhone, iPad and Mac',
            'Separate paid products for macOS Explorer Pro, iPhone Chess and iPad Chess',
          ],
          [
            'Bundled engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 (full) ready with zero setup',
            'HIARCS 15 engine bundled; desktop Explorer Pro also hosts external UCI engines',
          ],
          [
            'Game collection philosophy',
            'Curated 900 decisive short/famous master games in Watch + 1,624 Guess the Elo games',
            'Supports multi-million-game PGN/HCE databases, player dossiers & opening books',
          ],
          [
            'Built-in drill modes',
            '14,351 tactics, 116 positional tests, 15 endgame drills, Rush & Guess the Elo',
            'Analysis & engine play focus; requires importing external PGN puzzle files for drills',
          ],
          [
            'Online human play',
            'Apple Game Center matchmaking & friend invitations (3–30 min clocks)',
            'Desktop/mobile focus is database analysis and solo engine play',
          ],
        ],
      },
      {
        id: 'pricing-setup',
        heading: 'Pricing, licensing and setup friction',
        caption: 'Cost and onboarding comparison between Brass Pawn and HIARCS editions',
        headers: ['Factor', 'Brass Pawn', 'HIARCS Ecosystem'],
        rows: [
          [
            'Entry price',
            '$0 free download — unlimited coached engine play, Game Center & 900 Watch games',
            'Paid upfront licenses on both macOS desktop and iOS/iPadOS App Store',
          ],
          [
            'Full Apple ecosystem cost',
            '$39.99 one-off (or $3.99/mo) unlocks Pro across iPhone, iPad and Mac together',
            'Desktop HCE Pro (~$70–$120+ depending on book/deep edition) + separate iPhone/iPad apps',
          ],
          [
            'First-minute experience',
            'Tap Tactics, Play or Watch and start immediately offline',
            'Create/open databases, configure engine threads and opening book paths on desktop',
          ],
          [
            'Board aesthetics',
            'Dark-theatre SwiftUI with 2D sets plus carved and brass/bronze 3D boards',
            'Traditional multi-pane macOS database window and classic 2D iOS boards',
          ],
          [
            'Licence',
            'GNU AGPLv3 open source on GitHub',
            'Proprietary commercial software',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When Mac & iOS players need Brass Pawn vs HIARCS',
        caption: 'Decision matrix for Apple users comparing Brass Pawn and HIARCS',
        headers: ['Task', 'Better tool', 'Why'],
        rows: [
          [
            'Preparing against a specific FIDE tournament opponent’s PGN archive on Mac',
            'HIARCS Chess Explorer Pro',
            'Purpose-built for searching millions of PGN games, player dossiers and opening trees.',
          ],
          [
            'Daily 20-minute tactics, positional judgement and coached sparring across iPhone, iPad and Mac',
            'Brass Pawn',
            'Ships 14,351 rated puzzles, spaced repetition and live move coaching with zero PGN setup.',
          ],
          [
            'Analysing a real chessboard from a camera photo on iPhone, iPad or Mac',
            'Brass Pawn',
            'Includes on-device Apple Vision board photo reading right into the analysis board.',
          ],
          [
            'Running multi-core custom UCI engine tournaments or Syzygy tablebases on macOS',
            'HIARCS Chess Explorer Pro',
            'Desktop UCI workbench supports arbitrary external engines and local tablebase folders.',
          ],
          [
            'Paying once to cover iPhone, iPad and Mac without separate per-device licenses',
            'Brass Pawn',
            'One universal Apple Account purchase covers all three platforms.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'A library vs a database on macOS',
        paragraphs: [
          'Brass Pawn explains the distinction explicitly on its Watch page: a ten-million-game database is a place you go when you already have a specific theoretical question; a curated 900-game library is a place you open when you want a decisive, instructive game worth playing through and taking over against an engine.',
          'On macOS, HIARCS Chess Explorer Pro is arguably the strongest native Mac alternative to Windows-only ChessBase for heavy PGN database work. Brass Pawn solves the complementary daily problem: structured tactical motifs, quiet positional judgement, endgame conversion against Stockfish 18, and coached sparring that moves seamlessly from your Mac desk to your iPhone on the train.',
        ],
      },
      {
        heading: 'Win-probability move grading for practical players',
        paragraphs: [
          'Traditional database GUIs hand you "+0.85" and three engine lines, leaving you to translate centipawns into practical urgency. Brass Pawn converts engine output into win-probability loss and writes out which positional feature changed, bridging raw search depth and human board understanding.',
        ],
      },
    ],
    honestTradeoffs: [
      'HIARCS Chess Explorer Pro handles multi-million-game databases, opening books, player preparation trees and full PGN archiving that Brass Pawn deliberately omits.',
      'HIARCS lets desktop power users attach arbitrary third-party UCI binaries and local endgame tablebases.',
      'HIARCS also supports Windows PCs; Brass Pawn is strictly for iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn try to replace HIARCS for tournament opening prep?',
        a: 'No. Brass Pawn deliberately omits opening books and multi-million-game PGN databases. Tournament players who use HIARCS on Mac for weekend opponent prep often use Brass Pawn on iPhone and iPad for daily tactics, positional judgement and coached sparring.',
      },
      {
        q: 'Does Brass Pawn run natively on Apple Silicon Macs?',
        a: 'Yes. Brass Pawn supports macOS 14.0 or later alongside iOS 17.0+ and iPadOS 17.0+, running Stockfish 18 and Reckless 0.10 natively on the device.',
      },
      {
        q: 'Do I have to buy Brass Pawn separately on Mac and iPhone?',
        a: 'No. Brass Pawn is a single App Store listing; playing is free on every device, and restoring Brass Pawn Pro ($3.99/mo or $39.99 once) applies across your iPhone, iPad and Mac.',
      },
      {
        q: 'Can I paste a PGN or FEN position into Brass Pawn on Mac?',
        a: 'You can paste a game or position onto Brass Pawn’s board (or read a position from a photograph) to analyse with Stockfish 18 or Reckless 0.10 and play on from any move.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chessbase',
      'brass-pawn-vs-en-croissant',
      'brass-pawn-vs-shredder-chess',
    ],
    relatedGuides: [
      { slug: 'mac-chess-analysis-workflow', title: 'Chess analysis on Mac: organise one question at a time' },
      { slug: 'chess-engine-analysis-workflow', title: 'A chess engine analysis workflow that answers a question' },
      { slug: 'study-master-games-with-takeover', title: 'Study a master game by taking over the position' },
    ],
  },
  {
    slug: 'brass-pawn-vs-chessbase',
    tldr:
      'ChessBase is the $150–$500+ professional Windows tournament preparation database used by grandmasters to search millions of historical games and build opening novelties. Brass Pawn is a native iPhone, iPad and Mac chess trainer ($0 free play, $3.99/month or $39.99 once) built for everyday tactical calculation, positional judgement, endgame conversion and coached Stockfish 18 sparring. Unless you prepare opponent-specific FIDE dossiers on Windows, Brass Pawn matches daily improvement needs at a fraction of the cost and complexity.',
    tables: [
      {
        id: 'product-comparison',
        heading: 'Everyday Apple chess trainer vs professional Windows database',
        caption: 'Core comparison between Brass Pawn and ChessBase',
        headers: ['Dimension', 'Brass Pawn', 'ChessBase (Desktop / Cloud)'],
        rows: [
          [
            'Primary audience',
            'Everyday to strong club players (600–2200+) on iPhone, iPad and Mac',
            'Titled players, coaches and FIDE tournament competitors on Windows',
          ],
          [
            'Native OS support',
            'Native iOS 17+, iPadOS 17+ and macOS 14+ (no emulator needed)',
            'Windows desktop flagship (Mac users need Windows VM/CrossOver or web apps)',
          ],
          [
            'Core workflow',
            'Solve rated tactics, assess quiet positions, convert endgames & play coached games',
            'Query Mega Database, build opening trees, annotate PGNs & prepare opponent dossiers',
          ],
          [
            'Bundled engines',
            'Stockfish 18 + Reckless 0.10 compiled locally on device',
            'Supports local Windows UCI engines plus paid Cloud Engine rentals (ducats)',
          ],
          [
            'Game archive scope',
            '900 curated decisive classics in Watch + Today top-event turning points',
            '10+ million tournament games in Mega Database (paid packages & updates)',
          ],
          [
            'Setup time',
            'Zero — install from App Store and play or train offline in seconds',
            'Substantial — software install, database indexing, reference DB & UCI setup',
          ],
        ],
      },
      {
        id: 'cost-breakdown',
        heading: 'Cost and licensing comparison',
        caption: 'Total cost of ownership in Brass Pawn vs ChessBase packages',
        headers: ['Cost item', 'Brass Pawn', 'ChessBase Ecosystem'],
        rows: [
          [
            'Base software',
            '$0 free download (unlimited coached & online play + 900 Watch games)',
            'ChessBase Starter / Program standalone purchase (~$150–$220+)',
          ],
          [
            'Full training / data bundle',
            '$39.99 one-off unlock (or $3.99/mo) for unlimited daily drills across all modes',
            'Mega Package / Premium bundles commonly run $300–$550+ with annual DB upgrades',
          ],
          [
            'Mobile & Mac coverage',
            'Included in the same $0 / $39.99 App Store app',
            'ChessBase Account web/mobile subscription sold separately from Windows desktop program',
          ],
          [
            'Cloud engine fees',
            '$0 — Stockfish 18 & Reckless 0.10 run on your own Apple Silicon / iPhone CPU',
            'Local CPU free; remote Cloud Engines billed separately via ducats',
          ],
          [
            'Source licence',
            'GNU AGPLv3 open source, zero ads, no account',
            'Proprietary commercial license with activation keys and ChessBase Account',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Do you need ChessBase or Brass Pawn?',
        caption: 'Practical decision matrix between Brass Pawn and ChessBase',
        headers: ['Player situation', 'Right choice', 'Explanation'],
        rows: [
          [
            'Club player on Mac, iPad or iPhone working to stop blunders and sharpen calculation',
            'Brass Pawn',
            'Native Apple app with 14,351 tactics, positional drills and live win-probability coaching.',
          ],
          [
            '2200+ FIDE player or coach researching an opponent’s exact 1.d4 sidelines before round 6',
            'ChessBase',
            'Nothing replaces a multi-million-game reference database for opponent-specific novelty prep.',
          ],
          [
            'Studying decisive master games on the sofa and taking over critical positions against Stockfish',
            'Brass Pawn',
            'Watch filters out 90-move draws and lets you take over any of 900 games in one tap.',
          ],
          [
            'Publishing annotated PGN magazines, ChessBase FritzTrainer DVDs or tournament bulletins',
            'ChessBase',
            'Industry-standard PGN/CBH publishing, sub-variations and reference search tools.',
          ],
          [
            'Keeping total chess software spend under $40 forever with zero subscriptions',
            'Brass Pawn',
            '$39.99 once unlocks every training counter permanently across your Apple devices.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why 95% of club players underuse a tournament database',
        paragraphs: [
          'Buying a ten-million-game Windows database to improve from 1200 to 1700 is like buying an airline flight-dispatch console to learn how to land a Cessna. At club ratings, opponents deviate from grandmaster theory by move seven, and the game is decided by who spots a hanging piece, a deflection, an open rook file or a king-and-pawn opposition.',
          'Brass Pawn focuses relentlessly on those transferable board skills: 14,351 single-answer tactical puzzles with spaced repetition, 116 quiet positional assessments where no tactic exists, 15 canonical endgame conversions against Stockfish 18, and unlimited coached games that grade every move by win probability.',
        ],
      },
      {
        heading: 'Native Apple Silicon performance without Windows workarounds',
        paragraphs: [
          'ChessBase has remained Windows-first for decades, leaving Mac and iPad players juggling virtual machines or stripped-down browser tools. Brass Pawn is written natively in Swift and SwiftUI for iPhone, iPad and Mac, compiling Stockfish 18 and Reckless 0.10 directly into the binary.',
        ],
      },
    ],
    honestTradeoffs: [
      'ChessBase provides a 10M+ game reference database, novelty search, player dossiers and deep tree annotations that Brass Pawn never claims to offer.',
      'ChessBase includes opening book trees and FritzTrainer video courses; Brass Pawn intentionally excludes opening repertoire memorisation.',
      'ChessBase runs natively on Windows PCs; Brass Pawn runs natively on iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Why does Brass Pawn include 900 master games instead of 10 million?',
        a: 'Because a database is a reference archive you query with a specific opening question, while a library is something you actually play through. Every one of Brass Pawn’s 900 Watch games is decisive, between named players, and either finishes inside 25 moves or is famous enough to have a name — with one-tap engine takeover at any move.',
      },
      {
        q: 'Does Brass Pawn follow current elite chess events at all?',
        a: 'Yes. Brass Pawn’s Today mode highlights finished games from major top-board broadcasts at the exact move where Stockfish’s evaluation turned, letting you replay the story or try the critical position yourself.',
      },
      {
        q: 'Can Brass Pawn run on my MacBook without Parallels or Wine?',
        a: 'Yes. Brass Pawn ships natively for macOS 14.0 or later directly from the Mac App Store.',
      },
      {
        q: 'Are there any hidden cloud engine credits in Brass Pawn?',
        a: 'Never. Both Stockfish 18 and Reckless 0.10 compute locally on your own iPhone, iPad or Mac hardware at zero marginal cost.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-hiarcs-chess-explorer',
      'brass-pawn-vs-fritz',
      'brass-pawn-vs-en-croissant',
    ],
    relatedGuides: [
      { slug: 'opening-vs-endgame-study', title: 'Should you study chess openings or endgames first?' },
      { slug: 'mac-chess-analysis-workflow', title: 'Chess analysis on Mac: organise one question at a time' },
      { slug: 'analyse-chess-game-without-engine', title: 'Analyse your chess game before turning on the engine' },
    ],
  },
];
