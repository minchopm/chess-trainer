# Brass Pawn for iOS

A native iOS build of the trainer: SwiftUI, with two chess engines compiled into
the app and running in-process. No network, no account, no server — everything is
on the device.

The player picks the engine in Settings. **Stockfish 18** is the default and the
only one that can play at a rating — the whole opponent ladder is built on its
`UCI_Elo`. **Reckless** is the alternative: a different opponent with different
taste, at full strength only, because it has no strength limiter to offer. See
"Two engines" below.

## Building

```bash
sh ios/scripts/fetch-networks.sh     # once — downloads ~107 MB of Stockfish networks
sh ios/scripts/build-reckless.sh     # once — 63 MB network + three cargo builds
open ios/BrassPawn.xcodeproj
```

`build-reckless.sh` is not optional: `Package.swift` has a binary target pointing
at the xcframework it produces, so nothing builds until it has run. It needs a
Rust toolchain of 1.85 or newer (the crate is edition 2024) with the
`aarch64-apple-ios` and `aarch64-apple-ios-sim` targets installed. It also builds
an `aarch64-apple-darwin` slice, which is what lets `swift test` exercise the
engine on the host.

The Xcode project is committed, so XcodeGen is not required to open or build the
app. Then pick a simulator or your own device and run.

`project.yml` remains the source of truth for project structure. After changing
it, regenerate and commit the updated project:

```bash
brew install xcodegen                # once
cd ios && xcodegen generate
```

From the command line:

```bash
cd ios
xcodebuild -project BrassPawn.xcodeproj -scheme BrassPawn \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Layout

```
Package.swift              Swift package: all the logic, testable from the CLI
Sources/
  ChessCore/               rules of chess — no I/O, proven by perft
  ChessEngine/             Engine protocol + one actor per engine
  ChessTraining/           features, grading, rating, spaced repetition, selection
  BrassPawnApp/            SwiftUI views and view models
  sfprobe/                 CLI driver for diagnosing engine problems
Vendor/Stockfish/          upstream engine (GPLv3, unmodified) + a C bridge
Vendor/Reckless/           the other engine (AGPLv3) + a Rust C bridge
Resources/
  Data/                    puzzles, positional exercises, endgame drills, games
  Networks/                NNUE files (not committed — see scripts/fetch-networks.sh)
