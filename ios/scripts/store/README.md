# Store assets

Screenshots and previews for the App Store, in every language the app ships
in. Nothing here is tapped: the app is opened straight into a named scene by a
launch argument, so the only thing that changes between languages is the words.

    SIMULATOR_UDID=... sh ios/scripts/store/capture.sh      # 217 screenshots
    SIMULATOR_UDID=... sh ios/scripts/store/record-all.sh   # 93 previews

Both write to `build/store`, or wherever `STORE_OUT` points. Both skip work
already done, so a run that went wrong in one language can be repeated without
shooting the other twenty-eight.

`SIMULATOR_UDID` defaults to whichever simulator is booted. The scripts need
a debug build: the scenes they drive do not exist in a release one.

## Why the app is held

A preview cannot be recorded by starting the tape and launching the app.
`recordVideo` takes anywhere between two and fourteen seconds to begin writing,
and the opening — the menu, the board turning — has already happened by then.
So the app is launched first and waits, on a menu that is already up, until a
file appears telling it the tape is rolling.

Each scene also says when it is arranged, and the scripts wait for that rather
than for a number of seconds. The numbers they replaced were tuned against a
warm simulator and photographed a black screen on a cold one.

## Why frames are compared

Every fault these previews have had was something not moving: a frozen frame
left by cutting a stream copy at a keyframe, a search typed behind the menu, a
title board caught in the pause between two games, a game that never started.
All of them were found by a person watching.

`stillness.py` finds them instead. It asks how long the longest unchanging
stretch is, by hashing downscaled frames rather than by thresholding a
difference — no single noise figure both catches the recorder repeating its
first frame and spares a camera orbiting a few pixels a second. Anything over
two seconds is a bad take, and `record-all.sh` shoots it again.


## Screenshot sizes the store actually accepts

`capture.sh` photographs whichever simulator happens to be booted, and that is
the one thing about it worth checking before a run. The App Store has a fixed
set of slots, and a picture that is not one of those sizes is refused on upload:

| Slot | Pixels | Simulator |
|---|---|---|
| `APP_IPHONE_67` | 1320 × 2868 | iPhone 17 Pro Max |
| `APP_IPHONE_65` | 1242 × 2688 | iPhone 11 Pro Max and kin |
| `APP_IPHONE_61` | 1206 × 2622 | iPhone 17 Pro |
| `APP_IPAD_PRO_3GEN_129` | 2064 × 2752 | iPad Pro 13-inch |

The sizes here are the ones App Store Connect was asked to accept, one slot
at a time, rather than the ones a table somewhere claims. What matters is that
the slot matches the pixels: a 1206 × 2622 picture is fine, and is fine only in
`APP_IPHONE_61`. Put it in `APP_IPHONE_65` and it is refused.

## Why the age rating is 4+

Declared through the API, everything `NONE` or `false`. Nothing on Apple's list
is in the app, and the two questions that decide a rating for a game played
against a stranger — messaging and chat, user-generated content — are answered
by the wire protocol in `MatchProtocol.swift`: it carries a move, a
resignation, a draw offer and a result. There is no field a person can type
into, so there is nothing to moderate.

A capture is not violence, and chess is not simulated gambling.

**Not in the Kids Category**, which is a separate thing from a 4+ rating. That
category forbids links out of the app without a parental gate, and this one
links to the licence, the privacy policy and the source. Nothing in it needs
that category; the 4+ rating is what puts it in front of a beginner of any age.
