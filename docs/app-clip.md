# The App Clip

Six tactics and a button, in the ten seconds somebody will give a link in a
message. This is what it is, why it is not more than that, and what was found
out the hard way.

## What it does

Somebody in the app taps **Invite somebody** on the multiplayer screen and gets
a link. Whoever receives it — in Messages, WhatsApp, mail, anywhere — opens it
and the clip appears: their name at the top, "so-and-so invited you to a game",
and a real position on the real board. They solve one. Then another. After the
third, the App Store card comes up on its own; a button to it is on screen from
the first second regardless. If they install, the app finds the invitation
waiting for them and offers to put them straight through to whoever sent it.

## Why there is no engine in it

The clip's budget is **100 MB** uncompressed on iOS 17 and later. That sounds
generous until you weigh what the app carries:

| | |
|---|---|
| `nn-c288c895ea92.nnue` (Stockfish's smallest bundled network) | 103.9 MB |
| Reckless, per architecture | 141 MB |

The single smallest thing that would make an engine work is already over the
whole allowance. So: no analysis, no move values, no coach, no opponent. What
the clip carries is the board, six positions, the piece art and the string
catalogue — about 18 MB in a debug build, less when thinned.

The 100 MB figure applies when all three of these hold, and they do here:
the clip's deployment target is iOS 17, the parent app's is iOS 17, and the
build is made with a recent Xcode. Older clips were held to 50 MB, and an
earlier note in this project said 50; that was wrong.

## Why Game Center is not in it

The clip began as a spike with one question: does Game Center treat an App Clip
as the same game as the app it belongs to?

The answer is **no**. GameKit is not on the forbidden-framework list, the clip's
App ID had the Game Center capability enabled, and the full app signs in
perfectly on the same simulator with the same account — and the clip is still
refused with *"this application is not recognised"*. There is no Multiplayer
Compatibility section for App Clips in App Store Connect either, because a clip
has no app record of its own; it shares its parent's.

So an invitation cannot be *played* from inside a clip. It is carried across
instead, which turns out to be no worse: the clip writes the invitation into the
App Group, and the app reads it after the install.

## How two people find each other

Game Center will not hand you a named opponent. `GKMatchmaker` pairs whoever is
waiting in the same `playerGroup`, and the ordinary groups here are the five
clocks (`4003`…`4030`) — joining one of those finds a stranger.

An invitation therefore derives a group of its own from the inviter's Game
Center player ID and the chosen clock, by FNV-1a into `100_000 + n`. Both
devices compute the same number from the same link without talking to each other
first, and nobody else lands in it. Two people, one pool.

`Hasher` would not do: Swift seeds it per process, so the two devices would
compute different numbers for the same invitation.

## The pieces

| | |
|---|---|
| App Group | `group.com.arte-soft.brasspawn` |
| Clip bundle | `com.arte-soft.brasspawn.Clip` |
| Link | `https://appclip.apple.com/id?p=<clip bundle>&i=<invitation>` |
| Invitation | `Sources/ChessTraining/Invitation.swift` — JSON, URL-safe base64, unpadded |
| Handoff | `SharedContainer` in the same file; written by the clip, read once by the app |
| Puzzles | `data/clip-tactics.json` — six, chosen and ordered, 2 KB |

`appclip.apple.com` rather than a domain of ours: it needs no site, no
association file and no hosting, and it works the moment the clip is approved.

`BoardUI` exists because of this. The 2D board used to live in the same module
as the engine plumbing — not because it needed an engine, but because it shared
an address with one. It is now its own module over `ChessCore` and
`ChessTraining`, which is what lets the clip draw a position at all.

## Testing it

`simctl` has no notion of an App Clip invocation, and `simctl openurl` with an
`appclip.apple.com` link does nothing. Xcode passes the invocation URL in the
`_XCAppClipURL` environment variable, so from the command line:

```bash
SIMCTL_CHILD__XCAppClipURL="https://appclip.apple.com/id?p=com.arte-soft.brasspawn.Clip&i=..." xcrun simctl launch <udid> com.arte-soft.brasspawn.Clip
```

`ClipModel.acceptLaunchArgument()` reads it, which is the only way to arrive at
an invitation on a simulator. On a device the value is absent and the user
activity does the work.