App/                       the @main entry point
BrassPawn.xcodeproj/       Xcode project — open this directly
project.yml                XcodeGen spec used to regenerate the project
Tools/IconMaker/           draws the app icon
```

## Purchases

Two products, both optional; nothing about playing chess is behind them.

| Product | Type | Price |
| --- | --- | --- |
| `com.artesoft.brasspawn.pro.monthly` | auto-renewable subscription, group `brasspawn.pro` | $3.99 / month |
| `com.artesoft.brasspawn.pro.lifetime` | non-consumable | $49.99 once |

`Sources/ChessTraining/Entitlement.swift` holds the free allowance — what it
covers and how much of it a day carries — and is covered by tests, because it is
the part that decides whether somebody can use the app.
`Sources/BrassPawnApp/SubscriptionStore.swift` is StoreKit 2: entitlement
check, purchase, restore, manage, and a listener for renewals and purchases made
on another device.

App Store Connect is the source of truth for product metadata and localized
prices. The Xcode scheme does not use a local StoreKit configuration. Sign in
with a Sandbox Apple Account on a development device or simulator when testing
purchases; StoreKit fetches the products above by their exact identifiers.

Both products must remain configured in App Store Connect, and the app needs
the Terms of Use and Privacy Policy URLs filled in there as well as in the
paywall.

## Localization

Thirty-one locales, all complete. Nothing in `App/Localizable.xcstrings` is
hand-edited — it is built from `Localization/keys.json` (the English source) plus
one file per language:

```bash
python3 ios/scripts/build-catalog.py
```

The script prints how many of the 576 keys each language has, so a partial
translation is visible rather than silent. Adding a string means adding it to
`keys.json` and to whichever languages you can; the rest fall back to English.

Two things are deliberate. The board is pinned to left-to-right even in Arabic
and Hebrew, where the rest of the interface mirrors correctly — a1 is at the
bottom left of every board in the world. And the coach's sentences are whole
strings with numbered arguments rather than English fragments glued together,
because word order is not a detail other languages agree with us about.

## Online play

The Online mode uses Game Center. To run it on your own build:

1. Enable the **Game Center** capability for the App ID in the Apple Developer
   portal (Certificates, IDs & Profiles → Identifiers).
2. Build to two devices signed into two different Apple IDs. Game Center cannot
   be signed into on a simulator, so a real match cannot be tested there.

Debug builds carry a **Local test game** button in the online lobby. It wires a
second session to the first inside the same process and plays random legal
replies, which is how the clocks, the player rows and the result overlay can be
exercised without two devices. It is compiled out of release builds.

The match logic itself is covered by tests rather than by the network: the
sessions talk through a `MatchTransport`, and the suite hands one session's
packets straight to another to play whole games — moves, clock, resignation,
draw offers, a peer sending an illegal move — with no Game Center involved.

## The free board

Play → Board is the one screen with no opponent decided in advance. You bring a
position to it — pasted as a FEN, a PGN, bare moves (`1.e4 e5`) or UCI
(`e2e4 e7e5`) — and then push the pieces around. `ChessCore/GameImport.swift`
reads all four; comments, move numbers, NAGs, results and parenthesised
variations are skipped, and a line that breaks part way gives back the moves
before the break together with the token that stopped it, because twenty-nine
moves with a reason beat nothing without one.

Two rules are worth knowing because neither is guessable:

**Either side can change hands at any time.** White and Black each have a seat —
You, Stockfish or Reckless — and switching one mid-game hands that colour over
immediately. The engines are named rather than lumped together as "Engine",
because which one is playing is the interesting part of this screen: the two
disagreed on four of six test positions. Put a different one on each side and
they play each other. Both on You is an analysis board. There is no ladder here:
this screen is for looking at positions, and a deliberately weakened answer is
the wrong tool for that even when the engine can give one.

Both engines can therefore be alive at once. The one that is not the player's
chosen engine is built on demand by `AppModel.engine(for:)` and gets a quarter
of the hash — two full-sized tables is a quarter of a gigabyte on a phone — and
is released when the screen closes, because a Stockfish kept alive is its
hundred megabytes of networks kept in memory.

**A search whose board has changed is stopped, not waited out.** Handing a seat
over mid-search used to leave the abandoned search running its whole budget —
two and a half seconds, ten at the ceiling — while `isThinking` held the next
one off, so several quick changes queued behind each other and the board looked
frozen. `BoardModel` keeps the engine it is driving and calls `stop()` on it for
changes a person made; the tests measure the difference at 2.5 s against 0.13 s.
Not for the engine's own move, though: the loop plays one and starts the next
search straight away, and a stop arriving late would cut short the wrong one.

**Set up** opens the position editor, seeded with whatever is on the board. It
keeps a loose map of squares to pieces rather than a `Position`, because
half-built boards are the normal case there — two white kings while you move
one, no black king at all for the first ten taps — and `Position` refuses to
hold any of that. It hands over only when the board is a position, and until
then it says in a sentence what is wrong: no king, kings touching, a pawn on the
back rank, or the side not to move already in check. "Not a position" in front
of thirty-two pieces is not something anybody can act on.

The editor is also the correction step anything automatic will need. A position
read off a photograph is right about most squares and wrong about a few, and
there has to be somewhere to fix the few.

**Stepping back stops the engines.** An engine only owes a move at the live end
of the line. Step back to look at something and everything pauses, because a
board that moves while you are reading it is useless. Play a move from there and
the line branches — what came after is dropped, since keeping both would mean a
move tree, which is a different feature.

## The games you played

Every finished game is kept — from Play always, from the free board when it
reaches a real end, because that board spends most of its life holding
positions somebody is poking at and filing every poke would bury the games
worth having. They live in SwiftData (`ChessTraining/GameHistory.swift`),
separate from `progress.json`, which is read and rewritten whole on every
change and is no place for a couple of hundred games of notation.

Nothing is trimmed. A game is a few hundred bytes, so ten thousand of them is a
couple of megabytes — cheaper than deciding on somebody's behalf which of their
own games they are finished with.

Three details are deliberate:

- **The moves are stored as SAN, space-separated** — the form `GameImport`
  reads. A saved game comes back through the same parser as a pasted one: one
  reader, one set of bugs, and a database legible by eye.
- **Your own side is stored as an empty name**, not as the word "You". The word
  is translated, and a history written while the app happened to be in one
  language would read wrong in another ever after.
- **The id is a String**, so watch marks and favourites work on your games
  through the same machinery the classics use.

Watch has a clock switch beside the search that shows them instead of the
library — a switch rather than a fourth segment, for the same reason the
favourites switch is one.

**Play on from here** is the point of keeping them. Anywhere a game is being
watched — a classic or one of yours — the viewer offers to hand the position to
the free board, along with the moves that led to it, and you carry on from
there against a person or either engine.

It is deliberately not a takeback. The game is *reloaded* onto the board as one
line and continues; the moves after the point you picked never happened. A
takeback that could be undone would need a tree of variations, and a thousand
half-explored branches of the same game is not a feature, it is a mess. The
hand-over travels through `Navigator.boardHandoff` because the board is a mode
inside a tab rather than a destination, and it is cleared on being taken, so
returning to Board a week later does not silently reload a game you had moved
on from.

## Reading a board from a photograph

Board → Photo. Take or choose a picture, tap the board's four corners, and what
comes out opens in the position editor to be corrected. The corners, the
straightening and the cutting are here; the classifier that says what is
standing on each square is not written yet, and `UnreadBoard` stands in for it
by honestly recognising nothing.

### Why the corners are tapped rather than found

Every published pipeline finds the board by looking for lines, and that is the
step that breaks. Measured on ChessReD — 10,800 real smartphone photographs —
**chesscog locates the board in 34.38% of them**, and every error afterwards is
downstream of the miss: 2.3% of boards come out with no mistakes at all, 42.87
squares wrong per board on average. On its own synthetic dataset the same
system gets 93.86% of boards perfect. It is not a weak system; it is a system
outside its distribution.

Four handles cost a moment and take that failure to nothing. What is left is a
homography (`CIPerspectiveCorrection`, no model, no licence) and per-square
classification.

**Vision proposes where it can, which on a chessboard is rarely.** The handles
start wherever `BoardDetector` finds a quadrilateral worth offering, and fall
back to a neutral inset when it does not. The honest summary of trying it: a
generic rectangle detector does not find a chessboard. Measured on a rendered
board in perspective, it returned a patch of the internal grid covering under
three per cent of the picture, three hundred pixels from the real corners — a
chessboard is a quadrilateral containing sixty-four smaller ones, and nothing in
Vision knows which one matters. Asked for a page instead, document segmentation
returns the photograph's own frame.

So the proposals are filtered hard: not the frame, at least a quarter of the
picture, convex, and with opposite sides within three times each other. What
survives is worth offering; what does not leaves the handles where they were. A
wrong proposal is worse than none — four handles in the wrong place all have to
be dragged, where four set neutrally are at least obviously a starting point.
Whether it earns its keep on real photographs of real boards, which have a
border and a shadow and a table around them, is still unmeasured.

They are dragged rather than tapped, and that took a second attempt. Tapping
asks somebody to hit a point their own fingertip is covering, in a picture
shrunk to fit the screen — and where the board runs to the edge of the frame,
the corner cannot be hit at all. Four handles are placed for you and dragged
into place, with the quadrilateral drawn so its shape can be judged as a whole
and a loupe parked in the far corner showing what is under the finger. It is how
every document scanner does it, for the same reasons.

### Why we will train our own classifier

The state of the art on real photographs is the ResNeXt end-to-end model of
Masouris and van Gemert (VISAPP 2024): 15.26% of boards perfect, 3.40 squares
wrong per board, 5.31% per square. We cannot use it. **Its repository carries
no licence at all** — checked through the GitHub API, not the README — which
means all rights reserved, and **ChessReD is CC BY-NC-SA 4.0**, which a paid app
cannot touch.

What is clean:

| | licence | data | usable |
|---|---|---|---|
| chesscog | MIT | CC-BY 4.0 (OSF, checked via API) | yes |
| neural-chessboard | MIT | — | yes |
| chessboard2fen | MIT | — | yes |
| LiveChess2FEN | AGPL-3.0 | — | yes, as we already ship AGPL |
| end-to-end-chess-recognition | **none** | CC BY-NC-SA | **no** |
| ChessReD dataset | **CC BY-NC-SA** | — | **no** |

So the plan is a small per-square classifier of our own, trained on
CC-BY material — real photographs from Roboflow Universe plus chesscog's
renders — and exported to Core ML. A per-square model at that size is a few
megabytes, not tens.

### Why the editor is mandatory

Even the best published reader gets three or four squares wrong on an average
board. Correction is therefore the feature and not a safety net, and the
photograph hands its result to the editor every time — including when it
recognised nothing, which is what happens today.

That last case is why the hand-over carries a map of pieces rather than a
`Position`: a board with no kings on it is not a position, `Position(fen:)`
refuses to parse one, and an earlier draft quietly fell back to the opening
array — a photograph of an empty room would have produced a full chessboard.

## Store pictures and previews

Screenshots and app previews are taken by a script, in every language, without
a single tap. A launch argument opens the app straight into a named scene:

```bash
xcrun simctl launch <udid> com.arte-soft.brasspawn -shot playMistake \
  -AppleLanguages "(de-DE)"
