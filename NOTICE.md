# Third-party components

## Stockfish

This project includes Stockfish, a UCI chess engine.

- Copyright (C) 2004-2026 The Stockfish developers (see `ios/Vendor/Stockfish/AUTHORS`)
- Licensed under the **GNU General Public License version 3** — see `LICENSE`
- Upstream: https://github.com/official-stockfish/Stockfish
- Version bundled: see `ios/Vendor/Stockfish/VERSION.txt`
- Modifications: none. The engine source is vendored unchanged. The only added
  file is `ios/Vendor/Stockfish/bridge/`, a C interface over its public `Engine`
  class, written for this project and licensed under GPLv3 along with the rest.

Because Stockfish is GPLv3 and is linked into the application, **this entire
application is licensed under GPLv3**. The complete corresponding source is at
the repository this file ships with.

### Neural networks

The two NNUE evaluation files are produced by the Stockfish project and
distributed under the same licence. They are not committed to this repository;
`ios/scripts/fetch-networks.sh` downloads the exact versions the bundled engine
expects.

## Lichess databases

Most of the bundled tactics puzzles come from the Lichess puzzle database, and
the games behind Guess the Elo come from the Lichess game archives. Both are
released into the public domain under **CC0 1.0**.

- Source: https://database.lichess.org/
- No attribution is required by the licence; it is given here because it is
  deserved.
- The games keep the players' Lichess usernames out of the bundled file: the
  mode needs the ratings, not the people.

## GameKit

Online play uses Apple's Game Center. No game data leaves the two devices
playing: there is no server of ours in the middle, and nothing is collected.

## chess.js

Used only by the web version's build tooling, not by the iOS app.

- Copyright (c) Jeff Hlywa
- BSD 2-Clause licence
