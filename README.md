# Chess Trainer

A local chess training system. Real board, real rules, Stockfish 18 as the coach.
Four modes — tactics, positional judgement, endgame technique, and coached play —
with an Elo-style rating and spaced repetition so the work compounds instead of
resetting every session.

Everything runs on your machine. No account, no network calls, no telemetry.
Progress lives in your browser's `localStorage`.

```bash
npm install
npm start          # → http://localhost:5173
```

The bundled set is already generated and verified — **14,351 tactics puzzles**
(evenly spread from 760 to 2899), 116 positional exercises, and 14 endgame
drills. The app works immediately, offline.

---

## What is in here

### Tactics
Positions with exactly one winning move. Play it on the board and you get an
immediate verdict; miss it and the puzzle comes back tomorrow. Every puzzle is
tagged (fork, pin, back-rank mate, quiet move, …) and rated, so the trainer can
tell you which motifs you keep missing.

### Positional judgement
The mode built for the thing that separates strong players from good calculators.
No forced win exists. First you assess the position — clearly better, slightly
better, balanced — then you choose a move. Both answers are graded, and the
feedback names the concrete features: open files, rooks on them, knight outposts,
pawn structure, king safety, piece activity.

### Endgames
Canonical positions played out against Stockfish. You must actually achieve the
result — the engine defends properly, so knowing the idea is not the same as
converting it. After every move the trainer checks whether the result is still
reachable, and tells you the exact move where it stopped being.

### Play & coach
A full game at a strength you choose (1400 to full strength). Each of your moves
is graded as you play, and the coach explains what the better move would have
achieved. At the end you get accuracy, blunder count, and your costliest moment.

### Progress
Ratings per discipline, day streak, weakest motifs, and a ladder from beginner to
grandmaster range. Note that **puzzle ratings run several hundred points above
over-the-board ratings** — they measure progress against yourself, not FIDE
strength.

---

## Where the puzzles come from

Puzzles are **mined, not transcribed**. Transcribing positions from memory risks
shipping puzzles whose "solution" is wrong or not unique, which trains the wrong
instinct. Instead:

1. Stockfish plays itself at deliberately human-like strength (1320–2500 Elo),
   opening with a random pick among its top few shallow choices for variety.
2. Every position is screened at depth 12 with two candidate lines. The signal is
   not "somebody blundered" but the property a puzzle actually needs: *one move is
   far better than every alternative*.
3. Survivors are re-searched at depth 20 with MultiPV. A candidate is kept only if
   the best move beats the runner-up by ≥ 140 cp and actually achieves something.
4. The solution is extended move by move for as long as every one of the solver's
   moves stays uniquely best, so the puzzle has no branches.
5. Motifs are detected from the resulting line, and a rating is estimated from
   solution depth, whether the key move is quiet, whether material is sacrificed,
   and how wide the margin over the second-best move is.

`scripts/verify-puzzles.mjs` then re-checks the whole set at a higher depth with a
fresh engine, and independently confirms that every hand-written endgame drill has
the result its label claims. A mislabelled drill fails the check rather than
quietly teaching you something false.

It also checks something `chess.js` will not tell you: whether the side *not* to
move is in check. Such a position is illegal — no game can reach it — but the
library accepts it, and Stockfish answers with `bestmove (none)`, which reads like
an engine failure rather than a bad position. Three of the hand-written drills
were wrong in exactly this way; the check now catches it.

### Regenerating and extending

```bash
npm run generate -- --games 200 --workers 8    # more tactics (appends, deduplicated)
npm run generate:positions -- --games 60       # more positional exercises
npm run verify                                 # re-check everything
npm run verify -- --fix                        # …and drop anything unsound
```

Both generators append to the existing file and deduplicate, and both write after
every game — a run that dies at game 180 keeps everything it found.

Generation is CPU-bound and parallel. On eight workers, 190 games takes about 32
minutes and yields roughly 170 tactics puzzles; 45 games yields about 115
positional exercises. Verification is single-engine at roughly 6 seconds per
puzzle. On the bundled set it rejected 6 of 172 puzzles whose solutions stopped
being unique two plies deeper — those were dropped.

### Lichess database (imported)

Most of the bundled tactics come from the Lichess puzzle database (CC0): 14,185
puzzles carrying **human-calibrated ratings** derived from millions of real
solving attempts, plus Lichess' theme vocabulary. The remaining 166 are the
locally mined set.

The database itself is not committed — it is a 290 MB download. To refresh or
re-slice it:

