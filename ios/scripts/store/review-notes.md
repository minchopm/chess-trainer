# App Review notes

What to paste into **App Store Connect → App Review Information → Notes**, and
into a reply on the Resolution Center thread. Apple asked for it on the 1.1 macOS
submission (Guideline 2.1 — Information Needed, 23 Sep 2026) and asked that it be
kept in the Notes field for later submissions, so it lives here rather than in
one message.

Everything below is checkable against this repository, which is public: the app
is AGPLv3 and its complete source is what Apple is reviewing.

---

## 1. Demo account

**Not applicable — the app has no accounts.** There is no registration, no
sign-in, no profile and no password, so there is nothing to delete either. All
progress is kept in the app's own container on the device.

Multiplayer uses **Apple's Game Center**. Signing in to Game Center on the Mac is
the only sign-in anywhere in the app, and it is Apple's own, with Apple's own
account. Every other mode works signed out.

## 2. What the app is, and who it is for

Brass Pawn is an **offline chess trainer**. It plays, it grades what you played,
and it tells you why the better move was better.

The problem it solves: a beginner who plays online gets a result and no
explanation, and an engine analysis that says "-2.3" is not an explanation
either. This app puts a coach on every move — it names the mistake, says what it
cost and shows the move that was there — and then drills the pattern behind it.

Who it is for: **players from complete beginner to club strength** (roughly
600–2000). The opponent ladder is built on Stockfish's UCI_Elo, so the engine can
be asked to play at the user's own strength rather than at full strength.

What is in it:

- **Play** — a game against the engine at a chosen rating, with coaching after
  every move, take-backs and hints.
- **Multiplayer** — a real opponent over Game Center, on a clock.
- **Board** — a free board, two engines, paste a position or read one off a
  photograph of a real board.
- **Tactics** and **Rush** — puzzles, spaced by a review schedule.
- **Positional** and **Endgames** — drills.
- **Guess the Elo** — watch a real game and judge the players' strength.
- **Watch** — a library of famous games.
- **Progress** — ratings per activity, streaks, history.

## 3. How to reach every feature

No credentials, no sample files, no setup. Open the app and everything is one
click from the main menu.

- The **training modes are free five attempts a day each**, with no purchase and
  no account, which is enough to see every screen and every paid feature working.
- The **paywall** is reached from the card icon in the top-right corner of the
  main menu, or by using up a day's free attempts in any training mode. It offers a monthly subscription and
  a one-off lifetime unlock. Playing — against the engine and against a person —
  is free and unlimited, and always will be; what is sold is the training.
- **Multiplayer** needs Game Center signed in on the Mac, and a second player. If
  no opponent is found, that is matchmaking having nobody to match with, not an
  error.
- The **photograph** feature is Play → Board → **Photo**. It reads a position off
  a picture of a real board, on the device. On a Mac without a camera, it offers
  the photo library instead.

## 4. External services, tools and platforms

**None of ours. The app has no server, and makes no network requests of its own
— there is not one `URLSession` in the source.**

What it does use:

| | |
|---|---|
| **GameKit (Apple)** | Game Center, for finding an opponent and carrying moves between the two devices in Multiplayer. Nothing passes through any server of ours. |
| **StoreKit 2 (Apple)** | The subscription and the lifetime unlock. Payment is entirely Apple's; the app only asks whether a purchase is active. |
| **Vision (Apple)** | Reading a board off a photograph. On-device, offline. |

No analytics, no advertising, no attribution SDK, no crash reporter, no
third-party SDK of any kind. No AI service: the chess strength is two
conventional chess engines compiled into the app and running on the device, and
the coaching text is written from their output by code in this repository.

Everything the app knows ships inside it: the puzzle library, the drills, the
recorded games and both engines' neural networks are bundled resources.

## 5. Regional differences

**None.** The app behaves identically in every storefront: same features, same
content, same prices structure, no geo-gating and no region-specific content.

