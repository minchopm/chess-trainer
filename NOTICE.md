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

## Reckless

This project includes Reckless, a second UCI chess engine, which the player can
choose in Settings instead of Stockfish.

- Copyright (C) the Reckless developers
- Licensed under the **GNU Affero General Public License version 3** — see
  `AGPL` (in the app: About → Read the Affero licence)
- Upstream: https://github.com/codedeliveryservice/Reckless
- Commit vendored: `789de8912672360030d2dae2263292fd37575ae3`
- Modifications: the engine source is vendored otherwise unchanged. Three
  changes, all under `ios/Vendor/Reckless`:
  - `src/ffi.rs` — a new file, a C interface over the engine, written for this
    project. It exists because the crate exports nothing usable: every module in
    `src/lib.rs` is private, so no separate crate can reach the search.
  - `src/lib.rs` — one `pub mod ffi;`, declaring that file.
  - `Cargo.toml` — `staticlib` added to `crate-type`, so it can be linked into
    an application.
  Those additions are licensed under AGPLv3 along with the engine.

### Neural network

Reckless's NNUE evaluation file is produced by the Reckless project and
distributed under the same licence. It is compiled into the engine rather than
loaded at runtime, and is not committed to this repository;
`ios/scripts/build-reckless.sh` downloads the exact version the engine expects.

### What the AGPL means here

The GPL and the AGPL can be combined: **GPLv3 section 13** gives permission to
link a GPLv3 work with an AGPLv3 work, and says the AGPL's own section 13 then
applies to the combination.

That section requires anyone who lets users interact with the program *remotely
over a network* to offer those users its source. Brass Pawn does not: both
engines run on the device, and nobody interacts with a copy of this software
running somewhere else. Online play is two copies talking to each other through
Game Center, each one running on the phone of the person using it, which is not
what that clause is about — there is no instance of the program that a user
reaches across a network without having it. So the clause adds nothing in practice here
— but it travels with the application, and anyone who takes this source and puts
it behind a network service is bound by it.

Independently of that, the complete corresponding source is published, which is
what both licences require of a distributed application.

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

## Typefaces

Both are licensed under the SIL Open Font License 1.1, whose terms travel with
the files: `Resources/Fonts/OFL-cormorant.txt` and `OFL-jetbrains.txt` ship in
the app beside the fonts themselves.

- **Cormorant Garamond** — the display and body face. Copyright 2015 the
  Cormorant Project Authors, https://github.com/CatharsisFonts/Cormorant
- **JetBrains Mono** — the figures and anything set as data. Copyright 2020 the
  JetBrains Mono Project Authors, https://github.com/JetBrains/JetBrainsMono

Neither font is sold on its own or renamed, which is all the OFL asks of an
application that merely embeds them.

## The pieces and the board

Drawn for this app. The 3D pieces are built from measured coordinates in
`Sources/BoardScene`, not imported from a model: the reference model consulted
while shaping the knight is CC-BY-NC, which a paid app cannot use, so nothing of
it is in the binary.
