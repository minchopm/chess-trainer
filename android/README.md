# Brass Pawn for Android

The Android build of the trainer: Kotlin and Jetpack Compose, with Stockfish 18
compiled into the app from the same vendored sources and the same C bridge the
iOS app uses. Package `com.artesoft.brasspawn`.

Nothing here is a copy of something that already lives elsewhere in the
repository. The puzzle libraries come from `/data`; the photographed pieces,
board wood, brass icons, sounds, fonts, licence texts and engine networks come
from `ios/Resources`; and every string comes from the iOS string catalog
(`ios/App/Localizable.xcstrings`), key for key, in all of its languages. The
build gathers them (`gatherAssets` in `app/build.gradle.kts`,
`tools/strings.py`). Strings that exist only on Android are in
`localization/<language>.json`.

## Layout

| | |
|---|---|
| `core/` | Plain Kotlin, no Android: the rules of chess (`chess`), the online match state machine, clocks and Glicko (`match`), and the training logic — grading, features, selection, progress (`training`). Ported from `ios/Sources/ChessCore` and `ios/Sources/ChessTraining`, with their tests. |
| `app/src/main/cpp/` | CMake build of `ios/Vendor/Stockfish` plus a JNI layer over `sfbridge.h`. |
| `app/…/engine/` | The engine behind the same interface as on iOS, and the coach. |
| `app/…/online/` | Online play: device-key identity, the service client, the model. |
| `app/…/ui/` | The screens. |
| `tools/` | `remote.sh` (build, run and screenshot on another Mac), `strings.py`, `icons.py`. |

## Building

Requires JDK 17, Android SDK 37, NDK 27.1.12297006, CMake 3.22.1 and Python 3.
The engine networks must be present (`sh ios/scripts/fetch-networks.sh`, once).

```sh
cd android
./gradlew :core:test -PcoreOnly     # rules, match and training tests; no Android SDK needed
./gradlew :app:assembleDebug
```

`-Pabis=arm64-v8a,x86_64` adds the x86_64 slice. The Stockfish networks are
copied out of the APK on first launch, because the engine reads them from files.

### On another Mac

`tools/remote.sh` mirrors what the build needs to a second Mac over ssh, builds
there, and drives the app on an emulator of its own (`BrassPawn_API_36`,
`emulator-5580`), so the machine being edited on does none of the heavy work:

```sh
tools/remote.sh build && tools/remote.sh emulator && tools/remote.sh install
tools/remote.sh launch --es screen play      # debug builds can start on a screen
tools/remote.sh ui                           # labelled nodes and their centres
tools/remote.sh tap "START GAME"
tools/remote.sh shot play                    # → android/shots/play.png
```

## Online play

Android has no Game Center. Online play — on both platforms — goes through the
project's game service: it pairs players by clock, relays the same
`MatchPacket`s the iOS app has always exchanged, referees the game on its own
board, and keeps the ratings, rank lists, friends and invitation codes. The
wire protocol is `SharedExtensions/go/transport/chessplay/PROTOCOL.md` in the
Cloud Rush repository, which is where the server lives.

- **Identity.** An ECDSA P-256 key made in the Android Keystore on first use;
  signing in is signing a fresh timestamp. The player chooses a nickname.
  Nothing else about the person or the device is sent.
- **Transport.** Plain JSON over HTTP with one long poll for events. Release
  builds talk HTTP/3 to the service through Cronet (the origin is QUIC-only);
  debug builds talk clear-text HTTP to a development server on the machine
  running the emulator (`http://10.0.2.2:8787`, override with
  `-PonlineBaseUrl=…`).
- **Invitations.** A six-character code and a link,
  `https://brasspawn.com/play?i=CODE`, which the app opens.

## Not here yet

Watch, Guess the Elo, Rush, the daily feed, the board scanner, the
three-dimensional board, the second engine (Reckless) and purchases.
