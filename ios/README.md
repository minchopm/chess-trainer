# Chess Trainer for iOS

A native iOS build of the trainer: SwiftUI, with Stockfish 18 compiled into the
app and running in-process. No network, no account, no server — everything is on
the device.

## Building

```bash
brew install xcodegen                # once
sh ios/scripts/fetch-networks.sh     # once — downloads ~107 MB of networks
cd ios && xcodegen generate
open ChessTrainer.xcodeproj
```

Then pick a simulator or your own device and run.

From the command line:

```bash
cd ios
xcodebuild -project ChessTrainer.xcodeproj -scheme ChessTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Layout

```
Package.swift              Swift package: all the logic, testable from the CLI
Sources/
  ChessCore/               rules of chess — no I/O, proven by perft
  ChessEngine/             Swift wrapper over Stockfish
  ChessTraining/           features, grading, rating, spaced repetition, selection
  ChessTrainerApp/         SwiftUI views and view models
  sfprobe/                 CLI driver for diagnosing engine problems
Vendor/Stockfish/          upstream engine (GPLv3, unmodified) + a C bridge
Resources/
  Data/                    puzzles, positional exercises, endgame drills, games
  Networks/                NNUE files (not committed — see scripts/fetch-networks.sh)
App/                       the @main entry point
project.yml                XcodeGen spec — the .xcodeproj is generated, not edited
Tools/IconMaker/           draws the app icon
```

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
- **Engine integration.** Real searches against the real networks, including a
  terminal position. That last one matters: Stockfish reports a position with no
  legal moves through a different callback, and an unset callback ends the
  process with no diagnostic.

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

The app is GPLv3, because Stockfish is. That is not a formality:

- [ ] Publish the complete source publicly, including `Vendor/Stockfish` and the
      bridge. The `LICENSE` and `NOTICE.md` files at the repository root cover
      the obligations.
- [x] Licence text and attribution reachable from inside the app — Progress →
      About & licence, which carries the full GPL, the third-party notices and a
      link to the source.
- [x] Signing configured: team `8293TNMX6S` (ARTE SOFT EOOD), bundle identifier
      `com.arte-soft.chesstrainer`, automatic signing. A device build produces a
      signed app.
- [x] `AboutScreen.sourceURL` points at https://github.com/minchopm/chess-trainer
      — under GPL that link is an obligation, not a courtesy, so it has to stay
      public and current.
- [ ] Add screenshots and a privacy label. The app collects nothing and makes no
      network requests, so the label is "Data Not Collected".
- [ ] `ITSAppUsesNonExemptEncryption` is already set to `false`, which is
      accurate: the app uses no encryption.

The app is roughly 116 MB, almost all of it the large neural network. Apple's
over-the-air limit is 200 MB, so it downloads over cellular without a warning.
