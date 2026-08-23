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
