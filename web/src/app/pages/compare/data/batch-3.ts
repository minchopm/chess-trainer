import type { ComparePageContent } from '../types';

export const COMPARE_BATCH_3: readonly ComparePageContent[] = [
  {
    slug: 'brass-pawn-vs-chessvision-ai',
    tldr:
      'Chessvision.ai is a specialized diagram-recognition utility across browser extensions, PDF eBook readers and mobile scan apps. Brass Pawn is a full 8-mode native chess trainer for iPhone, iPad and Mac that also includes an on-device Apple Vision board photo reader (Play → Board → Photo) — letting you photograph a physical board or book diagram offline, verify squares in the editor, and immediately play or analyse with Stockfish 18 or Reckless 0.10.',
    tables: [
      {
        id: 'scanner-vs-trainer',
        heading: 'Full playable Apple trainer with photo reader vs dedicated scan utility',
        caption: 'Technical comparison between Brass Pawn and Chessvision.ai',
        headers: ['Capability', 'Brass Pawn', 'Chessvision.ai'],
        rows: [
          [
            'Core role',
            'Complete 8-mode chess trainer + built-in camera/photo board reader',
            'Specialized 2D diagram scanner for websites, YouTube videos, PDFs and screenshots',
          ],
          [
            'How photo scanning runs',
            '100% offline on device via Apple Vision + four-corner tap + verification editor',
            'Cloud computer-vision API (internet required to submit image and fetch FEN)',
          ],
          [
            'Real 3D wooden board photos',
            'Built specifically for photographing a physical board on a table or a book page',
            'Optimised primarily for flat 2D digital screenshots, PDFs and printed 2D diagrams',
          ],
          [
            'What happens after scanning',
            'Play on against Stockfish 18 / Reckless 0.10 locally with live move coaching',
            'Opens cloud Stockfish evaluation or exports FEN link to Lichess / Chess.com',
          ],
          [
            'Bundled training modes',
            '14,351 tactics, 116 positional, 15 endgames, Rush, Guess the Elo, 900 Watch games',
            'PDF eBook reader, video lookup and scanned-diagram library',
          ],
          [
            'Privacy of photos',
            'Photos stay on your iPhone, iPad or Mac (system PhotosPicker, zero Pictures entitlement)',
            'Cropped diagram images sent to remote recognition servers',
          ],
        ],
      },
      {
        id: 'pricing-platforms',
        heading: 'Pricing, scan limits and platform support',
        caption: 'Cost and platform comparison between Brass Pawn and Chessvision.ai',
        headers: ['Factor', 'Brass Pawn', 'Chessvision.ai'],
        rows: [
          [
            'Free board scanning & engine play',
            'Included free offline with zero scan credit limits and unlimited engine play',
            'Daily/monthly scan limits on free tier; membership required for unlimited scans & eBooks',
          ],
          [
            'Paid unlock',
            '$3.99/month or $39.99 one-off permanent unlock (for unlimited daily training drills)',
            'Recurring monthly or annual Chessvision.ai membership',
          ],
          [
            'Supported platforms',
            'Native iPhone, iPad and Mac',
            'Chrome/Firefox browser extensions, web eBook reader, iOS and Android apps',
          ],
          [
            'Licence',
            'GNU AGPLv3 open source, zero ads',
            'Proprietary commercial SaaS & extensions',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to use Brass Pawn vs Chessvision.ai',
        caption: 'Scenario guide comparing Brass Pawn and Chessvision.ai',
        headers: ['Use case', 'Better tool', 'Why'],
        rows: [
          [
            'Photographing a real wooden board or printed chess book on iPhone/iPad offline and playing on against Stockfish',
            'Brass Pawn',
            'Four-corner tap + on-device Apple Vision + local Stockfish 18 works with zero Wi-Fi and zero scan caps.',
          ],
          [
            'One-click scanning a 2D board inside a paused YouTube lecture in desktop Chrome',
            'Chessvision.ai',
            'Browser extension captures video frames directly inside desktop web tabs.',
          ],
          [
            'Converting a 300-page chess PDF book into clickable side-by-side diagrams',
            'Chessvision.ai',
            'Includes a dedicated cloud PDF chess eBook reader.',
          ],
          [
            'Having daily tactics, positional judgement, endgames and coached sparring in the same app you scan into',
            'Brass Pawn',
            'Combines the board reader with 8 complete offline training modes.',
          ],
          [
            'Keeping camera images strictly on device with zero cloud upload',
            'Brass Pawn',
            'All Vision inference and engine evaluation stay inside your Apple device.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why Brass Pawn uses four corner taps and an always-on editor',
        paragraphs: [
          'Automatic line-finding pipelines routinely fail on real-world phone photos of wooden boards shot at an angle under warm room lighting — and even strong square classifiers misread two or three pieces on shadowed squares. Brass Pawn’s photo reader (Play → Board → Photo) asks you to tap the four corners of the board, runs Apple Vision locally on your iPhone, iPad or Mac, and sends the result straight into a quick correction step before Stockfish 18 or Reckless 0.10 takes over.',
        ],
      },
      {
        heading: 'Zero Pictures-folder permissions on macOS and iOS',
        paragraphs: [
          'Choosing an existing image in Brass Pawn goes through Apple’s out-of-process system PhotosPicker, which hands the app only the single image you picked rather than requesting read access to your photo library.',
        ],
      },
    ],
    honestTradeoffs: [
      'Chessvision.ai’s Chrome/Firefox extension scans YouTube chess videos and web pages in one click and finds matching YouTube lectures containing that exact position.',
      'Chessvision.ai includes a dedicated multi-page PDF chess eBook studio.',
      'Chessvision.ai runs on Android, Windows and Linux browsers; Brass Pawn is native to iPhone, iPad and Mac.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn’s photo board reader work offline without internet?',
        a: 'Yes. Both the Apple Vision square recognition and the Stockfish 18 / Reckless 0.10 analysis run completely offline on your iPhone, iPad or Mac.',
      },
      {
        q: 'How do I reach the photo scanner in Brass Pawn?',
        a: 'Open Play → Board → Photo. On iPhone or iPad (or a Mac with a camera) you can take a photo directly or pick one from your library via Apple’s system PhotosPicker.',
      },
      {
        q: 'Are board photo scans metered or locked behind Pro?',
        a: 'No. Reading a board from a photo and analysing or playing on from it against the engine are completely free.',
      },
      {
        q: 'Does Brass Pawn gain access to all my photos when I pick a diagram?',
        a: 'No. Brass Pawn uses Apple’s system PhotosPicker, which runs outside the app and passes only the single image you selected — requiring zero photo-library folder entitlement.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-smallfish-stockfish-ios',
      'brass-pawn-vs-en-croissant',
      'native-mac-ipad-chess-app-vs-browser-tabs',
    ],
    relatedGuides: [
      { slug: 'chess-engine-analysis-workflow', title: 'A chess engine analysis workflow that answers a question' },
      { slug: 'analyse-chess-game-without-engine', title: 'Analyse your chess game before turning on the engine' },
      { slug: 'ipad-chess-practice-routine', title: 'Chess practice on iPad: use the space to explain a position' },
    ],
  },
  {
    slug: 'brass-pawn-vs-chesskid',
    tldr:
      'ChessKid is an online scholastic portal built around parent/coach guardianship accounts, animated beginner videos and supervised kid clubs. Brass Pawn is a zero-account, zero-ad, zero-chat native chess trainer for iPhone, iPad and Mac where all offline progress stays inside the device container, multiplayer runs strictly over Apple Game Center with no text messaging field, and parents can lock multiplayer completely with iOS/macOS Screen Time.',
    tables: [
      {
        id: 'safety-privacy',
        heading: 'Family safety, chat and privacy architecture',
        caption: 'Child-safety and privacy comparison between Brass Pawn and ChessKid',
        headers: ['Safety / Privacy dimension', 'Brass Pawn', 'ChessKid'],
        rows: [
          [
            'Account creation for a child',
            'None — zero registration, zero email, zero username/password profile',
            'Requires creating a child account linked to a parent or school coach guardian account',
          ],
          [
            'In-game chat & messaging',
            'Physically absent — MatchProtocol carries only moves, resignations and draw offers',
            'Restricted preset emojis/safe-club messaging managed by guardian/coach settings',
          ],
          [
            'OS-level multiplayer lock',
            'Parents can disable Game Center multiplayer entirely in Apple Screen Time',
            'Managed inside ChessKid’s web parent/coach dashboard',
          ],
          [
            'Advertising & analytics SDKs',
            'Zero ads, zero analytics libraries, zero third-party tracking SDKs',
            'No third-party banner ads; uses account analytics and subscription prompts',
          ],
          [
            'Where a child’s progress lives',
            'Locally in the app’s container on the family iPhone, iPad or Mac',
            'Stored in ChessKid’s cloud servers under the child’s profile',
          ],
          [
            'Offline car & airplane use',
            '100% of coached play, 14,351 puzzles, endgames & 900 Watch games work offline',
            'Online-first web/app portal requiring login for puzzles, bots and videos',
          ],
        ],
      },
      {
        id: 'curriculum-cost',
        heading: 'Training depth and family cost comparison',
        caption: 'Curriculum and pricing comparison between Brass Pawn and ChessKid',
        headers: ['Feature / Cost', 'Brass Pawn', 'ChessKid'],
        rows: [
          [
            'Teaching style',
            'Calm classical/3D boards, win-probability move coaching & 20-motif tactics (760–2800)',
            'Cartoon characters, animated video lessons, stars and scholastic workouts',
          ],
          [
            'Ceiling as the child improves',
            'Scales all the way to 2800 puzzles and full Stockfish 18 without switching apps',
            'Designed primarily for elementary/scholastic beginners (~0–1400)',
          ],
          [
            'Free tier',
            'Unlimited coached engine play, Game Center & 900 Watch games + 5/day per drill mode',
            'Limited daily puzzles and bot levels on basic free kid account',
          ],
          [
            'Paid upgrade',
            '$3.99/month or $39.99 one-off permanent unlock',
            'Recurring annual/monthly ChessKid Gold subscription (~$49/year per child)',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Which app fits your family or young player?',
        caption: 'Decision guide for parents choosing between Brass Pawn and ChessKid',
        headers: ['Family situation', 'Better choice', 'Why'],
        rows: [
          [
            'A 6-year-old learning piece rules via cartoon videos or participating in a school coach’s ChessKid club',
            'ChessKid',
            'Coach assignment tools and animated character videos are built for elementary classrooms.',
          ],
          [
            'Handing a child an iPad on a road trip or flight with zero accounts, zero Wi-Fi and zero chat',
            'Brass Pawn',
            'Works completely offline with no sign-up, no ads and nowhere to type or receive messages.',
          ],
          [
            'A junior player (900–1800) who has outgrown cartoon bots and wants real tactics and endgame defence',
            'Brass Pawn',
            '14,351 tactics, 15 Stockfish-defended endgames and 116 positional tests scale to club level.',
          ],
          [
            'Parents who prefer Apple Screen Time controls and $39.99 one-off ownership over annual renewals',
            'Brass Pawn',
            'Respects native iOS/macOS Screen Time restrictions and offers a non-renewing lifetime option.',
          ],
          [
            'Households using Chromebooks or Android tablets',
            'ChessKid',
            'Runs in Chromebook browsers and on Android; Brass Pawn is Apple-native.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why “no text field in the wire protocol” is stronger than chat moderation',
        paragraphs: [
          'Most family apps try to make online play safe by filtering chat words or restricting who can message whom. Brass Pawn eliminates the surface area altogether: its Game Center multiplayer protocol (`MatchProtocol.swift`, open for inspection on GitHub under AGPLv3) transmits a chess move, a resignation, a draw offer, a draw response and a game result. There is no text input anywhere in the app.',
          'If a parent wants the device to be 100% offline solo-only, toggling off Game Center multiplayer in *Settings → Screen Time → Content & Privacy Restrictions → Game Center* restricts Brass Pawn to its local engines, puzzles and Watch library immediately.',
        ],
      },
      {
        heading: 'A trainer a junior player does not outgrow in six months',
        paragraphs: [
          'Kids who fall in love with chess often jump from 700 to 1400 in a single school year. Because Brass Pawn’s tactics ladder spans 760 to 2800 and Stockfish 18 scales up to full strength, the same calm app grows with them into tournament chess.',
        ],
      },
    ],
    honestTradeoffs: [
      'ChessKid includes animated beginner rule videos, scholastic classroom management dashboards and coach homework tools.',
      'ChessKid works on school Chromebooks, Windows PCs and Android tablets; Brass Pawn requires iPhone, iPad or Mac.',
      'Brass Pawn assumes the child already knows basic legal piece movement.',
    ],
    faqs: [
      {
        q: 'Can strangers message my child in Brass Pawn?',
        a: 'No. Brass Pawn has no chat feature, no user bio, no custom avatar upload and no text input in multiplayer. Even friend requests carry only Apple Game Center nicknames — and turning off Game Center multiplayer in Screen Time disables online play completely.',
      },
      {
        q: 'Does Brass Pawn collect personal data from children?',
        a: 'Outside optional Game Center multiplayer (where online availability uses a one-way hashed Game Center ID deleted after 5 minutes, and can be switched off in Settings → Show when I’m online), Brass Pawn collects zero personal data, runs zero analytics and embeds zero ad SDKs.',
      },
      {
        q: 'Can two siblings or a parent and child review games together on an iPad?',
        a: 'Yes. Brass Pawn’s free analysis board, 900 Watch games and Play & Coach mode work great side-by-side on an iPad with take-backs, move values and plain-English coaching.',
      },
      {
        q: 'Does Family Sharing or restoring across family Apple devices require separate accounts?',
        a: 'Brass Pawn has no accounts of its own; purchases are standard App Store StoreKit 2 transactions managed by Apple.',
      },
    ],
    relatedCompare: [
      'private-no-chat-chess-app-for-kids-and-focus',
      'brass-pawn-vs-duolingo-chess',
      'brass-pawn-vs-chess-com',
    ],
    relatedGuides: [
      { slug: 'beginner-chess-study-plan', title: 'A beginner chess study plan built around real mistakes' },
      { slug: 'game-center-chess-with-friends', title: 'Playing chess with friends through Game Center' },
      { slug: 'chess-board-coordinates-warmup', title: 'Chess board coordinates: a beginner mental-board warmup' },
    ],
  },
  {
    slug: 'brass-pawn-vs-sparkchess',
    tldr:
      'SparkChess is a casual cross-platform chess game built around playing named low-to-medium personality bots (Boris, Claire, Guru) with higher bot levels and coach tools gated behind paid editions. Brass Pawn gives you unlimited free coached games against Stockfish 18 (1400 to full strength) and Reckless 0.10 natively on iPhone, iPad and Mac — plus 14,351 tactics puzzles, 116 positional exercises, 15 endgame drills and 900 decisive master games.',
    tables: [
      {
        id: 'bots-vs-engines',
        heading: 'Dual top engines + 8 training modes vs casual character bots',
        caption: 'Technical comparison between Brass Pawn and SparkChess',
        headers: ['Feature', 'Brass Pawn', 'SparkChess'],
        rows: [
          [
            'Computer opponents',
            'Stockfish 18 (adjustable 1400–full via UCI_Elo) + Reckless 0.10 (full) — all free',
            ' ~5 free beginner/casual character bots; stronger bots gated behind paid tiers',
          ],
          [
            'Move coaching',
            'Win-probability grading + plain-English board-feature sentences included free',
            'Visual coach/evaluation features primarily reserved for Premium/Pro subscribers',
          ],
          [
            'Tactics & training modes',
            '14,351 tactics (20 motifs), 116 positional, 15 endgames, Rush & 1,624 Guess the Elo',
            'Small set of lessons and basic puzzles compared with dedicated tactics libraries',
          ],
          [
            'Master game library',
            '900 decisive short/famous games in Watch with one-tap engine takeover (free)',
            'Selected historical games / PGN viewer in paid tiers',
          ],
          [
            'Board rendering',
            'Crisp 2D sets plus carved and brass/bronze 3D boards on iPhone, iPad & Mac',
            '2D and stylized 3D boards across mobile, desktop and web',
          ],
          [
            'Privacy & licence',
            'GNU AGPLv3 open source, no account, zero ads or tracking SDKs',
            'Proprietary commercial app with SparkChess multiplayer accounts',
          ],
        ],
      },
      {
        id: 'pricing-access',
        heading: 'Free play generosity and paid upgrade comparison',
        caption: 'Free vs paid access in Brass Pawn and SparkChess',
        headers: ['Access / Cost', 'Brass Pawn', 'SparkChess'],
        rows: [
          [
            'Play against strong engine for $0',
            'Yes — full range from 1400 up to maximum Stockfish 18 & Reckless 0.10 is free',
            'No — stronger computer opponents require buying Premium or subscribing',
          ],
          [
            'Human multiplayer for $0',
            'Unlimited real-time Game Center matches on 3/5/10/15/30-min clocks',
            'Casual lobby access with chat/club features',
          ],
          [
            'Paid upgrade structure',
            '$3.99/month or $39.99 one-off permanent unlock across iPhone, iPad & Mac',
            'Separate one-time per-platform app purchases or recurring cross-platform subscription',
          ],
          [
            'Advertising',
            'Zero ads in both Free and Pro',
            'Promotional upgrade prompts on free edition; ad-free paid editions',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to pick Brass Pawn vs SparkChess',
        caption: 'Player-fit matrix between Brass Pawn and SparkChess',
        headers: ['Player goal', 'Better fit', 'Why'],
        rows: [
          [
            'Playing a gentle ~700-Elo cartoon bot on Windows, Android or in a web browser',
            'SparkChess',
            'Very approachable sub-1000 casual bots across non-Apple platforms.',
          ],
          [
            'Improving from 1000 to 2000+ on iPhone, iPad and Mac with free coached sparring',
            'Brass Pawn',
            'Never locks engine strength or live move coaching behind a paywall.',
          ],
          [
            'Training 14,351 spaced-repetition tactics, positional judgement and Stockfish-defended endgames',
            'Brass Pawn',
            'Purpose-built multi-mode chess trainer rather than a casual bot board.',
          ],
          [
            'Zero-chat multiplayer without creating another username and password',
            'Brass Pawn',
            'Uses Apple Game Center directly with zero text chat.',
          ],
          [
            'Inspecting open-source engine and move-generator code',
            'Brass Pawn',
            'Published in full under GNU AGPLv3.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Never locking opponent strength behind a toll booth',
        paragraphs: [
          'Many casual chess apps let you beat two beginner bots for free and then demand payment the day you want an 1800 opponent or post-move coaching. Brass Pawn’s pricing philosophy is the exact reverse: playing against the engine — at every strength from 1400 to full Stockfish 18, with full move-by-move coaching — is free forever. Only unlimited daily repetitions of the five structured training libraries belong to Pro.',
        ],
      },
      {
        heading: 'Beyond bot matches: closing tactical and endgame leaks',
        paragraphs: [
          'Playing fifty casual games against the same fixed personality bot teaches you that bot’s quirks rather than chess itself. Brass Pawn balances coached sparring with 14,351 motif-tagged tactics, 116 quiet positional judgements and 15 canonical endgames defended accurately by Stockfish.',
        ],
      },
    ],
    honestTradeoffs: [
      'SparkChess offers very soft sub-1000 beginner bot personalities for players who find a 1400 UCI_Elo engine too tough without hints (though Brass Pawn includes two-step hints and take-backs).',
      'SparkChess runs on Windows, Android and web browsers in addition to Apple devices.',
      'SparkChess includes a cross-platform casual chat lobby.',
    ],
    faqs: [
      {
        q: 'What if Stockfish at 1400 feels hard when I am starting out in Brass Pawn?',
        a: 'In Brass Pawn’s Play & Coach mode, you can use take-backs freely, press Hint once to highlight which piece has a strong move or twice to see the move arrow, or toggle move values before moving while you build board vision.',
      },
      {
        q: 'Are any engine strengths locked behind Brass Pawn Pro?',
        a: 'No. Every Stockfish 18 strength setting and full-strength Reckless 0.10 are completely free.',
      },
      {
        q: 'Does Brass Pawn have 3D boards like SparkChess?',
        a: 'Yes — Brass Pawn includes both 2D boards and dimensional 3D boards (including carved and brass/bronze sets) on iPhone, iPad and Mac.',
      },
      {
        q: 'How many puzzles come bundled in Brass Pawn?',
        a: '14,351 tactical puzzles rated 760 to 2800, plus 116 positional judgement exercises and 15 engine-verified endgame drills.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-real-chess-3d',
      'brass-pawn-vs-shredder-chess',
      'structured-chess-bot-sparring-vs-blitz-tilt',
    ],
    relatedGuides: [
      { slug: 'choose-chess-computer-strength', title: 'Choosing a chess computer strength for useful practice' },
      { slug: 'avoid-one-move-chess-blunders', title: 'A practical check to avoid one-move chess blunders' },
      { slug: 'beginner-chess-study-plan', title: 'A beginner chess study plan built around real mistakes' },
    ],
  },
  {
    slug: 'brass-pawn-vs-en-croissant',
    tldr:
      'En Croissant is a modern, free GPLv3 desktop chess database and repertoire GUI built with Tauri and React for macOS, Windows and Linux. Brass Pawn is a ready-to-play native SwiftUI trainer for iPhone, iPad and Mac with Stockfish 18, Reckless 0.10, 14,351 tactics, 116 positional tests, 15 endgame drills and 900 Watch games already bundled inside the app — requiring zero engine downloads or database imports.',
    tables: [
      {
        id: 'app-vs-tauri-gui',
        heading: 'Zero-setup Apple trainer vs desktop Tauri database GUI',
        caption: 'Technical comparison between Brass Pawn and En Croissant',
        headers: ['Dimension', 'Brass Pawn', 'En Croissant'],
        rows: [
          [
            'Target devices',
            'iPhone, iPad and Mac (native SwiftUI)',
            'Desktop only: macOS, Windows and Linux (Tauri webview; no iPhone or iPad app)',
          ],
          [
            'Out-of-the-box readiness',
            'Engines, neural nets, 14,351 puzzles & 900 games ship inside the install',
            'Requires downloading UCI engines, reference databases and puzzle files inside the app',
          ],
          [
            'Core strength',
            'Coached sparring, spaced-repetition tactics, positional judgement, endgames & Rush',
            'PGN repertoire tree building, multi-million-game database search & multi-engine UCI tabs',
          ],
          [
            'Move coaching',
            'Win-probability grading + plain-English board-feature sentences',
            'Numeric engine lines, centipawn/WDL graphs and PGN move annotations',
          ],
          [
            'Camera board scanner',
            'On-device Apple Vision photo board reader built in',
            'FEN / PGN text import on desktop',
          ],
          [
            'Source licence',
            'GNU AGPLv3 open source',
            'GNU GPLv3 open source',
          ],
        ],
      },
      {
        id: 'workflow-cost',
        heading: 'Mobility, multiplayer and cost',
        caption: 'Workflow and pricing comparison between Brass Pawn and En Croissant',
        headers: ['Aspect', 'Brass Pawn', 'En Croissant'],
        rows: [
          [
            'iPhone & iPad offline training',
            'Full native touch UI with 2D & 3D boards',
            'Not available on iOS or iPadOS',
          ],
          [
            'Human multiplayer',
            'Apple Game Center matches (3, 5, 10, 15, 30 min) + friend invites',
            'Offline desktop database & analysis workbench',
          ],
          [
            'Opening repertoire builder',
            'Deliberately excluded',
            'Strong PGN repertoire editor with spaced-repetition line practice',
          ],
          [
            'Cost',
            'Free unlimited play + 5/day drills; Pro $3.99/mo or $39.99 once on App Store (AGPLv3 source)',
            '$0 free open-source desktop download',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'How Apple players use Brass Pawn and En Croissant',
        caption: 'Decision guide comparing Brass Pawn and En Croissant',
        headers: ['Task', 'Better tool', 'Why'],
        rows: [
          [
            'Training on iPhone, iPad or Mac without configuring engine binaries or PGN folders',
            'Brass Pawn',
            'Opens immediately into tactics, coached play, positional exercises and Watch.',
          ],
          [
            'Managing a personal PGN opening repertoire and querying Caissabase / Lichess Elite DB on desktop',
            'En Croissant',
            'Modern open-source desktop database workbench built specifically for PGN trees.',
          ],
          [
            'Understanding mistakes in plain sentences rather than raw MultiPV centipawns',
            'Brass Pawn',
            'Grades win-probability drops and names concrete positional features.',
          ],
          [
            'Working on a Windows or Linux laptop',
            'En Croissant',
            'Cross-platform desktop builds; Brass Pawn is Apple-native.',
          ],
          [
            'Combining free open-source desktop opening prep with mobile/iPad daily tactics & sparring',
            'Both together',
            'En Croissant handles opening trees on desktop; Brass Pawn handles everything else on iPhone, iPad & Mac.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Two modern open-source chess tools that complement each other cleanly',
        paragraphs: [
          'En Croissant and Brass Pawn share a deep respect for local execution, open-source licensing and zero ad clutter, yet they overlap remarkably little. En Croissant is a desktop database and opening-repertoire workbench built in Tauri; it has no iPhone or iPad app and leaves coaching prose out in favour of raw UCI panels and PGN trees.',
          'Brass Pawn deliberately omits opening-repertoire trees and multi-gigabyte reference databases so it can be an instant, tactile SwiftUI trainer across iPhone, iPad and Mac — complete with bundled Stockfish 18 and Reckless 0.10, win-probability coaching, 116 quiet positional judgements and Game Center play.',
        ],
      },
      {
        heading: 'Signed Mac App Store convenience with full source transparency',
        paragraphs: [
          'On macOS, Brass Pawn installs directly from the App Store with Apple sandboxing, automatic updates and zero Gatekeeper warnings, while keeping its complete Swift and engine C-interface source public on GitHub under AGPLv3.',
        ],
      },
    ],
    honestTradeoffs: [
      'En Croissant is 100% free on desktop and includes full PGN database search, Lichess/Chess.com account game downloaders and an opening repertoire builder.',
      'En Croissant lets you run multiple custom UCI engines side by side on macOS, Windows and Linux.',
      'Brass Pawn focuses on structured training modes and coached play rather than PGN database management.',
    ],
    faqs: [
      {
        q: 'Does En Croissant have an iPhone or iPad app?',
        a: 'No. En Croissant is a desktop Tauri application for macOS, Windows and Linux. Brass Pawn runs natively on iPhone, iPad and Mac.',
      },
      {
        q: 'Do I have to download Stockfish or puzzle databases separately inside Brass Pawn?',
        a: 'No. Both Stockfish 18 and Reckless 0.10 (including their neural networks), all 14,351 tactics puzzles, 116 positional exercises, 15 endgame drills, 1,624 Guess the Elo games and 900 Watch games ship inside the app bundle.',
      },
      {
        q: 'Why use both En Croissant and Brass Pawn on a Mac?',
        a: 'Because Brass Pawn intentionally omits opening repertoire trees: you can keep your opening PGN files in En Croissant at your desk while using Brass Pawn on Mac, iPad and iPhone for coached sparring, positional judgement, endgame conversion and spaced-repetition tactics.',
      },
      {
        q: 'Are both apps free of telemetry and ads?',
        a: 'Yes — both are copyleft open-source applications with zero advertising.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-hiarcs-chess-explorer',
      'brass-pawn-vs-lucas-chess',
      'brass-pawn-vs-nibbler-leela-gui',
    ],
    relatedGuides: [
      { slug: 'mac-chess-analysis-workflow', title: 'Chess analysis on Mac: organise one question at a time' },
      { slug: 'opening-memorization-vs-ideas', title: 'Opening memorisation versus ideas: build a repertoire you can explain' },
      { slug: 'chess-engine-analysis-workflow', title: 'A chess engine analysis workflow that answers a question' },
    ],
  },
  {
    slug: 'brass-pawn-vs-nibbler-leela-gui',
    tldr:
      'Nibbler is a specialized open-source Electron desktop GUI built specifically to inspect Leela Chess Zero (Lc0) search trees, policy priors and win-draw-loss (WDL) node statistics. Brass Pawn is a player-facing native SwiftUI trainer for iPhone, iPad and Mac that also grades moves by win probability rather than raw centipawns — but turns engine output into plain-English coaching sentences alongside 14,351 tactics puzzles, positional drills and endgames.',
    tables: [
      {
        id: 'player-vs-debugger',
        heading: 'Player-facing Apple chess coach vs Lc0 search-tree inspector',
        caption: 'Technical comparison between Brass Pawn and Nibbler',
        headers: ['Dimension', 'Brass Pawn', 'Nibbler (Lc0 GUI)'],
        rows: [
          [
            'Intended user',
            'Improving chess players (beginner to strong club) on iPhone, iPad & Mac',
            'Engine enthusiasts, analysts & developers inspecting Lc0 neural search graphs on desktop',
          ],
          [
            'Setup required',
            'Zero — Stockfish 18 & Reckless 0.10 bundled and ready on launch',
            'Manual desktop setup: compile/download Lc0 binary, GPU backend & neural network weights file',
          ],
          [
            'Win-probability insight',
            'Grades every player move by win-probability loss + plain-English board-feature note',
            'Displays raw WDL percentages, policy % arrows and node visit counts across candidate moves',
          ],
          [
            'Second engine option',
            'Switch between Stockfish 18 and Reckless 0.10 in Settings with one tap',
            'Can attach Stockfish or Lc0 UCI binaries via desktop JSON/menu config',
          ],
          [
            'Built-in training modes',
            '14,351 tactics, 116 positional, 15 endgames, Rush, Guess the Elo, 900 Watch games',
            'None — pure analysis and engine-vs-engine GUI',
          ],
          [
            'Platforms',
            'Native iPhone, iPad and Mac',
            'Desktop Electron app (Windows, Linux, macOS source/builds; no iOS/iPadOS)',
          ],
        ],
      },
      {
        id: 'usability-cost',
        heading: 'Ergonomics, hardware footprint and cost',
        caption: 'Practical usability comparison between Brass Pawn and Nibbler',
        headers: ['Aspect', 'Brass Pawn', 'Nibbler'],
        rows: [
          [
            'Pocket & tablet use',
            'Native iPhone and iPad app with offline battery-friendly CPU search',
            'Desktop-only; running large Lc0 neural nets draws heavy desktop GPU wattage',
          ],
          [
            'Board photo reading',
            'Built-in Apple Vision camera/photo diagram reader',
            'FEN / PGN paste on desktop',
          ],
          [
            'Human multiplayer',
            'Apple Game Center matches (3–30 min)',
            'None',
          ],
          [
            'Cost & licence',
            'Free unlimited play + 5/day drills; Pro $3.99/mo or $39.99 once (GNU AGPLv3)',
            '$0 free open-source desktop software (MIT/open licence)',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to open Brass Pawn vs Nibbler',
        caption: 'Scenario guide comparing Brass Pawn and Nibbler',
        headers: ['Goal', 'Better tool', 'Why'],
        rows: [
          [
            'Visualising Lc0 policy priors, node visits and WDL graphs on a desktop GPU',
            'Nibbler',
            'Nibbler is the gold-standard GUI designed specifically around Lc0’s verbose UCI output.',
          ],
          [
            'Getting win-probability move grading and plain-English coaching during real practice games',
            'Brass Pawn',
            'Applies the exact philosophy of win-probability grading without requiring a UCI debugger.',
          ],
          [
            'Comparing two elite engines (Stockfish 18 and Reckless 0.10) on iPhone, iPad or Mac with zero setup',
            'Brass Pawn',
            'Both engines are already compiled in and work offline in one tap.',
          ],
          [
            'Practising tactics, quiet positional judgement and endgame conversion daily',
            'Brass Pawn',
            'Includes 8 structured modes rather than an empty analysis board.',
          ],
          [
            'Running engine-vs-engine matches between custom neural network weight files on Windows/Linux',
            'Nibbler',
            'Built for engine testing and custom UCI configuration.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Shared insight: centipawns lie, win probability tells the truth',
        paragraphs: [
          'Analysts who use Nibbler with Leela Chess Zero love WDL (win-draw-loss) percentages for the exact same reason Brass Pawn’s engine essay highlights: "+1.00" means completely different things in a sterile opposite-coloured bishop endgame and a sacrificial kingside attack, and losing 100 centipawns at +9.0 changes your win probability by barely 1%.',
          'Where Nibbler exposes that math as developer telemetry — node counts, Q-values and policy priors on a desktop monitor — Brass Pawn turns win-probability evaluation into a calm coaching experience on iPhone, iPad and Mac, telling you which move hurt your winning chances and which positional feature on the board changed.',
        ],
      },
      {
        heading: 'Two bundled engines without command-line setup',
        paragraphs: [
          'Instead of compiling binaries and pointing file dialogs at weight files, Brass Pawn compiles both Stockfish 18 and Reckless 0.10 directly into the app so a second engine opinion is always one tap away in Settings.',
        ],
      },
    ],
    honestTradeoffs: [
      'Nibbler displays live Lc0 search-tree graphs, policy network heatmaps and node visit distributions that no consumer training app shows.',
      'Nibbler runs on Windows and Linux desktops and costs $0 across all features.',
      'Brass Pawn does not host external third-party UCI binaries or Leela weight files; it ships Stockfish 18 and Reckless 0.10 built in.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn include Leela Chess Zero (Lc0)?',
        a: 'No. Brass Pawn ships two compiled engines — Stockfish 18 (GPLv3) and Reckless 0.10 (AGPLv3) — running locally with their bundled neural networks, and converts evaluations to win probability for move grading.',
      },
      {
        q: 'Can Stockfish 18 and Reckless 0.10 play against each other in Brass Pawn?',
        a: 'No, deliberately. In Brass Pawn, you choose one engine in Settings to play, grade and label, and switch to the other whenever you want a second opinion on a position.',
      },
      {
        q: 'Why does win-probability grading matter to club players?',
        a: 'Because centipawn blunders cry wolf when a game is already +7.0. Grading moves by how much winning chance you actually lost highlights the single turning point that decided your game.',
      },
      {
        q: 'Can I view candidate move values live on the board in Brass Pawn?',
        a: 'Yes. In practice, you can toggle move values on the board to compare legal choices before playing, then switch them off when testing yourself.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-smallfish-stockfish-ios',
      'brass-pawn-vs-en-croissant',
      'brass-pawn-vs-decodechess',
    ],
    relatedGuides: [
      { slug: 'centipawns-vs-win-probability', title: 'Centipawns, winning chances and accuracy: read chess scores carefully' },
      { slug: 'chess-mistake-vs-blunder', title: 'Mistake or blunder? Look beyond the chess label' },
      { slug: 'chess-engine-analysis-workflow', title: 'A chess engine analysis workflow that answers a question' },
    ],
  },
  {
    slug: 'offline-chess-app-vs-online-chess-servers',
    tldr:
      'Most mobile chess apps are thin wrappers around an online server: lose cell signal in a subway tunnel or board a flight, and live coaching, puzzle queues and game libraries vanish or stall. A true offline chess app like Brass Pawn compiles Stockfish 18, Reckless 0.10, 14,351 tactics puzzles, 116 positional exercises, 15 endgame drills and 900 decisive master games directly into the iPhone, iPad and Mac bundle — leaving network calls strictly for optional Game Center matches and the Today feed.',
    tables: [
      {
        id: 'offline-capability-audit',
        heading: 'What actually works in Airplane Mode?',
        caption: 'Feature-by-feature Airplane Mode audit: Brass Pawn vs typical online chess servers',
        headers: ['Activity in Airplane Mode', 'Brass Pawn', 'Typical Online Chess Server App'],
        rows: [
          [
            'Full games vs adjustable engine (1400–full)',
            'Works 100% offline (Stockfish 18 & Reckless 0.10 compiled locally)',
            'Basic offline bots only; cloud/personality bots often unavailable',
          ],
          [
            'Move-by-move plain-English coaching',
            'Works 100% offline with instant win-probability grading',
            'Usually requires server Game Review connection',
          ],
          [
            'Rated tactics & spaced repetition',
            'All 14,351 puzzles, 20 motifs & review schedule work offline',
            'Often empty or restricted to a tiny pre-cached buffer offline',
          ],
          [
            'Positional & endgame drills',
            'All 116 positional tests & 15 Stockfish-defended endgames work offline',
            'Lesson servers typically fail to load without connectivity',
          ],
          [
            'Master game library & takeover',
            'All 900 decisive Watch games searchable & playable offline',
            'Cloud opening explorer and game archives require internet',
          ],
          [
            'Camera / photo board recognition',
            'Works 100% offline via on-device Apple Vision',
            'Cloud diagram scanners fail without internet',
          ],
        ],
      },
      {
        id: 'psychological-focus',
        heading: 'Focus, battery and rating-anxiety differences',
        caption: 'Practical differences between offline training and online server sessions',
        headers: ['Training factor', 'Native Offline Trainer (Brass Pawn)', 'Online Chess Server'],
        rows: [
          [
            'Tunnel / flight disconnects',
            'Zero forfeited games or frozen puzzle spinners',
            '30-second tunnel drop costs rating points by abandonment',
          ],
          [
            'Rating anxiety & tilt',
            'Local training ratings measure progress against yourself quietly',
            'Public blitz ratings tempt revenge-queueing when tired',
          ],
          [
            'Social distractions',
            'Zero chat, zero DMs, zero club feeds, zero ad banners',
            'Chat messages, rematch taunts, badges and streamer banners',
          ],
          [
            'Battery & data usage',
            'Zero background radio polling or ad-video streaming offline',
            'Continuous WebSocket keepalives, telemetry and ad fetches',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'How to split your chess week between offline training and online play',
        caption: 'Recommended split between offline practice in Brass Pawn and online match play',
        headers: ['Moment in your week', 'Best environment', 'Why'],
        rows: [
          [
            'Morning 15-minute tactics & spaced repetition on commute',
            'Offline app (Brass Pawn)',
            'Never stalls between subway stops and reinforces missed motifs.',
          ],
          [
            'Airplane flight or cabin weekend with zero Wi-Fi',
            'Offline app (Brass Pawn)',
            '900 master games to take over, 15 endgames and coached Stockfish 18 games.',
          ],
          [
            'Weekend rested 15+10 rated rapid match or club arena',
            'Online chess server (or Game Center)',
            'Tests your training under real human clock pressure when your connection is stable.',
          ],
          [
            'Late-night tired itch to play chess on the couch',
            'Offline coached game or Guess the Elo (Brass Pawn)',
            'Protects your hard-earned human rating from exhausted blunders.',
          ],
          [
            'Reviewing a physical chess book beside a wooden board',
            'Offline app (Brass Pawn)',
            'Scan positions via Apple Vision offline without opening distracted browser tabs.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why “cached offline” is not the same as “architected offline”',
        paragraphs: [
          'Many server-first apps claim offline mode because they cache twenty puzzles while you had Wi-Fi at home. Open them at 35,000 feet without having pre-warmed the cache, and half the tabs spin or ask you to sign in.',
          'Brass Pawn ships everything inside the App Store binary itself: Stockfish 18, Reckless 0.10, both engines’ neural networks, 14,351 tactics puzzles, 116 quiet positional exercises, 15 verified endgame drills, 1,624 Guess the Elo games and 900 decisive master games. Online connectivity is touched only when you explicitly open Today, Multiplayer over Game Center or App Store purchases.',
        ],
      },
      {
        heading: 'Separating training environments from performance arenas',
        paragraphs: [
          'Musicians do not rehearse scales live on stage, and chess players improve faster when training happens somewhere calm where a missed tactic triggers spaced repetition rather than public Elo loss and chat noise.',
        ],
      },
    ],
    honestTradeoffs: [
      'Offline training cannot replace the psychological pressure and unpredictable resourcefulness of real human opponents — which is why Brass Pawn also includes online Game Center play and pairs well with weekend rapid games.',
      'Bundling two engines, neural networks and 16,000+ positions/games makes the initial app download larger than a bare web bookmark.',
      'Offline progress lives locally on each device rather than syncing to a central cloud profile.',
    ],
    faqs: [
      {
        q: 'Can I launch Brass Pawn for the very first time in Airplane Mode with no account?',
        a: 'Yes. Because there is no sign-up screen and every engine and training dataset ships inside the bundle, Brass Pawn works from minute one with zero internet connection.',
      },
      {
        q: 'Which features in Brass Pawn do require internet access?',
        a: 'Only three: live human multiplayer and leaderboards over Apple Game Center, downloading the latest broadcast stories when you open Today, and App Store purchase/restore checks via StoreKit.',
      },
      {
        q: 'Does offline coaching lose accuracy compared with cloud analysis?',
        a: 'No. Stockfish 18 compiled natively on modern iPhone, iPad or Apple Silicon Mac hardware reaches superhuman search depths in fractions of a second right on your device.',
      },
      {
        q: 'What happens to my offline progress if I delete the app?',
        a: 'Because Brass Pawn has no cloud account and stores training data only in the app’s local container (and your encrypted Apple device backup if enabled), deleting the app deletes your local training history cleanly.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chess-com',
      'brass-pawn-vs-lichess',
      'structured-chess-bot-sparring-vs-blitz-tilt',
    ],
    relatedGuides: [
      { slug: 'offline-chess-app-checklist', title: 'Choosing an offline chess app: what should work without internet?' },
      { slug: 'online-chess-connection-planning', title: 'Online chess connection planning: prepare the device before the clock starts' },
      { slug: 'chess-training-vs-online-play', title: 'Chess training or online play: give each session a job' },
    ],
  },
  {
    slug: 'ad-free-chess-training-vs-diamond-subscriptions',
    tldr:
      'Premium chess subscriptions — from top-tier server memberships to cloud AI coaches and course passes — routinely cost $100 to $200+ every single year, totaling $300 to $600 over three years. Because Brass Pawn runs Stockfish 18 and Reckless 0.10 locally on your iPhone, iPad and Mac with zero cloud GPU bills and zero ad SDKs, playing is $0 forever and Brass Pawn Pro costs either $3.99/month or $39.99 once for life.',
    tables: [
      {
        id: 'three-year-cost-math',
        heading: '1-year and 3-year chess software cost math',
        caption: 'Transparent multi-year cost comparison across chess pricing models (US prices)',
        headers: ['Pricing tier / model', 'Year 1 cost', '3-Year cumulative cost', 'What happens if you stop paying'],
        rows: [
          [
            'Brass Pawn Free',
            '$0',
            '$0',
            'Nothing changes — unlimited coached engine play, Game Center, 900 Watch games + 5/day per drill mode, zero ads',
          ],
          [
            'Brass Pawn Pro (One-off unlock)',
            '$39.99',
            '$39.99',
            'Nothing to stop paying — non-consumable purchase never renews and restores across iPhone, iPad & Mac',
          ],
          [
            'Brass Pawn Pro (Monthly, cancel any time)',
            '$47.88 ($3.99 × 12)',
            '$143.64 (if kept monthly instead of $39.99 unlock)',
            'Reverts cleanly to Free tier; keeps all ratings, history & unlimited coached play',
          ],
          [
            'Premium Online Server Top Tier (e.g. Diamond-class annual/monthly)',
            '~$120–$200/yr',
            '~$360–$600',
            'Ads return and unlimited puzzles / cloud coach / lessons re-lock',
          ],
          [
            'Cloud Neural Bot / XAI Coach SaaS',
            '~$100–$220/yr',
            '~$300–$660',
            'Sparring or explanation credits stop once subscription ends',
          ],
          [
            'Lichess (Open-source server)',
            '$0 (optional Patron)',
            '$0',
            'Always $0 free online server',
          ],
        ],
      },
      {
        id: 'what-you-pay-for',
        heading: 'Where subscription dollars actually go',
        caption: 'Cost-driver comparison between cloud chess platforms and local native apps',
        headers: ['Cost driver', 'Brass Pawn (Local Native)', 'Cloud Subscription Platforms'],
        rows: [
          [
            'Engine compute per game',
            '$0 — runs on the Apple A-series / M-series chip you already bought',
            'Ongoing cloud server CPU/GPU queues billed back via annual tiers',
          ],
          [
            'Advertising SDK overhead',
            'Forbidden by GPLv3/AGPLv3 copyleft engine licences; zero ads ever',
            'Free tiers monetized by ad banners/videos to push paid upgrades',
          ],
          [
            'Paywall placement',
            'Never shown on app launch; appears only after 5 daily attempts in a drill mode',
            'Launch banners, countdown promos, badges and locked review buttons',
          ],
          [
            'Number of paid tiers',
            'One Pro tier ($3.99/mo or $39.99 once) — identical access',
            'Often 3 tiers (Gold / Platinum / Diamond or Basic / Pro / Max) splitting features',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When an annual subscription is worth it vs when one-off wins',
        caption: 'Honest budget guide for chess players',
        headers: ['What you actually use weekly', 'Best value', 'Why'],
        rows: [
          [
            'Daily tactics, coached engine sparring, positional & endgame practice on iPhone, iPad or Mac',
            'Brass Pawn ($0 Free or $39.99 once)',
            'Breaks even against a $10/month subscription in four months and costs $0 forever after.',
          ],
          [
            '5 puzzles + 1 coached game a day on a $0 budget with zero ads',
            'Brass Pawn Free (+ Lichess for large online pools)',
            'Gives 25 total daily drills across 5 modes plus unlimited coached play and zero ads for $0.',
          ],
          [
            'Watching hours of licensed grandmaster video series and playing daily prize arenas on one commercial portal',
            'Premium Server Subscription',
            'Ongoing video production and tournament operations justify a recurring fee if you use them heavily.',
          ],
          [
            'Testing full unlimited training for 30 days before committing to $39.99',
            'Brass Pawn Pro Monthly ($3.99)',
            'One month at $3.99 lets you verify the habit before buying the one-off unlock.',
          ],
          [
            'Gifting or setting up a family iPad without recurring credit-card renewals',
            'Brass Pawn One-off ($39.99) or Free',
            'Zero surprise annual renewals twelve months later.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Metered rather than locked — and why playing is never sold',
        paragraphs: [
          'A chess trainer that locks three of its modes behind a curtain teaches you nothing about whether those modes help you. In Brass Pawn, every mode opens every day on a free account: unlimited Play & Coach, unlimited Game Center play, unlimited Watch (900 decisive games), plus 5 daily attempts each in Tactics, Rush, Positional judgement, Endgames and Guess the Elo (resetting at 9:00 AM local time so a late-evening session is never split at midnight).',
          'Notice also what is missing from Brass Pawn’s pricing page: there is no confusing middle tier that unlocks puzzles while keeping explanations locked. Pro removes the daily counter — $3.99/month while you decide, or $39.99 once when you are sure.',
        ],
      },
      {
        heading: 'Why AGPLv3 guarantees Free stays ad-free',
        paragraphs: [
          'Because Stockfish 18 (GPLv3) and Reckless 0.10 (AGPLv3) are linked directly into Brass Pawn, adding a closed-source advertising SDK would make the binary undistributable. Free users never subsidise the app with their attention or tracking data.',
        ],
      },
    ],
    honestTradeoffs: [
      'Premium server subscriptions bundle large video libraries, opening explorers and global tournament perks that Brass Pawn does not offer.',
      'Lichess provides unlimited online puzzles and games at $0 if you are happy in a browser or server app.',
      'App Store regional taxes and local currency tiers are set by Apple per storefront ($3.99 and $39.99 are US App Store prices).',
    ],
    faqs: [
      {
        q: 'Is there any feature difference between Brass Pawn Pro $3.99/month and the $39.99 one-off unlock?',
        a: 'None at all. Both grant identical Brass Pawn Pro access — removing every daily limit across Tactics, Rush, Positional judgement, Endgames and Guess the Elo, plus playing on from older Today stories. One renews monthly until cancelled; the other is a single non-consumable purchase.',
      },
      {
        q: 'Why does Brass Pawn reset free daily attempts at 9:00 AM instead of midnight?',
        a: 'Resetting at 9:00 AM local device time keeps an evening study session intact rather than cutting your allowance weirdly across midnight.',
      },
      {
        q: 'How do I cancel Brass Pawn Pro monthly if I switch or stop?',
        a: 'Directly in Apple Settings → your name → Subscriptions → Brass Pawn. Because Apple handles StoreKit billing, Brass Pawn never holds your card details and cannot make cancellation difficult.',
      },
      {
        q: 'Will computer play or Game Center multiplayer ever move behind Pro?',
        a: 'No. Unlimited play against the engine and against real opponents is explicitly committed as free in Brass Pawn’s Terms and public pricing.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chess-com',
      'brass-pawn-vs-noctie-ai',
      'brass-pawn-vs-apple-arcade-chess',
    ],
    relatedGuides: [
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
      { slug: 'thirty-minute-chess-routine', title: 'A thirty-minute chess training session that closes the loop' },
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
    ],
  },
  {
    slug: 'private-no-chat-chess-app-for-kids-and-focus',
    tldr:
      'Parents and focused adults searching for a private chess app usually run into two problems: stranger chat messages in multiplayer and hidden ad/analytics trackers in “free” apps. Brass Pawn solves both structurally on iPhone, iPad and Mac — its multiplayer protocol contains no text field at all, the app carries zero ad or analytics SDKs, no Brass Pawn account exists, and Apple Screen Time can restrict Game Center multiplayer completely.',
    tables: [
      {
        id: 'privacy-surface-audit',
        heading: 'Data, chat and tracker audit',
        caption: 'Technical privacy and communication audit: Brass Pawn vs typical social chess apps',
        headers: ['Vector', 'Brass Pawn', 'Typical Social / Ad-Supported Chess App'],
        rows: [
          [
            'In-game chat & DMs',
            'Impossible — wire protocol carries moves, resignations and draw offers only',
            'Live chat, DMs, forums, profile bios and custom avatars (must remember to mute)',
          ],
          [
            'Account registration',
            'None — zero email, phone number, age prompt or password database',
            'Email, Google/Apple SSO or phone account required',
          ],
          [
            'Phone address-book access',
            'Never requested — “Contacts” on the App Store label means in-game Game Center nicknames only',
            'Often prompts to upload device contacts to “find friends”',
          ],
          [
            'Third-party SDKs',
            'Zero analytics, zero ad networks, zero attribution or crash-reporting SDKs',
            'Commonly embeds ad mediation, behavioral analytics and attribution trackers',
          ],
          [
            'Offline training storage',
            'Local app container on your device only; deleted when you delete the app',
            'Synced permanently to cloud user profiles',
          ],
          [
            'Website privacy (brasspawn.com)',
            'Zero cookies, zero analytics, self-hosted fonts, CloudFront/S3 request logs off',
            'Cookie banners, third-party fonts and web tracking pixels',
          ],
        ],
      },
      {
        id: 'network-disclosure',
        heading: 'Every network connection Brass Pawn ever makes',
        caption: 'Complete inventory of network behaviour in Brass Pawn (verified against open-source repo)',
        headers: ['Feature', 'Network destination', 'How to disable or limit'],
        rows: [
          [
            'Tactics, Positional, Endgames, Rush, Guess the Elo, Watch & Engine Play',
            'None — 100% local on device',
            'Always offline by construction',
          ],
          [
            'Online matches & clock leaderboards',
            'Apple Game Center (device-to-device legal move validation)',
            'Sign out of Game Center or disable Multiplayer in Apple Screen Time',
          ],
          [
            '“Who is online” presence & in-game friends',
            'Arte Soft EU (Frankfurt) service using one-way hashed Game Center ID (5-min TTL on presence)',
            'Toggle off Settings → Show when I’m online; remove any friend to delete on both sides',
          ],
          [
            'Today broadcast stories',
            'Static JSON from brasspawn.com/media/feed/v1/ (no cookies, no ID, logging off)',
            'Fetched only when you tap Today; never runs at launch or in background',
          ],
          [
            'Purchases & restores',
            'Apple App Store (StoreKit 2)',
            'Managed by Apple Screen Time purchase restrictions',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'Who benefits most from a zero-chat, zero-account chess app?',
        caption: 'Use-case matrix for Brass Pawn’s privacy and no-chat design',
        headers: ['User group', 'Why Brass Pawn fits', 'Key control to know'],
        rows: [
          [
            'Parents setting up an iPad or iPhone for a child',
            'Zero stranger text chat, zero third-party ads and zero email registration.',
            'Use iOS Screen Time → Content & Privacy → Game Center to allow or block multiplayer.',
          ],
          [
            'Adults who mute chat on every chess site to avoid toxic trash talk',
            'You never have to hunt for a mute toggle — opponents can only play chess moves.',
            'Game Center matches run on 3, 5, 10, 15 or 30-minute clocks with zero engine help.',
          ],
          [
            'Privacy-conscious professionals & open-source users',
            'Every claim in the privacy policy can be verified line-by-line in the AGPLv3 GitHub repo.',
            'Settings → Show when I’m online stops presence pings immediately.',
          ],
          [
            'Schools or families wanting solo offline chess only',
            'Works signed out of Game Center with full Stockfish 18 coaching and 14,351 puzzles.',
            'No login prompt ever blocks offline modes.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'What the App Store privacy label actually means in Brass Pawn',
        paragraphs: [
          'Apple’s standardized App Store privacy nutrition labels use broad bucket names that can look alarming without context. On Brass Pawn’s Privacy page, each of the three declared items (introduced only for online presence and friends) is explained plainly: Contacts means only the Game Center nicknames of friends you add inside Brass Pawn (never your phone’s address book); User ID is a one-way scrambled hash of your Game Center team ID; and Gameplay Content is simply whether you are currently online or in a game, deleted five minutes after you close the app.',
          'None of it is used for tracking or advertising, nothing is sold or shared, and outside online play Brass Pawn collects nothing at all.',
        ],
      },
      {
        heading: 'Source code as the primary privacy document',
        paragraphs: [
          'Most apps ask you to trust a legal PDF. Because Brass Pawn is free software under GNU AGPLv3, `OnlineService.swift`, `MatchProtocol.swift` and `TodayFeed.swift` are public on GitHub for anyone to audit.',
        ],
      },
    ],
    honestTradeoffs: [
      'Players who enjoy post-game text banter, club forums or coaching chat inside their chess app will not find social messaging in Brass Pawn.',
      'Because there is no cloud account, deleting Brass Pawn deletes your local training ratings and puzzle review queue (unless restored from an encrypted Apple device backup).',
      'Online multiplayer requires Apple Game Center on iPhone, iPad or Mac.',
    ],
    faqs: [
      {
        q: 'Does Brass Pawn ever read the contacts on my iPhone or Mac?',
        a: 'Never. Brass Pawn contains no code to request or read your device’s Contacts address book. The App Store “Contacts” category refers solely to the list of in-game friends you choose to add by Game Center nickname.',
      },
      {
        q: 'How can a parent make Brass Pawn 100% offline for a child?',
        a: 'Either keep the device signed out of Game Center or disable Multiplayer under Settings → Screen Time → Content & Privacy Restrictions → Game Center. All coached engine play, 14,351 puzzles, positional drills, endgames and 900 Watch games work offline.',
      },
      {
        q: 'Why can’t an opponent send an abusive message during a Brass Pawn online game?',
        a: 'Because the multiplayer protocol has no text message packet and the UI has no chat box — the only signals exchanged between devices are legal moves, draw offers/responses and resignations.',
      },
      {
        q: 'Does brasspawn.com use cookies or Google Analytics?',
        a: 'No. Even the website sets zero cookies, embeds zero analytics scripts and self-hosts its own fonts so reading a page reveals nothing to third parties.',
      },
    ],
    relatedCompare: [
      'brass-pawn-vs-chesskid',
      'brass-pawn-vs-chess-universe',
      'offline-chess-app-vs-online-chess-servers',
    ],
    relatedGuides: [
      { slug: 'game-center-chess-with-friends', title: 'Playing chess with friends through Game Center' },
      { slug: 'chess-engine-assistance-fair-play', title: 'Chess engine assistance and fair play: separate training from matches' },
      { slug: 'chess-app-without-ads', title: 'A chess app without ads: evaluate the practice experience' },
    ],
  },
  {
    slug: 'native-mac-ipad-chess-app-vs-browser-tabs',
    tldr:
      'Studying chess inside a web browser means sharing screen space with forty open work tabs, cookie banners and WebAssembly engine overhead — and losing your analysis board the moment Wi-Fi drops. Brass Pawn is a native SwiftUI application for Mac, iPad and iPhone (macOS 14+, iPadOS 17+, iOS 17+) running compiled native Stockfish 18 and Reckless 0.10 with instant offline launch and zero browser distractions.',
    tables: [
      {
        id: 'native-vs-wasm',
        heading: 'Native SwiftUI & compiled C++ engines vs browser chess tabs',
        caption: 'Technical comparison between native Brass Pawn (Mac, iPad, iPhone) and browser chess tabs',
        headers: ['Technical factor', 'Brass Pawn (Native Mac / iPad / iPhone)', 'Browser Chess Tabs'],
        rows: [
          [
            'Engine binary',
            'Compiled native ARM64/Apple Silicon C++ Stockfish 18 & Reckless 0.10',
            'WebAssembly (WASM) sandboxed engine or remote cloud server queue',
          ],
          [
            'Cold launch & offline readiness',
            'Opens from Dock or Home Screen in under a second with zero Wi-Fi',
            'Fails or reloads stale service-worker cache when offline',
          ],
          [
            'iPad & Mac layout ergonomics',
            'Native size-class grids, trackpad/mouse pointer precision, touch drag & tap',
            'Mobile Safari address-bar shifts, accidental back-swipe gestures & tab clutter',
          ],
          [
            'Visual environment',
            'Dedicated dark-theatre window with 2D & carved/bronze 3D sets + font picker',
            'Surrounded by Slack, email tabs, bookmark bars and cookie banners',
          ],
          [
            'Camera & system integration',
            'Native Apple Vision board photo scan, StoreKit 2 & Game Center',
            'Manual file uploads and separate web logins per tab',
          ],
          [
            'Privacy & cookies',
            'Zero cookies, zero third-party scripts, local app container storage',
            'Browser localStorage subject to clearing, plus third-party web scripts on commercial sites',
          ],
        ],
      },
      {
        id: 'device-roles',
        heading: 'How Brass Pawn adapts across Mac, iPad and iPhone',
        caption: 'Device-by-device strengths of Brass Pawn across the Apple ecosystem',
        headers: ['Apple device', 'Best Brass Pawn workflows', 'Hardware advantage'],
        rows: [
          [
            'Mac (macOS 14+ / Apple Silicon)',
            'Deep game takeover from Watch/Today, Positional judgement & 15+0 Game Center matches',
            'Fast desktop multi-core Stockfish 18 / Reckless 0.10 search & clean resizable window',
          ],
          [
            'iPad (iPadOS 17+)',
            'Couch master-game study, book diagram photo scanning & side-by-side coaching review',
            'Large square geometry with wider 3-column piece/theme galleries and tactile drag',
          ],
          [
            'iPhone (iOS 17+)',
            'Commute Tactics, timed Rush runs, Guess the Elo & 5-minute Game Center games',
            'Full-width board stage engineered to never lose square size to chrome headers',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to open a native Apple app vs a browser tab',
        caption: 'Decision guide between native Brass Pawn and browser chess tools',
        headers: ['Situation', 'Better choice', 'Why'],
        rows: [
          [
            'Focused 25-minute evening study session on MacBook or iPad with browser closed',
            'Brass Pawn (Native)',
            'Eliminates one-click temptation to wander into social media or email tabs.',
          ],
          [
            'Sharing an annotated URL link with a friend on Windows or Linux',
            'Browser chess tab (e.g. Lichess)',
            'URLs open across any OS with zero install.',
          ],
          [
            'Solving tactics and playing coached Stockfish 18 on an iPad during a flight',
            'Brass Pawn (Native)',
            '100% bundled offline without relying on fragile Safari WASM caches.',
          ],
          [
            'Using a borrowed library computer or Chromebook',
            'Browser chess tab',
            'Requires no App Store installation.',
          ],
          [
            'Switching between Stockfish 18 and Reckless 0.10 locally without COOP/COEP browser quirks',
            'Brass Pawn (Native)',
            'Native binaries run directly without SharedArrayBuffer cross-origin restrictions.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why native geometry and zero browser chrome matter on iPad and iPhone',
        paragraphs: [
          'In mobile Safari, dynamic toolbars, pull-to-refresh gestures and back-swipes constantly fight an 8x8 drag-and-drop chessboard. Brass Pawn’s SwiftUI `BoardStage` sizes the board directly from the window’s full width and lifts navigation out of the way while a game or drill is active, preserving every millimetre of square legibility.',
        ],
      },
      {
        heading: 'One Apple Account across iPhone, iPad and Mac',
        paragraphs: [
          'Installing Brass Pawn from the App Store covers your iPhone, iPad and Mac together. Playing is free on all three, and if you buy Brass Pawn Pro ($3.99/mo or $39.99 once) on one device, StoreKit 2 restores it automatically on the others.',
        ],
      },
    ],
    honestTradeoffs: [
      'Browser chess sites work on Windows, Linux, Android and Chromebooks and let you share positions via instant URLs.',
      'Brass Pawn stores training ratings locally on each device rather than syncing a single cloud profile across browsers.',
      'Note that Brass Pawn’s daily Today stories on brasspawn.com can also open directly into the native app or App Clip at the exact move you reached.',
    ],
    faqs: [
      {
        q: 'Is Brass Pawn on Mac a real native app or a web wrapper?',
        a: 'It is a native Swift and SwiftUI application (`macOS 14.0` or later) with Stockfish 18 and Reckless 0.10 compiled natively in C++ and linked directly into the binary.',
      },
      {
        q: 'Do brasspawn.com Today links open directly in the native app?',
        a: 'Yes. On iPhone and iPad, Today story pages carry an App Clip / universal app argument so tapping opens Brass Pawn directly on that game and move.',
      },
      {
        q: 'Does Brass Pawn drain battery like heavy 3D browser tabs?',
        a: 'No. Offline 2D play and native ARM64 Stockfish searches finish in milliseconds with zero background ad scripts or WebSocket polling, and reduced-motion preferences are respected.',
      },
      {
        q: 'What are the minimum OS versions for Brass Pawn?',
        a: 'iOS 17.0, iPadOS 17.0 or macOS 14.0 or later.',
      },
    ],
    relatedCompare: [
      'offline-chess-app-vs-online-chess-servers',
      'brass-pawn-vs-hiarcs-chess-explorer',
      'brass-pawn-vs-smallfish-stockfish-ios',
    ],
    relatedGuides: [
      { slug: 'ipad-chess-practice-routine', title: 'Chess practice on iPad: use the space to explain a position' },
      { slug: 'mac-chess-analysis-workflow', title: 'Chess analysis on Mac: organise one question at a time' },
      { slug: 'choose-iphone-chess-app', title: 'How to choose an iPhone chess app for your actual goal' },
    ],
  },
  {
    slug: 'structured-chess-bot-sparring-vs-blitz-tilt',
    tldr:
      'Playing twenty consecutive 3+0 online blitz games without reviewing a single mistake reinforces impulsive habits and triggers rating tilt. Structured sparring in Brass Pawn — playing a Stockfish 18 game calibrated to your strength with live win-probability coaching, followed by spaced-repetition tactics and endgame conversion — turns twenty minutes into deliberate feedback that actually fixes recurring blunders.',
    tables: [
      {
        id: 'feedback-loop-comparison',
        heading: 'Deliberate coached sparring vs unreviewed 3+0 blitz queues',
        caption: 'Learning-loop comparison between coached sparring in Brass Pawn and online blitz queues',
        headers: ['Learning mechanism', 'Brass Pawn Coached Sparring + Drills', 'Unreviewed 3+0 Online Blitz Queue'],
        rows: [
          [
            'When feedback arrives',
            'Immediately after each move while you still remember what you calculated',
            'Never (if you hit “New 3 min”), or minutes later when memory of the plan has faded',
          ],
          [
            'How mistakes are measured',
            'Win-probability drop + plain-English note naming the changed board feature',
            'Binary win/loss on the clock (flagging a lost position still feels like a “win”)',
          ],
          [
            'Testing “what if I played X instead?”',
            'Take back the move or toggle move values to test the alternative immediately',
            'Impossible mid-game; rarely checked afterward during a blitz streak',
          ],
          [
            'Follow-up on missed tactical motifs',
            'Spaced repetition resurfaces missed puzzles at 1, 4 and 10+ days across 20 motifs',
            'Same fork or back-rank pattern missed again three games later',
          ],
          [
            'Emotional state after 30 minutes',
            'Calm stopping point with accuracy, blunder count & costliest moment identified',
            'Chasing 45 lost rating points at midnight (“just one win before bed”)',
          ],
        ],
      },
      {
        id: 'thirty-minute-session',
        heading: 'Two ways to spend 30 minutes on chess',
        caption: 'Side-by-side breakdown of a 30-minute session in Brass Pawn vs blitz tilt',
        headers: ['Minute block', 'Structured Brass Pawn Routine ($0 Free tier)', 'Typical Blitz Tilt Session'],
        rows: [
          [
            'Minutes 0–8',
            '5 Tactics puzzles (with spaced-repetition misses) — untimed calculation check',
            'Blitz games 1 & 2 — won one on time from a lost rook ending, hung a knight in game 2',
          ],
          [
            'Minutes 8–14',
            '2–3 Positional judgement positions or 2 Endgame drills vs Stockfish defence',
            'Blitz games 3 & 4 — premoved into an opening trap, hit instant rematch',
          ],
          [
            'Minutes 14–28',
            '1 coached game vs Stockfish 18 at your target strength, reading each costly verdict',
            'Blitz games 5–8 — playing faster and shallower as frustration climbs',
          ],
          [
            'Minutes 28–30',
            'Replay the single costliest moment highlighted at game end, then close app cleanly',
            'Close tab annoyed with zero idea which positional mistake started the slide',
          ],
        ],
      },
      {
        id: 'decision-matrix',
        heading: 'When to spar with the coach vs when to play humans on a clock',
        caption: 'Balanced training schedule combining coached engine sparring and human clock games',
        headers: ['Training objective', 'Right mode', 'Why'],
        rows: [
          [
            'Eliminating one-move blunders and learning why quiet moves fail or work',
            'Brass Pawn Play & Coach',
            'Immediate win-probability feedback catches bad habits at the exact moment of decision.',
          ],
          [
            'Practising practical clock management and nerves against an unassisted human',
            '10 or 15-min Game Center match (or online rapid)',
            'Real human clocks have zero take-backs and zero hints, testing what stuck.',
          ],
          [
            'Converting won rook or king-and-pawn endings cleanly instead of flagging',
            'Brass Pawn Endgames (15 drills)',
            'Stockfish 18 defends accurately and names the exact move a win slipped to a draw.',
          ],
          [
            'Playing chess when tired after work without wrecking your rated rapid Elo',
            'Brass Pawn Play & Coach or Watch takeover',
            'Zero public rating anxiety and unlimited free games offline.',
          ],
          [
            'Sharpening fast tactical pattern speed under a timer without elo tilt',
            'Brass Pawn Rush',
            'Trains fast pattern recognition against a clock with personal high scores.',
          ],
        ],
      },
    ],
    sections: [
      {
        heading: 'Why immediate feedback beats post-mortem procrastination',
        paragraphs: [
          'Every chess player knows they should analyse their rapid games afterward, and almost nobody analyses their seventh consecutive blitz loss. By the time a game ends, you have forgotten which candidate moves you rejected on move 16. Brass Pawn’s Play & Coach grades your move while the position is still warm in your head — using win probability so it speaks up on real turning points and stays quiet on harmless centipawn noise.',
          'At the end of every coached game, Brass Pawn hands you three numbers that matter: accuracy, blunder count, and the single moment that cost you most.',
        ],
      },
      {
        heading: 'Keep human games sacred by separating practice from matches',
        paragraphs: [
          'Brass Pawn includes both sides of that boundary in one app — and never mixes them. In Play & Coach, Stockfish 18 grades every move and offers two-step hints. In Online (Game Center on 3, 5, 10, 15 or 30-minute clocks), there is no engine anywhere near the board: no hints, no move values, no take-backs and no chat.',
        ],
      },
    ],
    honestTradeoffs: [
      'Engine sparring alone never teaches clock management or handling messy human blunders — play unassisted 10+0 or 15+0 human games weekly alongside training.',
      'Leaving move values or take-backs turned on in every practice game can become a crutch; turn them off regularly to simulate real calculation.',
      'Brass Pawn explicitly promises zero guaranteed rating gains — improvement comes from consistent deliberate work.',
    ],
    faqs: [
      {
        q: 'Is coached engine sparring free in Brass Pawn?',
        a: 'Yes. Play & Coach against Stockfish 18 (from ~1400 to full strength) or Reckless 0.10 is 100% free and unlimited forever.',
      },
      {
        q: 'Can I turn off hints or move values so I don’t rely on them during practice?',
        a: 'Yes. Move values are an optional toggle, and hints only appear when you press Hint (first highlighting pieces, then showing the arrow on a second tap).',
      },
      {
        q: 'Does Brass Pawn let me play real humans when I am ready for a clock?',
        a: 'Yes — Online mode pairs you over Apple Game Center on 3, 5, 10, 15 or 30-minute clocks with all engine help disabled and zero chat.',
      },
      {
        q: 'Will five free training drills per mode per day actually fit a 30-minute routine?',
        a: 'Yes. Five Tactics puzzles, five Positional exercises and five Endgame drills already total 15 focused exercises before you even play a free coached game — and Pro ($3.99/mo or $39.99 once) removes all limits whenever you want longer sessions.',
      },
    ],
    relatedCompare: [
      'offline-chess-app-vs-online-chess-servers',
      'brass-pawn-vs-noctie-ai',
      'brass-pawn-vs-chess-com',
    ],
    relatedGuides: [
      { slug: 'blitz-vs-rapid-for-improvement', title: 'Blitz or rapid chess: choose a clock for the skill you want' },
      { slug: 'deliberate-chess-practice', title: 'Deliberate chess practice: turn one mistake into a test' },
      { slug: 'thirty-minute-chess-routine', title: 'A thirty-minute chess training session that closes the loop' },
    ],
  },
];