xcrun simctl io <udid> screenshot shot.png
```

`ScreenshotScene` (debug builds only) lists what can be asked for. Tapping was
tried first and is the wrong tool: a longer translation moves the buttons, so
the taps that work in English miss in German. A launch argument cannot be set by
another app or by a link, and none of this compiles into a Release build.

The position in each scene is the same in every language — only the words
change, which is what a set of store pictures wants. Two locale pairs are shot
once and copied, because their catalogues are byte-identical: the two Englishes
and the two Frenches. That is 29 captures filling 31 folders.

Previews are recorded the same way, with `simctl io recordVideo`, from a `demo`
scene that plays the app against a clock. Nothing is masked or resized here —
the raw frame goes to the tooling that composes the device shot.

Two things learned by looking at what came out, both now fixed and worth not
repeating: the coach's second sentence was assembled from English fragments
with only the clause translated, so an Arabic reader got Arabic inside English;
and chess notation dropped into a right-to-left sentence was reordered by the
bidirectional algorithm until it was no longer a variation.

## Testing

```bash
swift test --package-path ios -c release
```

The suite is worth knowing about because two parts of it are not the usual
"does it compile" reassurance:

- **Perft.** The move generator is checked against the six standard positions,
  9.6 million nodes deep. Castling rights lost to a rook capture, en passant
  that exposes the king along a rank, under-promotion — a generator that gets
  any of them wrong matches at depth 1 and diverges by depth 3.
- **Engine integration.** Real searches against the real networks, for both
  engines, including a terminal position. That last one matters and differently
  for each: Stockfish reports a position with no legal moves through a different
  callback, and an unset callback ends the process with no diagnostic, while
  Reckless reports one as a line with no moves in it.
- **Move value coverage.** That each engine returns a value for *every* legal
  move at wide MultiPV, in a quiet position and in a forced mate. The board draws
  a number per move and gets them from one search, so an engine that reports
  fewer lines than it was asked for is a visible defect rather than a subtle one.
- **The free board's two rules.** That a move played from the middle of a line
  drops what came after it, and that an engine owes no move once you have
  stepped back off the end. Both are invisible in the types — nothing stops
  `BoardModel` appending to a line it is not showing the end of — so they are
  held by tests rather than by the compiler.
- **The photograph's orientation.** Core Image counts y upwards and a tap counts
  it downwards. Getting that wrong produces a board upside down rather than an
  error, which is the kind of mistake that survives a review — so a picture with
  a white patch in one corner is straightened by its own corners and the patch
  has to still be there. Remove the flip and four of the five checks fail.

## Two engines

`Sources/ChessEngine/Engine.swift` is the protocol both satisfy;
`AppModel.engine` holds one of them and `AppModel.chooseEngine` swaps it. Only
one is alive at a time — each holds a network and a thread pool, and a phone can
usefully run one search.

Two things are worth knowing before changing any of it.

**Reckless cannot limit its strength.** Its whole option list is Hash, Threads,
MoveOverhead, Minimal, Clear Hash, UCI_Chess960, MultiPV and SyzygyPath. There is
no `UCI_LimitStrength` and no `UCI_Elo`, so the opponent ladder — Casual 1400
through Master 2700 — is Stockfish's and stays Stockfish's. Choosing Reckless
takes the ladder down to one rung, "Full strength", and Play says so.

The alternative was to fake it by capping depth or nodes. It was not taken, and
should not be: a depth-capped engine is not a weaker human. It plays a
positionally excellent game and then hangs a rook — superhuman in the parts that
need judgement, blind in the parts that need calculation — so "Casual (1400)"
would describe neither its strength nor its character. `EngineCapabilities`
exists so the app can ask rather than assume, and
`Tests/BrassPawnAppTests/OpponentLadderTests.swift` holds the rule.

**Reckless does cover every legal move.** The board labels each move with a
number, from one wide MultiPV search, so an engine that reports only the lines it
liked would leave dots where numbers were promised.
`Tests/ChessEngineTests/RecklessCoverageTests.swift` asks the same two questions
`ValueCoverageTests` asks of Stockfish — a quiet middlegame and a forced mate,
which is the case that matters, because the search proves the mate and stops —
and Reckless answers all of them. It matched Stockfish exactly at 40, 20, 40 and
24 moves across four positions.

## Notes on embedding Reckless

The engine is Rust, and the bridge in `Vendor/Reckless/src/ffi.rs` is the whole
of the fork: one new file, one `pub mod ffi;` in `src/lib.rs`, and `staticlib`
added to `crate-type` in `Cargo.toml`. Nothing else in the engine is touched, so
moving to a newer upstream is a re-apply of three small things. Four notes:

1. **`rk_global_init` has to be idempotent, and upstream's is not.**
   `lookup::initialize` builds a cuckoo table by insertion, evicting whatever
   occupies a slot and re-inserting it. On an empty table it terminates when an
   eviction yields the empty entry; on a full one it never does, and the loop
   spins forever. Upstream never notices because `run()` calls it once. The
   bridge guards it with a `Once` — without that, calling it twice hangs on a
   spinning thread with no diagnostic at all.
2. **A terminal position is reported, not omitted.** Reckless prints
   `info depth 0 score mate 0` with no variation after it. That is not a line,
   and `RecklessEngine` drops it, because `Analysis.isTerminal` is how every
   screen tells checkmate from a search that has not answered yet. Stockfish
   reaches the same place by reporting these through a callback the bridge
   ignores.
3. **There is no combined depth-and-time limit.** Reckless's `Limits` is one
   enum, so it cannot say "this deep, but no longer than this" — which is the
   pair `SearchBudget` carries everywhere. `rk_go` gets it by running a
   depth-limited search alongside a thread that stops it at the deadline, with a
   generation counter so a deadline that wakes late cannot cut short the *next*
   search.
4. **The release profile is `panic = "abort"`.** A panic anywhere in the engine
   ends the app rather than raising an error. The bridge validates what it can —
   an unparseable FEN is refused rather than silently replaced with the starting
   position, which is what the engine's own wasm binding does.

Both engines assume the position they are given is legal. Neither survives one
that is not: an illegal FEN — kings on adjacent squares, say — aborts Stockfish
with `SIGBUS` and Reckless with `SIGABRT`. Nothing in the app can reach that,
because every FEN handed to an engine comes from a `ChessCore.Position`, which
refuses to parse such a thing in the first place. It is worth knowing before
adding a call site that takes a FEN from anywhere else.

## Notes on embedding Stockfish

Three things cost time, and all three fail silently:

1. **`Engine::go` verifies the networks.** It compares the loaded file against
   the `EvalFile` option and calls `exit()` on a mismatch. Load networks by
   setting the option, not by calling `load_big_network` directly — the option's
   own callback does the loading and keeps the two in agreement.
2. **All five listeners must be set.** Stockfish calls them unconditionally, and
   an unset `std::function` throws from the search thread.
3. **Networks are found by size, not name.** The file names are pinned to the
   engine version and change with every release.

## Publishing

The app is GPLv3, because Stockfish is, and it carries an AGPLv3 obligation as
well, because Reckless is. Neither is a formality:

- [x] Publish the complete source publicly, including `Vendor/Stockfish`,
      `Vendor/Reckless` and both bridges — github.com/minchopm/chess-trainer is
      public and GPL-3.0. The `LICENSE` and `NOTICE.md` files at the repository
      root cover the obligations.
- [x] **Reckless is AGPLv3.** The two licences combine — GPLv3 §13 gives
      permission to link a GPLv3 work with an AGPLv3 one, and says the AGPL's own
      §13 then applies to the combination. That section binds anyone who lets
      users interact with the program *remotely over a network* to offer them the
      source. This app does not: both engines run on the device and it makes no
      network requests, so the clause adds nothing here. It travels with the
      source regardless, and anyone who puts this behind a network service is
      bound by it. The full Affero text ships in the app — About → Read the
      Affero licence — beside the GPL, and `NOTICE.md` records the three-file
      fork.
- [x] Licence text and attribution reachable from inside the app — Progress →
      About & licence, which carries the full GPL, the third-party notices and a
      link to the source.
- [x] Signing configured: team `8293TNMX6S` (ARTE SOFT EOOD), bundle identifier
      `com.arte-soft.brasspawn`, automatic signing. A device build produces a
      signed app.
- [x] `AboutScreen.sourceURL` points at https://github.com/minchopm/chess-trainer
      — under GPL that link is an obligation, not a courtesy, so it has to stay
      public and current.
- [x] `App/PrivacyInfo.xcprivacy` ships in the bundle. It declares no tracking,
      no collected data and — deliberately — no accessed API types: the app
      calls none of the ones that need a reason. No `UserDefaults` (the progress
      is a JSON file), no file timestamps (`attributesOfItem` is used once, for
      a network file's size), no disk space, no boot time. An inaccurate
      declaration would be worse than none, so if a future change reaches for
      one of those, its reason belongs in there.
- [ ] Add screenshots and a privacy label in App Store Connect. The label is
      "Data Not Collected": there is no server of ours, no analytics and no
      advertising, and the only thing that crosses a network is an online game,
      which goes device to device through Game Center. Apple collects that;
      we never see it. See `docs/app-privacy.md` for the questionnaire answered
      one screen at a time.
- [ ] Create the two products in App Store Connect with exactly these
      identifiers: `com.artesoft.brasspawn.pro.monthly` and
      `com.artesoft.brasspawn.pro.lifetime`. They do not match the bundle id
      (`com.arte-soft.brasspawn`, with the hyphen) and do not need to — but the
      strings in `SubscriptionStore.ProductID` are what the app asks StoreKit
      for, and anything else there means an empty paywall in production.
- [x] `ITSAppUsesNonExemptEncryption` is set to `false`, which is accurate: the
      app uses no encryption.
- [x] The permission prompts are translated. iOS reads them from Info.plist
      rather than from the app's catalogue, so they need their own —
      `Localization/infoplist.json` feeds `App/InfoPlist.xcstrings` through the
      same script. Left alone, the camera prompt would have been English in all
      twenty-nine languages, and it is the first sentence a good many people
      would read.

### Size

Two engines means two networks, and the second one is not small. Measured from an
unsigned Release build for a device:

| | Installed `.app` | Executable |
| --- | --- | --- |
| Stockfish only | 128 MiB | 8.2 MB |
| Both engines | 190 MiB | 73.3 MB |

The whole difference is Reckless: 60.3 MiB of network and 463 KB of code. Its
network is compiled into the binary as a `static` rather than shipped as a
resource, which is why the executable rather than the bundle is where it lands —
`__TEXT,__const` goes from 161 KB to 64.4 MB. Being in `__TEXT` it is read-only
and page-mapped from the binary, so it is clean memory: it costs nothing until a
search reads it and can be evicted under pressure. The Stockfish networks, loaded
from files into the heap, cannot.

**This is the number to watch.** Apple's over-the-air limit is 200 MB, and at
190 MiB the app is inside it with very little room. The App Store figure is the
compressed download rather than this one, and NNUE files compress poorly, so the
margin is real but thin. Anything else added to the bundle should be measured
against it, and if Reckless's network grows in a future version this stops
fitting.