```bash
curl -O https://database.lichess.org/lichess_db_puzzle.csv.zst
npm run import-lichess -- --file lichess_db_puzzle.csv.zst
```

Requires `zstd` on PATH for compressed input. The import scans all ~6.1 million
rows in about a minute.

**Sampling is per rating band, not first-N.** Most Lichess puzzles sit between
1200 and 1800, so taking the first N rows leaves the top of the ladder nearly
empty — exactly the part that matters once you are strong. The importer keeps up
to `--per-band` puzzles per 100-point band using reservoir sampling with a seeded
PRNG, so the spread is even and the same seed reproduces the same slice:

```bash
npm run import-lichess -- --file lichess_db_puzzle.csv.zst \
  --per-band 700 --band 100 --min-rating 800 --max-rating 2800 \
  --min-plays 100 --themes fork,pin,skewer   # optional theme filter
```

It also normalises Lichess' format: their FEN sits one ply *before* the puzzle
starts, with the opponent's blunder as the first listed move. The importer
replays that ply so the stored position has the solver to move, and validates
every move in the line before keeping the puzzle.

### Whole games, for Guess the Elo

The iOS app has a mode that plays a real game out move by move and asks you to
judge how strong the players were. It needs games rather than positions, so
there is a second importer:

```bash
curl -O https://database.lichess.org/standard/lichess_db_standard_rated_2014-07.pgn.zst
npm run import-games -- --files lichess_db_standard_rated_2014-07.pgn.zst
```

It samples per rating band, like the puzzle importer and for the same reason,
and it applies filters the mode depends on:

- **Both players within 150 points of each other.** A guess about "the players"
  only means something when there is one level to guess. A 1500 being taken
  apart by a 1900 produces a game that belongs to neither rating.
- **Blitz and classical only.** Bullet moves are a product of the clock as much
  as of the player, which is exactly the thing being judged.
- **18 to 70 moves.** Shorter is not a game, longer is not a film.
- **Every move replayed and validated**, so the app never has to defend itself
  against a line that stops halfway.

The bundled slice is 1,624 games from 800 to 2,599, taken from the January 2013
and July 2014 archives. Usernames are not kept — the mode needs the ratings.

### Checking an imported set

Full verification of 14,000 puzzles would take over a day, so imports get a
sampled check instead:

```bash
npm run spotcheck                                    # 40 puzzles across the range
npm run spotcheck -- --sample 60 --depth 20 --source lichess
```

It takes an evenly spaced sample by rating and asks whether the engine agrees
that the recorded first move is best. A systematic import bug — most obviously
getting the one-ply offset wrong — shows up as near-total disagreement, which
forty samples catch as reliably as a full pass. On the bundled set: 40/40 at
depth 18.

Occasional disagreements are expected and cluster on long, quiet, highly rated
puzzles whose point lies deeper than the check searches; they are a limit of the
check, not a fault in the data.

---

## The iOS app

There is a native iOS version in `ios/` — SwiftUI, with Stockfish compiled in and
running on the device. It shares this project's puzzle data and mining pipeline
but none of its code; the rules engine, coaching layer and training logic are
reimplemented in Swift and covered by their own tests, including a perft suite
that proves the move generator correct.

### Languages

The iOS app is translated into 31 locales: Arabic, Czech, Danish, German, Greek,
English (US and Canada), Spanish, Finnish, French (France and Canada), Hebrew,
Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Malay, Dutch,
Norwegian, Polish, Portuguese (Brazil), Romanian, Russian, Swedish, Thai,
Turkish, Vietnamese, and Chinese in both scripts.

The catalogue is generated rather than edited by hand:

```bash
python3 ios/scripts/build-catalog.py     # Localization/*.json → App/Localizable.xcstrings
```

`ios/Localization/keys.json` holds the English source for all 385 strings, one
file per language holds that language, and the script assembles the String
Catalog. A key with no translation falls back to English rather than showing the
key, so a half-finished language is merely half-English.

The chess vocabulary is the part worth being careful about, because it is the
part a player notices being wrong. A fork is a *horquilla* in Spanish, a
*fourchette* in French, 捉双 — "catching two" — in Chinese and 両取り in Japanese;
a skewer is an *enfilada*, a *шампур*, a 串擊. Translating those from the English
word rather than from the position they name is how a chess app ends up sounding
machine-made.

### Online

Two players over Game Center, on a clock: 3, 5, 10, 15 or 30 minutes each,
paired only with somebody who chose the same one. It is the one mode with no
engine in it — no hint, no move values, no coaching — because help that only
one side gets is not a game. The board faces your colour, the two rows carry
each player's Game Center name, rating, clock and captures, and the online
rating is kept apart from the training ratings: it measures you against people
rather than against a library.