It is localised into **32 languages** (`ios/App/Localizable.xcstrings`); the only
difference between regions is which one is displayed.

## 6. Regulated industries and third-party material

**Not a regulated industry.** No gambling, no wagering, no real-money play, no
financial, medical or legal content. Chess is the whole of it.

Third-party material, all of it either open-source or public domain, and all
credited in `NOTICE.md` in the repository and in the app under About → Licences:

- **Stockfish** (GPLv3) — bundled unchanged, plus a C interface written for this
  project. https://github.com/official-stockfish/Stockfish
- **Reckless** (AGPLv3) — a second engine, bundled with the same kind of C
  interface. https://github.com/codedeliveryservice/Reckless
- **Lichess puzzle and game databases** (CC0 1.0, public domain) — the tactics
  puzzles and the games behind Guess the Elo. https://database.lichess.org/
  Usernames are stripped; the modes use the ratings, not the people.
- **Cormorant Garamond** and **JetBrains Mono** (SIL Open Font License 1.1) —
  the typefaces, with their licences shipped beside them in the bundle.

Because Stockfish is GPLv3 and Reckless AGPLv3 and both are linked in, **the
whole application is licensed under AGPLv3**, and its complete corresponding
source is published at https://github.com/minchopm/chess-trainer. The app links
to it from About.

## 7. Privacy

The app collects nothing: no analytics, no advertising, no tracking, no account,
no server. Ratings, solved puzzles, review schedule and purchase state stay in
the app's container. Policy: `PRIVACY.md` in the repository.

## 8. Content and moderation

There is **no user-generated content and no messaging**. The Multiplayer wire
protocol carries a move, a resignation, a draw offer, a draw response and a
result — `ios/Sources/ChessTraining/MatchProtocol.swift` is the whole of it.
There is no field a person can type into, so there is nothing to report, block or
moderate. Opponents are identified by their Game Center nickname, which Apple
supplies and Apple's own controls cover.

---

# The screen recording

Apple asks for one "captured on a physical device, running the latest operating
system", beginning with launching the app. For a macOS submission that is this
Mac, recorded with ⇧⌘5 or QuickTime → File → New Screen Recording. Record the
app window, not the whole desktop.

The build in the recording should be the one submitted — a Release build of the
same version — not a debug build, and Game Center should be signed in before the
tape rolls so no sign-in sheet interrupts it.

Five or six minutes is plenty. In this order, because it answers their list in
the order they asked it:

1. **Launch.** Start recording on the desktop with the app closed, then open it.
   Let the title board turn for a few seconds; it is the first thing a customer
   sees.
2. **Play a game.** Menu → Play. Choose a strength, start, make three or four
   moves, and let a coached verdict appear. Take one move back. Press Hint twice
   so both rungs show — the ringed pieces, then the arrow.
3. **Show there is no account.** Open Settings from the main menu and scroll the
   whole way down. There is no account section, no sign-in and no profile, which
   is the answer to their first question, and it is more convincing shown than
   written.
4. **Paid features.** Open a training mode — Tactics is the clearest — and solve
   a puzzle. Then open the card icon in the top-right of the main menu to show
   the paywall, its two products and their prices. If a sandbox account is
   signed in, buy the monthly subscription on camera and show the modes
   unlocked. If not, say in the reply that the five-a-day free tier lets the
   reviewer see every paid screen without buying.
5. **Multiplayer.** Menu → Play → Multiplayer. Show the lobby and the clock
   choice. If a second device is at hand, show a game connecting; if not, let the
   search run for a few seconds and move on — it is matchmaking with nobody to
   match, not a failure.
6. **No user-generated content.** While the multiplayer board is up, show that
   the only controls are Resign and Offer draw: nowhere to type, nothing to
   moderate.
7. **About.** Settings → About, showing the licences and the link to the source.

Do not cut between steps. A single unbroken take is what they asked for, and a
cut is a thing they have to wonder about.
