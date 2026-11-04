import type { ComparePageContent } from '../types';

export const COMPARE_BATCH_2: readonly ComparePageContent[] = [
  {
    slug: 'brass-pawn-vs-fritz',
    tldr:
      'Fritz is the long-standing commercial Windows chess playing and analysis suite from ChessBase (paired with Fritz Online web apps). Brass Pawn is a native iPhone, iPad and Mac chess trainer with Stockfish 18 and Reckless 0.10 compiled locally, live win-probability move coaching, 14,351 tactics puzzles, 116 positional exercises and free Game Center play. Choose Fritz if you play on a Windows PC inside the ChessBase ecosystem; choose Brass Pawn for native Apple Silicon and iOS training.',
    tables: [
      {
        id: 'platform-engine',
        heading: 'Native Apple dual-engine trainer vs Windows Fritz suite',
        caption: 'Platform and engine comparison between Brass Pawn and Fritz',
        headers: ['Dimension', 'Brass Pawn', 'Fritz (Desktop / Online)'],
        rows: [
          [
            'Native platforms',
            'Native SwiftUI app for iPhone, iPad and Mac (iOS 17+, iPadOS 17+, macOS 14+)',
            'Windows desktop program plus browser-based Fritz Online via ChessBase Account',
          ],
          [
            'Bundled chess engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 (full) compiled natively on device',
            'Commercial Fritz engine (Ginkgo/Fritz neural net) with personality opponents',
          ],
          [
            'Live move feedback',
            'Win-probability grading + deterministic position-feature coaching sentences',
            'Assisted analysis colours, tactical hints and witty audio commentary on Windows',
          ],
          [
            'Built-in puzzles & drills',
            '14,351 tactics, 116 positional tests, 15 endgame drills, Rush & 1,624 Guess the Elo',
            ' Sparring/sacrifice coaching modes + online ChessBase Tactics web app',
          ],
          [
            'Master games',
            '900 decisive short/famous games in Watch with one-tap engine takeover',
            'Bundled database sample on Windows + optional paid ChessBase databases',
          ],
          [
            'Source & privacy',
            'GNU AGPLv3 open source, no account, zero ads or third-party trackers',
            'Proprietary Windows license + ChessBase Account sign-in for online features',
          ],
        ],
      },
      {
        id: 'pricing-comparison',
        heading: 'Pricing and multi-device ownership',
        caption: 'Cost comparison between Brass Pawn and Fritz',
        headers: ['Cost factor', 'Brass Pawn', 'Fritz'],
        rows: [
          [
            'Computer sparring cost',
            '$0 free and unlimited forever across iPhone, iPad and Mac',
            'Upfront paid Windows software (~$70–$95+) or recurring ChessBase Account for full Fritz Online',
          ],
          [
            'Full training unlock',
            '$3.99/month or $39.99 one-off permanent unlock',
            'Paid major version upgrades every cycle (Fritz 18 → 19 → 20) + optional account renewal',
          ],
          [
            'Mobile offline experience',
            'Full native offline iPhone and iPad app included',
            'Browser-dependent web app on mobile/Mac without native offline Windows features',
          ],
          [
            'Multiplayer included',
            'Free unlimited Apple Game Center matches (3, 5, 10, 15, 30 min)',
            'Playchess.com server access bundled for a fixed period with desktop purchase',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Should you pick Brass Pawn or Fritz?',
        caption: 'Decision guide for players comparing Brass Pawn and Fritz',
        headers: ['Player profile', 'Better choice', 'Why'],
        rows: [
          [
            'MacBook, iPad or iPhone owner wanting offline coached sparring and tactics',
            'Brass Pawn',
            'Runs natively across Apple devices without Windows emulation or browser tabs.',
          ],
          [
            'Windows desktop user invested in Playchess.com and ChessBase CBH files',
            'Fritz',
            'Integrates directly with ChessBase opening books, Windows UCI engines and Playchess.',
          ],
          [
            'Practising coached games without spending $80+ upfront',
            'Brass Pawn',
            'Coached games against Stockfish 18 (1400 to full strength) cost $0 forever.',
          ],
          [
            'Getting a second engine’s opinion offline without manually installing UCI binaries',
            'Brass Pawn',
            'Both Stockfish 18 and Reckless 0.10 ship inside the app and switch in Settings.',
          ],
          [
            'Training opening books with Windows tree statistics',
            'Fritz',
            'Includes traditional opening-book management; Brass Pawn omits opening memorisation.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Human-scaled opposition without theatrical gimmicks',
        paragraphs: [
          'Recent Fritz desktop releases lean heavily on caricatured opponent personas and spoken banter on Windows. Brass Pawn takes a quieter path suited to iPhone, iPad and Mac: Stockfish 18’s strength limiter restricts search depth and width from roughly 1400 upward so the engine misses deep tactics the way a human misses them, while the coach explains each move’s win-probability impact in plain sentences about open files, outposts and king safety.',
        ],
      },
      {
        heading: 'One purchase vs versioned Windows upgrades',
        paragraphs: [
          'Desktop chess suites traditionally charge $70–$95 for each numbered desktop release while billing separately for mobile/web ecosystems. Brass Pawn keeps computer play, Game Center multiplayer and 900 Watch games free forever, with a single $39.99 one-off Pro option that restores across your iPhone, iPad and Mac.',
        ],
      },
    ],
    honestTradeoffs: [
      'Fritz runs natively on Windows PCs and integrates with ChessBase databases, opening books and Playchess.com.',
      'Fritz supports importing arbitrary Windows UCI engines and Syzygy endgame tablebases on desktop.',
      'Brass Pawn intentionally omits opening repertoire trees and multi-million-game PGN archives.',
    ],
    faqs: [
      {
        q: 'Does Fritz have a native macOS or iPad offline app like Brass Pawn?',
        a: 'Flagship Fritz is a Windows desktop application; Mac and iPad users are generally directed to browser-based ChessBase web tools or Windows virtual machines. Brass Pawn runs natively on macOS 14+, iPadOS 17+ and iOS 17+.',
      },
      {
        q: 'How does Brass Pawn adjust engine difficulty?',
        a: 'When Stockfish 18 is selected, Brass Pawn uses UCI_Elo strength limiting (from roughly 1400 to full strength), restricting how deeply and widely the engine searches rather than injecting random blunders. Reckless 0.10 plays at full strength only.',
      },
      {
        q: 'Can Brass Pawn show move values before I play a move, like Fritz Assisted Analysis?',
        a: 'Yes. During practice games, you can turn on move values to compare legal choices before committing to a move, or leave them off and read the post-move coaching verdict.',
      },
      {
        q: 'Is Brass Pawn free to try before buying Pro?',
        a: 'Yes. Coached engine games, Game Center matches and all 900 Watch games are unlimited at $0, plus 5 free attempts per day in each metered training mode.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chessbase',
      'brass-pawn-vs-shredder-chess',
      'brass-pawn-vs-hiarcs-chess-explorer',
    ],
    relatedGuides: [
      { slug: 'choose-chess-computer-strength', title: 'Choosing a chess computer strength for useful practice' },
      { slug: 'chess-coach-vs-engine', title: 'Chess coach or engine: what kind of feedback do you need?' },
      { slug: 'mac-chess-analysis-workflow', title: 'Chess analysis on Mac: organise one question at a time' },
    ],
  },
  {
    slug: 'brass-pawn-vs-lucas-chess',
    tldr:
      'Lucas Chess is a generous, free open-source Windows and Linux desktop chess trainer packed with dozens of UCI engines and training widgets. Brass Pawn brings that same open-source, zero-ad, offline spirit natively to iPhone, iPad and Mac with a cohesive SwiftUI interface, Stockfish 18 and Reckless 0.10, win-probability move coaching, 14,351 tactics puzzles and Game Center multiplayer.',
    tables: [
      {
        id: 'platform-design',
        heading: 'Native Apple SwiftUI studio vs Windows/Linux desktop toolkit',
        caption: 'Platform, UX and engine comparison between Brass Pawn and Lucas Chess',
        headers: ['Dimension', 'Brass Pawn', 'Lucas Chess'],
        rows: [
          [
            'Supported operating systems',
            'Native iPhone, iPad and Mac (iOS 17+, iPadOS 17+, macOS 14+)',
            'Windows and Linux desktop (no iPhone or iPad app; no official notarised Mac App Store app)',
          ],
          [
            'Interface design',
            'Focused dark-theatre SwiftUI with 8 clear modes plus 2D & carved/bronze 3D boards',
            'Multi-menu Qt/Python desktop utility with dozens of sub-dialogs and mini-tools',
          ],
          [
            'Bundled engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 (full) compiled natively',
            'Dozens of bundled desktop UCI engines spanning weak novices to Stockfish',
          ],
          [
            'Tactics & spaced repetition',
            '14,351 puzzles across 20 motifs with automatic 1/4/10-day spaced repetition',
            'Large collection of tactical packs, Leitner boxes and custom PGN training files',
          ],
          [
            'Move coaching',
            'Win-probability grading + plain-English board-feature sentences',
            'Tutor dialog showing centipawn/eval tables, MultiPV lines and numeric hints',
          ],
          [
            'Licence & telemetry',
            'GNU AGPLv3 open source, zero ads, zero analytics',
            'GPL open source, zero ads, zero analytics',
          ],
        ],
      },
      {
        id: 'feature-cost',
        heading: 'Training modes, mobility and pricing',
        caption: 'Practical workflow and cost comparison between Brass Pawn and Lucas Chess',
        headers: ['Feature / Cost', 'Brass Pawn', 'Lucas Chess'],
        rows: [
          [
            'Pocket & tablet training',
            'First-class iPhone and iPad experience offline anywhere',
            'Desktop-only — requires sitting at a Windows or Linux PC',
          ],
          [
            'Positional & Elo modes',
            '116 quiet positional judgement exercises + 1,624 Guess the Elo games + 900 Watch games',
            'Determine-your-calculating-power, Find Best Move and GM game replay tools',
          ],
          [
            'Board photo scanner',
            'On-device Apple Vision camera/photo board reader built in',
            'Manual FEN/position setup on desktop',
          ],
          [
            'Online human play',
            'Apple Game Center matchmaking & friend invitations (3–30 min)',
            'Offline desktop training program',
          ],
          [
            'Cost',
            'Free unlimited play + 5/day drills; Pro $3.99/mo or $39.99 once on App Store (source is AGPLv3)',
            '$0 free open-source desktop download',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Which open-source trainer fits your setup?',
        caption: 'Choosing between Brass Pawn and Lucas Chess by device and workflow',
        headers: ['Scenario', 'Better choice', 'Why'],
        rows: [
          [
            'Training on an iPhone, iPad or Apple Silicon Mac with zero configuration',
            'Brass Pawn',
            'Native App Store installation with touch, pointer and retina typography built for Apple hardware.',
          ],
          [
            'Using a Windows or Linux PC and wanting dozens of quirky low-rated UCI engines for $0',
            'Lucas Chess',
            'Legendary free desktop sandbox with unmatched configurable sub-modes on Windows/Linux.',
          ],
          [
            'Preferring calm, legible plain-English feedback over complex numeric UCI tables',
            'Brass Pawn',
            'Translates win-probability drops directly into sentences about open files, outposts and king safety.',
          ],
          [
            'Drilling personal PGN opening lines and custom Leitner flashcard decks on a PC',
            'Lucas Chess',
            'Includes desktop opening-line and custom PGN import trainers.',
          ],
          [
            'Playing a quick 10-minute human game with zero chat after finishing daily puzzles',
            'Brass Pawn',
            'Includes Game Center multiplayer right beside the offline training modes.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Kindred philosophy, completely different platforms',
        paragraphs: [
          'Lucas Chess has earned enormous goodwill among Windows desktop players by offering serious offline training without accounts, telemetry or ads. Its only real barriers for Apple households are platform and interface: there is no iPhone or iPad app, and its desktop menus expose decades of accumulated checkboxes.',
          'Brass Pawn brings an equally uncompromising open-source (AGPLv3), offline-first ethic natively to iPhone, iPad and Mac. Instead of asking you to configure Leitner parameters or pick among forty obscure engines, it gives you eight focused modes, automatic spaced repetition, win-probability coaching and 31 localised languages.',
        ],
      },
      {
        heading: 'Open source on the App Store',
        paragraphs: [
          'Like Lucas Chess, Brass Pawn’s complete source code is public on GitHub under GNU AGPLv3. Installing from the App Store gives you signed automatic updates, Game Center matchmaking and optional Pro convenience ($3.99/mo or $39.99 once), while computer play and Watch stay $0 forever.',
        ],
      },
    ],
    honestTradeoffs: [
      'Lucas Chess is 100% free with zero daily counters on Windows and Linux.',
      'Lucas Chess includes opening-book trainers, PGN database tools and dozens of specialized calculation mini-modes.',
      'Brass Pawn targets iPhone, iPad and Mac rather than Windows or Linux desktops.',
    ],
    faqs: [
      {
        q: 'Does Lucas Chess run on iPhone or iPad?',
        a: 'No. Lucas Chess is a desktop Python/Qt application built for Windows and Linux. Brass Pawn is built natively in SwiftUI for iPhone, iPad and Mac.',
      },
      {
        q: 'Why does Brass Pawn ship two engines instead of forty?',
        a: 'Because Stockfish 18 covers human-scaled ratings from ~1400 to world-champion strength via UCI_Elo depth limiting, while Reckless 0.10 offers a genuine full-strength second opinion in imbalanced positions — without overwhelming Settings.',
      },
      {
        q: 'Can I build Brass Pawn from source under AGPLv3?',
        a: 'Yes. The complete Swift rules engine, perft test suite, puzzle-mining scripts and app source are published at github.com/minchopm/chess-trainer under GNU AGPLv3.',
      },
      {
        q: 'Does Brass Pawn work offline like Lucas Chess?',
        a: 'Yes. All training modes, both chess engines and all 900 Watch games work offline with zero network calls.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-en-croissant',
      'brass-pawn-vs-smallfish-stockfish-ios',
      'native-mac-ipad-chess-app-vs-browser-tabs',
    ],
    relatedGuides: [
      { slug: 'ipad-chess-practice-routine', title: 'Chess practice on iPad: use the space to explain a position' },
      { slug: 'deliberate-chess-practice', title: 'Deliberate chess practice: turn one mistake into a test' },
      { slug: 'offline-chess-app-checklist', title: 'Choosing an offline chess app: what should work without internet?' },
    ],
  },
  {
    slug: 'brass-pawn-vs-ct-art-chess-king',
    tldr:
      'CT-ART 4.0 and the Chess King Learn catalog offer classic Soviet-school tactical and thematic puzzle workbooks split across dozens of standalone course purchases or a MAX subscription. Brass Pawn unifies 14,351 motif-tagged tactics, 116 positional judgement exercises, 15 live Stockfish endgame drills, Rush, Guess the Elo, 900 Watch games and unlimited coached engine play inside a single native iPhone, iPad and Mac app.',
    tables: [
      {
        id: 'unified-vs-split',
        heading: 'One unified Apple chess trainer vs fragmented Chess King courses',
        caption: 'Structural comparison between Brass Pawn and CT-ART / Chess King Learn',
        headers: ['Dimension', 'Brass Pawn', 'CT-ART 4.0 / Chess King Learn'],
        rows: [
          [
            'App architecture',
            'One native SwiftUI app containing all 8 playing, coaching and training modes',
            'Dozens of separate topic apps or an umbrella catalog of individually locked courses',
          ],
          [
            'Tactics volume',
            '14,351 single-solution puzzles (760–2800) across 20 motifs + spaced repetition',
            'CT-ART ships ~2,200 curated exercises (+ 5x5 helper hints); other topics sold separately',
          ],
          [
            'Full game sparring & coach',
            'Unlimited free games vs Stockfish 18 (1400–full) or Reckless 0.10 with live coaching',
            'Workbook-first puzzle solver; minimal live coached full-game focus',
          ],
          [
            'Positional & endgame modes',
            '116 quiet positional exercises + 15 Stockfish-verified endgame drills included',
            'Requires separate Strategy, Middlegame and Total Chess Endgames course unlocks',
          ],
          [
            'Master game takeover',
            '900 decisive master games in Watch included free',
            'Separate annotated collection courses',
          ],
          [
            'Design & typography',
            'Modern Apple dark-theatre UI, 2D & 3D boards, 31 languages',
            'Utilitarian cross-platform course-reader layout',
          ],
        ],
      },
      {
        id: 'pricing-catalog',
        heading: 'All-in-one pricing vs per-course unlocks',
        caption: 'Cost comparison between Brass Pawn and Chess King courses',
        headers: ['Cost element', 'Brass Pawn', 'CT-ART / Chess King'],
        rows: [
          [
            'Free experience',
            'Unlimited engine & Game Center play, 900 Watch games + 5/day in every training mode',
            'Small sample chapters per course before paywall',
          ],
          [
            'Single-app / full unlock',
            '$39.99 once (or $3.99/mo) unlocks every mode across iPhone, iPad and Mac',
            'Individual courses ~$9.99–$29.99 each, or recurring Chess King MAX subscription',
          ],
          [
            'Cost of Tactics + Strategy + Endgames + Games',
            '$39.99 total one-off (or $0 at 5 drills/day)',
            'Multiple separate course purchases across topics or ongoing MAX subscription',
          ],
          [
            'Account & tracking',
            'No account required, zero ad or analytics SDKs',
            'Chess King account sync across mobile/web catalog',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to choose Brass Pawn vs CT-ART',
        caption: 'Decision guide for tactical and practical players',
        headers: ['Training goal', 'Better fit', 'Why'],
        rows: [
          [
            'Specifically working through Maxim Blokh’s classic CT-ART composed tactics with 5x5 mini-board hints',
            'CT-ART 4.0',
            'CT-ART’s 5x5 simplified hint boards are a classic pedagogical design for complex combinations.',
          ],
          [
            'One cohesive app on iPhone, iPad and Mac for daily tactics, positional plans, endgames and coached games',
            'Brass Pawn',
            'Everything lives under one roof with zero extra course upsells.',
          ],
          [
            'Practising practical game positions calibrated from real games (760–2800) with automatic spaced repetition',
            'Brass Pawn',
            '14,185 human-calibrated CC0 Lichess puzzles + 166 depth-20 mined positions resurface automatically when missed.',
          ],
          [
            'Training on Android or Windows browser',
            'CT-ART / Chess King',
            'Ships on Android, iOS and web; Brass Pawn is Apple-native.',
          ],
          [
            'Playing coached practice games immediately after solving puzzles to test pattern transfer',
            'Brass Pawn',
            'Play & Coach is built right beside Tactics and costs $0 forever.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Practical game recognition vs composed textbook combinations',
        paragraphs: [
          'CT-ART earned its place in chess training history with dense, multi-variation combinational exercises and 5x5 hint boards. Where players sometimes stall is switching between five separate Chess King apps — one for beginner mates, one for CT-ART, one for strategy, one for endings — without ever playing a coached game that ties those muscles together.',
          'Brass Pawn keeps all eight disciplines in one place on iPhone, iPad and Mac. Miss a deflection or quiet move in Tactics and spaced repetition brings it back; switch to Positional judgement when no forced win exists; then play a coached game against Stockfish 18 to test your blunder check under real move-by-move flow.',
        ],
      },
      {
        heading: 'No DLC walls between chess skills',
        paragraphs: [
          'In Brass Pawn, tactics, positional exercises, endgames, Rush and Guess the Elo are never sold as separate expansion packs. Every mode opens for five daily attempts on the free tier, and one Pro purchase unlocks all of them.',
        ],
      },
    ],
    honestTradeoffs: [
      'CT-ART’s hand-curated Blokh combinations include simplified 5x5 visual hint boards for intermediate/advanced calculation.',
      'Chess King’s catalog includes niche single-opening and elementary checkmate workbooks, plus Android support.',
      'Brass Pawn’s endgame mode focuses on 15 core engine-verified drills rather than hundreds of composed endgame studies.',
    ],
    faqs: [
      {
        q: 'How does Brass Pawn verify that its puzzles are sound?',
        a: 'The 14,185 imported Lichess puzzles undergo move-legality normalisation and MultiPV spot-checking, while the 166 locally mined puzzles are searched at depth 20 (requiring ≥140 cp margin over the second-best move) and independently re-verified by a separate script at higher depth.',
      },
      {
        q: 'Does Brass Pawn offer hints when I get stuck?',
        a: 'In Play & Coach games, Brass Pawn includes a two-step hint system — first highlighting candidate pieces, then showing the move arrow — plus take-backs. In Tactics, you commit to your calculated move on the board and get an immediate verdict plus spaced-repetition follow-up if you miss.',
      },
      {
        q: 'Are quiet moves included in Brass Pawn’s tactics library?',
        a: 'Yes — 1,101 puzzles in Brass Pawn’s bundled library specifically turn on a quiet move (not a check, not a capture, not an immediate mate threat), alongside 1,318 sacrifices and 646 deflections.',
      },
      {
        q: 'Do I have to pay separately for iPad and Mac?',
        a: 'No. Brass Pawn is one universal App Store app across iPhone, iPad and Mac.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chessable',
      'brass-pawn-vs-chess-tempo',
      'brass-pawn-vs-shredder-chess',
    ],
    relatedGuides: [
      { slug: 'spaced-repetition-chess', title: 'Spaced repetition for chess: remember ideas, not clicks' },
      { slug: 'deflection-versus-decoy', title: 'Deflection or decoy? Separate leaving a square from reaching one' },
      { slug: 'calculate-forcing-lines-without-tunnel-vision', title: 'Calculate forcing lines without following checks blindly' },
    ],
  },
  {
    slug: 'brass-pawn-vs-duolingo-chess',
    tldr:
      'Duolingo Chess brings bite-sized, streak-driven beginner exercises into the Duolingo habit loop alongside hearts, leagues and ad-supported free play. Brass Pawn is a dedicated native iPhone, iPad and Mac chess trainer with zero ads, zero streak pressure, two full-strength local engines (Stockfish 18 and Reckless 0.10), 14,351 rated tactics up to 2800, 116 positional exercises and 900 decisive master games.',
    tables: [
      {
        id: 'depth-gamification',
        heading: 'Dedicated chess trainer vs gamified streak micro-lessons',
        caption: 'Feature and pedagogical comparison between Brass Pawn and Duolingo Chess',
        headers: ['Dimension', 'Brass Pawn', 'Duolingo Chess'],
        rows: [
          [
            'Target learner',
            'Beginners who know piece movement through strong club players (760–2800 puzzles)',
            'Absolute novices & casual learners motivated by daily streaks, XP and leagues',
          ],
          [
            'Chess engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 running locally offline on device',
            'Scripted character drills and simplified bot encounters inside Duolingo',
          ],
          [
            'Full game experience',
            'Unlimited coached 8x8 games, 900 Watch master games & Game Center human play',
            'Primarily short board snippets, guided prompts and mini-matches',
          ],
          [
            'Feedback style',
            'Win-probability move grading + concrete sentences about files, outposts & structure',
            'Gamified animations, character reactions, XP counters and streak nudges',
          ],
          [
            'Advertising & notifications',
            'Zero ads ever, zero streak-nag notifications, zero analytics SDKs',
            'Ad-supported free tier (energy/hearts) and daily streak notifications',
          ],
          [
            'Apple platforms',
            'Native iPhone, iPad and Mac app',
            'Mobile Duolingo app ecosystem',
          ],
        ],
      },
      {
        id: 'pricing-privacy',
        heading: 'Pricing, ownership and privacy posture',
        caption: 'Cost and data comparison between Brass Pawn and Duolingo subscriptions',
        headers: ['Factor', 'Brass Pawn', 'Duolingo (Free / Super / Max)'],
        rows: [
          [
            'Free play without ads',
            'Yes — unlimited coached engine play, Game Center & 900 Watch games, zero ads',
            'Free tier displays ads between lessons and meters mistakes',
          ],
          [
            'Paid subscription cost',
            '$3.99/month removes daily 5-per-mode training limits',
            'Super Duolingo / Duolingo Max recurring monthly or annual plans (significantly higher annual price)',
          ],
          [
            'Lifetime one-off option',
            '$39.99 once — permanent unlock with zero renewals',
            'None — recurring subscription only',
          ],
          [
            'Account & data collection',
            'No account sign-up; training history stays locally in the device container',
            'Mandatory account profile, telemetry, leaderboards and ad/marketing identifiers',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When Duolingo Chess works vs when to graduate to Brass Pawn',
        caption: 'Player-fit matrix comparing Brass Pawn and Duolingo Chess',
        headers: ['Situation', 'Better fit', 'Why'],
        rows: [
          [
            'You already pay for Super Duolingo for Spanish and want a playful 3-minute intro to how pieces move',
            'Duolingo Chess',
            'Convenient zero-friction introduction to basic rules inside an app you already open.',
          ],
          [
            'You finished basic rules and want to play complete games without ads, hearts or cartoon interruptions',
            'Brass Pawn',
            'Unlimited ad-free coached games on a calm board with real Stockfish 18 evaluations.',
          ],
          [
            'Improving calculation past 1000 toward club strength (1400–2000+)',
            'Brass Pawn',
            '14,351 tactics across 20 motifs, 116 positional exercises and 15 Stockfish-defended endgames.',
          ],
          [
            'Studying on Mac or iPad offline during travel',
            'Brass Pawn',
            'Everything ships locally inside the native iOS, iPadOS and macOS bundle.',
          ],
          [
            'Giving a child a chess app with zero ads, zero social leaderboards and zero tracking',
            'Brass Pawn',
            'Zero ad SDKs, zero analytics and zero in-game chat.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Streaks measure attendance; chess improvement requires resistance',
        paragraphs: [
          'Gamified streak apps excel at getting a beginner to tap the icon for ninety consecutive days. In chess, however, tapping through three-piece prompts does not prepare you for move 22 of a real game when both kings are castled, no free piece is hanging, and you have to decide whether to open the c-file.',
          'Brass Pawn respects your attention. There are no hearts, gems or mascot animations — just a quiet dark room, an ivory-and-brass board, two world-class engines running locally on your device, and feedback that tells you why a move improved or worsened your winning chances.',
        ],
      },
      {
        heading: 'Zero ads by licence, not just by marketing promise',
        paragraphs: [
          'Because Brass Pawn links Stockfish 18 (GPLv3) and Reckless 0.10 (AGPLv3), compiling a closed-source advertising SDK into the app binary would violate copyleft licensing. Free users get the exact same ad-free board as Pro users.',
        ],
      },
    ],
    honestTradeoffs: [
      'Duolingo Chess teaches absolute day-one piece movement (how a bishop or pawn moves) from scratch; Brass Pawn assumes you already know the basic rules.',
      'If you already subscribe to Super Duolingo for languages, its beginner chess track carries no extra cost.',
      'Duolingo also supports Android devices; Brass Pawn is built natively for iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Can I switch to Brass Pawn right after learning the rules on Duolingo?',
        a: 'Yes — that is one of the cleanest progressions. Once you know legal moves, checks and castling, Brass Pawn’s 760+ tactics, 1400+ coached Stockfish games (with hints and take-backs) and 15 fundamental endgame drills pick up where introductory micro-lessons end.',
      },
      {
        q: 'Does Brass Pawn send daily push notifications to protect a streak?',
        a: 'No. Brass Pawn tracks your local training streak quietly inside the app’s Progress view, but it never badgers you with push notifications or streak-freeze upsells.',
      },
      {
        q: 'Are there ads on Brass Pawn’s free tier?',
        a: 'Never. Every screen in Brass Pawn is 100% free of banners, video ads and tracking SDKs.',
      },
      {
        q: 'How much cheaper is Brass Pawn Pro than a typical annual learning app?',
        a: 'Brass Pawn Pro is $3.99/month or $39.99 once forever — less than a single year of most premium gamified learning subscriptions — and coached play is $0 even without Pro.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-dr-wolf',
      'brass-pawn-vs-magnus-trainer',
      'ad-free-chess-training-vs-diamond-subscriptions',
    ],
    relatedGuides: [
      { slug: 'adult-beginner-chess-plan', title: 'Learning chess as an adult: a practical training plan' },
      { slug: 'ten-minute-chess-routine', title: 'A ten-minute chess routine with a clear stopping point' },
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
    ],
  },
  {
    slug: 'brass-pawn-vs-smallfish-stockfish-ios',
    tldr:
      'SmallFish is a lightweight, free open-source Stockfish GUI for iPhone and iPad aimed at players who want raw UCI evaluation lines and PGN browsing. Brass Pawn builds a complete native iPhone, iPad and Mac training environment around Stockfish 18 plus Reckless 0.10 — adding win-probability move coaching in plain words, 14,351 spaced-repetition tactics, 116 positional exercises, 15 endgame drills, 900 Watch games, on-device photo board scanning and Game Center play.',
    tables: [
      {
        id: 'trainer-vs-gui',
        heading: 'Guided 8-mode training suite vs minimalist Stockfish GUI',
        caption: 'Technical comparison between Brass Pawn and SmallFish on Apple devices',
        headers: ['Capability', 'Brass Pawn', 'SmallFish'],
        rows: [
          [
            'Bundled engines',
            'Stockfish 18 (1400–full) + Reckless 0.10 (full) compiled locally',
            'Local Stockfish build on iOS',
          ],
          [
            'Native platforms',
            'iPhone, iPad and Mac (macOS 14+, iOS/iPadOS 17+)',
            'iPhone and iPad (iOS/iPadOS)',
          ],
          [
            'Evaluation output',
            'Win-probability grading + plain-English position-feature coaching + move values',
            'Raw numeric centipawn evaluation and principal-variation move strings',
          ],
          [
            'Bundled training modes',
            '14,351 tactics, 116 positional, 15 endgames, Rush, 1,624 Guess the Elo, 900 Watch games',
            'Analysis board and engine play; no bundled spaced-repetition tactics or positional curriculum',
          ],
          [
            'Board photo recognition',
            'On-device Apple Vision camera/photo position reader included',
            'Manual board setup / FEN / PGN import',
          ],
          [
            'Board rendering',
            '2D themes plus 3D carved and brass/bronze sets in SwiftUI',
            'Clean 2D board',
          ],
        ],
      },
      {
        id: 'workflow-pricing',
        heading: 'Study workflow, multiplayer and cost',
        caption: 'Feature and licensing comparison between Brass Pawn and SmallFish',
        headers: ['Aspect', 'Brass Pawn', 'SmallFish'],
        rows: [
          [
            'Licence',
            'GNU AGPLv3 open source on GitHub',
            'GPLv3 open source',
          ],
          [
            'Advertising & tracking',
            'Zero ads, zero trackers, no account',
            'Zero ads, zero trackers, no account',
          ],
          [
            'Online human play',
            'Real-time Game Center matches (3, 5, 10, 15, 30 min) + friend invites',
            'Solo offline engine and PGN tool',
          ],
          [
            'Daily broadcast stories',
            'Today mode highlights turning points from current elite events',
            'Not included',
          ],
          [
            'Cost',
            '$0 unlimited engine play, Game Center & 900 Watch games; Pro $3.99/mo or $39.99 once for unlimited daily drills',
            '$0 free app',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to use Brass Pawn vs SmallFish',
        caption: 'Scenario guide comparing Brass Pawn and SmallFish',
        headers: ['What you want to do', 'Better fit', 'Why'],
        rows: [
          [
            'Understand why your move was bad in words rather than reading “-1.45 d5 exd5 Nxd5”',
            'Brass Pawn',
            'Win-probability move grading and position-feature sentences translate engine lines into plans.',
          ],
          [
            'Inspect raw Stockfish MultiPV lines and step through external PGN files for $0 on an older iPhone',
            'SmallFish',
            'Fast, minimalist raw UCI analysis board with zero frills.',
          ],
          [
            'Follow a structured daily loop of tactics, quiet positional judgement and endgame conversion',
            'Brass Pawn',
            'All bundled offline with spaced repetition and per-discipline ratings.',
          ],
          [
            'Compare Stockfish 18 against a second engine (Reckless 0.10) on iPhone, iPad or Mac',
            'Brass Pawn',
            'Both engines are compiled into Brass Pawn and switchable in Settings.',
          ],
          [
            'Snap a photo of a chess book diagram and play it out against Stockfish offline',
            'Brass Pawn',
            'Built-in on-device Apple Vision photo board reader.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why raw engine lines alone rarely cure club blunders',
        paragraphs: [
          'SmallFish is an admirable utility when you already know how to interrogate an engine: paste a PGN, read "+1.82", and play through ten plies of algebraic notation yourself. For most improving players, however, raw centipawn lines treat a meaningless drop at +8.0 identically to a game-losing concession at 0.0, and never name the strategic concept behind the line.',
          'Brass Pawn wraps Stockfish 18 and Reckless 0.10 in a coaching layer built for improvement: win-probability grading separates decisive mistakes from noise, coaching notes name open files, knight outposts and isolated pawns across 31 languages, and Play & Coach stays 100% free.',
        ],
      },
      {
        heading: 'Native macOS support alongside iPhone and iPad',
        paragraphs: [
          'Unlike iOS-only utilities, Brass Pawn ships natively for macOS 14+ as well as iPhone and iPad, with 2D and 3D boards, Game Center multiplayer and 900 decisive master games.',
        ],
      },
    ],
    honestTradeoffs: [
      'SmallFish is completely free across every screen, whereas Brass Pawn meters its five training drill modes to 5/day unless you unlock Pro ($3.99/mo or $39.99 once).',
      'SmallFish focuses on raw PGN file folder management and UCI parameter tweaking for users who want a bare engine scratchpad.',
      'SmallFish has lower OS minimums on older iOS hardware; Brass Pawn requires iOS/iPadOS 17.0+ or macOS 14.0+.',
    ],
    faqs: [
      {
        q: 'Is playing against Stockfish 18 free in Brass Pawn just like SmallFish?',
        a: 'Yes. Unlimited play against Stockfish 18 (from ~1400 to full strength) or Reckless 0.10, including live move-by-move coaching and take-backs, is completely free forever in Brass Pawn.',
      },
      {
        q: 'Which version of Stockfish ships in Brass Pawn?',
        a: 'Brass Pawn ships Stockfish 18 (GPLv3) alongside Reckless 0.10 (AGPLv3), both compiled natively into the app.',
      },
      {
        q: 'Can Brass Pawn read a chess position from a book or physical board?',
        a: 'Yes. Under Play → Board → Photo, Brass Pawn uses Apple Vision on your device (completely offline) plus a four-corner tap and editor check to read real chessboards or book diagrams.',
      },
      {
        q: 'Are both apps open source?',
        a: 'Yes — SmallFish is GPLv3 and Brass Pawn is GNU AGPLv3 with full source published on GitHub.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-shredder-chess',
      'brass-pawn-vs-en-croissant',
      'brass-pawn-vs-nibbler-leela-gui',
    ],
    relatedGuides: [
      { slug: 'chess-engine-analysis-workflow', title: 'A chess engine analysis workflow that answers a question' },
      { slug: 'centipawns-vs-win-probability', title: 'Centipawns, winning chances and accuracy: read chess scores carefully' },
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
    ],
  },
  {
    slug: 'brass-pawn-vs-apple-arcade-chess',
    tldr:
      'Apple Arcade chess titles (such as Really Bad Chess+ or Pocket Chess+ / 3D Arcade chess games) focus on casual visual variety or variant rules inside a $6.99/month Apple Arcade subscription — disappearing the day you cancel Arcade. Brass Pawn is a dedicated native iPhone, iPad and Mac chess trainer with free forever play, 2D and carved/bronze 3D boards, Stockfish 18 + Reckless 0.10, 14,351 tactics puzzles and an optional $39.99 permanent unlock.',
    tables: [
      {
        id: 'training-vs-arcade',
        heading: 'Dedicated chess trainer vs casual Apple Arcade chess titles',
        caption: 'Feature comparison between Brass Pawn and Apple Arcade chess games',
        headers: ['Dimension', 'Brass Pawn', 'Apple Arcade Chess Titles'],
        rows: [
          [
            'Primary design goal',
            'Real chess improvement: coached play, tactics, positional judgement & endgames',
            'Casual 3D environments, visual dioramas or randomised piece variants',
          ],
          [
            'Access without subscription',
            'Yes — unlimited engine play, Game Center & 900 Watch games at $0 forever',
            'No — app refuses to launch the moment your Apple Arcade subscription lapses',
          ],
          [
            'Engines & move feedback',
            'Stockfish 18 (1400–full) + Reckless 0.10 with win-probability coaching sentences',
            'Casual AI difficulty tiers without win-probability move-feature coaching',
          ],
          [
            'Structured training library',
            '14,351 tactics (20 motifs), 116 positional tests, 15 endgame drills, 1,624 Guess the Elo',
            'Light puzzle challenges or arcade campaign stages',
          ],
          [
            '2D & 3D board choice',
            'Fast 2D tournament boards AND carved / brass-and-bronze 3D dimensional sets',
            'Often heavy 3D-only scenes (slower for blitz/tactics) or minimalist casual boards',
          ],
          [
            'Advertising & tracking',
            'Zero ads, zero trackers, AGPLv3 open source',
            'Zero ads inside Apple Arcade, proprietary closed source',
          ],
        ],
      },
      {
        id: 'cost-ownership',
        heading: 'Subscription rental vs free play & permanent ownership',
        caption: 'Cost math comparing Brass Pawn with keeping Apple Arcade for chess',
        headers: ['Ownership metric', 'Brass Pawn', 'Apple Arcade ($6.99/mo standalone)'],
        rows: [
          [
            'Cost to play engine & Game Center forever',
            '$0',
            '~$83.88/year unless bundled in an Apple One plan you already keep forever',
          ],
          [
            'Cost for unlimited daily training',
            '$3.99/month or $39.99 once forever',
            'Included while subscribed; $0 permanent ownership option',
          ],
          [
            '3-year standalone cost',
            '$0 (free tier) or $39.99 (one-off Pro)',
            '~$251.64 over 36 months of standalone Apple Arcade',
          ],
          [
            'Devices covered',
            'iPhone, iPad and Mac',
            'iPhone, iPad, Mac and Apple TV',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When Apple Arcade chess is enough vs when you want Brass Pawn',
        caption: 'Player-fit matrix between Brass Pawn and Apple Arcade chess games',
        headers: ['Scenario', 'Better fit', 'Why'],
        rows: [
          [
            'You already have Apple One Family and want wacky randomised pieces (Really Bad Chess+) or scenic 3D casual play',
            'Apple Arcade Chess',
            'Included in your existing bundle for lighthearted casual entertainment.',
          ],
          [
            'You want to get genuinely stronger at classical chess tactics, positional plans and endgames',
            'Brass Pawn',
            'Built around Stockfish 18, spaced-repetition motifs and engine-verified endgame conversion.',
          ],
          [
            'You want both a crisp 2D board for fast calculation and a 3D brass/bronze set when relaxing',
            'Brass Pawn',
            'Settings switches cleanly between flat 2D themes and dimensional 3D sets.',
          ],
          [
            'You plan to cancel Apple Arcade without losing your chess app and saved progress',
            'Brass Pawn',
            'Free play never expires, and Pro offers a $39.99 non-consumable purchase.',
          ],
          [
            'Studying 900 decisive master games offline and taking over positions against Stockfish',
            'Brass Pawn',
            'Watch mode is free and built for active master-game study.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Flat 2D for speed, carved 3D for atmosphere — in the same app',
        paragraphs: [
          'Many 3D showcase chess apps force perspective camera angles that obscure diagonal pins during a five-minute game or tactical Rush run. Brass Pawn treats board dimension as a deliberate choice in Settings: switch to crisp 2D piece sets and wood/lamplight squares when calculating fast, or switch to the dimensional 3D board — including the selectable brass and bronze set with round rook bases — when playing at leisure.',
        ],
      },
      {
        heading: 'Owning your chess trainer outright',
        paragraphs: [
          'Apple Arcade is pleasant for disposable games you finish in a weekend, but chess training is a multi-year habit. With Brass Pawn, unlimited computer and Game Center play cost $0 forever without an active subscription, and $39.99 buys unlimited Pro training permanently.',
        ],
      },
    ],
    honestTradeoffs: [
      'If your household already pays for Apple One, Arcade chess titles carry zero incremental monthly cost.',
      'Some Apple Arcade titles support Apple TV living-room remotes or whimsical chess variants not in Brass Pawn.',
      'Brass Pawn focuses strictly on orthodox chess rules and serious improvement rather than arcade campaigns.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn have 3D chess pieces like Apple Arcade games?',
        a: 'Yes. Brass Pawn lets you choose between 2D flat boards (with multiple piece sets and light-square tones) and dimensional 3D boards, including carved sets and a brass-and-bronze set.',
      },
      {
        q: 'Does Brass Pawn also use Apple Game Center like Arcade games?',
        a: 'Yes. Brass Pawn uses Apple Game Center for real-time 3, 5, 10, 15 and 30-minute human matches, per-clock leaderboards and friend invitations, with zero ads and zero chat.',
      },
      {
        q: 'What happens to Brass Pawn if I buy Pro for a month and cancel?',
        a: 'Unlike Apple Arcade apps that lock completely when cancelled, Brass Pawn keeps all your local progress, ratings, unlimited coached engine play, Game Center multiplayer and 900 Watch games working free forever — returning only the five-a-day counter on training drills.',
      },
      {
        q: 'Can I share Brass Pawn on a family iPad?',
        a: 'Yes. Brass Pawn requires no account sign-up, contains no ads or chat, and runs natively on iPhone, iPad and Mac.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-real-chess-3d',
      'brass-pawn-vs-chess-universe',
      'ad-free-chess-training-vs-diamond-subscriptions',
    ],
    relatedGuides: [
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
      { slug: 'ipad-chess-practice-routine', title: 'Chess practice on iPad: use the space to explain a position' },
      { slug: 'game-center-chess-with-friends', title: 'Playing chess with friends through Game Center' },
    ],
  },
  {
    slug: 'brass-pawn-vs-chess-universe',
    tldr:
      'Chess Universe wraps mobile chess in free-to-play mobile gaming loops — cartoon avatars, daily quests, gems, cosmetic chests and ad-supported progression. Brass Pawn is the polar opposite: a calm, dark-theatre native trainer for iPhone, iPad and Mac with zero ads, zero virtual currencies, Stockfish 18 and Reckless 0.10 running offline, and 14,351 tactics puzzles.',
    tables: [
      {
        id: 'experience-comparison',
        heading: 'Quiet classical study vs free-to-play gems and avatars',
        caption: 'User experience and architecture comparison between Brass Pawn and Chess Universe',
        headers: ['Dimension', 'Brass Pawn', 'Chess Universe'],
        rows: [
          [
            'Visual & audio atmosphere',
            'Dark theatre, Cormorant Garamond / Inter / JetBrains Mono type, subtle wood & brass',
            'Cartoon avatars, animated emotes, treasure chests, quests and gem counters',
          ],
          [
            'Advertising & IAP economy',
            'Zero ads, zero gems, zero loot boxes; only optional Pro ($3.99/mo or $39.99 once)',
            'Rewarded/interstitial ads on free tier, gem packs and VIP subscription passes',
          ],
          [
            'Engines & coaching',
            'Local Stockfish 18 (1400–full) + Reckless 0.10 with win-probability coaching sentences',
            'Themed bot characters and basic academy puzzles',
          ],
          [
            'Training depth',
            '14,351 tactics, 116 positional exercises, 15 endgame drills, Rush & 1,624 Guess the Elo',
            'Casual puzzle quests and beginner/intermediate academy challenges',
          ],
          [
            'Privacy & tracking',
            'No account, zero third-party ad/analytics SDKs, AGPLv3 open source',
            'Account profiles, ad-network SDKs and behavioral analytics',
          ],
          [
            'Platforms',
            'Native iPhone, iPad and Mac',
            'iOS, Android and web/Steam casual cross-play',
          ],
        ],
      },
      {
        id: 'pricing-clarity',
        heading: 'Transparent pricing vs multi-currency mobile monetization',
        caption: 'Monetization comparison between Brass Pawn and Chess Universe',
        headers: ['Aspect', 'Brass Pawn', 'Chess Universe'],
        rows: [
          [
            'Free engine & human matches',
            'Unlimited, zero ads, zero energy/gem timers',
            'Free matches accompanied by ads, quest pop-ups and cosmetic upsells',
          ],
          [
            'Paywall behaviour',
            'Never shown on launch; appears only after 5 daily attempts in a training mode',
            'Shop, VIP pass and gem promotions surfaced across menus',
          ],
          [
            'Permanent unlock',
            '$39.99 one-off purchase removes every training counter forever',
            'Recurring VIP pass + consumable currency packs',
          ],
          [
            'Master game library',
            '900 decisive classics free in Watch with position takeover',
            'Not included',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Which app fits your taste?',
        caption: 'Player-fit guide comparing Brass Pawn and Chess Universe',
        headers: ['Preference', 'Better choice', 'Why'],
        rows: [
          [
            'You want a calm board where nothing flashes, begs for gems or plays a video ad',
            'Brass Pawn',
            'Designed explicitly as a quiet study room with zero ad SDKs.',
          ],
          [
            'You enjoy unlocking playful cartoon avatars, pets and emotes across Android and iOS',
            'Chess Universe',
            'Built around cosmetic collection and casual cross-platform quests.',
          ],
          [
            'You want honest feedback on why a move lost win probability',
            'Brass Pawn',
            'Local Stockfish 18 coaching names concrete board features on every move.',
          ],
          [
            'You want a kid-safe chess app with zero ad networks and zero emoticon/chat noise',
            'Brass Pawn',
            'No ads, no analytics SDKs and zero messaging or emote spam in Game Center play.',
          ],
          [
            'Practising offline on a flight across iPhone, iPad or Mac',
            'Brass Pawn',
            'All engines, puzzles and 900 Watch games run locally offline.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Attention is the scarce resource in chess calculation',
        paragraphs: [
          'Calculating a four-move deflection or rook endgame requires holding two or three candidate positions in working memory. Rewarded video ads, gem counters and season-pass pop-ups break that concentration every few minutes by design.',
          'Brass Pawn treats chess with the quiet focus of a good book: ivory typography, a warm board in the dark, optional system/serif/mono typefaces in Settings, and zero interruptions between positions.',
        ],
      },
      {
        heading: 'Copyleft as a permanent shield against ad bloat',
        paragraphs: [
          'Apps that start clean sometimes add ad networks two years later. Brass Pawn is licensed under GNU AGPLv3 because it links Stockfish 18 and Reckless 0.10 — making proprietary ad SDKs legally incompatible with distributing the binary.',
        ],
      },
    ],
    honestTradeoffs: [
      'Chess Universe offers cross-platform casual matchmaking across Android, iOS and PC; Brass Pawn is Apple-only (iPhone, iPad, Mac) using Game Center.',
      'Players who enjoy cosmetic unlocks, avatars and daily quest loops will find Brass Pawn intentionally minimalist.',
      'Chess Universe has larger casual cross-platform lobbies than Brass Pawn’s Game Center pool.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn have any gems, coins, hearts or energy bars?',
        a: 'None. Playing against the engine, playing over Game Center and studying all 900 Watch games have zero counters or currencies. The five training drill modes simply give 5 free attempts per day (resetting at 9:00 AM local time), or unlimited attempts with Pro.',
      },
      {
        q: 'Can opponents spam emotes or chat messages in Brass Pawn multiplayer?',
        a: 'No. Brass Pawn’s multiplayer protocol carries only legal moves, resignations, draw offers and draw responses — no text chat and no emotes.',
      },
      {
        q: 'Can I still customise how the board looks without buying cosmetics?',
        a: 'Yes. Every 2D piece set, board style, light-square tone, typeface choice and 3D carved or brass/bronze board is included in Settings for every user — nothing cosmetic is sold.',
      },
      {
        q: 'Does Brass Pawn track my device ID for ads?',
        a: 'Never. Brass Pawn never requests ATT permission, contains zero tracking SDKs and collects nothing outside ephemeral Game Center online presence.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-real-chess-3d',
      'private-no-chat-chess-app-for-kids-and-focus',
      'ad-free-chess-training-vs-diamond-subscriptions',
    ],
    relatedGuides: [
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
      { slug: 'deliberate-chess-practice', title: 'Deliberate chess practice: turn one mistake into a test' },
      { slug: 'avoid-one-move-chess-blunders', title: 'A practical check to avoid one-move chess blunders' },
    ],
  },
  {
    slug: 'brass-pawn-vs-real-chess-3d',
    tldr:
      'Generic “Real Chess 3D” mobile apps attract downloads with rotatable 3D boards, then interrupt games with interstitial ads, weak engines and zero real training tools. Brass Pawn includes selectable 3D carved and brass-and-bronze sets (plus crisp 2D sets) natively on iPhone, iPad and Mac — backed by Stockfish 18 and Reckless 0.10, 14,351 tactics puzzles, live move coaching and zero ads forever.',
    tables: [
      {
        id: '3d-engine-comparison',
        heading: 'Clean Apple 3D + Stockfish 18 vs ad-supported 3D chess apps',
        caption: 'Technical comparison between Brass Pawn and typical Real Chess 3D mobile apps',
        headers: ['Feature', 'Brass Pawn', 'Real Chess 3D Apps'],
        rows: [
          [
            '3D & 2D board support',
            'Dimensional 3D boards (including brass & bronze set) + instant toggle to flat 2D sets',
            '3D camera board (often clunky or slow for tactical calculation)',
          ],
          [
            'Chess engine quality',
            'Stockfish 18 (1400–full) + Reckless 0.10 compiled locally on device',
            'Basic weak built-in AI levels with erratic tactical horizon mistakes',
          ],
          [
            'Move coaching',
            'Win-probability grading + plain-English sentences explaining what changed',
            'None — wins or loses with no positional explanation',
          ],
          [
            'Training curriculum',
            '14,351 tactics, 116 positional exercises, 15 endgame drills, Rush, 900 Watch games',
            'Usually zero or a tiny static puzzle list',
          ],
          [
            'Advertising & tracking',
            'Zero banner or video ads ever; zero tracking SDKs (AGPLv3)',
            'Frequent post-game video interstitials, banner ads and ad-mediation SDKs',
          ],
          [
            'Apple hardware support',
            'Native SwiftUI across iPhone, iPad and Mac',
            'Generic mobile Unity/OpenGL wrapper (heavy battery & thermal drain)',
          ],
        ],
      },
      {
        id: 'cost-battery',
        heading: 'Pricing, battery life and privacy',
        caption: 'Operational and cost comparison between Brass Pawn and Real Chess 3D apps',
        headers: ['Dimension', 'Brass Pawn', 'Real Chess 3D Apps'],
        rows: [
          [
            'Cost for ad-free 3D computer play',
            '$0 — completely free and ad-free out of the box',
            'Requires “Remove Ads” IAP or recurring VIP subscription to stop video ads',
          ],
          [
            'Pro training option',
            '$3.99/month or $39.99 one-off unlock for unlimited daily training drills',
            'No deep training library to unlock',
          ],
          [
            'Network calls during solo 3D play',
            'Zero — offline engines, zero ad-bidding background traffic',
            'Constant background ad-network requests and telemetry when online',
          ],
          [
            'Real-board photo reader',
            'Included on device via Apple Vision (Play → Board → Photo)',
            'Not included',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to choose Brass Pawn vs Real Chess 3D',
        caption: 'Scenario comparison between Brass Pawn and ad-supported 3D chess apps',
        headers: ['Goal', 'Better choice', 'Why'],
        rows: [
          [
            'Playing on a handsome 3D brass-and-bronze board on iPhone, iPad or Mac with zero video ads',
            'Brass Pawn',
            '3D sets and unlimited coached Stockfish 18 play are free with zero ads.',
          ],
          [
            'Switching to a crisp 2D board when solving timed Rush tactics or playing a 3-minute Game Center clock',
            'Brass Pawn',
            'Settings treats 2D and 3D as instant peers so fast games never suffer 3D perspective lag.',
          ],
          [
            'Playing on a budget Android handset',
            'Real Chess 3D (Android)',
            'Brass Pawn ships exclusively on Apple platforms (iPhone, iPad, Mac).',
          ],
          [
            'Actually improving your chess rating beyond casual AI matches',
            'Brass Pawn',
            'Provides 14,351 spaced-repetition tactics, 116 positional tests and 15 endgame drills.',
          ],
          [
            'Keeping a child’s iPad free of third-party mobile game ad promos',
            'Brass Pawn',
            'Contains zero ad SDKs and zero external game-store pop-ups.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: '3D craftsmanship without the ad-network tax',
        paragraphs: [
          'Searching the App Store for “3D chess” turns up dozens of lookalike wrappers that show a thirty-second unskippable ad after every checkmate while running an engine from twenty years ago. Brass Pawn gives you dimensional 3D play — including carved sets and a selectable brass-and-bronze set with round rook bases — at $0 with zero advertisements anywhere in the binary.',
        ],
      },
      {
        heading: 'A real trainer underneath the 3D board',
        paragraphs: [
          'Behind Brass Pawn’s board sits a verified Swift move generator tested against a full perft suite, Stockfish 18 and Reckless 0.10, win-probability move grading, 14,351 tactics across 20 motifs, and 900 decisive master games.',
        ],
      },
    ],
    honestTradeoffs: [
      'Real Chess 3D apps are available on Android phones and tablets; Brass Pawn is built natively for iPhone, iPad and Mac.',
      'Some standalone 3D apps include pass-and-play fantasy environments or free-roaming 360° camera toys rather than focused chess lighting.',
      'Brass Pawn’s five structured drill modes are metered to 5/day on the free tier (though 3D engine & Game Center play are unlimited free).',
    ],
    faqs: [
      {
        q: 'Do I have to buy Brass Pawn Pro to use the 3D board or brass/bronze pieces?',
        a: 'No. Every board dimension (2D and 3D), piece carving and square style in Settings is available to free users with zero cosmetic paywalls.',
      },
      {
        q: 'Why does Brass Pawn include both 2D and 3D boards?',
        a: 'Because a dimensional 3D set is a pleasure to look at in a relaxed game, while a flat 2D board is faster to scan during Puzzle Rush or a 5-minute clock. Settings lets you switch between them whenever you like.',
      },
      {
        q: 'Are there ads after games in Brass Pawn?',
        a: 'Never — not after one game, not after a hundred games.',
      },
      {
        q: 'How strong is the 3D computer opponent in Brass Pawn?',
        a: 'It runs the exact same local Stockfish 18 (adjustable from ~1400 to full grandmaster-plus strength) or full-strength Reckless 0.10.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-apple-arcade-chess',
      'brass-pawn-vs-chess-universe',
      'brass-pawn-vs-sparkchess',
    ],
    relatedGuides: [
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
      { slug: 'ipad-chess-practice-routine', title: 'Chess practice on iPad: use the space to explain a position' },
    ],
  },
  {
    slug: 'brass-pawn-vs-noctie-ai',
    tldr:
      'Noctie AI is a cloud-based browser SaaS built around neural networks trained to mimic human mistake patterns at a target Elo, paired with auto-generated flashcards for a recurring monthly/annual fee. Brass Pawn runs Stockfish 18 (depth/width-limited from 1400 to full strength) and Reckless 0.10 natively offline on iPhone, iPad and Mac — offering unlimited free coached sparring and an optional $39.99 one-off Pro unlock.',
    tables: [
      {
        id: 'local-vs-cloud',
        heading: 'Local native engines vs cloud neural-bot SaaS',
        caption: 'Technical and architectural comparison between Brass Pawn and Noctie AI',
        headers: ['Dimension', 'Brass Pawn', 'Noctie AI'],
        rows: [
          [
            'Where chess compute runs',
            '100% locally on your iPhone, iPad or Mac (zero network latency)',
            'Remote cloud GPU servers accessed in a web browser',
          ],
          [
            'Offline play & analysis',
            'Full offline play, coaching, 14,351 tactics & 900 Watch games',
            'None — requires an active internet connection for every move',
          ],
          [
            'Opponent scaling method',
            'Stockfish 18 UCI_Elo search-depth/width restriction (1400–full) + Reckless 0.10',
            'Cloud neural models tuned to imitate human-like move distributions by rating',
          ],
          [
            'Move feedback',
            'Win-probability grading + plain-English board-feature sentences on every move',
            'Post-move/post-game accuracy, tactic alerts and mistake retry flashcards',
          ],
          [
            'Structured training modes',
            'Tactics (20 motifs), Positional (116), Endgames (15), Rush, Guess the Elo (1,624), Watch (900)',
            'Bot sparring, custom PGN/opening sparring positions and mistake flashcards',
          ],
          [
            'Privacy & account',
            'No account, zero telemetry, AGPLv3 open source',
            'Cloud account login with server-stored games and subscription billing',
          ],
        ],
      },
      {
        id: 'pricing-math',
        heading: 'Pricing and multi-year ownership math',
        caption: 'Cost comparison between Brass Pawn and Noctie AI subscriptions',
        headers: ['Cost metric', 'Brass Pawn', 'Noctie AI'],
        rows: [
          [
            'Unlimited engine sparring',
            '$0 free forever (including live move-by-move coaching)',
            'Strict free trial / daily cap; recurring subscription required for regular sparring',
          ],
          [
            'Monthly plan',
            '$3.99/month (for unlimited daily puzzle/drill modes)',
            'Higher monthly cloud SaaS rate (commonly ~$12–$20+/month billed monthly or annually)',
          ],
          [
            'One-off lifetime unlock',
            '$39.99 once forever across iPhone, iPad and Mac',
            'Not offered — ongoing cloud compute requires recurring SaaS payments',
          ],
          [
            '2-year cost of full access',
            '$39.99 total (with one-off Pro) or $0 for sparring alone',
            'Roughly $180–$350+ across two years of SaaS billing',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to choose Brass Pawn vs Noctie AI',
        caption: 'Decision matrix comparing Brass Pawn and Noctie AI',
        headers: ['Priority', 'Better choice', 'Why'],
        rows: [
          [
            'Unlimited free coached sparring on iPhone, iPad or Mac — including on flights and subways',
            'Brass Pawn',
            'Local Stockfish 18 sparring costs nothing to run on your CPU and stays $0 forever.',
          ],
          [
            'Specifically sparring from custom imported PGN opening tabiyas against human-imitation neural nets in a desktop browser',
            'Noctie AI',
            'Noctie specialises in human-distribution neural move choice and opening-tabiya sparring.',
          ],
          [
            'Keeping 2-year training software spend at $0–$39.99 instead of $200+ in cloud SaaS fees',
            'Brass Pawn',
            'Local execution eliminates cloud GPU bills and allows a $39.99 permanent unlock.',
          ],
          [
            'Working through 14,351 motif-tagged tactics, 116 quiet positional exercises and 15 endgames',
            'Brass Pawn',
            'Ships a complete multi-mode offline curriculum rather than bot-sparring alone.',
          ],
          [
            'Using Windows, Linux or Android browsers',
            'Noctie AI',
            'Runs in any modern web browser; Brass Pawn is native to Apple platforms.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'How depth-limited Stockfish 18 compares with cloud neural bots',
        paragraphs: [
          'Old chess programs weakened themselves clumsily by playing nine grandmaster moves and then tossing a queen away on move ten. Modern Stockfish 18’s UCI_Elo limits search depth and width instead, so a 1500 setting plays natural developing moves and overlooks three-ply tactical combinations — closely matching why club games are actually won and lost.',
          'Because that search runs locally on your Apple Silicon Mac, iPad or iPhone in milliseconds, Brass Pawn never charges you monthly cloud GPU rent just to play a practice game.',
        ],
      },
      {
        heading: 'Coaching while you play + Game Center when you want a real human',
        paragraphs: [
          'No bot — neural or classical — completely replaces human psychology on a clock. When you want true human unpredictability, Brass Pawn includes unlimited real-time Game Center matches on 3, 5, 10, 15 and 30-minute clocks at $0.',
        ],
      },
    ],
    honestTradeoffs: [
      'Noctie’s cloud neural networks are trained specifically on human game distributions (Maia-style) to mimic human opening/middlegame tendencies even more closely than depth-limited classical search.',
      'Noctie supports sparring from user-uploaded opening PGN repertoires in any browser (Windows, Android, Linux).',
      'Brass Pawn intentionally omits opening repertoire flashcards and requires iPhone, iPad or Mac.',
    ],
    faqs: [
      {
        q: 'Why can Brass Pawn offer free unlimited coached games while Noctie charges a SaaS fee?',
        a: 'Every move Noctie plays or analyses runs on Noctie’s cloud servers, creating ongoing server cost per game. Brass Pawn compiles Stockfish 18 and Reckless 0.10 directly into your iPhone, iPad and Mac app, so computer games cost $0 to serve forever.',
      },
      {
        q: 'Does Stockfish 18 in Brass Pawn just blunder pieces randomly at lower ratings?',
        a: 'No. Brass Pawn uses Stockfish’s UCI_Elo search-depth and width limiting (from ~1400 to full strength), meaning the engine misses deeper tactical horizons rather than making absurd random giveaways.',
      },
      {
        q: 'Can I start from a specific master game position in Brass Pawn?',
        a: 'Yes — in Watch (900 decisive master games) or Today’s stories, you can tap Play on from here at any move to continue that exact position against the local engine with full coaching, or paste/photograph a position on the board.',
      },
      {
        q: 'Does Brass Pawn work with zero internet?',
        a: 'Yes. Every engine game, coaching note, tactic, positional drill, endgame drill and Watch game runs 100% offline.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-decodechess',
      'structured-chess-bot-sparring-vs-blitz-tilt',
      'ad-free-chess-training-vs-diamond-subscriptions',
    ],
    relatedGuides: [
      { slug: 'choose-chess-computer-strength', title: 'Choosing a chess computer strength for useful practice' },
      { slug: 'chess-coach-vs-engine', title: 'Chess coach or engine: what kind of feedback do you need?' },
      { slug: 'deliberate-chess-practice', title: 'Deliberate chess practice: turn one mistake into a test' },
    ],
  },
  {
    slug: 'brass-pawn-vs-decodechess',
    tldr:
      'DecodeChess is a cloud web tool that runs deep explainable-AI (XAI) algorithms to generate multi-paragraph threat and plan breakdowns for imported games, metered by per-game analysis credits or monthly SaaS tiers. Brass Pawn runs Stockfish 18 and Reckless 0.10 locally on iPhone, iPad and Mac, delivering instant offline win-probability grading and concise position-feature coaching on every move you play — unlimited and free.',
    tables: [
      {
        id: 'explanation-architecture',
        heading: 'Instant on-device move coaching vs cloud XAI game credits',
        caption: 'Technical comparison between Brass Pawn and DecodeChess',
        headers: ['Dimension', 'Brass Pawn', 'DecodeChess'],
        rows: [
          [
            'Explanation engine',
            'On-device Stockfish 18 / Reckless 0.10 + deterministic board-feature change extractor',
            'Cloud Stockfish + proprietary XAI threat/concept graph generator',
          ],
          [
            'Response latency',
            'Instant local feedback after every move (offline)',
            'Seconds-to-minutes of cloud processing per position/game (internet required)',
          ],
          [
            'Explanation length & style',
            'One clear sentence naming the decisive board feature + win-probability swing',
            'Multi-tab visual arrows, threat lists, piece roles and long prose breakdowns',
          ],
          [
            'Built-in training curriculum',
            '14,351 tactics, 116 positional exercises, 15 endgames, Rush, Guess the Elo, 900 Watch games',
            'Focused primarily on deep position/PGN decoding plus supplementary puzzles',
          ],
          [
            'Native platforms',
            'SwiftUI app for iPhone, iPad and Mac',
            'Browser web application (desktop & mobile web)',
          ],
          [
            'Privacy',
            'Zero games uploaded to any cloud server; no account required',
            'Games and positions uploaded to DecodeChess cloud under your user account',
          ],
        ],
      },
      {
        id: 'cost-metering',
        heading: 'Unlimited local coaching vs per-game credit metering',
        caption: 'Cost and usage limits in Brass Pawn vs DecodeChess',
        headers: ['Usage / Cost', 'Brass Pawn', 'DecodeChess'],
        rows: [
          [
            'Coached games per day (Free)',
            'Unlimited — zero credit counters on Play & Coach',
            'Strictly capped free daily/trial decodes',
          ],
          [
            'Monthly subscription',
            '$3.99/month (removes 5/day limit on bundled drill modes)',
            'Recurring monthly/annual cloud plan with tiered decode allowances or unlimited tier',
          ],
          [
            'Lifetime one-off unlock',
            '$39.99 once forever',
            'None — cloud CPU per decode requires recurring subscription or credit packs',
          ],
          [
            'Offline commuting / flights',
            'Works 100% offline with zero degraded coaching',
            'Unavailable without internet access',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to use Brass Pawn vs DecodeChess',
        caption: 'Scenario guide comparing Brass Pawn and DecodeChess',
        headers: ['Scenario', 'Better choice', 'Why'],
        rows: [
          [
            'Getting immediate, readable feedback after every move of a practice game on iPhone, iPad or Mac',
            'Brass Pawn',
            'Zero wait, zero decode credits consumed, and graded by win probability rather than raw centipawns.',
          ],
          [
            'Generating an exhaustive multi-paragraph visual threat report on one critical tournament PGN in a desktop browser',
            'DecodeChess',
            'DecodeChess’s cloud XAI unpacks secondary threats and prophylaxis across long sub-trees.',
          ],
          [
            'Training quiet positional judgement directly rather than passively reading engine essays',
            'Brass Pawn',
            '116 Positional exercises make you judge the position first, then grade both your assessment and move.',
          ],
          [
            'Practising offline with zero cloud uploads and a one-off purchase option',
            'Brass Pawn',
            'All compute stays on your Apple device; Pro is $39.99 once.',
          ],
          [
            'Working on Windows, Chromebook or Linux browsers',
            'DecodeChess',
            'Runs in any desktop browser; Brass Pawn is Apple-native.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'One sharp sentence you read vs five paragraphs you skim',
        paragraphs: [
          'Long auto-generated essays on every ply of a forty-move game quickly cause analysis fatigue: when everything gets six bullet points, the one moment the game actually turned gets buried. Brass Pawn’s coaching layer does two things before speaking: first, it converts engine evaluations to win probability so harmless centipawn jitter is ignored; second, it states the concrete board feature that changed — “takes the open d-file”, “plants the knight on the e5 outpost”, “breaks up the enemy bishop pair”.',
          'Because that logic executes locally on top of Stockfish 18 or Reckless 0.10, it runs instantaneously during live practice games at zero per-game cost.',
        ],
      },
      {
        heading: 'Active judgement beats passive reading',
        paragraphs: [
          'Reading why an engine liked a move feels productive even when nothing sticks. Brass Pawn pairs move coaching with active recall: 116 quiet Positional judgement exercises force you to commit to an evaluation (“slightly better”, “balanced”) and a move before seeing the feature breakdown.',
        ],
      },
    ],
    honestTradeoffs: [
      'DecodeChess produces deeper multi-layered threat trees and prophylaxis diagrams when dissecting an imported PGN game on a large desktop monitor.',
      'DecodeChess imports full PGN archives in any browser across Windows, Linux and Android.',
      'Brass Pawn’s coaching is intentionally concise (one feature-focused verdict per move) rather than a long-form annotated report.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn use generative AI or cloud credits for its explanations?',
        a: 'Neither. Brass Pawn’s explanations are generated deterministically on your device by comparing board features across Stockfish 18 or Reckless 0.10’s search lines — requiring zero internet and zero credits.',
      },
      {
        q: 'Are Brass Pawn’s coaching sentences available in languages besides English?',
        a: 'Yes. All 31 shipped locales translate both the interface and the chess-specific tactical and positional vocabulary.',
      },
      {
        q: 'Can I paste a position or scan a diagram to get Stockfish + Reckless analysis in Brass Pawn?',
        a: 'Yes. You can paste a game/position on the board or read a physical diagram offline via Apple Vision (Play → Board → Photo), and switch between Stockfish 18 and Reckless 0.10 in Settings.',
      },
      {
        q: 'Do coached games run out on Brass Pawn’s free tier?',
        a: 'No. Play & Coach is free and unlimited forever.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-noctie-ai',
      'brass-pawn-vs-aimchess',
      'brass-pawn-vs-dr-wolf',
    ],
    relatedGuides: [
      { slug: 'centipawns-vs-win-probability', title: 'Centipawns, winning chances and accuracy: read chess scores carefully' },
      { slug: 'chess-coach-vs-engine', title: 'Chess coach or engine: what kind of feedback do you need?' },
      { slug: 'analyse-chess-game-without-engine', title: 'Analyse your chess game before turning on the engine' },
    ],
  },
];