There is no server. The two devices talk to each other through Game Center, and
both run the rules — a move is played only if it is legal in the position the
receiving device already has, so a peer that lies produces a dropped packet
rather than an illegal board. That also means the rating is honest rather than
tamper-proof: a modified build could lie to it.

It also takes moves before your turn: while the engine thinks you can queue a
short plan — take, recapture, castle — and it plays out move by move as the
board allows, or is dropped whole the moment the engine makes its first step
impossible.

It also has two modes the web version does not: **Rush**, a timed run against
the clock, and **Guess the Elo**, which plays a real rated game out move by move
and asks you to say how strong the players were. The second is not a quiz for
its own sake — reading a game's level is the same skill as judging your own
moves, since both come down to noticing which mistakes are being made and which
are not.

See [ios/README.md](ios/README.md) to build it.

---

## Layout

```
server.mjs                  static server
data/
  tactics.json              the set the app uses: Lichess + mined, merged
  tactics-lichess.json      the imported Lichess slice on its own
  tactics-mined.json        the locally mined set on its own
  positions.json            quiet positions for judgement training
  endgames.json             hand-written drills, engine-verified labels
  games.json                whole rated games for the iOS Guess the Elo mode
scripts/
  generate-puzzles.mjs      the tactics miner
  generate-positions.mjs    the quiet-position miner
  verify-puzzles.mjs        independent soundness check (every puzzle)
  spotcheck-puzzles.mjs     sampled check, for sets too large to verify fully
  import-lichess.mjs        optional Lichess puzzle importer
  import-games.mjs          optional Lichess game importer (Guess the Elo)
  engine-node.mjs           Stockfish wrapper for Node
  themes.mjs                motif detection and rating estimation
public/js/
  board.js                  interactive board (drag & drop, legality, arrows)
  engine.js                 Stockfish worker wrapper (UCI, MultiPV, strength limit)
  features.js               positional feature extraction and move description
  coach.js                  move grading and explanation
  store.js                  ratings, spaced repetition, statistics
  modes/                    the five modes
```

## Notes on the engine

The bundled build is Stockfish 18 **lite, single-threaded** (~7 MB). Single-threaded
means no `SharedArrayBuffer`, which means the app works without cross-origin
isolation headers. It is still far stronger than any human. To swap in the
multi-threaded or full build, copy the other files out of
`node_modules/stockfish/bin/` into `public/vendor/` and change `ENGINE_URL` in
`public/js/engine.js`; the server already sends the COOP/COEP headers those builds
need.

Move grading uses **win probability**, not raw centipawns. Losing 100 cp when you
are already up a queen barely matters; losing it in a level position is decisive.
Centipawns cannot tell those apart, and a trainer that says "blunder" when nothing
happened stops being worth listening to.

## Honest limitations

- **The set mixes two rating scales.** The 14,185 Lichess puzzles carry ratings
  calibrated against millions of human attempts. The 166 locally mined ones carry
  estimates derived from solution depth and motif. Both order sensibly, but a
  mined 1600 and a Lichess 1600 are not measured the same way. The mined set is
  kept separately in `data/tactics-mined.json` if you want only one of them.
- **Only the mined puzzles are individually verified.** Each was checked twice
  against the engine. The Lichess puzzles rely on Lichess' own upstream
  validation plus this project's move-legality check and a sampled engine check.
- **The browser engine is the lite build.** It is far stronger than any human, but
  it is not the strongest Stockfish. Analysis at the depths used here is
  nonetheless reliable.
- **No opening training.** Deliberately: opening study is memorisation against a
  repertoire you choose, which is a different tool. The positional mode covers the
  transition out of the opening.
- **This will not make you a grandmaster.** Nothing will, on its own. Titles come
  from thousands of hours plus rated tournament play against humans. What this
  gives you is the training half of that, structured, with an honest measure of
  where you actually are.

## Keyboard

- `f` — flip the board
- `n` — next puzzle / position / drill

## Licence

Copyright © 2026 Mincho Milev.

This program is free software: you can redistribute it and/or modify it under the
terms of the **GNU General Public License, version 3 or later**, as published by
the Free Software Foundation. See [LICENSE](LICENSE) for the full text.

It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

The licence is GPLv3 because the app links Stockfish, which is GPLv3 — a work
that includes it must carry the same terms. See [NOTICE.md](NOTICE.md) for the
third-party components and their licences.
